// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pcb.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PCBAdapter extends TypeAdapter<PCB> {
  @override
  final int typeId = 4;

  @override
  PCB read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PCB(
      id: fields[0] as String,
      name: fields[1] as String,
      deviceId: fields[2] as String,
      bom: fields[3] as BOM?,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      description: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PCB obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.deviceId)
      ..writeByte(3)
      ..write(obj.bom)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PCBAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
