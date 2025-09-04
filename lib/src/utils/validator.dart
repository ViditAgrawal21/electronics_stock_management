class Validator {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, [String fieldName = 'Field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Number validation
  static String? validateNumber(String? value, [String fieldName = 'Number']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (double.tryParse(value) == null) {
      return '$fieldName must be a valid number';
    }

    return null;
  }

  // Positive number validation
  static String? validatePositiveNumber(
    String? value, [
    String fieldName = 'Number',
  ]) {
    final numberValidation = validateNumber(value, fieldName);
    if (numberValidation != null) return numberValidation;

    final number = double.parse(value!);
    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }

    return null;
  }

  // Integer validation
  static String? validateInteger(String? value, [String fieldName = 'Number']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (int.tryParse(value) == null) {
      return '$fieldName must be a valid integer';
    }

    return null;
  }

  // Positive integer validation
  static String? validatePositiveInteger(
    String? value, [
    String fieldName = 'Number',
  ]) {
    final intValidation = validateInteger(value, fieldName);
    if (intValidation != null) return intValidation;

    final number = int.parse(value!);
    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }

    return null;
  }

  // Material name validation
  static String? validateMaterialName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Material name is required';
    }

    if (value.trim().length < 2) {
      return 'Material name must be at least 2 characters';
    }

    if (value.trim().length > 100) {
      return 'Material name must be less than 100 characters';
    }

    return null;
  }

  // Device name validation
  static String? validateDeviceName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Device name is required';
    }

    if (value.trim().length < 3) {
      return 'Device name must be at least 3 characters';
    }

    if (value.trim().length > 50) {
      return 'Device name must be less than 50 characters';
    }

    return null;
  }

  // PCB reference validation (e.g., C1, R1, U1)
  static String? validatePCBReference(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Reference is required';
    }

    final referenceRegex = RegExp(r'^[A-Z]+\d+$', caseSensitive: false);
    if (!referenceRegex.hasMatch(value.trim())) {
      return 'Reference format should be like C1, R1, U1';
    }

    return null;
  }

  // Layer validation (top/bottom)
  static String? validateLayer(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Layer is required';
    }

    final layer = value.trim().toLowerCase();
    if (!['top', 'bottom'].contains(layer)) {
      return 'Layer must be "top" or "bottom"';
    }

    return null;
  }

  // Quantity range validation
  static String? validateQuantityRange(
    String? value, {
    int? min,
    int? max,
    String fieldName = 'Quantity',
  }) {
    final validation = validatePositiveInteger(value, fieldName);
    if (validation != null) return validation;

    final quantity = int.parse(value!);

    if (min != null && quantity < min) {
      return '$fieldName must be at least $min';
    }

    if (max != null && quantity > max) {
      return '$fieldName must be at most $max';
    }

    return null;
  }

  // Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }

    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // URL validation
  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }

    try {
      final uri = Uri.parse(value.trim());
      if (!uri.hasScheme || !['http', 'https'].contains(uri.scheme)) {
        return 'Please enter a valid URL (http:// or https://)';
      }
    } catch (e) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  // Cost validation (can be 0 or positive)
  static String? validateCost(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }

    final cost = double.tryParse(value);
    if (cost == null) {
      return 'Cost must be a valid number';
    }

    if (cost < 0) {
      return 'Cost cannot be negative';
    }

    return null;
  }

  // Percentage validation (0-100)
  static String? validatePercentage(
    String? value, [
    String fieldName = 'Percentage',
  ]) {
    final numberValidation = validateNumber(value, fieldName);
    if (numberValidation != null) return numberValidation;

    final percentage = double.parse(value!);
    if (percentage < 0 || percentage > 100) {
      return '$fieldName must be between 0 and 100';
    }

    return null;
  }

  // Date validation
  static String? validateDate(String? value, [String fieldName = 'Date']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    try {
      DateTime.parse(value);
    } catch (e) {
      return 'Please enter a valid $fieldName';
    }

    return null;
  }

  // Future date validation
  static String? validateFutureDate(
    String? value, [
    String fieldName = 'Date',
  ]) {
    final dateValidation = validateDate(value, fieldName);
    if (dateValidation != null) return dateValidation;

    final date = DateTime.parse(value!);
    if (date.isBefore(DateTime.now())) {
      return '$fieldName must be in the future';
    }

    return null;
  }

  // Text length validation
  static String? validateTextLength(
    String? value, {
    int? minLength,
    int? maxLength,
    String fieldName = 'Field',
    bool required = true,
  }) {
    if (!required && (value == null || value.trim().isEmpty)) {
      return null;
    }

    if (required && (value == null || value.trim().isEmpty)) {
      return '$fieldName is required';
    }

    final length = value!.trim().length;

    if (minLength != null && length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    if (maxLength != null && length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }

    return null;
  }

  // Multiple validators
  static String? validateMultiple(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (var validator in validators) {
      final result = validator(value);
      if (result != null) return result;
    }
    return null;
  }

  // Custom validation with condition
  static String? validateConditional(
    String? value,
    bool condition,
    String? Function(String?) validator,
  ) {
    if (!condition) return null;
    return validator(value);
  }
}
