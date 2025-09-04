class AppStrings {
  // App Info
  static const String appName = 'Electronics Stock Manager';
  static const String appVersion = '1.0.0';

  // Authentication
  static const String loginTitle = 'Login to Stock Manager';
  static const String username = 'Username';
  static const String password = 'Password';
  static const String login = 'Login';
  static const String loginFailed = 'Invalid credentials. Please try again.';

  // Navigation
  static const String home = 'Home';
  static const String materials = 'Materials';
  static const String pcbCreation = 'PCB Creation';
  static const String bomUpload = 'BOM Upload';
  static const String deviceHistory = 'Device History';
  static const String alerts = 'Alerts';

  // Materials Screen
  static const String materialsTitle = 'Raw Materials';
  static const String importExcel = 'Import Excel';
  static const String exportExcel = 'Export Excel';
  static const String searchMaterials = 'Search materials...';
  static const String filterMaterials = 'Filter';
  static const String sortMaterials = 'Sort';
  static const String totalMaterials = 'Total Materials';
  static const String lowStockItems = 'Low Stock Items';
  static const String outOfStockItems = 'Out of Stock Items';

  // PCB Creation
  static const String pcbCreationTitle = 'PCB Creation';
  static const String deviceName = 'Device Name';
  static const String subComponents = 'Sub Components';
  static const String pcbBoards = 'PCB Boards';
  static const String addComponent = 'Add Component';
  static const String addPcbBoard = 'Add PCB Board';
  static const String createDevice = 'Create Device';

  // BOM Upload
  static const String bomUploadTitle = 'BOM Upload';
  static const String uploadBom = 'Upload BOM';
  static const String bomFormat =
      'BOM Format: Sr.No, Reference, Value, Footprint, Qty, Top/Bottom';
  static const String saveBom = 'Save BOM';
  static const String bomSaved = 'BOM saved successfully';

  // Batch Production
  static const String batchProduction = 'Batch Production';
  static const String calculateBatch = 'Calculate Batch';
  static const String quantityToProduce = 'Quantity to Produce';
  static const String materialRequirements = 'Material Requirements';
  static const String sufficientStock = 'Sufficient stock available';
  static const String insufficientStock = 'Insufficient stock for production';
  static const String proceedProduction = 'Proceed with Production';

  // Device History
  static const String deviceHistoryTitle = 'Device History';
  static const String producedDevices = 'Produced Devices';
  static const String productionDate = 'Production Date';
  static const String materialsUsed = 'Materials Used';
  static const String totalCost = 'Total Cost';

  // Alerts
  static const String alertsTitle = 'Stock Alerts';
  static const String lowStockAlert = 'Low Stock Alert';
  static const String criticalStockAlert = 'Critical Stock Alert';
  static const String outOfStockAlert = 'Out of Stock Alert';
  static const String noAlerts = 'No alerts at this time';

  // General
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String add = 'Add';
  static const String update = 'Update';
  static const String confirm = 'Confirm';
  static const String success = 'Success';
  static const String error = 'Error';
  static const String warning = 'Warning';
  static const String info = 'Info';
  static const String loading = 'Loading...';
  static const String noData = 'No data available';
  static const String refresh = 'Refresh';

  // Error Messages
  static const String fileNotFound = 'File not found';
  static const String invalidFileFormat = 'Invalid file format';
  static const String importFailed = 'Import failed';
  static const String exportFailed = 'Export failed';
  static const String saveFailed = 'Save failed';
  static const String deleteFailed = 'Delete failed';
  static const String networkError = 'Network error';
  static const String unknownError = 'Unknown error occurred';
}
