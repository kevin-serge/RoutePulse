// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeliveryAdapter extends TypeAdapter<Delivery> {
  @override
  final int typeId = 0;

  @override
  Delivery read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Delivery(
      client: fields[0] as String,
      address: fields[1] as String,
      status: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Delivery obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.client)
      ..writeByte(1)
      ..write(obj.address)
      ..writeByte(2)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
