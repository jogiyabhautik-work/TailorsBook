import 'package:hive/hive.dart';

part 'fabric_model.g.dart';

@HiveType(typeId: 12)
class ShopFabricModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String shopId;
  @HiveField(2)
  final String name;
  @HiveField(3)
  final String fabricType;
  @HiveField(4)
  final String color;
  @HiveField(5)
  final double quantityMeters;
  @HiveField(6)
  final double unitPricePerMeter;
  @HiveField(7)
  final DateTime createdAt;
  @HiveField(8)
  final DateTime updatedAt;

  ShopFabricModel({
    required this.id,
    required this.shopId,
    required this.name,
    required this.fabricType,
    required this.color,
    required this.quantityMeters,
    required this.unitPricePerMeter,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShopFabricModel.fromJson(Map<String, dynamic> json) {
    return ShopFabricModel(
      id: json['id']?.toString() ?? '',
      shopId: json['shop_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      fabricType: json['fabric_type']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      quantityMeters: (json['quantity_meters'] as num?)?.toDouble() ?? 0.0,
      unitPricePerMeter: (json['unit_price_per_meter'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'shop_id': shopId,
      'name': name,
      'fabric_type': fabricType,
      'color': color,
      'quantity_meters': quantityMeters,
      'unit_price_per_meter': unitPricePerMeter,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ShopFabricModel copyWith({
    String? id,
    String? shopId,
    String? name,
    String? fabricType,
    String? color,
    double? quantityMeters,
    double? unitPricePerMeter,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShopFabricModel(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      fabricType: fabricType ?? this.fabricType,
      color: color ?? this.color,
      quantityMeters: quantityMeters ?? this.quantityMeters,
      unitPricePerMeter: unitPricePerMeter ?? this.unitPricePerMeter,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@HiveType(typeId: 13)
class CustomerFabricModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String customerId;
  @HiveField(2)
  final String orderId;
  @HiveField(3)
  final String fabricType;
  @HiveField(4)
  final String color;
  @HiveField(5)
  final double quantityMeters;
  @HiveField(6)
  final double usedMeters;
  @HiveField(7)
  final String? notes;
  @HiveField(8)
  final bool isReturned;
  @HiveField(9)
  final DateTime createdAt;
  @HiveField(10)
  final DateTime updatedAt;

  CustomerFabricModel({
    required this.id,
    required this.customerId,
    required this.orderId,
    required this.fabricType,
    required this.color,
    required this.quantityMeters,
    this.usedMeters = 0.0,
    this.notes,
    this.isReturned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  double get leftoverMeters => quantityMeters - usedMeters;

  factory CustomerFabricModel.fromJson(Map<String, dynamic> json) {
    return CustomerFabricModel(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      fabricType: json['fabric_type']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      quantityMeters: (json['quantity_meters'] as num?)?.toDouble() ?? 0.0,
      usedMeters: (json['used_meters'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes']?.toString(),
      isReturned: json['is_returned'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'customer_id': customerId,
      'order_id': orderId,
      'fabric_type': fabricType,
      'color': color,
      'quantity_meters': quantityMeters,
      'used_meters': usedMeters,
      if (notes != null) 'notes': notes,
      'is_returned': isReturned,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CustomerFabricModel copyWith({
    String? id,
    String? customerId,
    String? orderId,
    String? fabricType,
    String? color,
    double? quantityMeters,
    double? usedMeters,
    String? notes,
    bool? isReturned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerFabricModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      orderId: orderId ?? this.orderId,
      fabricType: fabricType ?? this.fabricType,
      color: color ?? this.color,
      quantityMeters: quantityMeters ?? this.quantityMeters,
      usedMeters: usedMeters ?? this.usedMeters,
      notes: notes ?? this.notes,
      isReturned: isReturned ?? this.isReturned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@HiveType(typeId: 14)
class OrderItemFabricModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String orderItemId;
  @HiveField(2)
  final String fabricSource; // 'SHOP' or 'CUSTOMER'
  @HiveField(3)
  final String? shopFabricId;
  @HiveField(4)
  final String? customerFabricId;
  @HiveField(5)
  final double metersAllocated;
  @HiveField(6)
  final String purpose;
  @HiveField(7)
  final DateTime createdAt;
  @HiveField(8)
  final DateTime updatedAt;

  OrderItemFabricModel({
    required this.id,
    required this.orderItemId,
    required this.fabricSource,
    this.shopFabricId,
    this.customerFabricId,
    required this.metersAllocated,
    required this.purpose,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderItemFabricModel.fromJson(Map<String, dynamic> json) {
    return OrderItemFabricModel(
      id: json['id']?.toString() ?? '',
      orderItemId: json['order_item_id']?.toString() ?? '',
      fabricSource: json['fabric_source']?.toString() ?? '',
      shopFabricId: json['shop_fabric_id']?.toString(),
      customerFabricId: json['customer_fabric_id']?.toString(),
      metersAllocated: (json['meters_allocated'] as num?)?.toDouble() ?? 0.0,
      purpose: json['purpose']?.toString() ?? 'Main',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'order_item_id': orderItemId,
      'fabric_source': fabricSource,
      if (shopFabricId != null) 'shop_fabric_id': shopFabricId,
      if (customerFabricId != null) 'customer_fabric_id': customerFabricId,
      'meters_allocated': metersAllocated,
      'purpose': purpose,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  OrderItemFabricModel copyWith({
    String? id,
    String? orderItemId,
    String? fabricSource,
    String? shopFabricId,
    String? customerFabricId,
    double? metersAllocated,
    String? purpose,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderItemFabricModel(
      id: id ?? this.id,
      orderItemId: orderItemId ?? this.orderItemId,
      fabricSource: fabricSource ?? this.fabricSource,
      shopFabricId: shopFabricId ?? this.shopFabricId,
      customerFabricId: customerFabricId ?? this.customerFabricId,
      metersAllocated: metersAllocated ?? this.metersAllocated,
      purpose: purpose ?? this.purpose,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
