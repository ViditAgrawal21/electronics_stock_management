import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/materials.dart';
import '../models/bom.dart';
import '../constants/app_config.dart';
import '../utils/excel_utils.dart'; // ADD THIS IMPORT

class ExcelService {
  // Import materials from Excel file - CORRECTED VERSION
  static Future<List<Material>> importMaterials() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConfig.allowedExcelExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        List<int> bytes = await file.readAsBytes();
        Excel excel = Excel.decodeBytes(bytes);

        List<Material> materials = [];

        for (String tableName in excel.tables.keys) {
          Sheet? sheet = excel.tables[tableName];
          if (sheet == null) continue;

          print('Processing sheet: $tableName');

          // Skip header row (assuming first row is header)
          for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
            List<Data?> row = sheet.row(rowIndex);
            if (_isEmptyRow(row)) continue;

            // PRESERVE RAW MATERIAL NAME EXACTLY AS IN EXCEL
            String rawMaterialName = _getRawMaterialName(
              row,
              0,
            ); // First column

            if (rawMaterialName.trim().isEmpty) {
              print('Skipping row $rowIndex: Empty raw material name');
              continue;
            }

            // Convert row to values but preserve the raw material name
            List<dynamic> rowValues = [];
            for (int cellIndex = 0; cellIndex < row.length; cellIndex++) {
              if (cellIndex == 0) {
                // Use preserved raw material name for first column
                rowValues.add(rawMaterialName);
              } else {
                // Use normal conversion for other columns
                rowValues.add(ExcelUtils.convertCellValue(row[cellIndex]));
              }
            }

            // Generate unique ID for material
            String materialId =
                DateTime.now().millisecondsSinceEpoch.toString() + '_$rowIndex';

            try {
              Material material = Material.fromExcelRow(
                rowValues,
                id: materialId,
              );

              if (material.name.isNotEmpty) {
                materials.add(material);
                print('Successfully imported: "${material.name}"');
              }
            } catch (e) {
              print('Error processing row $rowIndex: $e');
              print('Raw material name: "$rawMaterialName"');
              print('Row values: $rowValues');
              continue;
            }
          }
        }

        print('Total materials imported: ${materials.length}');
        return materials;
      }
    } catch (e) {
      print('Error importing materials: $e');
      throw Exception('Failed to import materials: $e');
    }

    return [];
  }

  // Export materials to Excel file
  static Future<bool> exportMaterials(List<Material> materials) async {
    try {
      Excel excel = Excel.createExcel();
      Sheet sheet = excel['Materials'];

      // Add headers
      List<String> headers = [
        'Material Name',
        'Initial Quantity',
        'Remaining Quantity',
        'Used Quantity',
        'Description',
        'Category',
        'Unit Cost',
        'Supplier',
        'Location',
      ];

      for (int i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = TextCellValue(
          headers[i],
        );
      }

      // Add data rows
      for (int i = 0; i < materials.length; i++) {
        List<dynamic> rowData = materials[i].toExcelRow();
        for (int j = 0; j < rowData.length; j++) {
          var cellValue = rowData[j];
          CellValue value;

          if (cellValue is String) {
            value = TextCellValue(cellValue);
          } else if (cellValue is int) {
            value = IntCellValue(cellValue);
          } else if (cellValue is double) {
            value = DoubleCellValue(cellValue);
          } else {
            value = TextCellValue(cellValue?.toString() ?? '');
          }

          sheet
                  .cell(
                    CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1),
                  )
                  .value =
              value;
        }
      }

      // Save file
      Directory? directory = await getExternalStorageDirectory();
      String fileName =
          'materials_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      String filePath = '${directory!.path}/$fileName';

      List<int> fileBytes = excel.save()!;
      File file = File(filePath);
      await file.writeAsBytes(fileBytes);

      return true;
    } catch (e) {
      print('Error exporting materials: $e');
      return false;
    }
  }

  // Import BOM from Excel file
  static Future<List<BOMItem>> importBOM(String pcbId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConfig.allowedExcelExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        List<int> bytes = await file.readAsBytes();
        Excel excel = Excel.decodeBytes(bytes);

        List<BOMItem> bomItems = [];

        for (String tableName in excel.tables.keys) {
          Sheet? sheet = excel.tables[tableName];
          if (sheet == null) continue;

          // Skip header row
          for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
            List<Data?> row = sheet.row(rowIndex);
            if (_isEmptyRow(row)) continue;

            // Convert Data objects to dynamic values
            List<dynamic> rowValues = row
                .map((cell) => ExcelUtils.convertCellValue(cell))
                .toList();

            // Generate unique ID for BOM item
            String bomItemId =
                DateTime.now().millisecondsSinceEpoch.toString() + '_$rowIndex';

            try {
              BOMItem bomItem = BOMItem.fromExcelRow(
                rowValues,
                id: bomItemId,
                pcbId: pcbId,
              );

              // More permissive validation - include rows with reference OR value
              bool hasReference =
                  bomItem.reference.isNotEmpty &&
                  bomItem.reference.trim() != 'Reference';
              bool hasValue =
                  bomItem.value.isNotEmpty && bomItem.value.trim() != 'Value';
              bool hasValidData = hasReference || hasValue;

              // Include rows that have meaningful content
              if (hasValidData) {
                bomItems.add(bomItem);
              } else {
                print('Skipping empty row $rowIndex');
              }
            } catch (e) {
              print('Error processing BOM row $rowIndex: $e');
              continue;
            }
          }
        }

        return bomItems;
      }
    } catch (e) {
      print('Error importing BOM: $e');
      throw Exception('Failed to import BOM: $e');
    }

    return [];
  }

  // Export BOM to Excel file
  static Future<bool> exportBOM(List<BOMItem> bomItems, String fileName) async {
    try {
      Excel excel = Excel.createExcel();
      Sheet sheet = excel['BOM'];

      // Add headers
      List<String> headers = [
        'Sr.No',
        'Reference',
        'Value',
        'Footprint',
        'Qty',
        'Top/Bottom',
      ];

      for (int i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = TextCellValue(
          headers[i],
        );
      }

      // Add data rows
      for (int i = 0; i < bomItems.length; i++) {
        List<dynamic> rowData = bomItems[i].toExcelRow();
        for (int j = 0; j < rowData.length; j++) {
          var cellValue = rowData[j];
          CellValue value;

          if (cellValue is String) {
            value = TextCellValue(cellValue);
          } else if (cellValue is int) {
            value = IntCellValue(cellValue);
          } else if (cellValue is double) {
            value = DoubleCellValue(cellValue);
          } else {
            value = TextCellValue(cellValue?.toString() ?? '');
          }

          sheet
                  .cell(
                    CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1),
                  )
                  .value =
              value;
        }
      }

      // Save file
      Directory? directory = await getExternalStorageDirectory();
      String fullFileName =
          '${fileName}_bom_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      String filePath = '${directory!.path}/$fullFileName';

      List<int> fileBytes = excel.save()!;
      File file = File(filePath);
      await file.writeAsBytes(fileBytes);

      return true;
    } catch (e) {
      print('Error exporting BOM: $e');
      return false;
    }
  }

  // Create BOM template Excel file
  static Future<bool> createBOMTemplate() async {
    try {
      Excel excel = Excel.createExcel();
      Sheet sheet = excel['BOM_Template'];

      // Add headers with formatting
      List<String> headers = [
        'Sr.No',
        'Reference',
        'Value (Raw Material)',
        'Footprint',
        'Qty',
        'Top/Bottom',
      ];

      for (int i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = TextCellValue(
          headers[i],
        );
      }

      // Add example rows
      List<List<dynamic>> examples = [
        [1, 'C1', 'Capacitor 10uF', '0805', 1, 'top'],
        [2, 'R1', 'Resistor 1K', '0603', 1, 'top'],
        [3, 'U1', 'IC STM32', 'LQFP64', 1, 'top'],
        [4, 'LED1', 'LED Red', '0805', 1, 'bottom'],
      ];

      for (int i = 0; i < examples.length; i++) {
        for (int j = 0; j < examples[i].length; j++) {
          var cellValue = examples[i][j];
          CellValue value;

          if (cellValue is String) {
            value = TextCellValue(cellValue);
          } else if (cellValue is int) {
            value = IntCellValue(cellValue);
          } else {
            value = TextCellValue(cellValue.toString());
          }

          sheet
                  .cell(
                    CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1),
                  )
                  .value =
              value;
        }
      }

      // Save template file
      Directory? directory = await getExternalStorageDirectory();
      String fileName = 'BOM_Template.xlsx';
      String filePath = '${directory!.path}/$fileName';

      List<int> fileBytes = excel.save()!;
      File file = File(filePath);
      await file.writeAsBytes(fileBytes);

      return true;
    } catch (e) {
      print('Error creating BOM template: $e');
      return false;
    }
  }

  // CORRECTED: Helper method to get raw material name - returns String
  static String _getRawMaterialName(List<Data?> row, int columnIndex) {
    if (columnIndex >= row.length) return '';

    Data? cell = row[columnIndex];
    if (cell?.value == null) return '';

    // Preserve exact text formatting for raw material name
    if (cell!.value is TextCellValue) {
      // TextCellValue.value returns TextSpan, extract the text content
      var textCellValue = cell.value as TextCellValue;
      var textSpan = textCellValue.value;

      // Extract text from TextSpan - try multiple approaches
      if (textSpan.text != null) {
        return textSpan.text!;
      } else {
        // If text is null, build text from children
        return _extractTextFromTextSpan(textSpan);
      }
    } else if (cell.value is IntCellValue) {
      return (cell.value as IntCellValue).value.toString();
    } else if (cell.value is DoubleCellValue) {
      return (cell.value as DoubleCellValue).value.toString();
    } else {
      return cell.value.toString();
    }
  }

  // Helper method to extract text from TextSpan recursively
  static String _extractTextFromTextSpan(TextSpan textSpan) {
    StringBuffer buffer = StringBuffer();

    // Add the main text if available
    if (textSpan.text != null) {
      buffer.write(textSpan.text);
    }

    // Add text from children if available
    if (textSpan.children != null) {
      for (var child in textSpan.children!) {
        if (child is TextSpan) {
          buffer.write(_extractTextFromTextSpan(child));
        } else {
          buffer.write(child.toString());
        }
      }
    }

    return buffer.toString();
  }

  // Helper method to check if row is empty
  static bool _isEmptyRow(List<Data?> row) {
    return row.every(
      (cell) =>
          cell == null ||
          cell.value == null ||
          cell.value.toString().trim().isEmpty,
    );
  }

  // Validate Excel file format
  static bool validateExcelFile(String filePath) {
    try {
      String extension = filePath.split('.').last.toLowerCase();
      return AppConfig.allowedExcelExtensions.contains(extension);
    } catch (e) {
      return false;
    }
  }
}
