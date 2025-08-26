class Material {
  final String id;
  final String name;
  final String reference;
  final String value;
  final String footprint;
  final String category;
  final int initialQuantity;
  int remainingQuantity;
  int usedQuantity;
  final String unit; // pcs, meters, grams, etc.
  final double? unitPrice;
  final String? supplier;
  final String? location; // Storage location
  final int? minStockLevel; // For low stock alerts
  final DateTime dateAdded;
  final DateTime? lastUpdated;
  final String? notes;

  Material({
    required this.id,
    required this.name,
    required this.reference,
    required this.value,
    required this.footprint,
    required this.category,
    required this.initialQuantity,
    required this.remainingQuantity,
    this.usedQuantity = 0,
    this.unit = 'pcs',
    this.unitPrice,
    this.supplier,
    this.location,
    this.minStockLevel,
    required this.dateAdded,
    this.lastUpdated,
    this.notes,
  });

  // Create Material from Excel row data
  factory Material.fromExcelRow(Map<String, dynamic> row) {
    return Material(
      id: _generateId(row),
      name: row['name']?.toString() ?? '',
      reference: row['reference']?.toString() ?? '',
      value: row['value']?.toString() ?? '',
      footprint: row['footprint']?.toString() ?? '',
      category: row['category']?.toString() ?? 'General',
      initialQuantity: _parseInteger(row['initial_quantity']),
      remainingQuantity: _parseInteger(row['remaining_quantity'] ?? row['initial_quantity']),
      usedQuantity: _parseInteger(row['used_quantity']),
      unit: row['unit']?.toString() ?? 'pcs',
      unitPrice: _parseDouble(row['unit_price']),
      supplier: row['supplier']?.toString(),
      location: row['location']?.toString(),
      minStockLevel: _parseInteger(row['min_stock_level']),
      dateAdded: DateTime.now(),
      notes: row['notes']?.toString(),
    );
  }

  // Convert Material to Map for Excel export
  Map<String, dynamic> toExcelMap() {
    return {
      'id': id,
      'name': name,
      'reference': reference,
      'value': value,
      'footprint': footprint,
      'category': category,
      'initial_quantity': initialQuantity,
      'remaining_quantity': remainingQuantity,
      'used_quantity': usedQuantity,
      'unit': unit,
      'unit_price': unitPrice,
      'supplier': supplier,
      'location': location,
      'min_stock_level': minStockLevel,
      'date_added': dateAdded.toIso8601String(),
      'last_updated': lastUpdated?.toIso8601String(),
      'notes': notes,
    };
  }

  // Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'reference': reference,
      'value': value,
      'footprint': footprint,
      'category': category,
      'initialQuantity': initialQuantity,
      'remainingQuantity': remainingQuantity,
      'usedQuantity': usedQuantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'supplier': supplier,
      'location': location,
      'minStockLevel': minStockLevel,
      'dateAdded': dateAdded.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
      'notes': notes,
    };
  }

  // Create Material from JSON
  factory Material.fromJson(Map<String, dynamic> json) {
    return Material(
      id: json['id'],
      name: json['name'],
      reference: json['reference'],
      value: json['value'],
      footprint: json['footprint'],
      category: json['category'],
      initialQuantity: json['initialQuantity'],
      remainingQuantity: json['remainingQuantity'],
      usedQuantity: json['usedQuantity'] ?? 0,
      unit: json['unit'] ?? 'pcs',
      unitPrice: json['unitPrice']?.toDouble(),
      supplier: json['supplier'],
      location: json['location'],
      minStockLevel: json['minStockLevel'],
      dateAdded: DateTime.parse(json['dateAdded']),
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : null,
      notes: json['notes'],
    );
  }

  // Create a copy with updated values
  Material copyWith({
    String? id,
    String? name,
    String? reference,
    String? value,
    String? footprint,
    String? category,
    int? initialQuantity,
    int? remainingQuantity,
    int? usedQuantity,
    String? unit,
    double? unitPrice,
    String? supplier,
    String? location,
    int? minStockLevel,
    DateTime? dateAdded,
    DateTime? lastUpdated,
    String? notes,
  }) {
    return Material(
      id: id ?? this.id,
      name: name ?? this.name,
      reference: reference ?? this.reference,
      value: value ?? this.value,
      footprint: footprint ?? this.footprint,
      category: category ?? this.category,
      initialQuantity: initialQuantity ?? this.initialQuantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      usedQuantity: usedQuantity ?? this.usedQuantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      supplier: supplier ?? this.supplier,
      location: location ?? this.location,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      dateAdded: dateAdded ?? this.dateAdded,
      lastUpdated: lastUpdated ?? DateTime.now(),
      notes: notes ?? this.notes,
    );
  }

  // Update stock quantity and automatically calculate used quantity
  Material updateStock(int newRemainingQuantity, {String? reason}) {
    final newUsedQuantity = initialQuantity - newRemainingQuantity;
    return copyWith(
      remainingQuantity: newRemainingQuantity,
      usedQuantity: newUsedQuantity >= 0 ? newUsedQuantity : 0,
      lastUpdated: DateTime.now(),
      notes: reason != null ? '$notes\nUpdated: $reason' : notes,
    );
  }

  // Check if material is in low stock
  bool get isLowStock {
    if (minStockLevel == null) return false;
    return remainingQuantity <= minStockLevel!;
  }

  // Check if material is out of stock
  bool get isOutOfStock => remainingQuantity <= 0;

  // Get stock status as string
  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  // Get stock percentage
  double get stockPercentage {
    if (initialQuantity == 0) return 0.0;
    return (remainingQuantity / initialQuantity) * 100;
  }

  // Calculate total value in stock
  double get totalValue {
    if (unitPrice == null) return 0.0;
    return remainingQuantity * unitPrice!;
  }

  // Generate search keywords for trie search
  List<String> get searchKeywords {
    return [
      name.toLowerCase(),
      reference.toLowerCase(),
      value.toLowerCase(),
      footprint.toLowerCase(),
      category.toLowerCase(),
      supplier?.toLowerCase() ?? '',
    ].where((keyword) => keyword.isNotEmpty).toList();
  }

  @override
  String toString() {
    return 'Material(name: $name, reference: $reference, remaining: $remainingQuantity/$initialQuantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Material && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper methods for parsing Excel data
  static String _generateId(Map<String, dynamic> row) {
    final name = row['name']?.toString() ?? '';
    final reference = row['reference']?.toString() ?? '';
    final value = row['value']?.toString() ?? '';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    return '${name}_${reference}_${value}_$timestamp'
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')
        .toLowerCase();
  }

  static int _parseInteger(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value.replaceAll(',', '')) ?? 0;
    }
    return 0;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', ''));
    }
    return null;
  }
}