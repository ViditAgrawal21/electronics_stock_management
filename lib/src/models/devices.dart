import 'dart:convert';

class Device {
  final String id;
  final String name;
  final String description;
  final List<DeviceComponent> components;
  final List<DevicePCB> pcbs;
  final DateTime createdDate;
  final DateTime? lastModified;
  final bool isActive;

  Device({
    required this.id,
    required this.name,
    required this.description,
    required this.components,
    required this.pcbs,
    required this.createdDate,
    this.lastModified,
    this.isActive = true,
  });

  // Copy constructor for updates
  Device copyWith({
    String? id,
    String? name,
    String? description,
    List<DeviceComponent>? components,
    List<DevicePCB>? pcbs,
    DateTime? createdDate,
    DateTime? lastModified,
    bool? isActive,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      components: components ?? this.components,
      pcbs: pcbs ?? this.pcbs,
      createdDate: createdDate ?? this.createdDate,
      lastModified: lastModified ?? this.lastModified,
      isActive: isActive ?? this.isActive,
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'components': components.map((c) => c.toMap()).toList(),
      'pcbs': pcbs.map((p) => p.toMap()).toList(),
      'createdDate': createdDate.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
      'isActive': isActive,
    };
  }

  // Create from Map for loading
  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      components: (map['components'] as List<dynamic>? ?? [])
          .map((c) => DeviceComponent.fromMap(c as Map<String, dynamic>))
          .toList(),
      pcbs: (map['pcbs'] as List<dynamic>? ?? [])
          .map((p) => DevicePCB.fromMap(p as Map<String, dynamic>))
          .toList(),
      createdDate: DateTime.parse(map['createdDate'] ?? DateTime.now().toIso8601String()),
      lastModified: map['lastModified'] != null 
          ? DateTime.parse(map['lastModified']) 
          : null,
      isActive: map['isActive'] ?? true,
    );
  }

  // Convert to JSON string
  String toJson() => jsonEncode(toMap());

  // Create from JSON string
  factory Device.fromJson(String source) => Device.fromMap(jsonDecode(source));

  @override
  String toString() {
    return 'Device(id: $id, name: $name, description: $description, components: ${components.length}, pcbs: ${pcbs.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Device && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper methods
  int get totalComponentsCount => components.length;
  int get totalPCBsCount => pcbs.length;
  
  // Get all unique materials needed for this device
  List<String> get allRequiredMaterials {
    Set<String> materials = {};
    
    // Add component materials
    for (var component in components) {
      materials.add(component.materialName);
    }
    
    // Add PCB materials
    for (var pcb in pcbs) {
      for (var bomItem in pcb.bomItems) {
        materials.add(bomItem.materialName);
      }
    }
    
    return materials.toList();
  }

  // Calculate total material requirement for given quantity
  Map<String, int> calculateMaterialRequirement(int deviceQuantity) {
    Map<String, int> requirements = {};
    
    // Calculate component requirements
    for (var component in components) {
      String material = component.materialName;
      int required = component.quantity * deviceQuantity;
      requirements[material] = (requirements[material] ?? 0) + required;
    }
    
    // Calculate PCB material requirements
    for (var pcb in pcbs) {
      for (var bomItem in pcb.bomItems) {
        String material = bomItem.materialName;
        int required = bomItem.quantity * pcb.quantity * deviceQuantity;
        requirements[material] = (requirements[material] ?? 0) + required;
      }
    }
    
    return requirements;
  }
}

class DeviceComponent {
  final String id;
  final String name;
  final String materialName; // Reference to raw material
  final int quantity;
  final String? description;
  final String? location; // Where this component is used

  DeviceComponent({
    required this.id,
    required this.name,
    required this.materialName,
    required this.quantity,
    this.description,
    this.location,
  });

  DeviceComponent copyWith({
    String? id,
    String? name,
    String? materialName,
    int? quantity,
    String? description,
    String? location,
  }) {
    return DeviceComponent(
      id: id ?? this.id,
      name: name ?? this.name,
      materialName: materialName ?? this.materialName,
      quantity: quantity ?? this.quantity,
      description: description ?? this.description,
      location: location ?? this.location,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'materialName': materialName,
      'quantity': quantity,
      'description': description,
      'location': location,
    };
  }

  factory DeviceComponent.fromMap(Map<String, dynamic> map) {
    return DeviceComponent(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      materialName: map['materialName'] ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
      description: map['description'],
      location: map['location'],
    );
  }

