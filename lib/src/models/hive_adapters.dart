import 'package:hive/hive.dart';
import '../models/bom.dart';

class BOMItemAdapter extends TypeAdapter<BOMItem> {
  @override
  final int typeId = 1;

  @override
  BOMItem read(BinaryReader reader) {
    return BOMItem(
      id: reader.readString(),
      serialNumber: reader.readInt(),
      reference: reader.readString(),
      value: reader.readString(),
      // Fix: materialName can be int or String, handle both
      materialName: () {
        var val = reader.read();
        if (val is int) {
          return val.toString();
        } else if (val == null) {
          return '';
        } else {
          return val as String;
        }
      }(),
      footprint: reader.readString(),
      quantity: reader.readInt(),
      layer: reader.readString(),
      pcbId: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, BOMItem obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.serialNumber);
    writer.writeString(obj.reference);
    writer.writeString(obj.value);
    writer.writeString(obj.materialName);
    writer.writeString(obj.footprint);
    writer.writeInt(obj.quantity);
    writer.writeString(obj.layer);
    writer.writeString(obj.pcbId);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}

class BOMAdapter extends TypeAdapter<BOM> {
  @override
  final int typeId = 2;

  @override
  BOM read(BinaryReader reader) {
    return BOM(
      id: reader.readString(),
      name: reader.readString(),
      pcbId: reader.readString(),
      items: (reader.readList()).cast<BOMItem>(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, BOM obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.pcbId);
    writer.writeList(obj.items);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
  }
}
