class AppConfig {
  // App Information
  static const String appName = 'Electronics Inventory Manager';
  static const String appVersion = '1.0.0';
  static const String companyName = 'TWAIPL';

  // Authentication Configuration
  static const String defaultUsername = 'TWAIPL';
  static const String defaultPassword = '1234';

  // Stock Management Configuration
  static const int lowStockThreshold = 10;
  static const int criticalStockThreshold = 5;
  static const int maxSearchResults = 100;

  // Excel Configuration
  static const List<String> supportedExcelFormats = ['.xlsx', '.xls'];
  static const int maxExcelFileSize = 10 * 1024 * 1024; // 10MB in bytes

  // BOM Configuration
  static const List<String> bomColumns = [
    'sr.no',
    'reference',
    'value',
    'footprint',
    'qty',
    'top/bottom',
  ];

  // Material Categories
  static const List<String> materialCategories = [
    'Resistors',
    'Capacitors',
    'ICs',
    'Connectors',
    'LEDs',
    'Sensors',
    'PCBs',
    'Enclosures',
    'Mechanical',
    'Other',
  ];

  // PCB Types
  static const List<String> pcbTypes = [
    'Cape Board',
    'DIDO Board',
    'LED Board',
    'Main Board',
    'Sensor Board',
    'Power Board',
  ];

  // Device Categories
  static const List<String> deviceCategories = [
    'Air Leak Tester',
    'Sensor Module',
    'Control Unit',
    'Display Module',
    'Power Supply',
    'Test Equipment',
  ];

  // Filter Options
  static const List<String> sortOptions = [
    'Name (A-Z)',
    'Name (Z-A)',
    'Quantity (Low to High)',
    'Quantity (High to Low)',
    'Recently Added',
    'Most Used',
  ];

  // UI Configuration
  static const int itemsPerPage = 20;
  static const double cardElevation = 2.0;
  static const double borderRadius = 8.0;

  // Animation Durations (in milliseconds)
  static const int shortAnimation = 200;
  static const int mediumAnimation = 400;
  static const int longAnimation = 600;

  // Local Storage Keys
  static const String materialsDataKey = 'materials_data';
  static const String devicesDataKey = 'devices_data';
  static const String bomDataKey = 'bom_data';
  static const String pcbDataKey = 'pcb_data';
  static const String userPreferencesKey = 'user_preferences';
  static const String lastBackupKey = 'last_backup_date';

  // Notification Configuration
  static const String lowStockChannelId = 'low_stock_alerts';
  static const String lowStockChannelName = 'Low Stock Alerts';
  static const String lowStockChannelDescription =
      'Notifications for low stock materials';

  // File Paths
  static const String backupFolderName = 'ElectronicsInventory';
  static const String exportFolderName = 'Exports';
  static const String templatesFolderName = 'Templates';

  // Excel Templates
  static const Map<String, List<String>> excelTemplates = {
    'materials': [
      'Material Name',
      'Category',
      'Initial Quantity',
      'Remaining Quantity',
      'Unit',
      'Supplier',
      'Cost per Unit',
      'Location',
    ],
    'bom': ['Sr.No', 'Reference', 'Value', 'Footprint', 'Qty', 'Top/Bottom'],
  };

  // Validation Rules
  static const int minPasswordLength = 4;
  static const int maxMaterialNameLength = 50;
  static const int maxDeviceNameLength = 50;
  static const int maxQuantity = 999999;
  static const int minQuantity = 0;

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';

  // Error Messages
  static const String networkError = 'Network connection error';
  static const String fileNotFoundError = 'File not found';
  static const String invalidFileError = 'Invalid file format';
  static const String insufficientStockError = 'Insufficient stock available';
  static const String duplicateEntryError = 'Entry already exists';

  // Success Messages
  static const String loginSuccess = 'Login successful';
  static const String dataImportSuccess = 'Data imported successfully';
  static const String stockUpdateSuccess = 'Stock updated successfully';
  static const String bomUploadSuccess = 'BOM uploaded successfully';
  static const String deviceCreatedSuccess = 'Device created successfully';

  // Backup Configuration
  static const int autoBackupDays = 7; // Auto backup every 7 days
  static const int maxBackupFiles = 10; // Keep maximum 10 backup files

  // Development Configuration
  static const bool debugMode = true;
  static const bool enableLogging = true;
  static const String logFileName = 'app_logs.txt';
}
