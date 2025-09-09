import 'pcb.dart';

class SubComponent {
  final String id;
  final String name;
  final int quantity;
  final String? description;

  SubComponent({
    required this.id,
    required this.name,
    required this.quantity,
    this.description,
  });

  // Create from JSON
  factory SubComponent.fromJson(Map<String, dynamic> json) {
    return SubComponent(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      description: json['description'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'description': description,
    };
  }

  // Copy with method
  SubComponent copyWith({
    String? id,
    String? name,
    int? quantity,
    String? description,
  }) {
    return SubComponent(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      description: description ?? this.description,
    );
  }

  @override
  String toString() {
    return 'SubComponent(id: $id, name: $name, qty: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubComponent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class Device {
  final String id;
  final String name;
  final List<SubComponent> subComponents;
  final List<PCB> pcbs;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;

  Device({
    required this.id,
    required this.name,
    required this.subComponents,
    required this.pcbs,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  // Get total BOM items count across all PCBs
  int get totalBomItems {
    int total = 0;
    for (final pcb in pcbs) {
      if (pcb.bom != null) {
        total += pcb.bom!.items.length;
      }
    }
    return total;
  }

  // Get total PCBs count
  int get totalPcbs => pcbs.length;

  // Get total sub components count
  int get totalSubComponents =>
      subComponents.fold(0, (sum, comp) => sum + comp.quantity);

  // Get PCBs with BOM
  List<PCB> get pcbsWithBOM => pcbs.where((pcb) => pcb.hasBOM).toList();

  // Get PCBs without BOM
  List<PCB> get pcbsWithoutBOM => pcbs.where((pcb) => !pcb.hasBOM).toList();

  // Check if device is ready for production (all PCBs have BOM)
  bool get isReadyForProduction =>
      pcbs.isNotEmpty && pcbs.every((pcb) => pcb.hasBOM);

  // Create from JSON
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      subComponents:
          (json['subComponents'] as List<dynamic>?)
              ?.map(
                (comp) => SubComponent.fromJson(comp as Map<String, dynamic>),
              )
              .toList() ??
          [],
      pcbs:
          (json['pcbs'] as List<dynamic>?)
              ?.map((pcb) => PCB.fromJson(pcb as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      description: json['description'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subComponents': subComponents.map((comp) => comp.toJson()).toList(),
      'pcbs': pcbs.map((pcb) => pcb.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'description': description,
    };
  }

  // Copy with method
  Device copyWith({
    String? id,
    String? name,
    List<SubComponent>? subComponents,
    List<PCB>? pcbs,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      subComponents: subComponents ?? this.subComponents,
      pcbs: pcbs ?? this.pcbs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
    );
  }

  @override
  String toString() {
    return 'Device(id: $id, name: $name, pcbs: ${pcbs.length}, components: ${subComponents.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Device && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class ProductionRecord {
  final String id;
  final String deviceId;
  final String deviceName;
  final int quantityProduced;
  final DateTime productionDate;
  final Map<String, int> materialsUsed; // materialId -> quantity used
  final double totalCost;
  final String? notes;

  ProductionRecord({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.quantityProduced,
    required this.productionDate,
    required this.materialsUsed,
    required this.totalCost,
    this.notes,
  });

  // Get total materials used count
  int get totalMaterialsUsed =>
      materialsUsed.values.fold(0, (sum, qty) => sum + qty);

  // Get unique materials count
  int get uniqueMaterialsUsed => materialsUsed.keys.length;

  // Create from JSON
  factory ProductionRecord.fromJson(Map<String, dynamic> json) {
    return ProductionRecord(
      id: json['id'] ?? '',
      deviceId: json['deviceId'] ?? '',
      deviceName: json['deviceName'] ?? '',
      quantityProduced: json['quantityProduced'] ?? 0,
      productionDate: DateTime.parse(
        json['productionDate'] ?? DateTime.now().toIso8601String(),
      ),
      materialsUsed: Map<String, int>.from(json['materialsUsed'] ?? {}),
      totalCost: (json['totalCost'] ?? 0).toDouble(),
      notes: json['notes'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'quantityProduced': quantityProduced,
      'productionDate': productionDate.toIso8601String(),
      'materialsUsed': materialsUsed,
      'totalCost': totalCost,
      'notes': notes,
    };
  }

  // Copy with method
  ProductionRecord copyWith({
    String? id,
    String? deviceId,
    String? deviceName,
    int? quantityProduced,
    DateTime? productionDate,
    Map<String, int>? materialsUsed,
    double? totalCost,
    String? notes,
  }) {
    return ProductionRecord(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      quantityProduced: quantityProduced ?? this.quantityProduced,
      productionDate: productionDate ?? this.productionDate,
      materialsUsed: materialsUsed ?? this.materialsUsed,
      totalCost: totalCost ?? this.totalCost,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'ProductionRecord(id: $id, device: $deviceName, qty: $quantityProduced, cost: $totalCost)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductionRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
