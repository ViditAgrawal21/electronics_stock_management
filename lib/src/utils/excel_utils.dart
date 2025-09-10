import 'dart:io';
import 'package:excel/excel.dart';
import 'package:electronics_stock_management/src/models/materials.dart';
import '../models/bom.dart';

class ExcelUtils {
  // Validate Excel file extension
  static bool isValidExcelFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return ['xlsx', 'xls'].contains(extension);
  }

  // Convert Excel cell value to appropriate type
  static dynamic convertCellValue(Data? cellData) {
    if (cellData == null || cellData.value == null) {
      return null;
    }

    final value = cellData.value;

    // Handle different cell value types
    if (value is TextCellValue) {
      return value.value.toString();
    } else if (value is IntCellValue) {
      return value.value;
    } else if (value is DoubleCellValue) {
      return value.value;
    } else if (value is DateCellValue) {
      return value.asDateTimeLocal();
    } else if (value is TimeCellValue) {
      return value.asDuration();
    } else if (value is BoolCellValue) {
      return value.value;
    } else if (value is FormulaCellValue) {
      return value.formula;
    }

    return value.toString();
  }

  // Check if Excel row is empty
  static bool isRowEmpty(List<Data?> row) {
    if (row.isEmpty) return true;

    return row.every((cell) {
      if (cell == null || cell.value == null) return true;

      final value = convertCellValue(cell);
      if (value == null) return true;

      return value.toString().trim().isEmpty;
    });
  }

  // Extract raw values from Excel row
  static List<dynamic> extractRowValues(List<Data?> row) {
    return row.map((cell) => convertCellValue(cell)).toList();
  }

  // Validate material Excel format
  static Map<String, dynamic> validateMaterialsExcel(Excel excel) {
    List<String> errors = [];
    List<String> warnings = [];
    int totalRows = 0;
    int validRows = 0;

    for (String tableName in excel.tables.keys) {
      Sheet? sheet = excel.tables[tableName];
      if (sheet == null) continue;

      // Check if sheet has data
      if (sheet.maxRows <= 1) {
        warnings.add('Sheet "$tableName" has no data rows');
        continue;
      }

      // Validate headers (optional but recommended)
      List<Data?> headerRow = sheet.row(0);
      List<String> expectedHeaders = [
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

      // Check for basic required columns
      if (headerRow.length < 3) {
        errors.add(
          'Sheet "$tableName" must have at least 3 columns (Name, Initial Qty, Remaining Qty)',
        );
        continue;
      }

      // Validate data rows
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        List<Data?> row = sheet.row(rowIndex);
        if (isRowEmpty(row)) continue;

        totalRows++;
        List<dynamic> rowValues = extractRowValues(row);

        // Validate material name
        if (rowValues.isEmpty ||
            rowValues[0] == null ||
            rowValues[0].toString().trim().isEmpty) {
          errors.add('Row ${rowIndex + 1}: Material name is required');
          continue;
        }

        // Validate initial quantity
        if (rowValues.length < 2 || !_isValidNumber(rowValues[1])) {
          errors.add('Row ${rowIndex + 1}: Invalid initial quantity');
          continue;
        }

        // Validate remaining quantity
        if (rowValues.length < 3 || !_isValidNumber(rowValues[2])) {
          errors.add('Row ${rowIndex + 1}: Invalid remaining quantity');
          continue;
        }

        // Check logical consistency
        int initialQty = _parseNumber(rowValues[1]);
        int remainingQty = _parseNumber(rowValues[2]);

        if (remainingQty > initialQty) {
          warnings.add(
            'Row ${rowIndex + 1}: Remaining quantity exceeds initial quantity',
          );
        }

        validRows++;
      }
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
      'totalRows': totalRows,
      'validRows': validRows,
    };
  }

  // Validate BOM Excel format
  static Map<String, dynamic> validateBOMExcel(Excel excel) {
    List<String> errors = [];
    List<String> warnings = [];
    int totalRows = 0;
    int validRows = 0;

    for (String tableName in excel.tables.keys) {
      Sheet? sheet = excel.tables[tableName];
      if (sheet == null) continue;

      if (sheet.maxRows <= 1) {
        warnings.add('Sheet "$tableName" has no data rows');
        continue;
      }

      // Validate BOM format
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        List<Data?> row = sheet.row(rowIndex);
        if (isRowEmpty(row)) continue;

        totalRows++;
        List<dynamic> rowValues = extractRowValues(row);

        // Validate required BOM columns
        if (rowValues.length < 6) {
          errors.add(
            'Row ${rowIndex + 1}: BOM must have 6 columns (Sr.No, Reference, Value, Footprint, Qty, Top/Bottom)',
          );
          continue;
        }

        // Validate serial number
        if (!_isValidNumber(rowValues[0])) {
          errors.add('Row ${rowIndex + 1}: Invalid serial number');
          continue;
        }

        // Validate reference
        if (rowValues[1] == null || rowValues[1].toString().trim().isEmpty) {
          errors.add('Row ${rowIndex + 1}: Reference is required');
          continue;
        }

        // Validate value (material name)
        if (rowValues[2] == null || rowValues[2].toString().trim().isEmpty) {
          errors.add('Row ${rowIndex + 1}: Value (material name) is required');
          continue;
        }

        // Validate quantity
        if (!_isValidNumber(rowValues[4]) || _parseNumber(rowValues[4]) <= 0) {
          errors.add('Row ${rowIndex + 1}: Quantity must be a positive number');
          continue;
        }

        // Validate layer
        String layer = rowValues[5]?.toString().toLowerCase() ?? '';
        if (!['top', 'bottom'].contains(layer)) {
          warnings.add(
            'Row ${rowIndex + 1}: Layer should be "top" or "bottom"',
          );
        }

        // Validate reference format
        String reference = rowValues[1].toString();
        if (!RegExp(r'^[A-Z]+\d+$', caseSensitive: false).hasMatch(reference)) {
          warnings.add(
            'Row ${rowIndex + 1}: Reference format should be like C1, R1, U1',
          );
        }

        validRows++;
      }
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
      'totalRows': totalRows,
      'validRows': validRows,
    };
  }

  // Create Excel template for materials
  static Excel createMaterialsTemplate() {
    Excel excel = Excel.createExcel();
    Sheet sheet = excel['Materials_Template'];

    // Headers
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

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(
        headers[i],
      );
    }

    // Add example data
    List<List<dynamic>> examples = [
      [
        'Resistor 1K Ohm',
        100,
        85,
        15,
        '1/4W Carbon Film Resistor',
        'Resistors',
        0.05,
        'Digikey',
        'Shelf A1',
      ],
      [
        'Capacitor 10uF',
        50,
        45,
        5,
        'Electrolytic Capacitor 25V',
        'Capacitors',
        0.15,
        'Mouser',
        'Shelf A2',
      ],
      [
        'LED Red 5mm',
        200,
        180,
        20,
        'Standard Red LED',
        'LEDs',
        0.10,
        'Digikey',
        'Shelf B1',
      ],
      [
        'IC STM32F103',
        25,
        20,
        5,
        'Microcontroller 32-bit ARM',
        'ICs',
        5.50,
        'Mouser',
        'Shelf C1',
      ],
    ];

    for (int i = 0; i < examples.length; i++) {
      for (int j = 0; j < examples[i].length; j++) {
        var value = examples[i][j];
        CellValue cellValue;

        if (value is String) {
          cellValue = TextCellValue(value);
        } else if (value is int) {
          cellValue = IntCellValue(value);
        } else if (value is double) {
          cellValue = DoubleCellValue(value);
        } else {
          cellValue = TextCellValue(value.toString());
        }

        sheet
                .cell(
                  CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1),
                )
                .value =
            cellValue;
      }
    }

    return excel;
  }

  // Create Excel template for BOM
  static Excel createBOMTemplate() {
    Excel excel = Excel.createExcel();
    Sheet sheet = excel['BOM_Template'];

    // Headers
    List<String> headers = [
      'Sr.No',
      'Reference',
      'Value',
      'Footprint',
      'Qty',
      'Top/Bottom',
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(
        headers[i],
      );
    }

    // Add example data
    List<List<dynamic>> examples = [
      [1, 'C1', 'Capacitor 10uF', '0805', 1, 'top'],
      [2, 'C2', 'Capacitor 100nF', '0603', 1, 'top'],
      [3, 'R1', 'Resistor 1K', '0603', 1, 'top'],
      [4, 'R2', 'Resistor 10K', '0603', 2, 'top'],
      [5, 'U1', 'IC STM32F103', 'LQFP64', 1, 'top'],
      [6, 'LED1', 'LED Red', '0805', 1, 'bottom'],
      [7, 'SW1', 'Switch Tactile', 'SMD', 1, 'bottom'],
    ];

    for (int i = 0; i < examples.length; i++) {
      for (int j = 0; j < examples[i].length; j++) {
        var value = examples[i][j];
        CellValue cellValue;

        if (value is String) {
          cellValue = TextCellValue(value);
        } else if (value is int) {
          cellValue = IntCellValue(value);
        } else {
          cellValue = TextCellValue(value.toString());
        }

        sheet
                .cell(
                  CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1),
                )
                .value =
            cellValue;
      }
    }

    return excel;
  }

  // Convert materials to Excel format
  static Excel materialsToExcel(List<Material> materials) {
    Excel excel = Excel.createExcel();
    Sheet sheet = excel['Materials'];

    // Headers
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
      'Created Date',
      'Last Used Date',
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(
        headers[i],
      );
    }

    // Add material data
    for (int i = 0; i < materials.length; i++) {
      Material material = materials[i];
      List<dynamic> rowData = [
        material.name,
        material.initialQuantity,
        material.remainingQuantity,
        material.calculatedUsedQuantity,
        material.description ?? '',
        material.category ?? '',
        material.unitCost ?? 0.0,
        material.supplier ?? '',
        material.location ?? '',
        material.createdAt.toString(),
        material.lastUsedAt.toString(),
      ];

      for (int j = 0; j < rowData.length; j++) {
        var value = rowData[j];
        CellValue cellValue;

        if (value is String) {
          cellValue = TextCellValue(value);
        } else if (value is int) {
          cellValue = IntCellValue(value);
        } else if (value is double) {
          cellValue = DoubleCellValue(value);
        } else {
          cellValue = TextCellValue(value.toString());
        }

        sheet
                .cell(
                  CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1),
                )
                .value =
            cellValue;
      }
    }

    return excel;
  }

  // Convert BOM to Excel format
  static Excel bomToExcel(List<BOMItem> bomItems, String sheetName) {
    Excel excel = Excel.createExcel();
    Sheet sheet = excel[sheetName];

    // Headers
    List<String> headers = [
      'Sr.No',
      'Reference',
      'Value',
      'Footprint',
      'Qty',
      'Top/Bottom',
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(
        headers[i],
      );
    }

    // Add BOM data
    for (int i = 0; i < bomItems.length; i++) {
      BOMItem item = bomItems[i];
      List<dynamic> rowData = [
        item.serialNumber,
        item.reference,
        item.value,
        item.footprint,
        item.quantity,
        item.layer,
      ];

      for (int j = 0; j < rowData.length; j++) {
        var value = rowData[j];
        CellValue cellValue;

        if (value is String) {
          cellValue = TextCellValue(value);
        } else if (value is int) {
          cellValue = IntCellValue(value);
        } else {
          cellValue = TextCellValue(value.toString());
        }

        sheet
                .cell(
                  CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1),
                )
                .value =
            cellValue;
      }
    }

    return excel;
  }

  // Helper methods
  static bool _isValidNumber(dynamic value) {
    if (value == null) return false;

    if (value is num) return true;

    if (value is String) {
      return double.tryParse(value) != null;
    }

    return false;
  }

  static int _parseNumber(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.round() ?? 0;
    }
    return 0;
  }

  // Get Excel file info
  static Map<String, dynamic> getExcelInfo(Excel excel) {
    int totalSheets = excel.tables.length;
    int totalRows = 0;
    List<String> sheetNames = [];

    for (String tableName in excel.tables.keys) {
      sheetNames.add(tableName);
      Sheet? sheet = excel.tables[tableName];
      if (sheet != null) {
        totalRows += sheet.maxRows;
      }
    }

    return {
      'totalSheets': totalSheets,
      'totalRows': totalRows,
      'sheetNames': sheetNames,
    };
  }
}
