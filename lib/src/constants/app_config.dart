class AppConfig {
  // Authentication
  static const String defaultUsername = 'TWAIPL';
  static const String defaultPassword = '1234';

  // Stock thresholds
  static const int lowStockThreshold = 10;
  static const int criticalStockThreshold = 5;

  // Excel column indices for raw materials
  static const int materialNameColumn = 0;
  static const int initialQuantityColumn = 1;
  static const int remainingQuantityColumn = 2;
  static const int usedQuantityColumn = 3;

  // Excel column indices for BOM
  static const int bomSrNoColumn = 0;
  static const int bomReferenceColumn = 1;
  static const int bomValueColumn = 2;
  static const int bomFootprintColumn = 3;
  static const int bomQuantityColumn = 4;
  static const int bomLayerColumn = 5; // top/bottom

  // File extensions
  static const List<String> allowedExcelExtensions = ['xlsx', 'xls'];

  // Sorting options
  static const List<String> sortingOptions = [
    'Name (A-Z)',
    'Name (Z-A)',
    'Quantity (High-Low)',
    'Quantity (Low-High)',
    'Most Used',
    'Least Used',
  ];

  // Filter options
  static const List<String> filterOptions = [
    'All Materials',
    'Low Stock',
    'Critical Stock',
    'Out of Stock',
    'Never Used',
    'Recently Used',
  ];
}
