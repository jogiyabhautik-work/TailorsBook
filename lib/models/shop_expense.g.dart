// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShopExpenseAdapter extends TypeAdapter<ShopExpense> {
  @override
  final int typeId = 18;

  @override
  ShopExpense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShopExpense(
      id: fields[0] as String,
      tailorId: fields[1] as String,
      title: fields[2] as String,
      amount: fields[4] as double,
      expenseDate: fields[5] as DateTime,
      category: fields[3] as String?,
      notes: fields[6] as String?,
      receiptUrl: fields[7] as String?,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
      syncStatus: fields[10] as String,
      deletedAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ShopExpense obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tailorId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.expenseDate)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.receiptUrl)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.syncStatus)
      ..writeByte(11)
      ..write(obj.deletedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
