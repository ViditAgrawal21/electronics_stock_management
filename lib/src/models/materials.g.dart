// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'materials.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MaterialAdapter extends TypeAdapter<Material> {
  @override
  final int typeId = 0;

  @override
  Material read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Material(
      id: fields[0] as String,
      name: fields[1] as String,
      initialQuantity: fields[2] as int,
      remainingQuantity: fields[3] as int,
      usedQuantity: fields[4] as int,
      description: fields[5] as String?,
      category: fields[6] as String?,
      unitCost: fields[7] as double?,
      supplier: fields[8] as String?,
      location: fields[9] as String?,
      createdAt: fields[10] as DateTime,
      lastUsedAt: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Material obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.initialQuantity)
      ..writeByte(3)
      ..write(obj.remainingQuantity)
      ..writeByte(4)
      ..write(obj.usedQuantity)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.unitCost)
      ..writeByte(8)
      ..write(obj.supplier)
      ..writeByte(9)
      ..write(obj.location)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.lastUsedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
