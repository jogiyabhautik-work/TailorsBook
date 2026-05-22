// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'worker_assignment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkerAssignmentModelAdapter extends TypeAdapter<WorkerAssignmentModel> {
  @override
  final int typeId = 15;

  @override
  WorkerAssignmentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkerAssignmentModel(
      id: fields[0] as String,
      orderItemId: fields[1] as String,
      workerId: fields[2] as String,
      orderId: fields[9] as String,
      status: fields[3] as String,
      assignedAt: fields[4] as DateTime,
      startedAt: fields[5] as DateTime?,
      completedAt: fields[6] as DateTime?,
      reworkCount: fields[7] as int,
      expectedCompletionDate: fields[8] as DateTime?,
      productName: fields[10] as String,
      quantity: fields[11] as int,
      workerRate: fields[12] as double,
      subtotal: fields[13] as double,
      assignedBy: fields[14] as String?,
      notes: fields[15] as String?,
      receivedAt: fields[16] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, WorkerAssignmentModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.orderItemId)
      ..writeByte(2)
      ..write(obj.workerId)
      ..writeByte(9)
      ..write(obj.orderId)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.assignedAt)
      ..writeByte(5)
      ..write(obj.startedAt)
      ..writeByte(6)
      ..write(obj.completedAt)
      ..writeByte(7)
      ..write(obj.reworkCount)
      ..writeByte(8)
      ..write(obj.expectedCompletionDate)
      ..writeByte(10)
      ..write(obj.productName)
      ..writeByte(11)
      ..write(obj.quantity)
      ..writeByte(12)
      ..write(obj.workerRate)
      ..writeByte(13)
      ..write(obj.subtotal)
      ..writeByte(14)
      ..write(obj.assignedBy)
      ..writeByte(15)
      ..write(obj.notes)
      ..writeByte(16)
      ..write(obj.receivedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkerAssignmentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
