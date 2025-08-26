import 'package:flutter/material.dart';
import '../models/pcb.dart';
import '../models/bom.dart';
import '../models/materials.dart';
import '../services/bom_services.dart';
import '../services/stock_services.dart';
import '../utils/notifier.dart';

class PcbProvider extends ChangeNotifier {
  final BomService _bomService = BomService();
  final StockService _stockService = StockService();

  // State variables
  List<PCB> _pcbs = [];
  List<BomItem> _currentBomItems = [];
  PCB? _selectedPcb;
  bool _isLoading = false;
  String _errorMessage = '';
  Map<String, int> _batchCalculationResult = {};

  // Getters
  List<PCB> get pcbs => _pcbs;
  List<BomItem> get currentBomItems => _currentBomItems;
  PCB? get selectedPcb => _selectedPcb;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  Map<String, int> get batchCalculationResult => _batchCalculationResult;

  // Create new PCB
  Future<bool> createPcb({
    required String name,
    required String description,
    required String footprint,
    required List<BomItem> bomItems,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Validate BOM items against available materials
      bool hasValidMaterials = await _validateBomMaterials(bomItems);
      if (!hasValidMaterials) {
        _setError('Some BOM materials are not available in stock');
        return false;
      }

      // Create PCB object
      PCB newPcb = PCB(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: description,
        footprint: footprint,
        bomItems: bomItems,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add to list
      _pcbs.add(newPcb);
      _selectedPcb = newPcb;

      // Save to local storage
      await _savePcbsToStorage();

      NotificationUtils.showSuccess('PCB "$name" created successfully');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create PCB: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Upload and process BOM from Excel
  Future<bool> uploadBom(String filePath) async {
    try {
      _setLoading(true);
      _clearError();

      // Process Excel file through BOM service
      List<BomItem> bomItems = await _bomService.processBomFile(filePath);
      
      if (bomItems.isEmpty) {
        _setError('No valid BOM items found in the uploaded file');
        return false;
      }

      // Validate materials exist in inventory
      List<BomItem> validatedItems = await _validateAndEnrichBomItems(bomItems);
      
      _currentBomItems = validatedItems;
      
      NotificationUtils.showSuccess('BOM uploaded successfully with ${bomItems.length} items');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to upload BOM: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Calculate batch production requirements
  Future<Map<String, dynamic>> calculateBatchRequirements({
    required String pcbId,
    required int quantity,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      PCB? pcb = _pcbs.firstWhere((p) => p.id == pcbId);
      if (pcb == null) {
        throw Exception('PCB not found');
      }

      Map<String, dynamic> result = {
        'canProduce': true,
        'requiredMaterials': <String, int>{},
        'insufficientMaterials': <String, int>{},
        'totalCost': 0.0,
      };

      // Calculate required quantities for each material
      for (BomItem bomItem in pcb.bomItems) {
        int requiredQty = bomItem.quantity * quantity;
        result['requiredMaterials'][bomItem.reference] = requiredQty;

        // Check available stock
        Material? material = await _stockService.getMaterialByReference(bomItem.reference);
        if (material == null || material.remainingStock < requiredQty) {
          result['canProduce'] = false;
          result['insufficientMaterials'][bomItem.reference] = 
              requiredQty - (material?.remainingStock ?? 0);
        }

        // Calculate cost if material has price
        if (material != null && material.unitPrice != null) {
          result['totalCost'] += material.unitPrice! * requiredQty;
        }
      }

      _batchCalculationResult = result['requiredMaterials'];
      
      notifyListeners();
      return result;
    } catch (e) {
      _setError('Failed to calculate batch requirements: ${e.toString()}');
      return {
        'canProduce': false,
        'requiredMaterials': <String, int>{},
        'insufficientMaterials': <String, int>{},
        'totalCost': 0.0,
      };
    } finally {
      _setLoading(false);
    }
  }

  // Build PCB and update stock
  Future<bool> buildPcb({
    required String pcbId,
    required int quantity,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // First check if we can build
      Map<String, dynamic> requirements = await calculateBatchRequirements(
        pcbId: pcbId,
        quantity: quantity,
      );

      if (!requirements['canProduce']) {
        _setError('Insufficient materials to build $quantity PCBs');
        return false;
      }

      PCB? pcb = _pcbs.firstWhere((p) => p.id == pcbId);
      if (pcb == null) {
        throw Exception('PCB not found');
      }

      // Update stock for each BOM item
      for (BomItem bomItem in pcb.bomItems) {
        int usedQty = bomItem.quantity * quantity;
        bool stockUpdated = await _stockService.updateMaterialUsage(
          bomItem.reference,
          usedQty,
        );
        
        if (!stockUpdated) {
          _setError('Failed to update stock for ${bomItem.reference}');
          return false;
        }
      }

      // Update PCB build count
      pcb.builtCount += quantity;
      pcb.updatedAt = DateTime.now();

      await _savePcbsToStorage();

      NotificationUtils.showSuccess('Built $quantity units of ${pcb.name}');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to build PCB: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get PCB by ID
  PCB? getPcbById(String id) {
    try {
      return _pcbs.firstWhere((pcb) => pcb.id == id);
    } catch (e) {
      return null;
    }
  }

  // Update PCB
  Future<bool> updatePcb(PCB updatedPcb) async {
    try {
      _setLoading(true);
      _clearError();

      int index = _pcbs.indexWhere((pcb) => pcb.id == updatedPcb.id);
      if (index == -1) {
        _setError('PCB not found');
        return false;
      }

      updatedPcb.updatedAt = DateTime.now();
      _pcbs[index] = updatedPcb;

      if (_selectedPcb?.id == updatedPcb.id) {
        _selectedPcb = updatedPcb;
      }

      await _savePcbsToStorage();
      
      NotificationUtils.showSuccess('PCB updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update PCB: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete PCB
  Future<bool> deletePcb(String id) async {
    try {
      _setLoading(true);
      _clearError();

      int index = _pcbs.indexWhere((pcb) => pcb.id == id);
      if (index == -1) {
        _setError('PCB not found');
        return false;
      }

      String pcbName = _pcbs[index].name;
      _pcbs.removeAt(index);

      if (_selectedPcb?.id == id) {
        _selectedPcb = null;
      }

      await _savePcbsToStorage();
      
      NotificationUtils.showSuccess('PCB "$pcbName" deleted successfully');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete PCB: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load PCBs from storage
  Future<void> loadPcbs() async {
    try {
      _setLoading(true);
      _clearError();

      // Load from local storage (implement based on your storage solution)
      List<PCB> loadedPcbs = await _loadPcbsFromStorage();
      _pcbs = loadedPcbs;

      notifyListeners();
    } catch (e) {
      _setError('Failed to load PCBs: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Clear current BOM items
  void clearCurrentBom() {
    _currentBomItems.clear();
    notifyListeners();
  }

  // Select PCB
  void selectPcb(PCB pcb) {
    _selectedPcb = pcb;
    notifyListeners();
  }

  // Clear selection
  void clearSelection() {
    _selectedPcb = null;
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    NotificationUtils.showError(error);
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
  }

  // Validate BOM materials against inventory
  Future<bool> _validateBomMaterials(List<BomItem> bomItems) async {
    for (BomItem item in bomItems) {
      Material? material = await _stockService.getMaterialByReference(item.reference);
      if (material == null) {
        return false;
      }
    }
    return true;
  }

  // Validate and enrich BOM items with material info
  Future<List<BomItem>> _validateAndEnrichBomItems(List<BomItem> bomItems) async {
    List<BomItem> enrichedItems = [];
    
    for (BomItem item in bomItems) {
      Material? material = await _stockService.getMaterialByReference(item.reference);
      if (material != null) {
        // Create enriched BOM item with material info
        BomItem enrichedItem = BomItem(
          srNo: item.srNo,
          reference: item.reference,
          value: item.value,
          footprint: item.footprint,
          quantity: item.quantity,
          side: item.side,
          materialName: material.name,
          availableStock: material.remainingStock,
          unitPrice: material.unitPrice,
        );
        enrichedItems.add(enrichedItem);
      } else {
        // Add with warning for missing material
        BomItem warningItem = BomItem(
          srNo: item.srNo,
          reference: item.reference,
          value: item.value,
          footprint: item.footprint,
          quantity: item.quantity,
          side: item.side,
          materialName: 'Material not found in inventory',
          availableStock: 0,
        );
        enrichedItems.add(warningItem);
      }
    }
    
    return enrichedItems;
  }

  // Storage operations (implement based on your storage solution)
  Future<void> _savePcbsToStorage() async {
    // Implement saving to local storage
    // This could use SharedPreferences, SQLite, or file system
  }

  Future<List<PCB>> _loadPcbsFromStorage() async {
    // Implement loading from local storage
    // Return empty list for now
    return [];
  }

  @override
  void dispose() {
    _pcbs.clear();
    _currentBomItems.clear();
    _selectedPcb = null;
    super.dispose();
  }
}