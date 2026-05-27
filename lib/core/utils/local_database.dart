import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../models/customer_model.dart';
import '../../../../models/order_model.dart';
import '../../../../models/worker_model.dart';
import '../../../../models/measurement_template.dart';
import '../../../../models/measurement_record.dart';


import '../../../../models/shop_expense.dart';
import '../../../../models/worker_assignment_model.dart';
import '../../../../models/fabric_model.dart';

class LocalDatabase {
  static const String customerBoxName = 'customers';
  static const String orderBoxName = 'orders';
  static const String workerBoxName = 'workers';
  static const String templateBoxName = 'templates';
  static const String measurementBoxName = 'measurements';
  static const String paymentSyncBoxName = 'payments_sync';
  
  // Fabric System Boxes
  static const String shopFabricBoxName = 'shop_fabrics';
  static const String customerFabricBoxName = 'customer_fabrics';
  static const String orderItemFabricBoxName = 'order_item_fabrics';

  // Worker Assignments Box
  static const String workerAssignmentBoxName = 'worker_assignments';

  static const String expenseBoxName = 'shop_expenses';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Adapters
    _registerAdapters();

    // Open Boxes with Self-Healing Logic
    await _openSafeBox<Customer>(customerBoxName);
    await _openSafeBox<OrderModel>(orderBoxName);
    await _openSafeBox<WorkerModel>(workerBoxName);
    await _openSafeBox<ProductTemplate>(templateBoxName);
    await _openSafeBox<MeasurementRecord>(measurementBoxName);
    await _openSafeBox<Map>(paymentSyncBoxName);
    
    // Open Fabric Boxes
    await _openSafeBox<ShopFabricModel>(shopFabricBoxName);
    await _openSafeBox<CustomerFabricModel>(customerFabricBoxName);
    await _openSafeBox<OrderItemFabricModel>(orderItemFabricBoxName);

    // Open Worker Assignment Box
    await _openSafeBox<WorkerAssignmentModel>(workerAssignmentBoxName);

    await _openSafeBox<ShopExpense>(expenseBoxName);
  }

  static void _registerAdapters() {
    // Only register if not already registered to avoid errors on hot restart
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CustomerAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(OrderItemAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(OrderModelAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(SalaryTypeAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(WorkerModelAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(WorkLogAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(WorkerPaymentAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(TemplateCategoryAdapter());
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(MeasurementFieldAdapter());
    if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(ProductTemplateAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(MeasurementRecordAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(FieldTypeAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(ShopFabricModelAdapter());
    if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(CustomerFabricModelAdapter());
    if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(OrderItemFabricModelAdapter());
    if (!Hive.isAdapterRegistered(15)) Hive.registerAdapter(WorkerAssignmentModelAdapter());

    if (!Hive.isAdapterRegistered(18)) Hive.registerAdapter(ShopExpenseAdapter());
  }

  /// Attempts to open a box. If corrupted or error occurs, deletes and recreates it.
  static Future<Box<T>> _openSafeBox<T>(String name) async {
    try {
      return await Hive.openBox<T>(name);
    } catch (e) {
      debugPrint('Hive: Failed to open box "$name", attempting recovery: $e');
      try {
        // If it's already open but corrupted, close it first
        if (Hive.isBoxOpen(name)) {
          await Hive.box(name).close();
        }
        await Hive.deleteBoxFromDisk(name);
      } catch (deleteError) {
        debugPrint('Hive Recovery: Could not delete box from disk: $deleteError');
      }
      return await Hive.openBox<T>(name);
    }
  }

  // Generic helpers
  static Box<T> getBox<T>(String name) => Hive.box<T>(name);
  
  static Future<void> saveAll<T>(String boxName, List<T> items, dynamic Function(T) keySelector) async {
    final box = getBox<T>(boxName);
    final Map<dynamic, T> map = {for (var item in items) keySelector(item): item};
    await box.putAll(map);
  }

  static List<T> getAll<T>(String boxName) {
    return getBox<T>(boxName).values.toList();
  }

  static Future<void> clear<T>(String boxName) async {
    await getBox<T>(boxName).clear();
  }
}
