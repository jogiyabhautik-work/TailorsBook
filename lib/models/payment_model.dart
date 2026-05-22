class PaymentModel {
  final String id;
  final String orderId;
  final String customerId;
  final String? userId;
  final double amount;
  final bool isAdvance;
  final String paymentMethod;
  final String? paymentNote;
  final DateTime paymentDate;
  final DateTime createdAt;
  final String refundStatus;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    this.userId,
    required this.amount,
    this.isAdvance = false,
    this.paymentMethod = 'cash',
    this.paymentNote,
    required this.paymentDate,
    required this.createdAt,
    this.refundStatus = 'none',
  });

  bool get isRefunded => refundStatus == 'refunded';
  bool get isPartiallyRefunded => refundStatus == 'partial';

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      isAdvance: json['is_advance'] == true,
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      paymentNote: json['payment_note']?.toString(),
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'].toString())
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      refundStatus: json['refund_status']?.toString() ?? 'none',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'order_id': orderId,
      'customer_id': customerId,
      if (userId != null) 'user_id': userId,
      'amount': amount,
      'is_advance': isAdvance,
      'payment_method': paymentMethod,
      if (paymentNote != null) 'payment_note': paymentNote,
      'payment_date': paymentDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'refund_status': refundStatus,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? orderId,
    String? customerId,
    String? userId,
    double? amount,
    bool? isAdvance,
    String? paymentMethod,
    String? paymentNote,
    DateTime? paymentDate,
    DateTime? createdAt,
    String? refundStatus,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      isAdvance: isAdvance ?? this.isAdvance,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentNote: paymentNote ?? this.paymentNote,
      paymentDate: paymentDate ?? this.paymentDate,
      createdAt: createdAt ?? this.createdAt,
      refundStatus: refundStatus ?? this.refundStatus,
    );
  }
}
