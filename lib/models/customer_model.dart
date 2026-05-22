import 'package:hive/hive.dart';

part 'customer_model.g.dart';

@HiveType(typeId: 0)
class Customer extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String phone;
  @HiveField(3)
  final String address;
  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final String syncStatus;
  @HiveField(6)
  final DateTime? deletedAt;
  @HiveField(7)
  final String? tailorId;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    DateTime? createdAt,
    this.syncStatus = 'synced',
    this.deletedAt,
    this.tailorId,
  }) : createdAt = createdAt ?? DateTime.now();

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    DateTime? createdAt,
    String? syncStatus,
    DateTime? deletedAt,
    String? tailorId,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      deletedAt: deletedAt ?? this.deletedAt,
      tailorId: tailorId ?? this.tailorId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'created_at': createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'tailor_id': tailorId,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '')
          ?? DateTime.tryParse(map['createdAt']?.toString() ?? '')
          ?? DateTime.now(),
      syncStatus: map['sync_status']?.toString() ?? 'synced',
      deletedAt: DateTime.tryParse(map['deleted_at']?.toString() ?? ''),
      tailorId: map['tailor_id']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Customer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
