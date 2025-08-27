/// Utility class for form validation and data validation throughout the app
class AppValidator {
  // Login validation
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.trim().isEmpty) {
      return 'Username cannot be empty';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.trim().isEmpty) {
      return 'Password cannot be empty';
    }
    return null;
  }

  // Material validation
  static String? validateMaterialName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Material name is required';
    }
    if (value.trim().isEmpty) {
      return 'Material name cannot be empty';
    }
    if (value.trim().length < 2) {
      return 'Material name must be at least 2 characters';
    }
    return null;
  }

  static String? validateQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Quantity is required';
    }

    final quantity = int.tryParse(value);
    if (quantity == null) {
      return 'Please enter a valid number';
    }

    if (quantity < 0) {
      return 'Quantity cannot be negative';
    }

    return null;
  }

  static String? validatePositiveQuantity(String? value) {
    final result = validateQuantity(value);
    if (result != null) return result;

    final quantity = int.parse(value!);
    if (quantity == 0) {
      return 'Quantity must be greater than 0';
    }

    return null;
  }

  // Device validation
  static String? validateDeviceName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Device name is required';
    }
    if (value.trim().isEmpty) {
      return 'Device name cannot be empty';
    }
    if (value.trim().length < 3) {
      return 'Device name must be at least 3 characters';
    }
    return null;
  }

  // PCB validation
  static String? validatePcbName(String? value) {
    if (value == null || value.isEmpty) {
      return 'PCB name is required';
    }
    if (value.trim().isEmpty) {
      return 'PCB name cannot be empty';
    }
    if (value.trim().length < 2) {
      return 'PCB name must be at least 2 characters';
    }
    return null;
  }

  // BOM validation
  static String? validateReference(String? value) {
    if (value == null || value.isEmpty) {
      return 'Reference is required';
    }
    if (value.trim().isEmpty) {
      return 'Reference cannot be empty';
    }
    return null;
  }

  static String? validateValue(String? value) {
    if (value == null || value.isEmpty) {
      return 'Value is required';
    }
    if (value.trim().isEmpty) {
      return 'Value cannot be empty';
    }
    return null;
  }

  static String? validateFootprint(String? value) {
    // Footprint can be optional, so only validate if provided
    if (value != null && value.isNotEmpty && value.trim().isEmpty) {
      return 'Footprint cannot be empty if provided';
    }
    return null;
  }

  static String? validateTopBottom(String? value) {
    if (value == null || value.isEmpty) {
      return 'Top/Bottom is required';
    }

    final normalizedValue = value.trim().toLowerCase();
    if (normalizedValue != 'top' && normalizedValue != 'bottom') {
      return 'Must be either "Top" or "Bottom"';
    }

    return null;
  }

  // File validation
  static String? validateExcelFile(String? filePath) {
    if (filePath == null || filePath.isEmpty) {
      return 'Please select a file';
    }

    if (!filePath.toLowerCase().endsWith('.xlsx') &&
        !filePath.toLowerCase().endsWith('.xls')) {
      return 'Please select a valid Excel file (.xlsx or .xls)';
    }

    return null;
  }

  // Batch quantity validation
  static String? validateBatchQuantity(String? value, int maxPossible) {
    final result = validatePositiveQuantity(value);
    if (result != null) return result;

    final quantity = int.parse(value!);
    if (quantity > maxPossible) {
      return 'Cannot create $quantity units. Maximum possible: $maxPossible';
    }

    return null;
  }

  // Stock level validation
  static bool isLowStock(int currentStock, int minThreshold) {
    return currentStock <= minThreshold;
  }

  static bool isOutOfStock(int currentStock) {
    return currentStock <= 0;
  }

  // Search validation
  static bool isValidSearchQuery(String? query) {
    return query != null && query.trim().isNotEmpty && query.trim().length >= 1;
  }

  // Numeric validation helpers
  static bool isValidInteger(String value) {
    return int.tryParse(value) != null;
  }

  static bool isValidDouble(String value) {
    return double.tryParse(value) != null;
  }

  static bool isPositiveInteger(String value) {
    final intValue = int.tryParse(value);
    return intValue != null && intValue > 0;
  }

  static bool isNonNegativeInteger(String value) {
    final intValue = int.tryParse(value);
    return intValue != null && intValue >= 0;
  }

  // Material shortage validation
  static Map<String, int> calculateShortage(
    Map<String, int> required,
    Map<String, int> available,
  ) {
    final shortage = <String, int>{};

    for (final entry in required.entries) {
      final materialName = entry.key;
      final requiredQty = entry.value;
      final availableQty = available[materialName] ?? 0;

      if (requiredQty > availableQty) {
        shortage[materialName] = requiredQty - availableQty;
      }
    }

    return shortage;
  }

  // Check if production is possible
  static bool canProducePCB(
    Map<String, int> requiredMaterials,
    Map<String, int> availableMaterials,
  ) {
    for (final entry in requiredMaterials.entries) {
      final materialName = entry.key;
      final requiredQty = entry.value;
      final availableQty = availableMaterials[materialName] ?? 0;

      if (requiredQty > availableQty) {
        return false;
      }
    }

    return true;
  }

  // Calculate maximum possible production quantity
  static int calculateMaxProduction(
    Map<String, int> requiredPerUnit,
    Map<String, int> availableMaterials,
  ) {
    int maxPossible = double.maxFinite.toInt();

    for (final entry in requiredPerUnit.entries) {
      final materialName = entry.key;
      final requiredQty = entry.value;
      final availableQty = availableMaterials[materialName] ?? 0;

      if (requiredQty > 0) {
        final possibleFromThisMaterial = availableQty ~/ requiredQty;
        maxPossible = maxPossible < possibleFromThisMaterial
            ? maxPossible
            : possibleFromThisMaterial;
      }
    }

    return maxPossible == double.maxFinite.toInt() ? 0 : maxPossible;
  }

  // Email validation (if needed for future features)
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Phone validation (if needed for future features)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    if (!phoneRegex.hasMatch(value.replaceAll(' ', '').replaceAll('-', ''))) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // Clean and format input
  static String cleanString(String? input) {
    if (input == null) return '';
    return input.trim();
  }

  static String formatMaterialName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String normalizeReference(String reference) {
    return reference.trim().toUpperCase();
  }
}
