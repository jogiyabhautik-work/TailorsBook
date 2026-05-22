import 'package:hive/hive.dart';

part 'worker_assignment_model.g.dart';

@HiveType(typeId: 15)
class WorkerAssignmentModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String orderItemId;
  @HiveField(2)
  final String workerId;
  @HiveField(9)
  final String orderId;
  @HiveField(3)
  final String status; // assigned, in_progress, completed, reassigned
  @HiveField(4)
  final DateTime assignedAt;
  @HiveField(5)
  final DateTime? startedAt;
  @HiveField(6)
  final DateTime? completedAt;
  @HiveField(7)
  final int reworkCount;
  @HiveField(8)
  final DateTime? expectedCompletionDate;

  // ── Pricing Fields ──
  @HiveField(10)
  final String productName;
  @HiveField(11)
  final int quantity;
  @HiveField(12)
  final double workerRate;
  @HiveField(13)
  final double subtotal;
  @HiveField(14)
  final String? assignedBy;
  @HiveField(15)
  final String? notes;
  @HiveField(16)
  final DateTime? receivedAt;

  WorkerAssignmentModel({
    required this.id,
    required this.orderItemId,
    required this.workerId,
    required this.orderId,
    this.status = 'assigned',
    required this.assignedAt,
    this.startedAt,
    this.completedAt,
    this.reworkCount = 0,
    this.expectedCompletionDate,
    this.productName = '',
    this.quantity = 1,
    this.workerRate = 0.0,
    this.subtotal = 0.0,
    this.assignedBy,
    this.notes,
    this.receivedAt,
  });

  factory WorkerAssignmentModel.fromJson(Map<String, dynamic> json) {
    return WorkerAssignmentModel(
      id: json['id']?.toString() ?? '',
      orderItemId: json['order_item_id']?.toString() ?? '',
      workerId: json['worker_id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'assigned',
      assignedAt: DateTime.tryParse(json['assigned_at']?.toString() ?? '') ?? DateTime.now(),
      startedAt: json['started_at'] != null ? DateTime.tryParse(json['started_at'].toString()) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) : null,
      reworkCount: (json['rework_count'] as num?)?.toInt() ?? 0,
      expectedCompletionDate: json['expected_completion_date'] != null 
          ? DateTime.tryParse(json['expected_completion_date'].toString()) 
          : null,
      productName: json['product_name']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      workerRate: (json['worker_rate'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      assignedBy: json['assigned_by']?.toString(),
      notes: json['notes']?.toString(),
      receivedAt: json['received_at'] != null ? DateTime.tryParse(json['received_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'order_item_id': orderItemId,
      'worker_id': workerId,
      'order_id': orderId,
      'status': status,
      'assigned_at': assignedAt.toIso8601String(),
      if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      'rework_count': reworkCount,
      if (expectedCompletionDate != null) 'expected_completion_date': expectedCompletionDate!.toIso8601String(),
      'product_name': productName,
      'quantity': quantity,
      'worker_rate': workerRate,
      'subtotal': subtotal,
      if (assignedBy != null) 'assigned_by': assignedBy,
      if (notes != null) 'notes': notes,
      if (receivedAt != null) 'received_at': receivedAt!.toIso8601String(),
    };
  }

  WorkerAssignmentModel copyWith({
    String? id,
    String? orderItemId,
    String? workerId,
    String? orderId,
    String? status,
    DateTime? assignedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    int? reworkCount,
    DateTime? expectedCompletionDate,
    String? productName,
    int? quantity,
    double? workerRate,
    double? subtotal,
    String? assignedBy,
    String? notes,
    DateTime? receivedAt,
  }) {
    return WorkerAssignmentModel(
      id: id ?? this.id,
      orderItemId: orderItemId ?? this.orderItemId,
      workerId: workerId ?? this.workerId,
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      assignedAt: assignedAt ?? this.assignedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      reworkCount: reworkCount ?? this.reworkCount,
      expectedCompletionDate: expectedCompletionDate ?? this.expectedCompletionDate,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      workerRate: workerRate ?? this.workerRate,
      subtotal: subtotal ?? this.subtotal,
      assignedBy: assignedBy ?? this.assignedBy,
      notes: notes ?? this.notes,
      receivedAt: receivedAt ?? this.receivedAt,
    );
  }
}
