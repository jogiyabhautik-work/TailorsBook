// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'worker_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkerModelAdapter extends TypeAdapter<WorkerModel> {
  @override
  final int typeId = 4;

  @override
  WorkerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkerModel(
      id: fields[0] as String,
      tailorId: fields[1] as String,
      name: fields[2] as String,
      phone: fields[3] as String?,
      salaryType: fields[4] as SalaryType,
      monthlyRate: fields[5] as double,
      joiningDate: fields[6] as DateTime,
      isActive: fields[7] as bool,
      createdAt: fields[8] as DateTime,
      activeOrderCount: fields[9] == null ? 0 : fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, WorkerModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tailorId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.salaryType)
      ..writeByte(5)
      ..write(obj.monthlyRate)
      ..writeByte(6)
      ..write(obj.joiningDate)
      ..writeByte(7)
      ..write(obj.isActive)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.activeOrderCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkLogAdapter extends TypeAdapter<WorkLog> {
  @override
  final int typeId = 5;

  @override
  WorkLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkLog(
      id: fields[0] as String,
      workerId: fields[1] as String,
      itemName: fields[2] as String,
      quantity: fields[3] as int,
      ratePerPiece: fields[4] as double,
      totalAmount: fields[5] as double,
      workDate: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WorkLog obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.workerId)
      ..writeByte(2)
      ..write(obj.itemName)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.ratePerPiece)
      ..writeByte(5)
      ..write(obj.totalAmount)
      ..writeByte(6)
      ..write(obj.workDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkerPaymentAdapter extends TypeAdapter<WorkerPayment> {
  @override
  final int typeId = 6;

  @override
  WorkerPayment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkerPayment(
      id: fields[0] as String,
      workerId: fields[1] as String,
      amount: fields[2] as double,
      paymentType: fields[3] as String,
      paymentDate: fields[4] as DateTime,
      notes: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WorkerPayment obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.workerId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.paymentType)
      ..writeByte(4)
      ..write(obj.paymentDate)
      ..writeByte(5)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkerPaymentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SalaryTypeAdapter extends TypeAdapter<SalaryType> {
  @override
  final int typeId = 3;

  @override
  SalaryType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SalaryType.monthly;
      case 1:
        return SalaryType.piece_rate;
      default:
        return SalaryType.monthly;
    }
  }

  @override
  void write(BinaryWriter writer, SalaryType obj) {
    switch (obj) {
      case SalaryType.monthly:
        writer.writeByte(0);
        break;
      case SalaryType.piece_rate:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalaryTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
