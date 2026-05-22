import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/order_model.dart';
import '../core/utils/tailor_flow_helper.dart';
import '../core/services/notification_service_helper.dart';
import '../../main.dart';
import '../core/utils/validation.dart';
import '../core/utils/connectivity_helper.dart';
import '../core/utils/supabase_error_handler.dart';
import '../core/utils/app_refresh_controller.dart';
import '../models/payment_model.dart';
import 'fabric_provider.dart';
class OrderProvider extends ChangeNotifier {
  SupabaseClient get _supabase => Supabase.instance.client;
  final FabricProvider _fabricProvider;
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  OrderProvider({FabricProvider? fabricProvider})
      : _fabricProvider = fabricProvider ?? FabricProvider();

  RealtimeChannel? _orderChannel;
  RealtimeChannel? _orderItemChannel;
  RealtimeChannel? _paymentChannel;

  // â”€â”€ Dedup & Sync Safety â”€â”€
  final Set<String> _processingOrderIds = {};
  final Map<String, DateTime> _localModifiedTimestamps = {};
  Timer? _realtimeDebounceTimer;
  final List<VoidCallback> _pendingRealtimeUpdates = [];
  bool _isRealtimeConnected = false;
  int _realtimeEventCount = 0;

  // â”€â”€ Payment Safety â”€â”€
  bool _isProcessingPayment = false;
  DateTime _lastPaymentSubmitTime = DateTime.now().subtract(const Duration(seconds: 10));

  // â”€â”€ Cached Stats â”€â”€
  double _totalEarnings = 0.0;
  int _activeOrdersCount = 0;
  double _totalDues = 0.0;

  double get totalEarnings => _totalEarnings;
  int get activeOrdersCount => _activeOrdersCount;
  double get totalDues => _totalDues;

  void _recalculateCachedStats() {
    double earningsSum = 0.0;
    int activeCount = 0;
    double duesSum = 0.0;

    for (final o in _orders) {
      if (!o.isCancelled) {
        earningsSum += o.totalPrice;
        if (o.status.toLowerCase() != 'delivered') {
          activeCount++;
        }
        duesSum += o.pendingBalance;
      }
    }

    _totalEarnings = earningsSum;
    _activeOrdersCount = activeCount;
    _totalDues = duesSum;
  }

  @override
  void notifyListeners() {
    _recalculateCachedStats();
    super.notifyListeners();
  }

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isRealtimeConnected => _isRealtimeConnected;

  List<OrderModel> get activeOrders => _orders
      .where((o) => !o.isCancelled && TailorFlowHelper.activeStates.contains(o.status.toLowerCase()))
      .toList();

  void _log(String msg) {
    debugPrint('[OrderProvider] $msg');
  }

  /// Full reset for logout/user switch â€” clears all state safely.
  void clearState() {
    _realtimeDebounceTimer?.cancel();
    _orderChannel?.unsubscribe();
    _orderItemChannel?.unsubscribe();
    _paymentChannel?.unsubscribe();
    _orders = [];
    _isLoading = false;
    _errorMessage = null;
    _processingOrderIds.clear();
    _localModifiedTimestamps.clear();
    _pendingRealtimeUpdates.clear();
    _isRealtimeConnected = false;
    _realtimeEventCount = 0;
    _isProcessingPayment = false;
    _lastPaymentSubmitTime = DateTime.now().subtract(const Duration(seconds: 10));
    notifyListeners();
  }

