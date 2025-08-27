import 'package:flutter/foundation.dart';
import '../models/materials.dart';
import '../services/excel_service.dart';
import '../services/stock_services.dart';
import '../utils/search_trie.dart';

class MaterialsProvider extends ChangeNotifier {
  List<Material> _materials = [];
  List<Material> _filteredMaterials = [];
  SearchTrie _searchTrie = SearchTrie();
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';
  MaterialFilter _currentFilter = MaterialFilter.none;
  bool _isAscending = true;

  // Getters
  List<Material> get materials => _filteredMaterials;
  List<Material> get allMaterials => _materials;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  MaterialFilter get currentFilter => _currentFilter;
  bool get isAscending => _isAscending;
  int get totalMaterials => _materials.length;
  int get lowStockCount => _materials.where((m) => m.isLowStock).length;

  // Load materials from Excel file
  Future<void> loadMaterialsFromExcel(String filePath) async {
    _setLoading(true);
    _setError('');

    try {
      final excelService = ExcelService();
      final loadedMaterials = await excelService.importMaterials(filePath);

      _materials = loadedMaterials;
      _buildSearchTrie();
      _applyCurrentFilters();

      // Save to local storage
      await StockService.saveMaterialsToLocal(_materials);

      _setError('');
    } catch (e) {
      _setError('Failed to load Excel file: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load materials from local storage
  Future<void> loadMaterialsFromLocal() async {
    _setLoading(true);

    try {
      _materials = await StockService.loadMaterialsFromLocal();
      _buildSearchTrie();
      _applyCurrentFilters();
    } catch (e) {
      _setError('Failed to load local data: ${e.toString()}');
      _materials = [];
      _filteredMaterials = [];
    } finally {
      _setLoading(false);
    }
  }

  // Add new material
  void addMaterial(Material material) {
    _materials.add(material);
    _searchTrie.insert(material.name, material.id);
    _searchTrie.insert(material.category, material.id);
    _applyCurrentFilters();
    _saveToLocal();
    notifyListeners();
  }

  // Update material stock
  Future<void> updateMaterialStock(String materialId, int newQuantity) async {
    try {
      final materialIndex = _materials.indexWhere((m) => m.id == materialId);
      if (materialIndex != -1) {
        _materials[materialIndex] = _materials[materialIndex].copyWith(
          remainingQuantity: newQuantity,
        );
        _applyCurrentFilters();
        await _saveToLocal();
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update stock: ${e.toString()}');
    }
  }

  // Use materials for production
  Future<bool> useMaterials(List<MaterialUsage> usageList) async {
    try {
      for (final usage in usageList) {
        final material = _materials.firstWhere((m) => m.id == usage.materialId);
        if (material.remainingQuantity < usage.quantity) {
          _setError('Insufficient stock for ${material.name}');
          return false;
        }
      }

      // If all checks pass, update quantities
      for (final usage in usageList) {
        final materialIndex = _materials.indexWhere(
          (m) => m.id == usage.materialId,
        );
        if (materialIndex != -1) {
          final currentMaterial = _materials[materialIndex];
          _materials[materialIndex] = currentMaterial.copyWith(
            remainingQuantity:
                currentMaterial.remainingQuantity - usage.quantity,
            usedQuantity: currentMaterial.usedQuantity + usage.quantity,
          );
        }
      }

      _applyCurrentFilters();
      await _saveToLocal();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to use materials: ${e.toString()}');
      return false;
    }
  }

  // Search materials
  void searchMaterials(String query) {
    _searchQuery = query;
    _applyCurrentFilters();
    notifyListeners();
  }

  // Apply filters
  void applyFilter(MaterialFilter filter, {bool? ascending}) {
    _currentFilter = filter;
    if (ascending != null) {
      _isAscending = ascending;
    }
    _applyCurrentFilters();
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _searchQuery = '';
    _currentFilter = MaterialFilter.none;
    _isAscending = true;
    _applyCurrentFilters();
    notifyListeners();
  }

  // Get materials that need restock
  List<Material> getLowStockMaterials() {
    return _materials.where((material) => material.isLowStock).toList();
  }

  // Check if sufficient stock exists for production
  Map<String, int> checkStockRequirements(List<MaterialUsage> requirements) {
    Map<String, int> shortages = {};

    for (final requirement in requirements) {
      final material = _materials.firstWhere(
        (m) => m.id == requirement.materialId,
        orElse: () =>
            throw Exception('Material not found: ${requirement.materialId}'),
      );

      if (material.remainingQuantity < requirement.quantity) {
        shortages[material.name] =
            requirement.quantity - material.remainingQuantity;
      }
    }

    return shortages;
  }

  // Export current materials to Excel
  Future<String?> exportMaterialsToExcel() async {
    try {
      final excelService = ExcelService();
      return await excelService.exportMaterials(_materials);
    } catch (e) {
      _setError('Failed to export materials: ${e.toString()}');
      return null;
    }
  }

  // Private helper methods
  void _buildSearchTrie() {
    _searchTrie = SearchTrie();
    for (final material in _materials) {
      _searchTrie.insert(material.name.toLowerCase(), material.id);
      _searchTrie.insert(material.category.toLowerCase(), material.id);
      _searchTrie.insert(material.footprint.toLowerCase(), material.id);
    }
  }

  void _applyCurrentFilters() {
    List<Material> filtered = List.from(_materials);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final searchResults = _searchTrie.search(_searchQuery.toLowerCase());
      filtered = filtered
          .where((material) => searchResults.contains(material.id))
          .toList();
    }

    // Apply sorting filter
    switch (_currentFilter) {
      case MaterialFilter.alphabetical:
        filtered.sort(
          (a, b) => _isAscending
              ? a.name.compareTo(b.name)
              : b.name.compareTo(a.name),
        );
        break;
      case MaterialFilter.quantity:
        filtered.sort(
          (a, b) => _isAscending
              ? a.remainingQuantity.compareTo(b.remainingQuantity)
              : b.remainingQuantity.compareTo(a.remainingQuantity),
        );
        break;
      case MaterialFilter.lowStock:
        filtered = filtered.where((m) => m.isLowStock).toList();
        break;
      case MaterialFilter.category:
        filtered.sort(
          (a, b) => _isAscending
              ? a.category.compareTo(b.category)
              : b.category.compareTo(a.category),
        );
        break;
      case MaterialFilter.mostUsed:
        filtered.sort(
          (a, b) => _isAscending
              ? a.usedQuantity.compareTo(b.usedQuantity)
              : b.usedQuantity.compareTo(a.usedQuantity),
        );
        break;
      case MaterialFilter.none:
      default:
        // No additional sorting
        break;
    }

    _filteredMaterials = filtered;
  }

  Future<void> _saveToLocal() async {
    try {
      await StockService.saveMaterialsToLocal(_materials);
    } catch (e) {
      _setError('Failed to save data locally: ${e.toString()}');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    if (error.isNotEmpty) {
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Enum for filter types
enum MaterialFilter {
  none,
  alphabetical,
  quantity,
  lowStock,
  category,
  mostUsed,
}

// Helper class for material usage tracking
class MaterialUsage {
  final String materialId;
  final int quantity;

  MaterialUsage({required this.materialId, required this.quantity});
}
