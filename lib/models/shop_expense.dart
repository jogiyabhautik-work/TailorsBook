import 'package:hive/hive.dart';

part 'shop_expense.g.dart';

@HiveType(typeId: 18)
class ShopExpense extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String tailorId;
  @HiveField(2)
  final String title;
  @HiveField(3)
  final String? category;
  @HiveField(4)
  final double amount;
  @HiveField(5)
  final DateTime expenseDate;
  @HiveField(6)
  final String? notes;
  @HiveField(7)
  final String? receiptUrl;
  @HiveField(8)
  final DateTime createdAt;
  @HiveField(9)
  final DateTime updatedAt;

  @HiveField(10)
  final String syncStatus;
  @HiveField(11)
  final DateTime? deletedAt;

  ShopExpense({
    required this.id,
    required this.tailorId,
    required this.title,
    required this.amount,
    required this.expenseDate,
    this.category,
    this.notes,
    this.receiptUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = 'synced',
    this.deletedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ShopExpense.fromMap(Map<String, dynamic> map) {
    return ShopExpense(
      id: map['id']?.toString() ?? '',
      tailorId: map['tailor_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      category: map['category']?.toString(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      expenseDate: map['expense_date'] != null
          ? DateTime.parse(map['expense_date'].toString())
          : DateTime.now(),
      notes: map['notes']?.toString(),
      receiptUrl: map['receipt_url']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : DateTime.now(),
      syncStatus: map['sync_status']?.toString() ?? 'synced',
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'].toString()) : null,
    );
  }

  factory ShopExpense.fromJson(Map<String, dynamic> json) => ShopExpense.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tailor_id': tailorId,
      'title': title,
      'category': category,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
      'notes': notes,
      'receipt_url': receiptUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
