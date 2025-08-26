import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/bom.dart';
import '../models/materials.dart';
import '../utils/excel_utils.dart';

class BomService {
  static const String _bomStorageKey = 'stored_boms';
  static const String _bomHistoryKey = 'bom_history';

  // Singleton pattern for service
  static final BomService _instance = BomService._internal();
  factory BomService() => _instance;
  BomService._internal();

  /// Upload BOM from Excel file
  /// Expected format: Sr.No | Reference | Value | Footprint | Qty | Top/Bottom
  Future<List<BomItem>> uploadBomFromExcel() async {
    try {
      // Pick Excel file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('No file selected');
      }

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      List<BomItem> bomItems = [];
      
      // Get first sheet
      final sheet = excel.tables.keys.first;
      final table = excel.tables[sheet];

      if (table == null || table.rows.isEmpty) {
        throw Exception('Excel file is empty or corrupted');
      }

      // Skip header row (assuming first row is header)
      for (int i = 1; i < table.rows.length; i++) {
        final row = table.rows[i];
        
        // Skip empty rows
        if (row.every((cell) => cell?.value == null || cell?.value.toString().trim().isEmpty)) {
          continue;
        }

        try {
          final bomItem = BomItem(
            srNo: _getCellValue(row, 0),
            reference: _getCellValue(row, 1),
            value: _getCellValue(row, 2),
            footprint: _getCellValue(row, 3),
            quantity: _parseQuantity(_getCellValue(row, 4)),
            layer: _getCellValue(row, 5), // Top/Bottom
            createdAt: DateTime.now(),
          );
          
          bomItems.add(bomItem);
        } catch (e) {
          print('Error parsing row $i: $e');
          // Continue with next row instead of stopping
          continue;
        }
      }

      if (bomItems.isEmpty) {
        throw Exception('No valid BOM items found in the Excel file');
      }

      return bomItems;
    } catch (e) {
      print('Error uploading BOM: $e');
      throw Exception('Failed to upload BOM: ${e.toString()}');
    }
  }

  /// Save BOM to local storage for future reference
  Future<void> saveBomToStorage(String bomName, List<BomItem> bomItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final bom = Bom(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: bomName,
        items: bomItems,
        createdAt: DateTime.now(),
      );

      // Get existing BOMs
      final existingBomsJson = prefs.getString(_bomStorageKey) ?? '[]';
      final List<dynamic> existingBoms = json.decode(existingBomsJson);
      
      // Add new BOM
      existingBoms.add(bom.toJson());
      
      // Save back to storage
      await prefs.setString(_bomStorageKey, json.encode(existingBoms));
      
      print('BOM saved successfully: $bomName');
    } catch (e) {
      print('Error saving BOM: $e');
      throw Exception('Failed to save BOM: ${e.toString()}');
    }
  }

  /// Get all saved BOMs
  Future<List<Bom>> getSavedBoms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bomsJson = prefs.getString(_bomStorageKey) ?? '[]';
      final List<dynamic> bomsList = json.decode(bomsJson);
      
      return bomsList.map((json) => Bom.fromJson(json)).toList();
    } catch (e) {
      print('Error loading BOMs: $e');
      return [];
    }
  }

  /// Get BOM by ID
  Future<Bom?> getBomById(String bomId) async {
    try {
      final boms = await getSavedBoms();
      return boms.firstWhere((bom) => bom.id == bomId);
    } catch (e) {
      print('BOM not found: $bomId');
      return null;
    }
  }

  /// Delete BOM by ID
  Future<void> deleteBom(String bomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final boms = await getSavedBoms();
      
      boms.removeWhere((bom) => bom.id == bomId);
      
      final bomsJson = boms.map((bom) => bom.toJson()).toList();
      await prefs.setString(_bomStorageKey, json.encode(bomsJson));
    } catch (e) {
      print('Error deleting BOM: $e');
      throw Exception('Failed to delete BOM');
    }
  }

  /// Calculate material requirements for multiple PCBs
  /// Returns a map of material -> required quantity
  Map<String, int> calculateMaterialRequirements(List<BomItem> bomItems, int pcbQuantity) {
    Map<String, int> requirements = {};
    
    for (var item in bomItems) {
      final materialKey = '${item.value}-${item.footprint}';
      final totalRequired = item.quantity * pcbQuantity;
      
      if (requirements.containsKey(materialKey)) {
        requirements[materialKey] = requirements[materialKey]! + totalRequired;
      } else {
        requirements[materialKey] = totalRequired;
      }
    }
    
    return requirements;
  }

  /// Check if enough materials are available for production
  /// Returns list of insufficient materials
  Future<List<String>> checkMaterialAvailability(
    List<BomItem> bomItems, 
    int pcbQuantity,
    List<Material> availableMaterials
  ) async {
    final requirements = calculateMaterialRequirements(bomItems, pcbQuantity);
    List<String> insufficientMaterials = [];
    
    for (var entry in requirements.entries) {
      final materialKey = entry.key;
      final requiredQty = entry.value;
      
      // Find matching material in available materials
      final availableMaterial = availableMaterials.firstWhere(
        (material) => '${material.value}-${material.footprint}' == materialKey,
        orElse: () => Material(
          id: '',
          name: '',
          value: '',
          footprint: '',
          initialQuantity: 0,
          remainingQuantity: 0,
          usedQuantity: 0,
        ),
      );
      
      if (availableMaterial.id.isEmpty || availableMaterial.remainingQuantity < requiredQty) {
        final shortfall = requiredQty - (availableMaterial.remainingQuantity);
        insufficientMaterials.add(
          '$materialKey: Need $requiredQty, Available ${availableMaterial.remainingQuantity}, Short by $shortfall'
        );
      }
    }
    
    return insufficientMaterials;
  }

  /// Export BOM to Excel file
  Future<String> exportBomToExcel(Bom bom) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['BOM_${bom.name}'];
      
      // Add headers
      final headers = ['Sr.No', 'Reference', 'Value', 'Footprint', 'Qty', 'Top/Bottom'];
      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = headers[i];
      }
      
      // Add data rows
      for (int i = 0; i < bom.items.length; i++) {
        final item = bom.items[i];
        final rowIndex = i + 1;
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = item.srNo;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = item.reference;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = item.value;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = item.footprint;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = item.quantity;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = item.layer;
      }
      
      // Save file
      final fileName = 'BOM_${bom.name}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final bytes = excel.encode();
      
      if (bytes != null) {
        final file = File('/storage/emulated/0/Download/$fileName');
        await file.writeAsBytes(bytes);
        return file.path;
      } else {
        throw Exception('Failed to encode Excel file');
      }
    } catch (e) {
      print('Error exporting BOM: $e');
      throw Exception('Failed to export BOM: ${e.toString()}');
    }
  }

  /// Add BOM usage to history for tracking
  Future<void> addBomUsageToHistory(String bomId, String deviceName, int quantity, DateTime usedAt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_bomHistoryKey) ?? '[]';
      final List<dynamic> history = json.decode(historyJson);
      
      final usage = {
        'bomId': bomId,
        'deviceName': deviceName,
        'quantity': quantity,
        'usedAt': usedAt.toIso8601String(),
      };
      
      history.add(usage);
      
      // Keep only last 100 records to prevent storage bloat
      if (history.length > 100) {
        history.removeRange(0, history.length - 100);
      }
      
      await prefs.setString(_bomHistoryKey, json.encode(history));
    } catch (e) {
      print('Error adding BOM usage to history: $e');
    }
  }

  /// Get BOM usage history
  Future<List<Map<String, dynamic>>> getBomUsageHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_bomHistoryKey) ?? '[]';
      final List<dynamic> history = json.decode(historyJson);
      
      return history.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error loading BOM history: $e');
      return [];
    }
  }

  /// Helper method to get cell value safely
  String _getCellValue(List<Data?> row, int index) {
    if (index >= row.length || row[index]?.value == null) {
      return '';
    }
    return row[index]!.value.toString().trim();
  }

  /// Helper method to parse quantity safely
  int _parseQuantity(String value) {
    if (value.isEmpty) return 0;
    return int.tryParse(value) ?? 0;
  }

  /// Clear all BOM data (for reset/debugging)
  Future<void> clearAllBomData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_bomStorageKey);
      await prefs.remove(_bomHistoryKey);
    } catch (e) {
      print('Error clearing BOM data: $e');
    }
  }
}