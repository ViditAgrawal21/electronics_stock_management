import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/materials.dart';
import '../models/bom.dart';

class ExcelService {
  static const String _materialsFileName = 'materials_inventory.xlsx';
  static const String _bomFileName = 'bom_data.xlsx';
  
  /// Import raw materials from Excel file
  /// Expected format: Name, Description, Initial_Qty, Used_Qty, Remaining_Qty, Min_Stock, Unit, Category
  Future<List<Material>> importMaterialsFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        var bytes = result.files.single.bytes!;
        var excel = Excel.decodeBytes(bytes);
        
        List<Material> materials = [];
        
        // Get first sheet
        var sheet = excel.tables.keys.first;
        var table = excel.tables[sheet]!;
        
        // Skip header row (index 0)
        for (int i = 1; i < table.maxRows; i++) {
          var row = table.rows[i];
          
          // Skip empty rows
          if (row.isEmpty || row.every((cell) => cell?.value == null)) {
            continue;
          }
          
          try {
            String name = _getCellValue(row[0]) ?? '';
            String description = _getCellValue(row[1]) ?? '';
            double initialQty = _parseDouble(_getCellValue(row[2])) ?? 0.0;
            double usedQty = _parseDouble(_getCellValue(row[3])) ?? 0.0;
            double remainingQty = _parseDouble(_getCellValue(row[4])) ?? 0.0;
            double minStock = _parseDouble(_getCellValue(row[5])) ?? 0.0;
            String unit = _getCellValue(row[6]) ?? 'pcs';
            String category = _getCellValue(row[7]) ?? 'General';
            
            // If remaining quantity is not provided, calculate it
            if (remainingQty == 0.0 && initialQty > 0) {
              remainingQty = initialQty - usedQty;
            }
            
            if (name.isNotEmpty) {
              materials.add(Material(
                id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
                name: name,
                description: description,
                initialQuantity: initialQty,
                usedQuantity: usedQty,
                remainingQuantity: remainingQty,
                minStockLevel: minStock,
                unit: unit,
                category: category,
                lastUpdated: DateTime.now(),
              ));
            }
          } catch (e) {
            print('Error processing row $i: $e');
            // Continue with next row
            continue;
          }
        }
        