  @override
  String toString() {
    return 'DeviceComponent(name: $name, material: $materialName, qty: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceComponent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class DevicePCB {
  final String id;
  final String name;
  final int quantity; // How many of this PCB needed per device
  final List<BOMItem> bomItems;
  final String? description;
  final PCBType type;

  DevicePCB({
    required this.id,
    required this.name,
    required this.quantity,
    required this.bomItems,
    this.description,
    this.type = PCBType.standard,
  });

  DevicePCB copyWith({
    String? id,
    String? name,
    int? quantity,
    List<BOMItem>? bomItems,
    String? description,
    PCBType? type,
  }) {
    return DevicePCB(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      bomItems: bomItems ?? this.bomItems,
      description: description ?? this.description,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'bomItems': bomItems.map((item) => item.toMap()).toList(),
      'description': description,
      'type': type.name,
    };
  }

  factory DevicePCB.fromMap(Map<String, dynamic> map) {
    return DevicePCB(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      quantity: map['quantity']?.toInt() ?? 1,
      bomItems: (map['bomItems'] as List<dynamic>? ?? [])
          .map((item) => BOMItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      description: map['description'],
      type: PCBType.values.firstWhere(
        (e) => e.name == map['type'], 
        orElse: () => PCBType.standard,
      ),
    );
  }

  @override
  String toString() {
    return 'DevicePCB(name: $name, qty: $quantity, bomItems: ${bomItems.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DevicePCB && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Get total material requirement for this PCB
  Map<String, int> getMaterialRequirement() {
    Map<String, int> requirements = {};
    for (var bomItem in bomItems) {
      String material = bomItem.materialName;
      requirements[material] = (requirements[material] ?? 0) + bomItem.quantity;
    }
    return requirements;
  }
}

// Simple BOM Item class for DevicePCB
class BOMItem {
  final String id;
  final String reference;
  final String materialName;
  final String footprint;
  final int quantity;
  final PCBSide side;

  BOMItem({
    required this.id,
    required this.reference,
    required this.materialName,
    required this.footprint,
    required this.quantity,
    this.side = PCBSide.top,
  });

  BOMItem copyWith({
    String? id,
    String? reference,
    String? materialName,
    String? footprint,
    int? quantity,
    PCBSide? side,
  }) {
    return BOMItem(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      materialName: materialName ?? this.materialName,
      footprint: footprint ?? this.footprint,
      quantity: quantity ?? this.quantity,
      side: side ?? this.side,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reference': reference,
      'materialName': materialName,
      'footprint': footprint,
      'quantity': quantity,
      'side': side.name,
    };
  }

  factory BOMItem.fromMap(Map<String, dynamic> map) {
    return BOMItem(
      id: map['id'] ?? '',
      reference: map['reference'] ?? '',
      materialName: map['materialName'] ?? '',
      footprint: map['footprint'] ?? '',
      quantity: map['quantity']?.toInt() ?? 1,
      side: PCBSide.values.firstWhere(
        (e) => e.name == map['side'], 
        orElse: () => PCBSide.top,
      ),
    );
  }

  @override
  String toString() {
    return 'BOMItem(ref: $reference, material: $materialName, qty: $quantity)';
  }
}

// Enums
enum PCBType {
  standard,
  cape,
  dido,
  led,
  display,
  sensor,
  power,
  custom
}

enum PCBSide {
  top,
  bottom,
  both
}

// Production Record for tracking finished devices
class ProductionRecord {
  final String id;
  final String deviceId;
  final String deviceName;
  final int quantityProduced;
  final DateTime productionDate;
  final Map<String, int> materialsUsed; // material_name -> quantity_used
  final double? totalCost;
  final String? batchNumber;
  final String? notes;
  final ProductionStatus status;

  ProductionRecord({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.quantityProduced,
    required this.productionDate,
    required this.materialsUsed,
    this.totalCost,
    this.batchNumber,
    this.notes,
    this.status = ProductionStatus.completed,
  });

  ProductionRecord copyWith({
    String? id,
    String? deviceId,
    String? deviceName,
    int? quantityProduced,
    DateTime? productionDate,
    Map<String, int>? materialsUsed,
    double? totalCost,
    String? batchNumber,
    String? notes,
    ProductionStatus? status,
  }) {
    return ProductionRecord(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      quantityProduced: quantityProduced ?? this.quantityProduced,
      productionDate: productionDate ?? this.productionDate,
      materialsUsed: materialsUsed ?? this.materialsUsed,
      totalCost: totalCost ?? this.totalCost,
      batchNumber: batchNumber ?? this.batchNumber,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'quantityProduced': quantityProduced,
      'productionDate': productionDate.toIso8601String(),
      'materialsUsed': materialsUsed,
      'totalCost': totalCost,
      'batchNumber': batchNumber,
      'notes': notes,
      'status': status.name,
    };
  }

  factory ProductionRecord.fromMap(Map<String, dynamic> map) {
    return ProductionRecord(
      id: map['id'] ?? '',
      deviceId: map['deviceId'] ?? '',
      deviceName: map['deviceName'] ?? '',
      quantityProduced: map['quantityProduced']?.toInt() ?? 0,
      productionDate: DateTime.parse(map['productionDate'] ?? DateTime.now().toIso8601String()),
      materialsUsed: Map<String, int>.from(map['materialsUsed'] ?? {}),
      totalCost: map['totalCost']?.toDouble(),
      batchNumber: map['batchNumber'],
      notes: map['notes'],
      status: ProductionStatus.values.firstWhere(
        (e) => e.name == map['status'], 
        orElse: () => ProductionStatus.completed,
      ),
    );
  }

  @override
  String toString() {
    return 'ProductionRecord(device: $deviceName, qty: $quantityProduced, date: ${productionDate.toString().substring(0, 10)})';
  }
}

enum ProductionStatus {
  planned,
  inProgress,
  completed,
  cancelled
}