// Material model with preserved raw material name handling

class Material {
  final String id;
  final String name; // This should be the raw material name exactly as in Excel
  final int initialQuantity;
  final int remainingQuantity;
  final int usedQuantity;
  final String? description;
  final String? category;
  final double? unitCost;
  final String? supplier;
  final String? location;
  final DateTime createdAt;
  final DateTime lastUsedAt;

  Material({
    required this.id,
    required this.name,
    required this.initialQuantity,
    required this.remainingQuantity,
    this.usedQuantity = 0,
    this.description,
    this.category,
    this.unitCost,
    this.supplier,
    this.location,
    required this.createdAt,
    required this.lastUsedAt,
  });

  // CRITICAL: This method should preserve the raw material name exactly
  static Material fromExcelRow(List<dynamic> rowValues, {required String id}) {
    // Ensure we have minimum required columns
    if (rowValues.length < 3) {
      throw Exception('Insufficient columns in Excel row');
    }

    // Extract raw material name exactly as it appears - NO MODIFICATION
    String rawMaterialName = (rowValues[0]?.toString() ?? '').trim();

    // Don't modify the name - preserve it exactly as in Excel
    // Avoid any transformations like:
    // - toLowerCase()
    // - toUpperCase()
    // - replaceAll()
    // - trim() beyond basic whitespace
    // - Any regex replacements

    if (rawMaterialName.isEmpty) {
      throw Exception('Raw material name cannot be empty');
    }

    // Parse other fields safely
    int initialQty = _parseInteger(rowValues[1]);
    int remainingQty = _parseInteger(rowValues[2]);
    int usedQty = rowValues.length > 3
        ? _parseInteger(rowValues[3])
        : (initialQty - remainingQty);

    return Material(
      id: id,
      name: rawMaterialName, // Use exactly as provided from Excel
      initialQuantity: initialQty,
      remainingQuantity: remainingQty,
      usedQuantity: usedQty,
      description: rowValues.length > 4
          ? rowValues[4]?.toString()?.trim()
          : null,
      category: rowValues.length > 5 ? rowValues[5]?.toString()?.trim() : null,
      unitCost: rowValues.length > 6 ? _parseDouble(rowValues[6]) : null,
      supplier: rowValues.length > 7 ? rowValues[7]?.toString()?.trim() : null,
      location: rowValues.length > 8 ? rowValues[8]?.toString()?.trim() : null,
      createdAt: DateTime.now(),
      lastUsedAt: DateTime.now(),
    );
  }

  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isCriticalStock) return 'Critical Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  // Alternative constructor with explicit raw material name parameter
  static Material fromExcelRowWithRawName(
    List<dynamic> rowValues, {
    required String rawMaterialName,
    required String id,
  }) {
    if (rawMaterialName.trim().isEmpty) {
      throw Exception('Raw material name cannot be empty');
    }

    int initialQty = _parseInteger(rowValues.length > 1 ? rowValues[1] : 0);
    int remainingQty = _parseInteger(rowValues.length > 2 ? rowValues[2] : 0);

    return Material(
      id: id,
      name: rawMaterialName, // Use the explicitly passed raw material name
      initialQuantity: initialQty,
      remainingQuantity: remainingQty,
      usedQuantity: initialQty - remainingQty,
      description: rowValues.length > 4
          ? rowValues[4]?.toString()?.trim()
          : null,
      category: rowValues.length > 5 ? rowValues[5]?.toString()?.trim() : null,
      unitCost: rowValues.length > 6 ? _parseDouble(rowValues[6]) : null,
      supplier: rowValues.length > 7 ? rowValues[7]?.toString()?.trim() : null,
      location: rowValues.length > 8 ? rowValues[8]?.toString()?.trim() : null,
      createdAt: DateTime.now(),
      lastUsedAt: DateTime.now(),
    );
  }

  // Safe integer parsing
  static int _parseInteger(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      return int.tryParse(value.trim()) ??
          double.tryParse(value.trim())?.round() ??
          0;
    }
    return 0;
  }

  // Safe double parsing
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  // Convert to Excel row format
  List<dynamic> toExcelRow() {
    return [
      name, // Preserve the exact raw material name
      initialQuantity,
      remainingQuantity,
      usedQuantity,
      description ?? '',
      category ?? '',
      unitCost ?? 0.0,
      supplier ?? '',
      location ?? '',
    ];
  }

  // Copy with method
  Material copyWith({
    String? id,
    String? name,
    int? initialQuantity,
    int? remainingQuantity,
    int? usedQuantity,
    String? description,
    String? category,
    double? unitCost,
    String? supplier,
    String? location,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return Material(
      id: id ?? this.id,
      name:
          name ?? this.name, // Preserve original name if not explicitly changed
      initialQuantity: initialQuantity ?? this.initialQuantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      usedQuantity: usedQuantity ?? this.usedQuantity,
      description: description ?? this.description,
      category: category ?? this.category,
      unitCost: unitCost ?? this.unitCost,
      supplier: supplier ?? this.supplier,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  // Stock status getters
  bool get isLowStock => remainingQuantity <= 10 && remainingQuantity > 5;
  bool get isCriticalStock => remainingQuantity <= 5 && remainingQuantity > 0;
  bool get isOutOfStock => remainingQuantity <= 0;

  int get calculatedUsedQuantity => initialQuantity - remainingQuantity;
}
