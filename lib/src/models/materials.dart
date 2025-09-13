import 'package:hive/hive.dart';

part 'materials.g.dart'; // This will be generated

@HiveType(typeId: 0)
class Material extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name; // This should be the raw material name exactly as in Excel
  
  @HiveField(2)
  final int initialQuantity;
  
  @HiveField(3)
  final int remainingQuantity;
  
  @HiveField(4)
  final int usedQuantity;
  
  @HiveField(5)
  final String? description;
  
  @HiveField(6)
  final String? category;
  
  @HiveField(7)
  final double? unitCost;
  
  @HiveField(8)
  final String? supplier;
  
  @HiveField(9)
  final String? location;
  
  @HiveField(10)
  final DateTime createdAt;
  
  @HiveField(11)
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
    // Handle both 2-column and 3+ column Excel formats
    if (rowValues.isEmpty) {
      throw Exception('Empty row in Excel');
    }

    // Extract raw material name exactly as it appears - NO MODIFICATION
    String rawMaterialName = (rowValues[0]?.toString() ?? '');

    if (rawMaterialName.isEmpty) {
      throw Exception('Raw material name cannot be empty');
    }

    // Parse quantity fields based on available columns
    int initialQty;
    int remainingQty;
    int usedQty;

    if (rowValues.length >= 3) {
      // Standard format: Name, Initial Qty, Remaining Qty, [Used Qty]
      initialQty = _parseInteger(rowValues[1]);
      remainingQty = _parseInteger(rowValues[2]);
      usedQty = rowValues.length > 3
          ? _parseInteger(rowValues[3])
          : (initialQty - remainingQty);
    } else if (rowValues.length == 2) {
      // Simple format: Name, Quantity (assume quantity is both initial and remaining)
      int quantity = _parseInteger(rowValues[1]);
      initialQty = quantity;
      remainingQty = quantity;
      usedQty = 0;
    } else {
      throw Exception(
        'Insufficient columns in Excel row - need at least Name and Quantity',
      );
    }

    return Material(
      id: id,
      name: rawMaterialName, // Use exactly as provided from Excel
      initialQuantity: initialQty,
      remainingQuantity: remainingQty,
      usedQuantity: usedQty,
      description: rowValues.length > 4
          ? rowValues[4]?.toString().trim()
          : null,
      category: rowValues.length > 5 ? rowValues[5]?.toString().trim() : null,
      unitCost: rowValues.length > 6 ? _parseDouble(rowValues[6]) : null,
      supplier: rowValues.length > 7 ? rowValues[7]?.toString().trim() : null,
      location: rowValues.length > 8 ? rowValues[8]?.toString().trim() : null,
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
    if (rawMaterialName.isEmpty) {
      throw Exception('Raw material name cannot be empty');
    }

    // Parse quantity fields based on available columns
    int initialQty;
    int remainingQty;

    if (rowValues.length >= 2) {
      // Has quantity columns
      initialQty = _parseInteger(rowValues[1]);
      remainingQty = rowValues.length > 2
          ? _parseInteger(rowValues[2])
          : initialQty;
    } else {
      // No quantity columns, assume 0
      initialQty = 0;
      remainingQty = 0;
    }

    return Material(
      id: id,
      name: rawMaterialName, // Use the explicitly passed raw material name
      initialQuantity: initialQty,
      remainingQuantity: remainingQty,
      usedQuantity: initialQty - remainingQty,
      description: rowValues.length > 3
          ? rowValues[3]?.toString().trim()
          : null,
      category: rowValues.length > 4 ? rowValues[4]?.toString().trim() : null,
      unitCost: rowValues.length > 5 ? _parseDouble(rowValues[5]) : null,
      supplier: rowValues.length > 6 ? rowValues[6]?.toString().trim() : null,
      location: rowValues.length > 7 ? rowValues[7]?.toString().trim() : null,
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
      name: name ?? this.name, // Preserve original name if not explicitly changed
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

  // Convert to JSON for backwards compatibility
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'initialQuantity': initialQuantity,
      'remainingQuantity': remainingQuantity,
      'usedQuantity': usedQuantity,
      'description': description,
      'category': category,
      'unitCost': unitCost,
      'supplier': supplier,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt.toIso8601String(),
    };
  }

  // Create from JSON for backwards compatibility
  factory Material.fromJson(Map<String, dynamic> json) {
    return Material(
      id: json['id'] as String,
      name: json['name'] as String,
      initialQuantity: json['initialQuantity'] as int,
      remainingQuantity: json['remainingQuantity'] as int,
      usedQuantity: json['usedQuantity'] as int? ?? 0,
      description: json['description'] as String?,
      category: json['category'] as String?,
      unitCost: json['unitCost'] as double?,
      supplier: json['supplier'] as String?,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: DateTime.parse(json['lastUsedAt'] as String),
    );
  }
}