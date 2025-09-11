import 'package:hive/hive.dart';
import 'bom.dart';

part 'pcb.g.dart';

@HiveType(typeId: 4)
class PCB {
  final String id;
  final String name;
  final String deviceId;
  final BOM? bom;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;

  PCB({
    required this.id,
    required this.name,
    required this.deviceId,
    this.bom,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  // Check if PCB has BOM
  bool get hasBOM => bom != null;

  // Get total components if BOM exists
  int get totalComponents => bom?.totalComponents ?? 0;

  // Get unique components count if BOM exists
  int get uniqueComponents => bom?.uniqueComponents ?? 0;

  // Create from JSON
  factory PCB.fromJson(Map<String, dynamic> json) {
    return PCB(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      deviceId: json['deviceId'] ?? '',
      bom: json['bom'] != null
          ? BOM.fromJson(json['bom'] as Map<String, dynamic>)
          : null,
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
      'deviceId': deviceId,
      'bom': bom?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'description': description,
    };
  }

  // Copy with method
  PCB copyWith({
    String? id,
    String? name,
    String? deviceId,
    BOM? bom,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
  }) {
    return PCB(
      id: id ?? this.id,
      name: name ?? this.name,
      deviceId: deviceId ?? this.deviceId,
      bom: bom ?? this.bom,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
    );
  }

  @override
  String toString() {
    return 'PCB(id: $id, name: $name, hasBOM: $hasBOM)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PCB && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
