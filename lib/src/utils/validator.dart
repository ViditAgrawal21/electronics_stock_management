/// Utility class for input validation in electronics inventory management
class Validator {
  // Login validation
  static String? validateUsername(String? username) {
    if (username == null || username.trim().isEmpty) {
      return 'Username is required';
    }
    if (username.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 4) {
      return 'Password must be at least 4 characters';
    }
    return null;
  }

  // Material/Stock validation
  static String? validateMaterialName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Material name is required';
    }
    if (name.trim().length < 2) {
      return 'Material name must be at least 2 characters';
    }
    return null;
  }

  static String? validateQuantity(String? quantity) {
    if (quantity == null || quantity.trim().isEmpty) {
      return 'Quantity is required';
    }
    
    final parsedQty = int.tryParse(quantity.trim());
    if (parsedQty == null) {
      return 'Please enter a valid number';
    }
    
    if (parsedQty < 0) {
      return 'Quantity cannot be negative';
    }
    
    return null;
  }

  static String? validatePrice(String? price) {
    if (price == null || price.trim().isEmpty) {
      return null; // Price is optional
    }
    
    final parsedPrice = double.tryParse(price.trim());
    if (parsedPrice == null) {
      return 'Please enter a valid price';
    }
    
    if (parsedPrice < 0) {
      return 'Price cannot be negative';
    }
    
    return null;
  }

  // Device/PCB validation
  static String? validateDeviceName(String? deviceName) {
    if (deviceName == null || deviceName.trim().isEmpty) {
      return 'Device name is required';
    }
    if (deviceName.trim().length < 3) {
      return 'Device name must be at least 3 characters';
    }
    return null;
  }

  static String? validatePcbName(String? pcbName) {
    if (pcbName == null || pcbName.trim().isEmpty) {
      return 'PCB name is required';
    }
    if (pcbName.trim().length < 2) {
      return 'PCB name must be at least 2 characters';
    }
    return null;
  }

  static String? validateReference(String? reference) {
    if (reference == null || reference.trim().isEmpty) {
      return 'Reference is required';
    }
    if (reference.trim().length < 1) {
      return 'Reference cannot be empty';
    }
    return null;
  }

  static String? validateFootprint(String? footprint) {
    if (footprint == null || footprint.trim().isEmpty) {
      return null; // Footprint is optional
    }
    return null;
  }

  // BOM validation
  static String? validateBomQuantity(String? quantity) {
    if (quantity == null || quantity.trim().isEmpty) {
      return 'BOM quantity is required';
    }
    
    final parsedQty = int.tryParse(quantity.trim());
    if (parsedQty == null) {
      return 'Please enter a valid number';
    }
    
    if (parsedQty <= 0) {
      return 'BOM quantity must be greater than 0';
    }
    
    return null;
  }

  static String? validateSide(String? side) {
    if (side == null || side.trim().isEmpty) {
      return null; // Side is optional, will default to 'Top'
    }
    
    final validSides = ['Top', 'Bottom', 'Both'];
    if (!validSides.contains(side.trim())) {
      return 'Side must be Top, Bottom, or Both';
    }
    
    return null;
  }

  // File validation
  static String? validateExcelFile(String? fileName) {
    if (fileName == null || fileName.isEmpty) {
      return 'Please select a file';
    }
    
    if (!fileName.toLowerCase().endsWith('.xlsx') && 
        !fileName.toLowerCase().endsWith('.xls')) {
      return 'Please select a valid Excel file (.xlsx or .xls)';
    }
    
    return null;
  }

  // Batch calculation validation
  static String? validateBatchSize(String? batchSize) {
    if (batchSize == null || batchSize.trim().isEmpty) {
      return 'Batch size is required';
    }
    
    final parsedSize = int.tryParse(batchSize.trim());
    if (parsedSize == null) {
      return 'Please enter a valid number';
    }
    
    if (parsedSize <= 0) {
      return 'Batch size must be greater than 0';
    }
    
    if (parsedSize > 10000) {
      return 'Batch size too large (max 10000)';
    }
    
    return null;
  }

  // General validation helpers
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidNumber(String value) {
    return int.tryParse(value) != null || double.tryParse(value) != null;
  }

  static bool isPositiveInteger(String value) {
    final parsed = int.tryParse(value);
    return parsed != null && parsed > 0;
  }

  static bool isNonNegativeInteger(String value) {
    final parsed = int.tryParse(value);
    return parsed != null && parsed >= 0;
  }

  // Clean and sanitize input
  static String cleanString(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String? cleanAndValidateMaterialName(String? name) {
    if (name == null) return 'Material name is required';
    
    final cleaned = cleanString(name);
    return validateMaterialName(cleaned);
  }

  static String? cleanAndValidateDeviceName(String? name) {
    if (name == null) return 'Device name is required';
    
    final cleaned = cleanString(name);
    return validateDeviceName(cleaned);
  }

  // Stock level validation
  static String? validateMinimumStock(String? minStock) {
    if (minStock == null || minStock.trim().isEmpty) {
      return null; // Minimum stock is optional
    }
    
    final parsed = int.tryParse(minStock.trim());
    if (parsed == null) {
      return 'Please enter a valid number';
    }
    
    if (parsed < 0) {
      return 'Minimum stock cannot be negative';
    }
    
    return null;
  }

  // Validation for stock updates
  static String? validateStockUpdate(String? newStock, int currentStock) {
    final validation = validateQuantity(newStock);
    if (validation != null) return validation;
    
    final newStockValue = int.parse(newStock!.trim());
    
    // Warning for significant stock changes (optional - can be removed)
    if ((newStockValue - currentStock).abs() > 1000) {
      return 'Large stock change detected. Please verify the quantity';
    }
    
    return null;
  }
}