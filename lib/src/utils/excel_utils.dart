import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ExcelUtils {
  // Column indices for raw materials Excel format
  static const int MATERIAL_NAME_COL = 0;
  static const int INITIAL_QTY_COL = 1;
  static const int REMAINING_QTY_COL = 2;
  static const int USED_QTY_COL = 3;
  static const int MIN_QTY_COL = 4;
  static const int UNIT_COL = 5;
  
  // Column indices for BOM Excel format
  static const int BOM_SR_NO_COL = 0;
  static const int BOM_REFERENCE_COL = 1;
  static const int BOM_VALUE_COL = 2;
  static const int BOM_FOOTPRINT_COL = 3;
  static const int BOM_QTY_COL = 4;
  static const int BOM_SIDE_COL = 5; // top/bottom

  /// Pick and read Excel file for raw materials import
  static Future<List<Map<String, dynamic>>?> importRawMaterials() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        return _parseRawMaterialsExcel(result.files.single.bytes!);
      }
    } catch (e) {
      debugPrint('Error importing raw materials: $e');
      throw Exception('Failed to import Excel file: $e');
    }
    return null;
  }

  /// Pick and read Excel file for BOM import
  static Future<List<Map<String, dynamic>>?> importBOM() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        return _parseBOMExcel(result.files.single.bytes!);
      }
    } catch (e) {
      debugPrint('Error importing BOM: $e');
      throw Exception('Failed to import BOM file: $e');
    }
    return null;
  }

  /// Parse raw materials Excel data
  static List<Map<String, dynamic>> _parseRawMaterialsExcel(Uint8List bytes) {
    List<Map<String, dynamic>> materials = [];
    
    try {
      var excel = Excel.decodeBytes(bytes);
      
      // Get first sheet
      String? firstSheetName = excel.sheets.keys.first;
      Sheet? sheet = excel.sheets[firstSheetName];
      
      if (sheet == null) {
        throw Exception('No valid sheet found in Excel file');
      }

      // Skip header row (assuming row 0 is header)
      for (int row = 1; row < sheet.maxRows; row++) {
        var materialName = _getCellValue(sheet, row, MATERIAL_NAME_COL);
        
        // Skip empty rows
        if (materialName == null || materialName.toString().trim().isEmpty) {
          continue;
        }

        var initialQty = _getCellValue(sheet, row, INITIAL_QTY_COL);
        var remainingQty = _getCellValue(sheet, row, REMAINING_QTY_COL);
        var usedQty = _getCellValue(sheet, row, USED_QTY_COL);
        var minQty = _getCellValue(sheet, row, MIN_QTY_COL);
        var unit = _getCellValue(sheet, row, UNIT_COL);

        materials.add({
          'name': materialName.toString().trim(),
          'initialQuantity': _parseNumber(initialQty) ?? 0.0,
          'remainingQuantity': _parseNumber(remainingQty) ?? 0.0,
          'usedQuantity': _parseNumber(usedQty) ?? 0.0,
          'minQuantity': _parseNumber(minQty) ?? 0.0,
          'unit': unit?.toString().trim() ?? 'pcs',
          'importedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error parsing raw materials Excel: $e');
      throw Exception('Invalid Excel format for raw materials: $e');
    }

    return materials;
  }

  /// Parse BOM Excel data
  static List<Map<String, dynamic>> _parseBOMExcel(Uint8List bytes) {
    List<Map<String, dynamic>> bomItems = [];
    
    try {
      var excel = Excel.decodeBytes(bytes);
      
      // Get first sheet
      String? firstSheetName = excel.sheets.keys.first;
      Sheet? sheet = excel.sheets[firstSheetName];
      
      if (sheet == null) {
        throw Exception('No valid sheet found in BOM file');
      }

      // Skip header row
      for (int row = 1; row < sheet.maxRows; row++) {
        var reference = _getCellValue(sheet, row, BOM_REFERENCE_COL);
        
        // Skip empty rows
        if (reference == null || reference.toString().trim().isEmpty) {
          continue;
        }

        var srNo = _getCellValue(sheet, row, BOM_SR_NO_COL);
        var value = _getCellValue(sheet, row, BOM_VALUE_COL);
        var footprint = _getCellValue(sheet, row, BOM_FOOTPRINT_COL);
        var qty = _getCellValue(sheet, row, BOM_QTY_COL);
        var side = _getCellValue(sheet, row, BOM_SIDE_COL);

        bomItems.add({
          'srNo': srNo?.toString().trim() ?? '',
          'reference': reference.toString().trim(),
          'value': value?.toString().trim() ?? '',
          'footprint': footprint?.toString().trim() ?? '',
          'quantity': _parseNumber(qty) ?? 1.0,
          'side': side?.toString().trim().toLowerCase() ?? 'top',
          'importedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error parsing BOM Excel: $e');
      throw Exception('Invalid Excel format for BOM: $e');
    }

    return bomItems;
  }

  /// Export raw materials to Excel
  static Future<bool> exportRawMaterials(List<Map<String, dynamic>> materials) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Raw Materials'];

      // Add headers
      sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Material Name');
      sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Initial Quantity');
      sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Remaining Quantity');
      sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('Used Quantity');
      sheet.cell(CellIndex.indexByString('E1')).value = TextCellValue('Min Quantity');
      sheet.cell(CellIndex.indexByString('F1')).value = TextCellValue('Unit');

      // Add data
      for (int i = 0; i < materials.length; i++) {
        int row = i + 2; // Start from row 2 (after header)
        var material = materials[i];
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row - 1)).value = 
            TextCellValue(material['name'] ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row - 1)).value = 
            DoubleCellValue(material['initialQuantity']?.toDouble() ?? 0.0);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row - 1)).value = 
            DoubleCellValue(material['remainingQuantity']?.toDouble() ?? 0.0);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row - 1)).value = 
            DoubleCellValue(material['usedQuantity']?.toDouble() ?? 0.0);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row - 1)).value = 
            DoubleCellValue(material['minQuantity']?.toDouble() ?? 0.0);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row - 1)).value = 
            TextCellValue(material['unit'] ?? 'pcs');
      }

      return await _saveExcelFile(excel, 'raw_materials_export.xlsx');
    } catch (e) {
      debugPrint('Error exporting raw materials: $e');
      return false;
    }
  }

  /// Export BOM to Excel
  static Future<bool> exportBOM(List<Map<String, dynamic>> bomItems, String pcbName) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['BOM_$pcbName'];

      // Add headers
      sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Sr. No');
      sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Reference');
      sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Value');
      sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('Footprint');
      sheet.cell(CellIndex.indexByString('E1')).value = TextCellValue('Quantity');
      sheet.cell(CellIndex.indexByString('F1')).value = TextCellValue('Side');

      // Add data
      for (int i = 0; i < bomItems.length; i++) {
        int row = i + 2;
        var item = bomItems[i];
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row - 1)).value = 
            TextCellValue(item['srNo'] ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row - 1)).value = 
            TextCellValue(item['reference'] ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row - 1)).value = 
            TextCellValue(item['value'] ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row - 1)).value = 
            TextCellValue(item['footprint'] ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row - 1)).value = 
            DoubleCellValue(item['quantity']?.toDouble() ?? 1.0);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row - 1)).value = 
            TextCellValue(item['side'] ?? 'top');
      }

      return await _saveExcelFile(excel, 'BOM_${pcbName}_export.xlsx');
    } catch (e) {
      debugPrint('Error exporting BOM: $e');
      return false;
    }
  }

  /// Create template Excel files for import
  static Future<bool> createRawMaterialsTemplate() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Raw Materials Template'];

      // Add headers
      sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Material Name');
      sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Initial Quantity');
      sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Remaining Quantity');
      sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('Used Quantity');
      sheet.cell(CellIndex.indexByString('E1')).value = TextCellValue('Min Quantity');
      sheet.cell(CellIndex.indexByString('F1')).value = TextCellValue('Unit');

      // Add sample data
      sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue('Resistor 10K');
      sheet.cell(CellIndex.indexByString('B2')).value = DoubleCellValue(100.0);
      sheet.cell(CellIndex.indexByString('C2')).value = DoubleCellValue(85.0);
      sheet.cell(CellIndex.indexByString('D2')).value = DoubleCellValue(15.0);
      sheet.cell(CellIndex.indexByString('E2')).value = DoubleCellValue(20.0);
      sheet.cell(CellIndex.indexByString('F2')).value = TextCellValue('pcs');

      return await _saveExcelFile(excel, 'raw_materials_template.xlsx');
    } catch (e) {
      debugPrint('Error creating template: $e');
      return false;
    }
  }

  /// Helper method to get cell value safely
  static CellValue? _getCellValue(Sheet sheet, int row, int col) {
    try {
      return sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value;
    } catch (e) {
      return null;
    }
  }

  /// Helper method to parse numeric values
  static double? _parseNumber(CellValue? cellValue) {
    if (cellValue == null) return null;
    
    if (cellValue is DoubleCellValue) {
      return cellValue.value;
    } else if (cellValue is IntCellValue) {
      return cellValue.value.toDouble();
    } else if (cellValue is TextCellValue) {
      try {
        return double.parse(cellValue.value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Helper method to save Excel file
  static Future<bool> _saveExcelFile(Excel excel, String fileName) async {
    try {
      List<int>? fileBytes = excel.save();
      if (fileBytes == null) return false;

      if (kIsWeb) {
        // For web, trigger download
        // Note: You'll need to implement web download logic here
        debugPrint('Web download not implemented yet');
        return false;
      } else {
        // For mobile/desktop
        Directory? directory = await getApplicationDocumentsDirectory();
        String filePath = '${directory.path}/$fileName';
        File file = File(filePath);
        await file.writeAsBytes(fileBytes);
        debugPrint('File saved to: $filePath');
        return true;
      }
    } catch (e) {
      debugPrint('Error saving Excel file: $e');
      return false;
    }
  }

  /// Validate raw materials Excel format
  static bool validateRawMaterialsFormat(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return false;
    
    for (var material in data) {
      if (!material.containsKey('name') || 
          material['name'].toString().trim().isEmpty) {
        return false;
      }
      
      if (!material.containsKey('initialQuantity') || 
          material['initialQuantity'] == null) {
        return false;
      }
    }
    return true;
  }

  /// Validate BOM Excel format
  static bool validateBOMFormat(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return false;
    
    for (var item in data) {
      if (!item.containsKey('reference') || 
          item['reference'].toString().trim().isEmpty) {
        return false;
      }
      
      if (!item.containsKey('quantity') || 
          item['quantity'] == null || 
          item['quantity'] <= 0) {
        return false;
      }
    }
    return true;
  }
}