        return materials;
      }
    } catch (e) {
      print('Error importing materials: $e');
      throw Exception('Failed to import materials from Excel: $e');
    }
    
    return [];
  }
  
  /// Import BOM from Excel file
  /// Expected format: Sr_No, Reference, Value, Footprint, Qty, Top_Bottom
  Future<List<BomItem>> importBomFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        var bytes = result.files.single.bytes!;
        var excel = Excel.decodeBytes(bytes);
        
        List<BomItem> bomItems = [];
        
        // Get first sheet
        var sheet = excel.tables.keys.first;
        var table = excel.tables[sheet]!;
        
        // Skip header row (index 0)
        for (int i = 1; i < table.maxRows; i++) {
          var row = table.rows[i];
          
          // Skip empty rows
          if (row.isEmpty || row.every((cell) => cell?.value == null)) {
            continue;
          }
          
          try {
            int srNo = _parseInt(_getCellValue(row[0])) ?? i;
            String reference = _getCellValue(row[1]) ?? '';
            String value = _getCellValue(row[2]) ?? '';
            String footprint = _getCellValue(row[3]) ?? '';
            int quantity = _parseInt(_getCellValue(row[4])) ?? 1;
            String topBottom = _getCellValue(row[5]) ?? 'Top';
            
            if (reference.isNotEmpty && value.isNotEmpty) {
              bomItems.add(BomItem(
                id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
                serialNumber: srNo,
                reference: reference,
                value: value,
                footprint: footprint,
                quantity: quantity,
                topBottom: topBottom,
              ));
            }
          } catch (e) {
            print('Error processing BOM row $i: $e');
            continue;
          }
        }
        
        return bomItems;
      }
    } catch (e) {
      print('Error importing BOM: $e');
      throw Exception('Failed to import BOM from Excel: $e');
    }
    
    return [];
  }
  
  /// Export materials to Excel file
  Future<bool> exportMaterialsToExcel(List<Material> materials) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Materials'];
      
      // Add headers
      sheet.cell(CellIndex.indexByString('A1')).value = 'Name';
      sheet.cell(CellIndex.indexByString('B1')).value = 'Description';
      sheet.cell(CellIndex.indexByString('C1')).value = 'Initial_Qty';
      sheet.cell(CellIndex.indexByString('D1')).value = 'Used_Qty';
      sheet.cell(CellIndex.indexByString('E1')).value = 'Remaining_Qty';
      sheet.cell(CellIndex.indexByString('F1')).value = 'Min_Stock';
      sheet.cell(CellIndex.indexByString('G1')).value = 'Unit';
      sheet.cell(CellIndex.indexByString('H1')).value = 'Category';
      sheet.cell(CellIndex.indexByString('I1')).value = 'Last_Updated';
      
      // Add data
      for (int i = 0; i < materials.length; i++) {
        int row = i + 2; // Start from row 2 (after header)
        Material material = materials[i];
        
        sheet.cell(CellIndex.indexByString('A$row')).value = material.name;
        sheet.cell(CellIndex.indexByString('B$row')).value = material.description;
        sheet.cell(CellIndex.indexByString('C$row')).value = material.initialQuantity;
        sheet.cell(CellIndex.indexByString('D$row')).value = material.usedQuantity;
        sheet.cell(CellIndex.indexByString('E$row')).value = material.remainingQuantity;
        sheet.cell(CellIndex.indexByString('F$row')).value = material.minStockLevel;
        sheet.cell(CellIndex.indexByString('G$row')).value = material.unit;
        sheet.cell(CellIndex.indexByString('H$row')).value = material.category;
        sheet.cell(CellIndex.indexByString('I$row')).value = material.lastUpdated.toIso8601String();
      }
      
      // Save to app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$_materialsFileName';
      
      var fileBytes = excel.save();
      if (fileBytes != null) {
        File(path)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error exporting materials: $e');
      return false;
    }
  }
  
  /// Export BOM to Excel file
  Future<bool> exportBomToExcel(List<BomItem> bomItems, String fileName) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['BOM'];
      
      // Add headers
      sheet.cell(CellIndex.indexByString('A1')).value = 'Sr_No';
      sheet.cell(CellIndex.indexByString('B1')).value = 'Reference';
      sheet.cell(CellIndex.indexByString('C1')).value = 'Value';
      sheet.cell(CellIndex.indexByString('D1')).value = 'Footprint';
      sheet.cell(CellIndex.indexByString('E1')).value = 'Qty';
      sheet.cell(CellIndex.indexByString('F1')).value = 'Top_Bottom';
      
      // Add data
      for (int i = 0; i < bomItems.length; i++) {
        int row = i + 2;
        BomItem item = bomItems[i];
        
        sheet.cell(CellIndex.indexByString('A$row')).value = item.serialNumber;
        sheet.cell(CellIndex.indexByString('B$row')).value = item.reference;
        sheet.cell(CellIndex.indexByString('C$row')).value = item.value;
        sheet.cell(CellIndex.indexByString('D$row')).value = item.footprint;
        sheet.cell(CellIndex.indexByString('E$row')).value = item.quantity;
        sheet.cell(CellIndex.indexByString('F$row')).value = item.topBottom;
      }
      
      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/${fileName.isEmpty ? _bomFileName : fileName}';
      
      var fileBytes = excel.save();
      if (fileBytes != null) {
        File(path)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error exporting BOM: $e');
      return false;
    }
  }
  
  /// Create template Excel file for materials
  Future<String?> createMaterialTemplate() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Materials_Template'];
      
      // Add headers with sample data
      sheet.cell(CellIndex.indexByString('A1')).value = 'Name';
      sheet.cell(CellIndex.indexByString('B1')).value = 'Description';
      sheet.cell(CellIndex.indexByString('C1')).value = 'Initial_Qty';
      sheet.cell(CellIndex.indexByString('D1')).value = 'Used_Qty';
      sheet.cell(CellIndex.indexByString('E1')).value = 'Remaining_Qty';
      sheet.cell(CellIndex.indexByString('F1')).value = 'Min_Stock';
      sheet.cell(CellIndex.indexByString('G1')).value = 'Unit';
      sheet.cell(CellIndex.indexByString('H1')).value = 'Category';
      
      // Add sample row
      sheet.cell(CellIndex.indexByString('A2')).value = 'Resistor 10k';
      sheet.cell(CellIndex.indexByString('B2')).value = '10k Ohm Resistor 0805';
      sheet.cell(CellIndex.indexByString('C2')).value = 100;
      sheet.cell(CellIndex.indexByString('D2')).value = 0;
      sheet.cell(CellIndex.indexByString('E2')).value = 100;
      sheet.cell(CellIndex.indexByString('F2')).value = 10;
      sheet.cell(CellIndex.indexByString('G2')).value = 'pcs';
      sheet.cell(CellIndex.indexByString('H2')).value = 'Resistors';
      
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/materials_template.xlsx';
      
      var fileBytes = excel.save();
      if (fileBytes != null) {
        File(path)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
        return path;
      }
      
      return null;
    } catch (e) {
      print('Error creating template: $e');
      return null;
    }
  }
  
  /// Create template Excel file for BOM
  Future<String?> createBomTemplate() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['BOM_Template'];
      
      // Add headers
      sheet.cell(CellIndex.indexByString('A1')).value = 'Sr_No';
      sheet.cell(CellIndex.indexByString('B1')).value = 'Reference';
      sheet.cell(CellIndex.indexByString('C1')).value = 'Value';
      sheet.cell(CellIndex.indexByString('D1')).value = 'Footprint';
      sheet.cell(CellIndex.indexByString('E1')).value = 'Qty';
      sheet.cell(CellIndex.indexByString('F1')).value = 'Top_Bottom';
      
      // Add sample rows
      sheet.cell(CellIndex.indexByString('A2')).value = 1;
      sheet.cell(CellIndex.indexByString('B2')).value = 'R1';
      sheet.cell(CellIndex.indexByString('C2')).value = '10k';
      sheet.cell(CellIndex.indexByString('D2')).value = '0805';
      sheet.cell(CellIndex.indexByString('E2')).value = 1;
      sheet.cell(CellIndex.indexByString('F2')).value = 'Top';
      
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/bom_template.xlsx';
      
      var fileBytes = excel.save();
      if (fileBytes != null) {
        File(path)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
        return path;
      }
      
      return null;
    } catch (e) {
      print('Error creating BOM template: $e');
      return null;
    }
  }
  
  // Helper methods
  String? _getCellValue(Data? cell) {
    if (cell?.value == null) return null;
    return cell!.value.toString().trim();
  }
  
  double? _parseDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return double.parse(value);
    } catch (e) {
      return null;
    }
  }
  
  int? _parseInt(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return int.parse(value);
    } catch (e) {
      return null;
    }
  }
}