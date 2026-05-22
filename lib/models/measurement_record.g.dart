// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MeasurementRecordAdapter extends TypeAdapter<MeasurementRecord> {
  @override
  final int typeId = 10;

  @override
  MeasurementRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MeasurementRecord(
      id: fields[0] as String,
      customerId: fields[1] as String,
      customerName: fields[2] as String,
      templateId: fields[3] as String,
      templateName: fields[4] as String,
      date: fields[5] as DateTime,
      values: (fields[6] as Map).cast<String, double>(),
      stitchingInstructions: fields[7] as String?,
      tailorId: fields[8] as String?,
      updatedAt: fields[9] as DateTime?,
      createdAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, MeasurementRecord obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.customerName)
      ..writeByte(3)
      ..write(obj.templateId)
      ..writeByte(4)
      ..write(obj.templateName)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.values)
      ..writeByte(7)
      ..write(obj.stitchingInstructions)
      ..writeByte(8)
      ..write(obj.tailorId)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasurementRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
