import 'package:hive/hive.dart';

part 'order_model.g.dart';

@HiveType(typeId: 1)
class OrderItem extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String orderId;
  @HiveField(2)
  final String productName;
  @HiveField(3)
  final int quantity;
  @HiveField(4)
  final double unitPrice;
  @HiveField(5)
  final String status; // pending, stitching, trialing, alteration, ready, delivered, cancelled
  @HiveField(6)
  final String? fabricDetails;
  @HiveField(7)
  final String? referenceImageUrl;
  @HiveField(8)
  final String? alterationNotes;
  @HiveField(9)
  final String? measurementId;
  @HiveField(10)
  final String? templateId;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.status = 'pending',
    this.fabricDetails,
    this.referenceImageUrl,
    this.alterationNotes,
    this.measurementId,
    this.templateId,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? 'Unknown Item',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'pending',
      fabricDetails: json['fabric_details']?.toString(),
      referenceImageUrl: json['reference_image_url']?.toString(),
      alterationNotes: json['alteration_notes']?.toString(),
      measurementId: json['measurement_id']?.toString(),
      templateId: json['template_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'order_id': orderId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'status': status,
      if (fabricDetails != null) 'fabric_details': fabricDetails,
      if (referenceImageUrl != null) 'reference_image_url': referenceImageUrl,
      if (alterationNotes != null) 'alteration_notes': alterationNotes,
      if (measurementId != null) 'measurement_id': measurementId,
      if (templateId != null) 'template_id': templateId,
    };
  }

  OrderItem copyWith({
    String? id,
    String? orderId,
    String? productName,
    int? quantity,
    double? unitPrice,
    String? status,
    String? fabricDetails,
    String? referenceImageUrl,
    String? alterationNotes,
    String? measurementId,
    String? templateId,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      status: status ?? this.status,
      fabricDetails: fabricDetails ?? this.fabricDetails,
      referenceImageUrl: referenceImageUrl ?? this.referenceImageUrl,
      alterationNotes: alterationNotes ?? this.alterationNotes,
      measurementId: measurementId ?? this.measurementId,
      templateId: templateId ?? this.templateId,
    );
  }
}