  void _cacheOrderLocally(OrderModel order, {bool notify = true}) {
    _recordLocalModification(order.id);
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index != -1) {
      _orders[index] = order;
    } else {
      _orders.insert(0, order);
    }
    if (notify) notifyListeners();
  }

  void _removeOrderLocally(String orderId) {
    _orders.removeWhere((o) => o.id == orderId);
    _localModifiedTimestamps.remove(orderId);
    notifyListeners();
  }

  void _recordLocalModification(String orderId) {
    _localModifiedTimestamps[orderId] = DateTime.now();
  }

  bool _wasRecentlyModifiedLocally(String orderId, {Duration within = const Duration(seconds: 3)}) {
    final ts = _localModifiedTimestamps[orderId];
    if (ts == null) return false;
    return DateTime.now().difference(ts) < within;
  }

  Future<bool> _ensureOnline() async {
    final isOnline = await ConnectivityHelper.hasInternet();
    if (!isOnline) {
      showGlobalSnackBar('Internet required. Please connect and try again.', isError: true);
      return false;
    }
    return true;
  }

  OrderModel _normalizeOrder(OrderModel order) {
    return order.copyWith(
      status: TailorFlowHelper.normalize(order.status),
      items: order.items
          .map((i) => i.copyWith(status: TailorFlowHelper.normalize(i.status)))
          .toList(),
    );
  }

  Future<void> _recalculatePaymentTotals(String orderId) async {
    try {
      final paymentsResponse = await _supabase
          .from('payments')
          .select('amount')
          .eq('order_id', orderId);

      final double actualTotalPaid = (paymentsResponse as List)
          .fold(0.0, (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0.0));

      final orderIndex = _orders.indexWhere((o) => o.id == orderId);
      final order = orderIndex != -1 ? _orders[orderIndex] : null;
      final totalPrice = order?.totalPrice ?? 0.0;
      final remaining = (totalPrice - actualTotalPaid).abs() < 0.01
          ? 0.0
          : totalPrice - actualTotalPaid;
      final paymentStatus = remaining <= 0.01
          ? 'paid'
          : actualTotalPaid > 0.01
              ? 'partial'
              : 'unpaid';

      await _supabase
          .from('orders')
          .update({
            'advance_paid': actualTotalPaid,
            'remaining_balance': remaining,
            'payment_status': paymentStatus,
            'last_modified_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      if (orderIndex != -1) {
        _orders[orderIndex] = _orders[orderIndex].copyWith(advancePaid: actualTotalPaid);
        notifyListeners();
      }
    } catch (e) {
      _log('Recalculate payment totals error: $e');
    }
  }

  List<OrderModel> ordersForWorker(String workerId) {
    return _orders.where((o) => o.assignedWorkerId == workerId && !o.isCancelled).toList();
  }

  int activeOrderCountForWorker(String workerId) {
    return ordersForWorker(workerId)
        .where((o) => o.status.toLowerCase() != 'delivered')
        .length;
  }

  List<OrderModel> dueTodayOrders() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _orders.where((o) {
      if (o.deliveryDate == null || o.isCancelled) return false;
      final delivery = DateTime(o.deliveryDate!.year, o.deliveryDate!.month, o.deliveryDate!.day);
      return delivery.isAtSameMomentAs(today) && o.status.toLowerCase() != 'delivered';
    }).toList();
  }

  Future<void> fetchOrders() async {
    if (!await _ensureOnline()) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('user_id', userId)
          .filter('deleted_at', 'is', 'null')
          .order('created_at', ascending: false);

      _orders = (response as List)
          .map((data) => _normalizeOrder(OrderModel.fromJson(data)))
          .toList();

      final dueTodayList = dueTodayOrders();
      if (dueTodayList.isNotEmpty) {
        await showLocalOrderNotification(
          title: 'Delivery reminder',
          body: '${dueTodayList.length} order(s) are due today.',
        );
      }

      subscribeToRealtime();
    } catch (e) {
      final handled = classifySupabaseError(e);
      _errorMessage = handled.userMessage;
      debugPrint('OrderProvider.fetchOrders Error: $e');
      showGlobalSnackBar(handled.userMessage, isError: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _flushRealtimeBatch() {
    final batch = List<VoidCallback>.from(_pendingRealtimeUpdates);
    _pendingRealtimeUpdates.clear();
    for (final update in batch) {
      update();
    }
  }

  void _enqueueRealtimeUpdate(VoidCallback update) {
    _pendingRealtimeUpdates.add(update);
    _realtimeDebounceTimer?.cancel();
    _realtimeDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_pendingRealtimeUpdates.isNotEmpty) {
        _flushRealtimeBatch();
        notifyListeners();
      }
    });
  }

  void subscribeToRealtime() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    final uid = user.id;

    unsubscribeFromRealtime();
    _isRealtimeConnected = false;
    _realtimeEventCount = 0;
    _log('Subscribing to realtime channels...');

    _orderChannel = _supabase.channel('public:orders').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'orders',
      callback: (payload) {
          _realtimeEventCount++;
          final eventName = payload.eventType.toString().toLowerCase();
          if (eventName.contains('delete')) {
            final deletedId = payload.oldRecord['id']?.toString() ?? payload.newRecord['id']?.toString();
            if (deletedId != null) {
              if (_wasRecentlyModifiedLocally(deletedId)) return;
              _enqueueRealtimeUpdate(() => _removeOrderLocally(deletedId));
            }
            return;
          }
          if (payload.newRecord['user_id']?.toString() != uid) return;
          final orderId = payload.newRecord['id']?.toString();
          if (orderId != null) {
            if (_wasRecentlyModifiedLocally(orderId)) return;
            _enqueueRealtimeUpdate(() => unawaited(_upsertOrderFromRealtime(payload.newRecord)));
          }
      }
    ).subscribe((status, error) {
      _isRealtimeConnected = status == RealtimeSubscribeStatus.subscribed;
      _log('Orders channel: $status (events: $_realtimeEventCount)');
      if (error != null) _log('Orders channel error: $error');
    });

    _orderItemChannel = _supabase.channel('public:order_items').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'order_items',
      callback: (payload) {
          _realtimeEventCount++;
          if (payload.eventType.toString().toLowerCase().contains('delete')) {
            _enqueueRealtimeUpdate(() => _removeOrderItemFromRealtime(payload.oldRecord));
            return;
          }
          _enqueueRealtimeUpdate(() => _updateOrderItemFromRealtime(payload.newRecord));
      }
    ).subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        _isRealtimeConnected = true;
      }
      _log('OrderItems channel: $status');
      if (error != null) _log('OrderItems channel error: $error');
    });
    
    _paymentChannel = _supabase.channel('public:payments').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'payments',
      callback: (payload) {
          _realtimeEventCount++;
          if (payload.eventType.toString().toLowerCase().contains('delete')) {
            final orderId = payload.oldRecord['order_id']?.toString();
            if (orderId != null) {
              _enqueueRealtimeUpdate(() => unawaited(_recalculatePaymentTotals(orderId)));
            }
            return;
          }
          _enqueueRealtimeUpdate(() => _updatePaymentFromRealtime(payload.newRecord));
      }
    ).subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        _isRealtimeConnected = true;
      }
      _log('Payments channel: $status');
      if (error != null) _log('Payments channel error: $error');
    });
  }

  void unsubscribeFromRealtime() {
    _realtimeDebounceTimer?.cancel();
    _realtimeDebounceTimer = null;
    _pendingRealtimeUpdates.clear();
    if (_orderChannel != null) _supabase.removeChannel(_orderChannel!);
    if (_orderItemChannel != null) _supabase.removeChannel(_orderItemChannel!);
    if (_paymentChannel != null) _supabase.removeChannel(_paymentChannel!);
    _orderChannel = null;
    _orderItemChannel = null;
    _paymentChannel = null;
    _isRealtimeConnected = false;
    _log('Unsubscribed from realtime channels');
  }

  @override
  void dispose() {
    unsubscribeFromRealtime();
    _localModifiedTimestamps.clear();
    _processingOrderIds.clear();
    super.dispose();
  }

  Future<void> _upsertOrderFromRealtime(Map<String, dynamic> newRecord) async {
     final orderId = newRecord['id']?.toString();
     if (orderId == null) return;

     // Avoid processing the same order concurrently
     if (_processingOrderIds.contains(orderId)) {
       _log('Skipping concurrent realtime update for $orderId');
       return;
     }
     _processingOrderIds.add(orderId);

     try {
       // Stale update prevention: skip if modified locally within last 3s
       if (_wasRecentlyModifiedLocally(orderId)) {
         _log('Skipping stale realtime update for $orderId');
         return;
       }

       final index = _orders.indexWhere((o) => o.id == orderId);
       final existingOrder = index == -1 ? null : _orders[index];

       if (existingOrder != null) {
         // Only merge fields that changed, preserving local state for fields not in payload
         final incomingLastModified = newRecord['last_modified_at'] != null
             ? DateTime.tryParse(newRecord['last_modified_at'].toString())
             : null;
         final localLastModified = existingOrder.lastModifiedAt;

         // Skip if incoming data is older than what we have
         if (incomingLastModified != null && localLastModified != null && incomingLastModified.isBefore(localLastModified)) {
           _log('Skipping older realtime update for $orderId');
           return;
         }

         final mergedOrder = existingOrder.copyWith(
           status: TailorFlowHelper.normalize(newRecord['status']?.toString() ?? existingOrder.status),
           totalPrice: (newRecord['total_price'] as num?)?.toDouble() ?? existingOrder.totalPrice,
           advancePaid: (newRecord['advance_paid'] as num?)?.toDouble() ?? existingOrder.advancePaid,
           deliveryDate: newRecord['delivery_date'] != null
               ? DateTime.tryParse(newRecord['delivery_date'].toString())
               : existingOrder.deliveryDate,
           trialDate: newRecord['trial_date'] != null
               ? DateTime.tryParse(newRecord['trial_date'].toString())
               : existingOrder.trialDate,
           fabricReceived: (newRecord['fabric_received'] as bool?) ?? existingOrder.fabricReceived,
           assignedWorkerId: (newRecord['assigned_worker_id']?.toString()) ?? 
                            (newRecord['worker_id']?.toString()) ?? 
                            existingOrder.assignedWorkerId,
            notes: newRecord['notes']?.toString() ?? existingOrder.notes,
            isSelfStitch: (newRecord['is_self_stitch'] as bool?) ?? existingOrder.isSelfStitch,
            lastModifiedAt: incomingLastModified ?? existingOrder.lastModifiedAt,
         );
         _cacheOrderLocally(mergedOrder, notify: false);
       } else {
         // New order from another device â€” fetch full snapshot
         final snapshot = await _fetchOrderSnapshot(orderId);
         if (snapshot != null) {
           _cacheOrderLocally(snapshot, notify: false);
         }
       }
     } finally {
       _processingOrderIds.remove(orderId);
     }
  }

  Future<OrderModel?> _fetchOrderSnapshot(String orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('id', orderId)
          .maybeSingle();

      if (response == null) return null;
      return _normalizeOrder(OrderModel.fromJson(response));
    } catch (e) {
      if (kDebugMode) print('Failed to hydrate realtime order $orderId: $e');
      return null;
    }
  }

  void _updateOrderItemFromRealtime(Map<String, dynamic> newRecord) {
     final orderId = newRecord['order_id']?.toString();
     if (orderId == null) return;

     // Skip item updates if order was recently modified locally
     if (_wasRecentlyModifiedLocally(orderId)) return;

     final orderIndex = _orders.indexWhere((o) => o.id == orderId);
     if (orderIndex == -1) return;
     
     final order = _orders[orderIndex];
     final itemId = newRecord['id']?.toString();
     final itemIndex = order.items.indexWhere((i) => i.id == itemId);
     
     if (itemIndex != -1) {
        final updatedItem = order.items[itemIndex].copyWith(
           status: TailorFlowHelper.normalize(newRecord['status'] as String? ?? order.items[itemIndex].status),
           alterationNotes: newRecord['alteration_notes'] as String?,
           measurementId: newRecord['measurement_id']?.toString(),
           templateId: newRecord['template_id']?.toString(),
        );
        final updatedItems = List<OrderItem>.from(order.items);
        updatedItems[itemIndex] = updatedItem;
        
        final updatedOrder = order.copyWith(
          items: updatedItems,
          status: TailorFlowHelper.getAggregatedStatus(updatedItems.map((i) => i.status).toList()),
        );
        _cacheOrderLocally(updatedOrder, notify: false);
     }
  }

  void _removeOrderItemFromRealtime(Map<String, dynamic> oldRecord) {
     final orderId = oldRecord['order_id']?.toString();
     final itemId = oldRecord['id']?.toString();
     if (orderId == null || itemId == null) return;

     final orderIndex = _orders.indexWhere((o) => o.id == orderId);
     if (orderIndex == -1) return;

     final order = _orders[orderIndex];
     final updatedItems = order.items.where((i) => i.id != itemId).toList();
     final updatedOrder = order.copyWith(
       items: updatedItems,
       status: TailorFlowHelper.getAggregatedStatus(updatedItems.map((i) => i.status).toList()),
     );
     _cacheOrderLocally(updatedOrder);
  }

  void _updatePaymentFromRealtime(Map<String, dynamic> newRecord) {
     final orderId = newRecord['order_id']?.toString();
     if (orderId != null) {
       unawaited(_recalculatePaymentTotals(orderId));
     }
  }

  Future<bool> createOrder(OrderModel order, List<OrderItem> items) async {
    if (!await _ensureOnline()) return false;
    
    // â”€â”€ Customer Validation â”€â”€
    if (order.customerId.startsWith('temp_')) {
      showGlobalSnackBar('Cannot create order with a temporary customer ID.', isError: true);
      return false;
    }
    
    // â”€â”€ Items Validation â”€â”€
    if (items.isEmpty) {
      showGlobalSnackBar('Order must contain at least one item.', isError: true);
      return false;
    }
    for (final item in items) {
      final itemError = Validation.validateOrderItem(
        productName: item.productName,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
      );
      if (itemError != null) {
        showGlobalSnackBar('$itemError (${item.productName})', isError: true);
        return false;
      }
    }

    // â”€â”€ Payment Validation â”€â”€
    if (order.advancePaid < 0) {
      showGlobalSnackBar('Advance amount cannot be negative.', isError: true);
      return false;
    }
    if (order.advancePaid > order.totalPrice) {
      showGlobalSnackBar('Advance amount cannot exceed total order amount.', isError: true);
      return false;
    }

    // â”€â”€ Date Validation â”€â”€
    final deliveryError = Validation.validateDeliveryDate(order.deliveryDate);
    if (deliveryError != null) {
      showGlobalSnackBar(deliveryError, isError: true);
      return false;
    }
    final trialError = Validation.validateTrialDate(order.trialDate, order.deliveryDate);
    if (trialError != null) {
      showGlobalSnackBar(trialError, isError: true);
      return false;
    }

    // â”€â”€ Work Mode Validation â”€â”€
    final workModeError = Validation.validateWorkMode(order.workMode);
    if (workModeError != null) {
      showGlobalSnackBar(workModeError, isError: true);
      return false;
    }

    _isLoading = true;
    notifyListeners();

    final userId = _supabase.auth.currentUser?.id;
    final payloadError = Validation.validateSyncPayload(
      userId: userId,
      customerId: order.customerId,
      totalPrice: order.totalPrice,
      items: items,
    );

    if (payloadError != null) {
      showGlobalSnackBar(payloadError, isError: true);
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final finalOrderId = const Uuid().v4();
    final normalizedOrder = order.copyWith(
      id: finalOrderId,
      userId: userId ?? '',
      status: TailorFlowHelper.statusPending,
      orderToken: order.orderToken.isNotEmpty ? order.orderToken : TailorFlowHelper.generateOrderToken(),
      statusHistory: TailorFlowHelper.appendHistory(
        current: [],
        fromStatus: '',
        toStatus: TailorFlowHelper.statusPending,
        note: 'Order created',
      ),
      createdAt: DateTime.now(),
      lastModifiedAt: DateTime.now(),
    );

    try {
      _recordLocalModification(finalOrderId);
      _orders.insert(0, normalizedOrder.copyWith(items: items));
      notifyListeners();

      await _supabase.from('orders').insert(normalizedOrder.toJson()..remove('items'));

      for (var item in items) {
         final finalItemId = const Uuid().v4();
         final finalItem = item.copyWith(id: finalItemId, orderId: finalOrderId);
         await _supabase.from('order_items').insert(finalItem.toJson());
      }

      showGlobalSnackBar('Order created successfully.');
      AppRefreshController().notifyOrders();
      return true;
    } catch (e) {
      debugPrint('Error creating order: $e');
      final handled = classifySupabaseError(e);
      showGlobalSnackBar(handled.userMessage, isError: true);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus, {String? note, bool updateItems = true}) async {
    if (!await _ensureOnline()) return false;

    final oldOrderIndex = _orders.indexWhere((o) => o.id == orderId);
    if (oldOrderIndex == -1) return false;
    final oldOrder = _orders[oldOrderIndex];

    if (!TailorFlowHelper.canTransition(oldOrder.status, newStatus)) {
      showGlobalSnackBar('Invalid status move from ${oldOrder.status} to $newStatus', isError: true);
      return false;
    }

    if (oldOrder.status == TailorFlowHelper.statusPending && newStatus == TailorFlowHelper.statusStitching) {
      if (!oldOrder.hasAllMeasurements) {
        showGlobalSnackBar('Add measurements for all items before starting stitching.', isError: true);
        return false;
      }
      if (!oldOrder.isSelfStitch && (oldOrder.assignedWorkerId == null || oldOrder.assignedWorkerId!.isEmpty)) {
        showGlobalSnackBar('Assign a worker before starting stitching.', isError: true);
        return false;
      }
    }

    if (newStatus == TailorFlowHelper.statusDelivered) {
       if (oldOrder.pendingBalance > 0.01) {
         showGlobalSnackBar('Cannot deliver with ₹${oldOrder.pendingBalance} balance remaining.', isError: true);
         return false;
       }
    }

    // Fabric Guardrail Pre-Check
    List<OrderItem> updatedItems = oldOrder.items;
    if (updateItems) {
      updatedItems = oldOrder.items.map((i) => i.copyWith(status: newStatus)).toList();
    }
    if (!_validateFabricStockForTransition(updatedItems, newStatus)) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      if (updateItems) {
        updatedItems = oldOrder.items.map((i) => i.copyWith(status: newStatus)).toList();
        for (var item in updatedItems) {
          await _supabase.from('order_items').update({'status': newStatus}).eq('id', item.id);
        }
      }

      final newHistory = TailorFlowHelper.appendHistory(
        current: oldOrder.statusHistory,
        fromStatus: oldOrder.status,
        toStatus: newStatus,
        note: note ?? 'Status updated',
      );

      await _supabase.from('orders').update({
        'status': newStatus,
        'status_history': newHistory,
        'last_modified_at': DateTime.now().toIso8601String()
      }).eq('id', orderId);

      _recordLocalModification(orderId);
      _orders[oldOrderIndex] = oldOrder.copyWith(
        status: newStatus,
        statusHistory: newHistory,
        items: updatedItems,
      );

      // Sync fabric inventory for all items
      for (var item in updatedItems) {
        await _syncFabricStatus(item.id, newStatus);
      }

      showGlobalSnackBar('Status: ${TailorFlowHelper.getStatusLabel(newStatus)}');
      AppRefreshController().notifyOrders();
      return true;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      final handled = classifySupabaseError(e);
      showGlobalSnackBar(handled.userMessage, isError: true);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> linkMeasurementToItem(String orderId, String itemId, String measurementId, {String? templateId}) async {
    if (!await _ensureOnline()) return false;

    final orderIndex = _orders.indexWhere((o) => o.id == orderId);
    if (orderIndex == -1) {
      debugPrint('LinkMeasurement: Order $orderId not found locally.');
      return false;
    }
    final order = _orders[orderIndex];
    
    final itemIndex = order.items.indexWhere((i) => i.id == itemId);
    if (itemIndex == -1) {
      debugPrint('LinkMeasurement: Item $itemId not found in order $orderId.');
      return false;
    }
    final item = order.items[itemIndex];

    final finalTemplateId = templateId ?? item.templateId;

    // Detailed debug logs for payload and context
    debugPrint('=== LINK MEASUREMENT INITIATED ===');
    debugPrint('Order ID: $orderId');
    debugPrint('Item ID: $itemId');
    debugPrint('Product Name: ${item.productName}');
    debugPrint('Customer ID: ${order.customerId}');
    debugPrint('Selected Measurement ID: $measurementId');
    debugPrint('Selected Template ID: $finalTemplateId');

    try {
      // 1. Fetch measurement record to validate template compatibility
      final measurementRes = await _supabase
          .from('measurement_records')
          .select()
          .eq('id', measurementId)
          .maybeSingle();

      if (measurementRes == null) {
        debugPrint('LinkMeasurement: Measurement $measurementId not found in Supabase.');
        showGlobalSnackBar('Measurement record not found on server.', isError: true);
        return false;
      }

      final recordCustomerId = measurementRes['customer_id']?.toString();
      final recordTemplateId = measurementRes['template_id']?.toString();

      debugPrint('Retrieved Measurement Customer ID: $recordCustomerId');
      debugPrint('Retrieved Measurement Template ID: $recordTemplateId');

      // Validation 1: Verify Customer Ownership
      if (recordCustomerId != order.customerId) {
        debugPrint('LinkMeasurement Validation Failed: Customer ID mismatch (Order customer: ${order.customerId}, Measurement customer: $recordCustomerId)');
        showGlobalSnackBar('Measurement record does not belong to this customer.', isError: true);
        return false;
      }

      // Validation 2: Verify Template Compatibility (non-blocking warning logs)
      if (finalTemplateId != null && recordTemplateId != null && finalTemplateId != recordTemplateId) {
        debugPrint('LinkMeasurement Validation Warning: Template ID mismatch (Selected/Item template: $finalTemplateId, Measurement template: $recordTemplateId)');
      }

      final updateData = <String, dynamic>{
        'measurement_id': measurementId,
      };
      if (finalTemplateId != null) updateData['template_id'] = finalTemplateId;

      debugPrint('Supabase Payload: $updateData');

      // 2. Perform Supabase update
      await _supabase.from('order_items').update(updateData).eq('id', itemId);

      // 3. Update local state
      final updatedItems = List<OrderItem>.from(order.items);
      updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(
        measurementId: measurementId,
        templateId: finalTemplateId ?? updatedItems[itemIndex].templateId,
      );
      
      _recordLocalModification(orderId);
      _orders[orderIndex] = order.copyWith(items: updatedItems);
      notifyListeners();
      
      debugPrint('=== LINK MEASUREMENT SUCCESS ===');
      return true;
    } catch (e) {
      debugPrint('=== LINK MEASUREMENT EXCEPTION ===');
      debugPrint('Exception type: ${e.runtimeType}');
      debugPrint('Exact exception: $e');
      if (e is PostgrestException) {
        debugPrint('PostgrestException details: Code: ${e.code}, Message: ${e.message}, Hint: ${e.hint}, Details: ${e.details}');
      }
      final handled = classifySupabaseError(e);
      showGlobalSnackBar(handled.userMessage, isError: true);
      return false;
    }
  }

  Future<bool> updateOrderItemStatus(String orderId, String itemId, String newStatus, {String? alterationNote}) async {
    if (!await _ensureOnline()) return false;

    final oldOrderIndex = _orders.indexWhere((o) => o.id == orderId);
    if (oldOrderIndex == -1) return false;
    final oldOrder = _orders[oldOrderIndex];
    
    final itemIndex = oldOrder.items.indexWhere((i) => i.id == itemId);
    if (itemIndex == -1) return false;
    final item = oldOrder.items[itemIndex];

    // Measurement Guardrail
    if (newStatus == TailorFlowHelper.statusStitching) {
      if (!oldOrder.hasAllMeasurements) {
        showGlobalSnackBar('Add measurements for all items before starting stitching.', isError: true);
        return false;
      }
    }

    // Fabric Guardrail Pre-Check
    final isProgressState = [
      TailorFlowHelper.statusStitching,
      TailorFlowHelper.statusTrialing,
      TailorFlowHelper.statusAlteration,
      TailorFlowHelper.statusReady,
      TailorFlowHelper.statusDelivered
    ].contains(newStatus);

    if (isProgressState) {
      final alloc = _fabricProvider.getAllocationForItem(itemId);
      if (alloc != null && alloc.fabricSource == 'SHOP' && alloc.purpose == FabricProvider.purposeAllocated) {
        final stockError = _fabricProvider.validateFabricQuantity(alloc.shopFabricId!, alloc.metersAllocated);
        if (stockError != null) {
          showGlobalSnackBar('${item.productName}: $stockError. Restock fabric first.', isError: true);
          return false;
        }
      }
    }

    try {
      await _supabase.from('order_items').update({
        'status': newStatus,
        'alteration_notes': ?alterationNote,
      }).eq('id', itemId);

      await _syncFabricStatus(itemId, newStatus);

      final updatedItems = List<OrderItem>.from(oldOrder.items);
      updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(
        status: newStatus,
        alterationNotes: alterationNote,
      );
      
      final aggregatedStatus = TailorFlowHelper.getAggregatedStatus(updatedItems.map((i) => i.status).toList());
      
      if (aggregatedStatus != oldOrder.status) {
         await updateOrderStatus(orderId, aggregatedStatus, note: 'Updated from item', updateItems: false);
      } else {
        _recordLocalModification(orderId);
        _orders[oldOrderIndex] = oldOrder.copyWith(items: updatedItems);
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating item status: $e');
      return false;
    }
  }

   Future<void> updateOrderFabric(String orderId, bool received) async {
    if (!await _ensureOnline()) return;
    try {
      await _supabase.from('orders').update({'fabric_received': received}).eq('id', orderId);
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _recordLocalModification(orderId);
        _orders[index] = _orders[index].copyWith(fabricReceived: received);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating fabric status: $e');
    }
  }

  /// Update an order with the provided OrderModel
  Future<bool> updateOrder(OrderModel order) async {
    if (!await _ensureOnline()) return false;
    try {
      final index = _orders.indexWhere((o) => o.id == order.id);
      if (index == -1) return false;

      await _supabase.from('orders').update(order.toJson()).eq('id', order.id);

      _recordLocalModification(order.id);
      _orders[index] = order;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating order: $e');
      return false;
    }
  }

  Future<bool> updateOrderWorker(String orderId, String? workerId) async {
    if (!await _ensureOnline()) return false;
    if (workerId != null && workerId.startsWith('temp_')) {
      showGlobalSnackBar('Cannot assign a temporary worker.', isError: true);
      return false;
    }
    try {
      final index = _orders.indexWhere((o) => o.id == orderId);
      final oldWorkerId = index != -1 ? _orders[index].assignedWorkerId : null;

      final updateData = <String, dynamic>{
        'assigned_worker_id': workerId,
        'worker_id': workerId,
        'last_modified_at': DateTime.now().toIso8601String(),
      };
      if (workerId != null && oldWorkerId != workerId) {
        updateData['worker_assigned_at'] = DateTime.now().toIso8601String();
      }
      // When a worker is assigned, set work mode to worker_assigned and update status
      if (workerId != null) {
        updateData['is_self_stitch'] = false;
        updateData['work_mode'] = 'worker_assigned';
        updateData['worker_assignment_status'] = 'assigned';
      } else {
        // When unassigning worker, default to pending decision mode
        updateData['is_self_stitch'] = false;
        updateData['work_mode'] = 'pending_decision';
        updateData['worker_assignment_status'] = 'not_assigned';
      }

      await _supabase.from('orders').update(updateData).eq('id', orderId);

      if (index != -1) {
        _recordLocalModification(orderId);
        final newWorkMode = workerId != null ? 'worker_assigned' : 'pending_decision';
        final newAssignmentStatus = workerId != null ? 'assigned' : 'not_assigned';
        _orders[index] = _orders[index].copyWith(
          assignedWorkerId: workerId,
          isSelfStitch: false,
          workMode: newWorkMode,
          workerAssignmentStatus: newAssignmentStatus,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error assigning worker: $e');
      return false;
    }
  }

  /// Toggle self-stitch mode for an order.
  Future<bool> toggleSelfStitch(String orderId, bool enabled) async {
    if (!await _ensureOnline()) return false;
    try {
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index == -1) return false;

      final order = _orders[index];

      // Block if order is delivered or cancelled
      if (order.status.toLowerCase() == 'delivered' || order.status.toLowerCase() == 'cancelled') {
        showGlobalSnackBar('Cannot change work mode for delivered or cancelled orders.', isError: true);
        return false;
      }

      // Cannot enable self-stitch if a worker is actively assigned (not yet received)
      if (enabled && order.assignedWorkerId != null && order.workerAssignmentStatus != 'received_from_worker') {
        showGlobalSnackBar('Cannot enable self-stitch while work is with a worker.', isError: true);
        return false;
      }

      final newWorkMode = enabled ? 'self_stitch' : 'worker_assigned';

      await _supabase.from('orders').update({
        'is_self_stitch': enabled,
        'work_mode': newWorkMode,
        'last_modified_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      _recordLocalModification(orderId);
      _orders[index] = _orders[index].copyWith(
        isSelfStitch: enabled,
        workMode: newWorkMode,
      );
      notifyListeners();
      AppRefreshController().notifyOrders();
      return true;
    } catch (e) {
      debugPrint('Error toggling self-stitch: $e');
      return false;
    }
  }

  /// Mark work as received from worker for a worker-assigned order.
  Future<bool> markWorkReceivedFromWorker(String orderId) async {
    if (!await _ensureOnline()) return false;
    try {
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index == -1) return false;

      final order = _orders[index];

      // Validate: Only worker-assigned orders can have work received
      if (order.workMode != 'worker_assigned') {
        showGlobalSnackBar('This is not a worker-assigned order.', isError: true);
        return false;
      }

      // Validate: Cannot mark received if not assigned
      if (order.workerAssignmentStatus == 'not_assigned' || order.workerAssignmentStatus == 'cancelled') {
        showGlobalSnackBar('Work is not assigned to any worker.', isError: true);
        return false;
      }

      final now = DateTime.now();
      final updateData = <String, dynamic>{
        'worker_assignment_status': 'received_from_worker',
        'worker_received_at': now.toIso8601String(),
        'last_modified_at': now.toIso8601String(),
      };

      String newStatus = order.status;
      List<OrderItem> updatedItems = order.items;
      bool statusChanged = false;
      List<dynamic>? newHistory;

      // If worker stitched it, move to trialing
      if (order.status == TailorFlowHelper.statusPending || order.status == TailorFlowHelper.statusStitching) {
        newStatus = TailorFlowHelper.statusTrialing;
        updateData['status'] = newStatus;
        
        newHistory = TailorFlowHelper.appendHistory(
          current: order.statusHistory,
          fromStatus: order.status,
          toStatus: newStatus,
          note: 'Work received from worker',
        );
        updateData['status_history'] = newHistory;
        
        // Also update items
        updatedItems = order.items.map((i) {
          if (i.status == TailorFlowHelper.statusPending || i.status == TailorFlowHelper.statusStitching) {
            return i.copyWith(status: newStatus);
          }
          return i;
        }).toList();
        
        statusChanged = true;
      }

      await _supabase.from('orders').update(updateData).eq('id', orderId);

      if (statusChanged) {
        for (var item in updatedItems) {
          if (item.status == newStatus) {
             await _supabase.from('order_items').update({'status': newStatus}).eq('id', item.id);
          }
        }
      }

      _recordLocalModification(orderId);
      _orders[index] = _orders[index].copyWith(
        workerAssignmentStatus: 'received_from_worker',
        workerReceivedAt: now,
        workMode: 'worker_assigned',
        isSelfStitch: false,
        status: statusChanged ? newStatus : order.status,
        statusHistory: statusChanged && newHistory != null ? List<Map<String, dynamic>>.from(newHistory) : order.statusHistory,
        items: updatedItems,
      );
      notifyListeners();
      AppRefreshController().notifyWorkers();
      return true;
    } catch (e) {
      debugPrint('Error marking work as received: $e');
      return false;
    }
  }

  Future<List<PaymentModel>> fetchOrderPayments(String orderId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select()
          .eq('order_id', orderId)
          .order('payment_date', ascending: false);
      return (response as List)
          .map((p) => PaymentModel.fromJson(p))
          .toList();
    } catch (e) {
      debugPrint('Error fetching payments: $e');
      return [];
    }
  }

  Future<bool> addOrderPayment(
    String orderId,
    double paymentAmount, {
    bool? isAdvance,
    bool? isSettle,
    String paymentMethod = 'cash',
    String? paymentNote,
  }) async {
    // â”€â”€ Guard: Double-submit prevention â”€â”€
    if (_isProcessingPayment) {
      _log('Blocked duplicate payment submit');
      return false;
    }
    final now = DateTime.now();
    if (now.difference(_lastPaymentSubmitTime).inSeconds < 2) {
      _log('Blocked rapid payment submit');
      return false;
    }

    if (!await _ensureOnline()) return false;

    // â”€â”€ Guard: Negative/zero amount â”€â”€
    paymentAmount = double.parse(paymentAmount.toStringAsFixed(2));
    if (paymentAmount <= 0) {
      showGlobalSnackBar('Amount must be positive.', isError: true);
      return false;
    }

    final orderIndex = _orders.indexWhere((o) => o.id == orderId);
    if (orderIndex == -1) return false;
    final order = _orders[orderIndex];

    // â”€â”€ Guard: Cannot add payment to delivered/cancelled â”€â”€
    if (order.status.toLowerCase() == 'delivered' || order.status.toLowerCase() == 'cancelled') {
      showGlobalSnackBar('Cannot add payment to a ${order.status} order.', isError: true);
      return false;
    }

    // â”€â”€ Guard: Payment exceeds remaining balance (unless settling) â”€â”€
    if (isSettle != true && (paymentAmount - order.pendingBalance) > 0.01) {
      showGlobalSnackBar('Payment of ₹${paymentAmount.toStringAsFixed(0)} exceeds balance of ₹${order.pendingBalance.toStringAsFixed(0)}', isError: true);
      return false;
    }

    _isProcessingPayment = true;
    _isLoading = true;
    notifyListeners();

    try {
      final isAdvanceFinal = isAdvance ?? (order.advancePaid < 0.01);

      await _supabase.from('payments').insert({
        'id': const Uuid().v4(),
        'order_id': orderId,
        'customer_id': order.customerId,
        'amount': paymentAmount,
        'is_advance': isAdvanceFinal,
        'payment_method': paymentMethod,
        if (paymentNote != null && paymentNote.trim().isNotEmpty)
          'payment_note': paymentNote.trim(),
        'payment_date': DateTime.now().toIso8601String(),
        'user_id': _supabase.auth.currentUser?.id,
        'refund_status': 'none',
      });

      await _recalculatePaymentTotals(orderId);
      _lastPaymentSubmitTime = DateTime.now();
      showGlobalSnackBar('Payment of ₹${paymentAmount.toStringAsFixed(0)} recorded.');
      AppRefreshController().notifyOrders();
      return true;
    } catch (e) {
      debugPrint('Error adding payment: $e');
      final handled = classifySupabaseError(e);
      showGlobalSnackBar(handled.userMessage, isError: true);
      return false;
    } finally {
      _isProcessingPayment = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteOrderPayment(String orderId, String paymentId) async {
    if (!await _ensureOnline()) return false;
    try {
      await _supabase.from('payments').delete().eq('id', paymentId);
      await _recalculatePaymentTotals(orderId);
      return true;
    } catch (e) {
      debugPrint('Error deleting payment: $e');
      return false;
    }
  }

  Future<bool> markPaymentRefunded(String orderId, String paymentId, {String refundStatus = 'refunded'}) async {
    if (!await _ensureOnline()) return false;
    try {
      await _supabase
          .from('payments')
          .update({'refund_status': refundStatus})
          .eq('id', paymentId);
      await _recalculatePaymentTotals(orderId);
      return true;
    } catch (e) {
      debugPrint('Error marking payment refund: $e');
      return false;
    }
  }

  Future<bool> deleteOrder(String orderId) async {
    if (!await _ensureOnline()) return false;
    try {
      await _supabase.from('orders').update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', orderId);
      _removeOrderLocally(orderId);
      AppRefreshController().notifyOrders();
      return true;
    } catch (e) {
      debugPrint('Error deleting order: $e');
      final handled = classifySupabaseError(e);
      showGlobalSnackBar(handled.userMessage, isError: true);
      return false;
    }
  }

  Future<bool> cancelOrder(String orderId, {String? reason, bool markPaymentsRefunded = false}) async {
    if (!await _ensureOnline()) return false;
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return false;
    final order = _orders[index];

    try {
      final newHistory = TailorFlowHelper.appendHistory(
        current: order.statusHistory,
        fromStatus: order.status,
        toStatus: TailorFlowHelper.statusCancelled,
        note: reason ?? 'Cancelled',
      );
      await _supabase.from('orders').update({
        'status': TailorFlowHelper.statusCancelled,
        'status_history': newHistory,
        'last_modified_at': DateTime.now().toIso8601String()
      }).eq('id', orderId);

      _recordLocalModification(orderId);
      _orders[index] = order.copyWith(status: TailorFlowHelper.statusCancelled, statusHistory: newHistory);

      // â”€â”€ Preserve payment history, optionally mark refunded â”€â”€
      if (markPaymentsRefunded && order.advancePaid > 0.01) {
        try {
          await _supabase
              .from('payments')
              .update({'refund_status': 'refunded'})
              .eq('order_id', orderId);
        } catch (e) {
          _log('Error marking payments as refunded: $e');
        }
      }

      // Restore fabric for all items
      for (var item in order.items) {
        await _syncFabricStatus(item.id, TailorFlowHelper.statusCancelled);
      }

      notifyListeners();
      AppRefreshController().notifyOrders();
      return true;
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      final handled = classifySupabaseError(e);
      showGlobalSnackBar(handled.userMessage, isError: true);
      return false;
    }
  }

  bool _validateFabricStockForTransition(List<OrderItem> items, String newStatus) {
    final isProgressState = [
      TailorFlowHelper.statusStitching,
      TailorFlowHelper.statusTrialing,
      TailorFlowHelper.statusAlteration,
      TailorFlowHelper.statusReady,
      TailorFlowHelper.statusDelivered
    ].contains(newStatus);

    if (!isProgressState) return true;

    for (var item in items) {
      final alloc = _fabricProvider.getAllocationForItem(item.id);
      if (alloc == null || alloc.fabricSource != 'SHOP') continue;

      if (alloc.purpose == FabricProvider.purposeAllocated) {
        final stockError = _fabricProvider.validateFabricQuantity(alloc.shopFabricId!, alloc.metersAllocated);
        if (stockError != null) {
          showGlobalSnackBar('${item.productName}: $stockError. Restock fabric first.', isError: true);
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _syncFabricStatus(String itemId, String newStatus) async {
    final alloc = _fabricProvider.getAllocationForItem(itemId);
    if (alloc == null || alloc.fabricSource != 'SHOP') return;

    // Consume if moving to progress states
    final isProgressState = [
      TailorFlowHelper.statusStitching,
      TailorFlowHelper.statusTrialing,
      TailorFlowHelper.statusAlteration,
      TailorFlowHelper.statusReady,
      TailorFlowHelper.statusDelivered
    ].contains(newStatus);

    if (isProgressState && alloc.purpose == FabricProvider.purposeAllocated) {
      await _fabricProvider.consumeFabricForStitching(itemId);
    } 
    // Restore if cancelled
    else if (newStatus == TailorFlowHelper.statusCancelled && alloc.purpose == FabricProvider.purposeConsumed) {
      await _fabricProvider.restoreFabricForItem(itemId);
    }
    // Re-allocate if restored from cancelled to pending
    else if (newStatus == TailorFlowHelper.statusPending && alloc.purpose == FabricProvider.purposeRestored) {
      await _fabricProvider.reallocateFabricForRestoredItem(itemId);
    }
  }
}
