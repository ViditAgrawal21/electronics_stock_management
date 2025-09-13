import 'package:hive/hive.dart';

part 'bom.g.dart';

@HiveType(typeId: 5)
class BOMItem extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final int serialNumber;
  @HiveField(2)
  final String reference;
  @HiveField(3)
  final String value;
  @HiveField(4)
  final String footprint;
  @HiveField(5)
  final int quantity;
  @HiveField(6)
  final String layer; // top/bottom
  @HiveField(7)
  final String pcbId;
  @HiveField(8)
  final DateTime createdAt;

  BOMItem({
    required this.id,
    required this.serialNumber,
    required this.reference,
    required this.value,
    required this.footprint,
    required this.quantity,
    required this.layer,
    required this.pcbId,
    required this.createdAt,
  });

  // Create from JSON
  factory BOMItem.fromJson(Map<String, dynamic> json) {
    return BOMItem(
      id: json['id'] ?? '',
      serialNumber: json['serialNumber'] ?? 0,
      reference: json['reference'] ?? '',
      value: json['value'] ?? '',
      footprint: json['footprint'] ?? '',
      quantity: json['quantity'] ?? 0,
      layer: json['layer'] ?? 'top',
      pcbId: json['pcbId'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serialNumber': serialNumber,
      'reference': reference,
      'value': value,
      'footprint': footprint,
      'quantity': quantity,
      'layer': layer,
      'pcbId': pcbId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Excel row
  factory BOMItem.fromExcelRow(
    List<dynamic> row, {
    required String id,
    required String pcbId,
  }) {
    // Handle layer value
    String layerValue = 'top'; // Default value
    if (row.length > 5 && row[5] != null) {
      String rawLayer = row[5].toString().toLowerCase().trim();
      if (['top', 'bottom'].contains(rawLayer)) {
        layerValue = rawLayer;
      }
    }

    // Handle quantity - default to 1 if 0 or invalid
    int quantity = 1;
    if (row.length > 4 && row[4] != null) {
      quantity = int.tryParse(row[4].toString()) ?? 1;
      if (quantity <= 0) quantity = 1; // Default to 1 for invalid quantities
    }

    // Handle serial number
    int serialNumber = 0;
    if (row.isNotEmpty && row[0] != null) {
      serialNumber = int.tryParse(row[0].toString()) ?? 0;
    }

    return BOMItem(
      id: id,
      serialNumber: serialNumber,
      reference: row.length > 1 ? (row[1]?.toString() ?? '').trim() : '',
      value: row.length > 2 ? (row[2]?.toString() ?? '').trim() : '',
      footprint: row.length > 3 ? (row[3]?.toString() ?? '').trim() : '',
      quantity: quantity,
      layer: layerValue,
      pcbId: pcbId,
      createdAt: DateTime.now(),
    );
  }

  // Convert to Excel row
  List<dynamic> toExcelRow() {
    return [serialNumber, reference, value, footprint, quantity, layer];
  }

  // Copy with method
  BOMItem copyWith({
    String? id,
    int? serialNumber,
    String? reference,
    String? value,
    String? footprint,
    int? quantity,
    String? layer,
    String? pcbId,
    DateTime? createdAt,
  }) {
    return BOMItem(
      id: id ?? this.id,
      serialNumber: serialNumber ?? this.serialNumber,
      reference: reference ?? this.reference,
      value: value ?? this.value,
      footprint: footprint ?? this.footprint,
      quantity: quantity ?? this.quantity,
      layer: layer ?? this.layer,
      pcbId: pcbId ?? this.pcbId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'BOMItem(id: $id, reference: $reference, value: $value, qty: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BOMItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@HiveType(typeId: 6)
class BOM extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String pcbId;
  @HiveField(3)
  final List<BOMItem> items;
  @HiveField(4)
  final DateTime createdAt;
  @HiveField(5)
  final DateTime updatedAt;

  BOM({
    required this.id,
    required this.name,
    required this.pcbId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  // Get total components count
  int get totalComponents => items.fold(0, (sum, item) => sum + item.quantity);

  // Get unique components count
  int get uniqueComponents => items.length;

  // Get components by layer
  List<BOMItem> getComponentsByLayer(String layer) {
    return items
        .where((item) => item.layer.toLowerCase() == layer.toLowerCase())
        .toList();
  }

  // Create from JSON
  factory BOM.fromJson(Map<String, dynamic> json) {
    return BOM(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      pcbId: json['pcbId'] ?? '',
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => BOMItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pcbId': pcbId,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copy with method
  BOM copyWith({
    String? id,
    String? name,
    String? pcbId,
    List<BOMItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BOM(
      id: id ?? this.id,
      name: name ?? this.name,
      pcbId: pcbId ?? this.pcbId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'BOM(id: $id, name: $name, items: ${items.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BOM && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
