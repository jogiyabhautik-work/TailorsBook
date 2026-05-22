// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fabric_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShopFabricModelAdapter extends TypeAdapter<ShopFabricModel> {
  @override
  final int typeId = 12;

  @override
  ShopFabricModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShopFabricModel(
      id: fields[0] as String,
      shopId: fields[1] as String,
      name: fields[2] as String,
      fabricType: fields[3] as String,
      color: fields[4] as String,
      quantityMeters: fields[5] as double,
      unitPricePerMeter: fields[6] as double,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ShopFabricModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.shopId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.fabricType)
      ..writeByte(4)
      ..write(obj.color)
      ..writeByte(5)
      ..write(obj.quantityMeters)
      ..writeByte(6)
      ..write(obj.unitPricePerMeter)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopFabricModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CustomerFabricModelAdapter extends TypeAdapter<CustomerFabricModel> {
  @override
  final int typeId = 13;

  @override
  CustomerFabricModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomerFabricModel(
      id: fields[0] as String,
      customerId: fields[1] as String,
      orderId: fields[2] as String,
      fabricType: fields[3] as String,
      color: fields[4] as String,
      quantityMeters: fields[5] as double,
      usedMeters: fields[6] as double,
      notes: fields[7] as String?,
      isReturned: fields[8] as bool,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CustomerFabricModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.orderId)
      ..writeByte(3)
      ..write(obj.fabricType)
      ..writeByte(4)
      ..write(obj.color)
      ..writeByte(5)
      ..write(obj.quantityMeters)
      ..writeByte(6)
      ..write(obj.usedMeters)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.isReturned)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerFabricModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OrderItemFabricModelAdapter extends TypeAdapter<OrderItemFabricModel> {
  @override
  final int typeId = 14;

  @override
  OrderItemFabricModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderItemFabricModel(
      id: fields[0] as String,
      orderItemId: fields[1] as String,
      fabricSource: fields[2] as String,
      shopFabricId: fields[3] as String?,
      customerFabricId: fields[4] as String?,
      metersAllocated: fields[5] as double,
      purpose: fields[6] as String,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, OrderItemFabricModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.orderItemId)
      ..writeByte(2)
      ..write(obj.fabricSource)
      ..writeByte(3)
      ..write(obj.shopFabricId)
      ..writeByte(4)
      ..write(obj.customerFabricId)
      ..writeByte(5)
      ..write(obj.metersAllocated)
      ..writeByte(6)
      ..write(obj.purpose)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItemFabricModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
