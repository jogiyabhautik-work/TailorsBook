import 'package:hive/hive.dart';

part 'measurement_record.g.dart';

@HiveType(typeId: 10)
class MeasurementRecord extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String customerId;
  @HiveField(2)
  final String customerName;
  @HiveField(3)
  final String templateId;
  @HiveField(4)
  final String templateName;
  @HiveField(5)
  final DateTime date;
  @HiveField(6)
  final Map<String, double> values; // Field ID -> Value
  @HiveField(7)
  final String? stitchingInstructions;
  @HiveField(8)
  final String? tailorId;
  @HiveField(9)
  final DateTime updatedAt;
  @HiveField(10)
  final DateTime createdAt;

  MeasurementRecord({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.templateId,
    required this.templateName,
    required this.date,
    required this.values,
    this.stitchingInstructions,
    this.tailorId,
    DateTime? updatedAt,
    DateTime? createdAt,
  })  : updatedAt = updatedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  MeasurementRecord copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? templateId,
    String? templateName,
    DateTime? date,
    Map<String, double>? values,
    String? stitchingInstructions,
    String? tailorId,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return MeasurementRecord(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
      date: date ?? this.date,
      values: values ?? Map.from(this.values),
      stitchingInstructions: stitchingInstructions ?? this.stitchingInstructions,
      tailorId: tailorId ?? this.tailorId,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'template_id': templateId,
      'template_name': templateName,
      'date': date.toIso8601String(),
      'values': values,
      'stitching_instructions': stitchingInstructions,
      'tailor_id': tailorId,
      'updated_at': updatedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MeasurementRecord.fromJson(Map<String, dynamic> map) {
    final rawValues = map['values'] as Map<dynamic, dynamic>? ?? {};
    final parsedValues = rawValues.map((key, value) {
      double parsedValue;
      if (value is num) {
        parsedValue = value.toDouble();
      } else if (value is String) {
        parsedValue = double.tryParse(value) ?? 0.0;
      } else {
        parsedValue = 0.0;
      }
      return MapEntry(key.toString(), parsedValue);
    });

    return MeasurementRecord(
      id: map['id']?.toString() ?? '',
      customerId: map['customer_id']?.toString() ?? '',
      customerName: map['customer_name'] ?? '',
      templateId: map['template_id'] ?? '',
      templateName: map['template_name'] ?? '',
      date: map['date'] != null ? (DateTime.tryParse(map['date'].toString()) ?? DateTime.now()) : DateTime.now(),
      values: parsedValues,
      stitchingInstructions: map['stitching_instructions'],
      tailorId: (map['user_id'] ?? map['tailor_id'])?.toString(),
      updatedAt: map['updated_at'] != null ? (DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()) : null,
      createdAt: map['created_at'] != null ? (DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()) : null,
    );
  }
}
