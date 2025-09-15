// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bom.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BOMItemAdapter extends TypeAdapter<BOMItem> {
  @override
  final int typeId = 5;

  @override
  BOMItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BOMItem(
      id: fields[0] as String,
      serialNumber: fields[1] as int,
      reference: fields[2] as String,
      value: fields[3] as String,
      materialName: fields[4] as String,
      footprint: fields[5] as String,
      quantity: fields[6] as int,
      layer: fields[7] as String,
      pcbId: fields[8] as String,
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, BOMItem obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.serialNumber)
      ..writeByte(2)
      ..write(obj.reference)
      ..writeByte(3)
      ..write(obj.value)
      ..writeByte(4)
      ..write(obj.materialName)
      ..writeByte(5)
      ..write(obj.footprint)
      ..writeByte(6)
      ..write(obj.quantity)
      ..writeByte(7)
      ..write(obj.layer)
      ..writeByte(8)
      ..write(obj.pcbId)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BOMItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BOMAdapter extends TypeAdapter<BOM> {
  @override
  final int typeId = 6;

  @override
  BOM read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BOM(
      id: fields[0] as String,
      name: fields[1] as String,
      pcbId: fields[2] as String,
      items: (fields[3] as List).cast<BOMItem>(),
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, BOM obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.pcbId)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BOMAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
