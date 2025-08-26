class PCB {
  final String id;
  final String name;
  final String description;
  final List<BOMItem> bomItems;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final PCBType type; // cape, dido, led, etc.
  final String? footprint;
  final PCBSide side; // top, bottom, both

  PCB({
    required this.id,
    required this.name,
    required this.description,
    required this.bomItems,
    required this.createdAt,
    this.updatedAt,
    required this.type,
    this.footprint,
    this.side = PCBSide.both,
  });

  // Calculate total material cost for this PCB
  double get totalCost {
    return bomItems.fold(0.0, (sum, item) => sum + item.totalCost);
  }

  // Get total unique components count
  int get totalComponents {
    return bomItems.length;
  }

  // Get total quantity of all components
  int get totalQuantity {
    return bomItems.fold(0, (sum, item) => sum + item.quantity);
  }

  // Check if PCB can be manufactured with current stock
  bool canManufacture(Map<String, int> currentStock, {int quantity = 1}) {
    for (BOMItem item in bomItems) {
      int requiredQuantity = item.quantity * quantity;
      int availableQuantity = currentStock[item.materialId] ?? 0;
      
      if (availableQuantity < requiredQuantity) {
        return false;
      }
    }
    return true;
  }

  // Get missing materials for manufacturing
  List<Map<String, dynamic>> getMissingMaterials(
    Map<String, int> currentStock, 
    Map<String, String> materialNames, {
    int quantity = 1
  }) {
    List<Map<String, dynamic>> missing = [];
    
    for (BOMItem item in bomItems) {
      int requiredQuantity = item.quantity * quantity;
      int availableQuantity = currentStock[item.materialId] ?? 0;
      
      if (availableQuantity < requiredQuantity) {
        missing.add({
          'materialId': item.materialId,
          'materialName': materialNames[item.materialId] ?? 'Unknown',
          'required': requiredQuantity,
          'available': availableQuantity,
          'shortage': requiredQuantity - availableQuantity,
          'reference': item.reference,
        });
      }
    }
    return missing;
  }

  // Calculate material requirements for batch production
  Map<String, int> calculateMaterialRequirements(int quantity) {
    Map<String, int> requirements = {};
    
    for (BOMItem item in bomItems) {
      String materialId = item.materialId;
      int requiredQuantity = item.quantity * quantity;
      
      if (requirements.containsKey(materialId)) {
        requirements[materialId] = requirements[materialId]! + requiredQuantity;
      } else {
        requirements[materialId] = requiredQuantity;
      }
    }
    return requirements;
  }

  // Factory constructor for creating PCB from JSON
  factory PCB.fromJson(Map<String, dynamic> json) {
    return PCB(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      bomItems: (json['bomItems'] as List)
          .map((item) => BOMItem.fromJson(item))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      type: PCBType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PCBType.other,
      ),
      footprint: json['footprint'],
      side: PCBSide.values.firstWhere(
        (e) => e.name == json['side'],
        orElse: () => PCBSide.both,
      ),
    );
  }

  // Convert PCB to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'bomItems': bomItems.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'type': type.name,
      'footprint': footprint,
      'side': side.name,
    };
  }

  // Copy with method for updates
  PCB copyWith({
    String? id,
    String? name,
    String? description,
    List<BOMItem>? bomItems,
    DateTime? createdAt,
    DateTime? updatedAt,
    PCBType? type,
    String? footprint,
    PCBSide? side,
  }) {
    return PCB(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      bomItems: bomItems ?? this.bomItems,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
      footprint: footprint ?? this.footprint,
      side: side ?? this.side,
    );
  }

  @override
  String toString() {
    return 'PCB{id: $id, name: $name, type: $type, components: ${bomItems.length}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PCB && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// BOM Item class for individual components in PCB
class BOMItem {
  final String id;
  final String materialId;
  final String reference; // Component reference (R1, C1, etc.)
  final String value; // Component value (10K, 100nF, etc.)
  final String footprint;
  final int quantity;
  final PCBSide side;
  final double? unitCost;

  BOMItem({
    required this.id,
    required this.materialId,
    required this.reference,
    required this.value,
    required this.footprint,
    required this.quantity,
    required this.side,
    this.unitCost,
  });

  // Calculate total cost for this BOM item
  double get totalCost {
    return (unitCost ?? 0.0) * quantity;
  }

  // Factory constructor from JSON
  factory BOMItem.fromJson(Map<String, dynamic> json) {
    return BOMItem(
      id: json['id'],
      materialId: json['materialId'],
      reference: json['reference'],
      value: json['value'],
      footprint: json['footprint'],
      quantity: json['quantity'],
      side: PCBSide.values.firstWhere(
        (e) => e.name == json['side'],
        orElse: () => PCBSide.top,
      ),
      unitCost: json['unitCost']?.toDouble(),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'materialId': materialId,
      'reference': reference,
      'value': value,
      'footprint': footprint,
      'quantity': quantity,
      'side': side.name,
      'unitCost': unitCost,
    };
  }

  // Copy with method
  BOMItem copyWith({
    String? id,
    String? materialId,
    String? reference,
    String? value,
    String? footprint,
    int? quantity,
    PCBSide? side,
    double? unitCost,
  }) {
    return BOMItem(
      id: id ?? this.id,
      materialId: materialId ?? this.materialId,
      reference: reference ?? this.reference,
      value: value ?? this.value,
      footprint: footprint ?? this.footprint,
      quantity: quantity ?? this.quantity,
      side: side ?? this.side,
      unitCost: unitCost ?? this.unitCost,
    );
  }

  @override
  String toString() {
    return 'BOMItem{reference: $reference, value: $value, qty: $quantity}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BOMItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Enum for PCB types
enum PCBType {
  cape,
  dido,
  led,
  main,
  sensor,
  power,
  interface,
  other;

  String get displayName {
    switch (this) {
      case PCBType.cape:
        return 'Cape Board';
      case PCBType.dido:
        return 'DIDO Board';
      case PCBType.led:
        return 'LED Board';
      case PCBType.main:
        return 'Main Board';
      case PCBType.sensor:
        return 'Sensor Board';
      case PCBType.power:
        return 'Power Board';
      case PCBType.interface:
        return 'Interface Board';
      case PCBType.other:
        return 'Other';
    }
  }
}

// Enum for PCB side placement
enum PCBSide {
  top,
  bottom,
  both;

  String get displayName {
    switch (this) {
      case PCBSide.top:
        return 'Top';
      case PCBSide.bottom:
        return 'Bottom';
      case PCBSide.both:
        return 'Both';
    }
  }
}