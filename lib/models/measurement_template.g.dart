// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement_template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MeasurementFieldAdapter extends TypeAdapter<MeasurementField> {
  @override
  final int typeId = 8;

  @override
  MeasurementField read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MeasurementField(
      id: fields[0] as String,
      label: fields[1] as String,
      unit: fields[2] as String,
      type: fields[3] as FieldType,
    );
  }

  @override
  void write(BinaryWriter writer, MeasurementField obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasurementFieldAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProductTemplateAdapter extends TypeAdapter<ProductTemplate> {
  @override
  final int typeId = 9;

  @override
  ProductTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductTemplate(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as TemplateCategory,
      isSystemTemplate: fields[3] as bool,
      tailorId: fields[4] as String?,
      fields: (fields[5] as List).cast<MeasurementField>(),
    );
  }

  @override
  void write(BinaryWriter writer, ProductTemplate obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.isSystemTemplate)
      ..writeByte(4)
      ..write(obj.tailorId)
      ..writeByte(5)
      ..write(obj.fields);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TemplateCategoryAdapter extends TypeAdapter<TemplateCategory> {
  @override
  final int typeId = 7;

  @override
  TemplateCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TemplateCategory.ladies;
      case 1:
        return TemplateCategory.gents;
      case 2:
        return TemplateCategory.custom;
      case 3:
        return TemplateCategory.both;
      default:
        return TemplateCategory.ladies;
    }
  }

  @override
  void write(BinaryWriter writer, TemplateCategory obj) {
    switch (obj) {
      case TemplateCategory.ladies:
        writer.writeByte(0);
        break;
      case TemplateCategory.gents:
        writer.writeByte(1);
        break;
      case TemplateCategory.custom:
        writer.writeByte(2);
        break;
      case TemplateCategory.both:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FieldTypeAdapter extends TypeAdapter<FieldType> {
  @override
  final int typeId = 11;

  @override
  FieldType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FieldType.number;
      case 1:
        return FieldType.text;
      default:
        return FieldType.number;
    }
  }

  @override
  void write(BinaryWriter writer, FieldType obj) {
    switch (obj) {
      case FieldType.number:
        writer.writeByte(0);
        break;
      case FieldType.text:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FieldTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
