class Material {
  final String id;
  final String name;
  final int initialQuantity;
  int remainingQuantity;
  int usedQuantity;
  final DateTime createdAt;
  DateTime lastUsedAt;
  final String? description;
  final String? category;
  final double? unitCost;
  final String? supplier;
  final String? location;

  Material({
    required this.id,
    required this.name,
    required this.initialQuantity,
    required this.remainingQuantity,
    this.usedQuantity = 0,
    required this.createdAt,
    required this.lastUsedAt,
    this.description,
    this.category,
    this.unitCost,
    this.supplier,
    this.location,
  });

  // Calculate used quantity automatically
  int get calculatedUsedQuantity => initialQuantity - remainingQuantity;

  // Check if material is low stock
  bool get isLowStock => remainingQuantity <= 10 && remainingQuantity > 5;

  // Check if material is critical stock
  bool get isCriticalStock => remainingQuantity <= 5 && remainingQuantity > 0;

  // Check if material is out of stock
  bool get isOutOfStock => remainingQuantity <= 0;

  // Get stock status
  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isCriticalStock) return 'Critical Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  // Create from JSON
  factory Material.fromJson(Map<String, dynamic> json) {
    return Material(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      initialQuantity: json['initialQuantity'] ?? 0,
      remainingQuantity: json['remainingQuantity'] ?? 0,
      usedQuantity: json['usedQuantity'] ?? 0,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      lastUsedAt: DateTime.parse(
        json['lastUsedAt'] ?? DateTime.now().toIso8601String(),
      ),
      description: json['description'],
      category: json['category'],
      unitCost: json['unitCost']?.toDouble(),
      supplier: json['supplier'],
      location: json['location'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'initialQuantity': initialQuantity,
      'remainingQuantity': remainingQuantity,
      'usedQuantity': usedQuantity,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt.toIso8601String(),
      'description': description,
      'category': category,
      'unitCost': unitCost,
      'supplier': supplier,
      'location': location,
    };
  }

  // Create from Excel row
  factory Material.fromExcelRow(List<dynamic> row, {required String id}) {
    final now = DateTime.now();
    return Material(
      id: id,
      name: row.isNotEmpty ? row[0]?.toString() ?? '' : '',
      initialQuantity: row.length > 1
          ? int.tryParse(row[1]?.toString() ?? '0') ?? 0
          : 0,
      remainingQuantity: row.length > 2
          ? int.tryParse(row[2]?.toString() ?? '0') ?? 0
          : 0,
      usedQuantity: row.length > 3
          ? int.tryParse(row[3]?.toString() ?? '0') ?? 0
          : 0,
      createdAt: now,
      lastUsedAt: now,
      description: row.length > 4 ? row[4]?.toString() : null,
      category: row.length > 5 ? row[5]?.toString() : null,
      unitCost: row.length > 6
          ? double.tryParse(row[6]?.toString() ?? '0')
          : null,
      supplier: row.length > 7 ? row[7]?.toString() : null,
      location: row.length > 8 ? row[8]?.toString() : null,
    );
  }

  // Convert to Excel row
  List<dynamic> toExcelRow() {
    return [
      name,
      initialQuantity,
      remainingQuantity,
      usedQuantity,
      description ?? '',
      category ?? '',
      unitCost ?? 0,
      supplier ?? '',
      location ?? '',
    ];
  }

  // Copy with method for updating
  Material copyWith({
    String? id,
    String? name,
    int? initialQuantity,
    int? remainingQuantity,
    int? usedQuantity,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    String? description,
    String? category,
    double? unitCost,
    String? supplier,
    String? location,
  }) {
    return Material(
      id: id ?? this.id,
      name: name ?? this.name,
      initialQuantity: initialQuantity ?? this.initialQuantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      usedQuantity: usedQuantity ?? this.usedQuantity,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      description: description ?? this.description,
      category: category ?? this.category,
      unitCost: unitCost ?? this.unitCost,
      supplier: supplier ?? this.supplier,
      location: location ?? this.location,
    );
  }

  @override
  String toString() {
    return 'Material(id: $id, name: $name, remaining: $remainingQuantity, used: $usedQuantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Material && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
