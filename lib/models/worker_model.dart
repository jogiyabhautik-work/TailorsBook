import 'package:hive/hive.dart';

part 'worker_model.g.dart';

@HiveType(typeId: 3)
enum SalaryType { 
  @HiveField(0)
  monthly, 
  @HiveField(1)
  piece_rate 
}

@HiveType(typeId: 4)
class WorkerModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String tailorId;
  @HiveField(2)
  final String name;
  @HiveField(3)
  final String? phone;
  @HiveField(4)
  final SalaryType salaryType;
  @HiveField(5)
  final double monthlyRate;
  @HiveField(6)
  final DateTime joiningDate;
  @HiveField(7)
  final bool isActive;
  @HiveField(8)
  final DateTime createdAt;
  @HiveField(9, defaultValue: 0)
  final int activeOrderCount;

  WorkerModel({
    required this.id,
    required this.tailorId,
    required this.name,
    this.phone,
    required this.salaryType,
    this.monthlyRate = 0.0,
    required this.joiningDate,
    this.isActive = true,
    required this.createdAt,
    this.activeOrderCount = 0,
  });

  factory WorkerModel.fromMap(Map<String, dynamic> map) {
    return WorkerModel(
      id: map['id'] ?? '',
      tailorId: map['tailor_id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      salaryType: map['salary_type'] == 'monthly' ? SalaryType.monthly : SalaryType.piece_rate,
      monthlyRate: (map['monthly_rate'] ?? 0.0).toDouble(),
      joiningDate: DateTime.tryParse(map['joining_date']?.toString() ?? '') ?? DateTime.now(),
      isActive: map['is_active'] ?? true,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      activeOrderCount: (map['active_order_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'salary_type': salaryType == SalaryType.monthly ? 'monthly' : 'piece_rate',
      'monthly_rate': monthlyRate,
      'joining_date': joiningDate.toIso8601String().split('T')[0],
      'is_active': isActive,
      'tailor_id': tailorId,
      'active_order_count': activeOrderCount,
    };
  }

  WorkerModel copyWith({
    String? id,
    String? tailorId,
    String? name,
    String? phone,
    SalaryType? salaryType,
    double? monthlyRate,
    DateTime? joiningDate,
    bool? isActive,
    DateTime? createdAt,
    int? activeOrderCount,
  }) {
    return WorkerModel(
      id: id ?? this.id,
      tailorId: tailorId ?? this.tailorId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      salaryType: salaryType ?? this.salaryType,
      monthlyRate: monthlyRate ?? this.monthlyRate,
      joiningDate: joiningDate ?? this.joiningDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      activeOrderCount: activeOrderCount ?? this.activeOrderCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkerModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@HiveType(typeId: 5)
class WorkLog extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String workerId;
  @HiveField(2)
  final String itemName;
  @HiveField(3)
  final int quantity;
  @HiveField(4)
  final double ratePerPiece;
  @HiveField(5)
  final double totalAmount;
  @HiveField(6)
  final DateTime workDate;

  WorkLog({
    required this.id,
    required this.workerId,
    required this.itemName,
    required this.quantity,
    required this.ratePerPiece,
    required this.totalAmount,
    required this.workDate,
  });

  factory WorkLog.fromMap(Map<String, dynamic> map) {
    return WorkLog(
      id: map['id']?.toString() ?? '',
      workerId: map['worker_id']?.toString() ?? '',
      itemName: map['item_name']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      ratePerPiece: (map['rate_per_piece'] ?? 0.0).toDouble(),
      totalAmount: (map['total_amount'] ?? 0.0).toDouble(),
      workDate: DateTime.tryParse(map['work_date']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

@HiveType(typeId: 6)
class WorkerPayment extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String workerId;
  @HiveField(2)
  final double amount;
  @HiveField(3)
  final String paymentType; 
  @HiveField(4)
  final DateTime paymentDate;
  @HiveField(5)
  final String? notes;

  WorkerPayment({
    required this.id,
    required this.workerId,
    required this.amount,
    required this.paymentType,
    required this.paymentDate,
    this.notes,
  });

  factory WorkerPayment.fromMap(Map<String, dynamic> map) {
    return WorkerPayment(
      id: map['id']?.toString() ?? '',
      workerId: map['worker_id']?.toString() ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      paymentType: map['payment_type']?.toString() ?? 'salary',
      paymentDate: DateTime.tryParse(map['payment_date']?.toString() ?? '') ?? DateTime.now(),
      notes: map['notes']?.toString(),
    );
  }
}
