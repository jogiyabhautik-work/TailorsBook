// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderItemAdapter extends TypeAdapter<OrderItem> {
  @override
  final int typeId = 1;

  @override
  OrderItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderItem(
      id: fields[0] as String,
      orderId: fields[1] as String,
      productName: fields[2] as String,
      quantity: fields[3] as int,
      unitPrice: fields[4] as double,
      status: fields[5] as String,
      fabricDetails: fields[6] as String?,
      referenceImageUrl: fields[7] as String?,
      alterationNotes: fields[8] as String?,
      measurementId: fields[9] as String?,
      templateId: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OrderItem obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.orderId)
      ..writeByte(2)
      ..write(obj.productName)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.unitPrice)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.fabricDetails)
      ..writeByte(7)
      ..write(obj.referenceImageUrl)
      ..writeByte(8)
      ..write(obj.alterationNotes)
      ..writeByte(9)
      ..write(obj.measurementId)
      ..writeByte(10)
      ..write(obj.templateId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OrderModelAdapter extends TypeAdapter<OrderModel> {
  @override
  final int typeId = 2;

  @override
  OrderModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      customerId: fields[2] as String,
      status: fields[3] as String,
      deliveryDate: fields[4] as DateTime?,
      trialDate: fields[5] as DateTime?,
      totalPrice: fields[6] as double,
      advancePaid: fields[7] as double,
      notes: fields[8] as String?,
      createdAt: fields[9] as DateTime,
      assignedWorkerId: fields[10] as String?,
      hasMeasurements: fields[11] == null ? false : fields[11] as bool,
      fabricReceived: fields[13] == null ? false : fields[13] as bool,
      items: (fields[12] as List).cast<OrderItem>(),
      orderToken: fields[14] as String,
      statusHistory: (fields[16] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      isDraft: fields[17] == null ? false : fields[17] as bool,
      syncStatus: fields[18] as String,
      deletedAt: fields[19] as DateTime?,
      lastModifiedAt: fields[20] as DateTime?,
      isSelfStitch: fields[21] == null ? false : fields[21] as bool,
      workMode: fields[22] == null ? 'self_stitch' : fields[22] as String,
      workerAssignmentStatus:
          fields[23] == null ? 'not_assigned' : fields[23] as String,
      workerReceivedAt: fields[24] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, OrderModel obj) {
    writer
      ..writeByte(24)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.customerId)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.deliveryDate)
      ..writeByte(5)
      ..write(obj.trialDate)
      ..writeByte(6)
      ..write(obj.totalPrice)
      ..writeByte(7)
      ..write(obj.advancePaid)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.assignedWorkerId)
      ..writeByte(11)
      ..write(obj.hasMeasurements)
      ..writeByte(12)
      ..write(obj.items)
      ..writeByte(13)
      ..write(obj.fabricReceived)
      ..writeByte(14)
      ..write(obj.orderToken)
      ..writeByte(16)
      ..write(obj.statusHistory)
      ..writeByte(17)
      ..write(obj.isDraft)
      ..writeByte(18)
      ..write(obj.syncStatus)
      ..writeByte(19)
      ..write(obj.deletedAt)
      ..writeByte(20)
      ..write(obj.lastModifiedAt)
      ..writeByte(21)
      ..write(obj.isSelfStitch)
      ..writeByte(22)
      ..write(obj.workMode)
      ..writeByte(23)
      ..write(obj.workerAssignmentStatus)
      ..writeByte(24)
      ..write(obj.workerReceivedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
