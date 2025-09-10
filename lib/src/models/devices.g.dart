// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'devices.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubComponentAdapter extends TypeAdapter<SubComponent> {
  @override
  final int typeId = 0;

  @override
  SubComponent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubComponent(
      id: fields[0] as String,
      name: fields[1] as String,
      quantity: fields[2] as int,
      description: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SubComponent obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubComponentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DeviceAdapter extends TypeAdapter<Device> {
  @override
  final int typeId = 1;

  @override
  Device read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Device(
      id: fields[0] as String,
      name: fields[1] as String,
      subComponents: (fields[2] as List).cast<SubComponent>(),
      pcbs: (fields[3] as List).cast<PCB>(),
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      description: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Device obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.subComponents)
      ..writeByte(3)
      ..write(obj.pcbs)
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
      other is DeviceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProductionRecordAdapter extends TypeAdapter<ProductionRecord> {
  @override
  final int typeId = 2;

  @override
  ProductionRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductionRecord(
      id: fields[0] as String,
      deviceId: fields[1] as String,
      deviceName: fields[2] as String,
      quantityProduced: fields[3] as int,
      productionDate: fields[4] as DateTime,
      materialsUsed: (fields[5] as Map).cast<String, int>(),
      totalCost: fields[6] as double,
      notes: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProductionRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.deviceId)
      ..writeByte(2)
      ..write(obj.deviceName)
      ..writeByte(3)
      ..write(obj.quantityProduced)
      ..writeByte(4)
      ..write(obj.productionDate)
      ..writeByte(5)
      ..write(obj.materialsUsed)
      ..writeByte(6)
      ..write(obj.totalCost)
      ..writeByte(7)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductionRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