@HiveType(typeId: 2)
class OrderModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final String customerId;
  @HiveField(3)
  final String status; // pending, stitching, trialing, alteration, ready, delivered, cancelled
  @HiveField(4)
  final DateTime? deliveryDate;
  @HiveField(5)
  final DateTime? trialDate;
  @HiveField(6)
  final double totalPrice;
  @HiveField(7)
  final double advancePaid;
  @HiveField(8)
  final String? notes;
  @HiveField(9)
  final DateTime createdAt;
  @HiveField(10)
  final String? assignedWorkerId;
  @HiveField(11, defaultValue: false)
  final bool hasMeasurements;
  @HiveField(12)
  final List<OrderItem> items;
  @HiveField(13, defaultValue: false)
  final bool fabricReceived;
  @HiveField(14)
  final String orderToken;
  @HiveField(16)
  final List<Map<String, dynamic>> statusHistory;
  @HiveField(17, defaultValue: false)
  final bool isDraft;
  @HiveField(18)
  final String syncStatus;
  @HiveField(19)
  final DateTime? deletedAt;
  @HiveField(20)
  final DateTime? lastModifiedAt;
  @HiveField(21, defaultValue: false)
  final bool isSelfStitch;
  @HiveField(22, defaultValue: 'self_stitch')
  final String workMode; // 'self_stitch' or 'worker_assigned'
  @HiveField(23, defaultValue: 'not_assigned')
  final String workerAssignmentStatus; // not_assigned, assigned, in_progress, received_from_worker, cancelled
  @HiveField(24)
  final DateTime? workerReceivedAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.customerId,
    required this.status,
    this.deliveryDate,
    this.trialDate,
    required this.totalPrice,
    required this.advancePaid,
    this.notes,
    required this.createdAt,
    this.assignedWorkerId,
    this.hasMeasurements = false,
    this.fabricReceived = false,
    this.items = const [],
    this.orderToken = '',
    this.statusHistory = const [],
    this.isDraft = false,
    this.syncStatus = 'synced',
    this.deletedAt,
    this.lastModifiedAt,
    this.isSelfStitch = false,
    this.workMode = 'self_stitch',
    this.workerAssignmentStatus = 'not_assigned',
    this.workerReceivedAt,
  });

  bool get isCancelled => status.toLowerCase() == 'cancelled';

  bool get isSelfStitchMode => workMode == 'self_stitch';
  bool get isWorkerAssignedMode => workMode == 'worker_assigned';
  bool get isWorkReceived => workerAssignmentStatus == 'received_from_worker';
  bool get isModeLocked => status.toLowerCase() == 'delivered' || status.toLowerCase() == 'cancelled';

  String get paymentStatus {
    if (pendingBalance <= 0.01) return 'paid';
    if (advancePaid > 0.01) return 'partial';
    return 'unpaid';
  }

  bool get hasAllMeasurements => items.isNotEmpty && items.every((i) => i.measurementId != null && i.measurementId!.isNotEmpty);
  int get missingMeasurementsCount => items.where((i) => i.measurementId == null || i.measurementId!.isEmpty).length;

  OrderModel copyWith({
    String? id,
    String? userId,
    String? customerId,
    String? status,
    DateTime? deliveryDate,
    DateTime? trialDate,
    double? totalPrice,
    double? advancePaid,
    String? notes,
    DateTime? createdAt,
    String? assignedWorkerId,
    bool? hasMeasurements,
    bool? fabricReceived,
    List<OrderItem>? items,
    String? orderToken,
    List<Map<String, dynamic>>? statusHistory,
    bool? isDraft,
    String? syncStatus,
    DateTime? deletedAt,
    DateTime? lastModifiedAt,
    bool? isSelfStitch,
    String? workMode,
    String? workerAssignmentStatus,
    DateTime? workerReceivedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      status: status ?? this.status,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      trialDate: trialDate ?? this.trialDate,
      totalPrice: totalPrice ?? this.totalPrice,
      advancePaid: advancePaid ?? this.advancePaid,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      assignedWorkerId: assignedWorkerId ?? this.assignedWorkerId,
      hasMeasurements: hasMeasurements ?? this.hasMeasurements,
      fabricReceived: fabricReceived ?? this.fabricReceived,
      items: items ?? this.items,
      orderToken: orderToken ?? this.orderToken,
      statusHistory: statusHistory ?? this.statusHistory,
      isDraft: isDraft ?? this.isDraft,
      syncStatus: syncStatus ?? this.syncStatus,
      deletedAt: deletedAt ?? this.deletedAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      isSelfStitch: isSelfStitch ?? this.isSelfStitch,
      workMode: workMode ?? this.workMode,
      workerAssignmentStatus: workerAssignmentStatus ?? this.workerAssignmentStatus,
      workerReceivedAt: workerReceivedAt ?? this.workerReceivedAt,
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var itemsList = <OrderItem>[];
    if (json['order_items'] != null && json['order_items'] is List) {
      itemsList = (json['order_items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList();
    }

    return OrderModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      deliveryDate: json['delivery_date'] != null
          ? DateTime.tryParse(json['delivery_date'].toString())
          : null,
      trialDate: json['trial_date'] != null
          ? DateTime.tryParse(json['trial_date'].toString())
          : null,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      advancePaid: (json['advance_paid'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      assignedWorkerId: (json['assigned_worker_id']?.toString()) ?? (json['worker_id']?.toString()),
      hasMeasurements: json['has_measurements'] as bool? ?? false,
      fabricReceived: json['fabric_received'] as bool? ?? false,
      items: itemsList,
      orderToken: json['order_token']?.toString() ?? '',
      statusHistory: (json['status_history'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          const [],
      syncStatus: json['sync_status']?.toString() ?? 'synced',
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
      lastModifiedAt: json['last_modified_at'] != null ? DateTime.tryParse(json['last_modified_at'].toString()) : null,
      isSelfStitch: json['is_self_stitch'] as bool? ?? false,
      workMode: json['work_mode']?.toString() ?? 'self_stitch',
      workerAssignmentStatus: json['worker_assignment_status']?.toString() ?? 'not_assigned',
      workerReceivedAt: json['worker_received_at'] != null ? DateTime.tryParse(json['worker_received_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'customer_id': customerId,
      'status': status,
      if (deliveryDate != null) 'delivery_date': deliveryDate!.toIso8601String(),
      if (trialDate != null) 'trial_date': trialDate!.toIso8601String(),
      'total_price': totalPrice,
      'advance_paid': advancePaid,
      if (notes != null) 'notes': notes,
      if (assignedWorkerId != null) 'assigned_worker_id': assignedWorkerId,
      'worker_id': assignedWorkerId,
      'has_measurements': hasMeasurements,
      'fabric_received': fabricReceived,
      if (orderToken.isNotEmpty) 'order_token': orderToken,
      // 'status_history' is currently omitted to match the Supabase schema
      'is_draft': isDraft,
      'created_at': createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'last_modified_at': lastModifiedAt?.toIso8601String(),
      'is_self_stitch': isSelfStitch,
      'work_mode': workMode,
      'worker_assignment_status': workerAssignmentStatus,
      if (workerReceivedAt != null) 'worker_received_at': workerReceivedAt!.toIso8601String(),
    };
  }

  double get pendingBalance => (totalPrice - advancePaid).abs() < 0.01 ? 0.0 : (totalPrice - advancePaid);
}
