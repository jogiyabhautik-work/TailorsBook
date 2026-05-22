import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/worker_model.dart';
import '../models/worker_assignment_model.dart';
import '../models/order_model.dart';
import '../../main.dart';
import '../core/utils/connectivity_helper.dart';
import '../core/utils/app_refresh_controller.dart';
import 'order_provider.dart';

class WorkerPerformanceMetrics {
  final int completedOrders;
  final int activeOrders;
  final int delayedOrders;
  final double avgCompletionDays;
  final double totalCommission;
  final double totalEarnings;
  final int pendingTasks;
  final int alterationCount;

  WorkerPerformanceMetrics({
    this.completedOrders = 0,
    this.activeOrders = 0,
    this.delayedOrders = 0,
    this.avgCompletionDays = 0,
    this.totalCommission = 0,
    this.totalEarnings = 0,
    this.pendingTasks = 0,
    this.alterationCount = 0,
  });
}

class WorkerProvider extends ChangeNotifier {
  final OrderProvider _orderProvider;
  List<WorkerModel> _workers = [];
  List<WorkerAssignmentModel> _assignments = [];
  bool _isLoading = false;
  bool _hasError = false;

  WorkerProvider({OrderProvider? orderProvider})
      : _orderProvider = orderProvider ?? OrderProvider();

  List<WorkerModel> get workers => _workers;
  List<WorkerAssignmentModel> get assignments => _assignments;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  List<WorkerModel> get activeWorkers => _workers.where((w) => w.isActive).toList();

  Future<bool> _ensureOnline() async {
    final isOnline = await ConnectivityHelper.hasInternet();
    if (!isOnline) {
      showGlobalSnackBar('Internet required. Please connect and try again.', isError: true);
      return false;
    }
    return true;
  }

  // ── Safety: Validate worker for assignment ──
  String? validateWorkerForAssignment(String? workerId) {
    if (workerId == null || workerId.isEmpty) return null;
    final worker = _workers.firstWhere(
      (w) => w.id == workerId,
      orElse: () => WorkerModel(
        id: '',
        tailorId: '',
        name: '',
        salaryType: SalaryType.monthly,
        joiningDate: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
    if (worker.id.isEmpty) return 'Worker not found';
    if (!worker.isActive) return 'Cannot assign inactive worker';
    return null;
  }

  // ── Safety: Check if worker is overloaded ──
  bool isWorkerOverloaded(String workerId, {int threshold = 5}) {
    final worker = _workers.firstWhere(
      (w) => w.id == workerId,
      orElse: () => WorkerModel(
        id: '',
        tailorId: '',
        name: '',
        salaryType: SalaryType.monthly,
        joiningDate: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
    return worker.activeOrderCount >= threshold;
  }

  Future<void> fetchWorkers() async {
    if (!await _ensureOnline()) {
      _hasError = true;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('workers')
          .select()
          .eq('tailor_id', userId)
          .order('name');

      _workers = (response as List).map((map) => WorkerModel.fromMap(map)).toList();
      _hasError = false;
      await fetchAssignments();
    } catch (e) {
      _hasError = true;
      debugPrint('Error fetching workers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Validate that a string is a proper UUID v4 format.
  bool _isValidUuid(String id) {
    if (id.isEmpty) return false;
    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
    return uuidRegex.hasMatch(id);
  }

  /// Full reset for logout/user switch — clears all state safely.
  void clearState() {
    _workers = [];
    _assignments = [];
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAssignments() async {
    try {
      final workerIds = _workers
          .map((w) => w.id)
          .where((id) => _isValidUuid(id))
          .toList();
      if (workerIds.isEmpty) {
        _assignments = [];
      } else {
        final ids = workerIds.join(',');
        final response = await supabase
            .from('worker_assignments')
            .select()
            .filter('worker_id', 'in', '($ids)');
        _assignments = (response as List).map((map) => WorkerAssignmentModel.fromJson(map)).toList();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching assignments: $e');
    }
  }

  String normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  Future<String?> _checkWorkerDuplicate(String name, String? phone, {String? excludeId}) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final response = await supabase
          .from('workers')
          .select('id, name, phone')
          .eq('tailor_id', user.id);

      final cleanName = name.trim().toLowerCase();
      final cleanPhone = phone != null ? normalizePhone(phone) : '';

      for (final row in response as List) {
        final dbId = row['id']?.toString() ?? '';
        if (excludeId != null && dbId == excludeId) continue;

        // Check duplicate name
        final dbName = (row['name']?.toString() ?? '').trim().toLowerCase();
        if (dbName == cleanName) {
          return 'A worker with this name already exists.';
        }

        // Check duplicate phone
        if (cleanPhone.isNotEmpty) {
          final dbPhone = normalizePhone(row['phone']?.toString() ?? '');
          if (dbPhone == cleanPhone) {
            return 'A worker with this phone number already exists.';
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error checking duplicate worker: $e');
      return null;
    }
  }

  Future<bool> createWorker(WorkerModel worker) async {
    if (!await _ensureOnline()) return false;

    final duplicateError = await _checkWorkerDuplicate(worker.name, worker.phone);
    if (duplicateError != null) {
      showGlobalSnackBar(duplicateError, isError: true);
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final userId = supabase.auth.currentUser?.id;
      final finalWorker = worker.copyWith(
        id: (worker.id.isEmpty || worker.id.startsWith('temp_'))
            ? const Uuid().v4()
            : worker.id,
        tailorId: userId,
        createdAt: DateTime.now(),
      );

      final response = await supabase
          .from('workers')
          .insert(finalWorker.toMap())
          .select()
          .single();
      
      final savedWorker = WorkerModel.fromMap(response);
      
      // Replace temp worker in local list with the real DB record
      final existingIndex = _workers.indexWhere((w) => w.id == worker.id || w.name == worker.name);
      if (existingIndex != -1) {
        _workers[existingIndex] = savedWorker;
      } else {
        _workers.insert(0, savedWorker);
      }
      _workers.sort((a, b) => a.name.compareTo(b.name));

      showGlobalSnackBar('Worker ${savedWorker.name} added.');
      return true;
    } catch (e) {
      debugPrint('Error creating worker: $e');
      showGlobalSnackBar('Failed to add worker.', isError: true);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addWorker(WorkerModel worker) => createWorker(worker);

  Future<bool> updateWorker(String id, Map<String, dynamic> data) async {
    if (!await _ensureOnline()) return false;

    final name = data['name']?.toString() ?? '';
    final phone = data['phone']?.toString();
    final duplicateError = await _checkWorkerDuplicate(name, phone, excludeId: id);
    if (duplicateError != null) {
      showGlobalSnackBar(duplicateError, isError: true);
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await supabase.from('workers').update(data).eq('id', id);
      final index = _workers.indexWhere((w) => w.id == id);
      if (index != -1) {
        await fetchWorkers();
      }
      showGlobalSnackBar('Worker details updated.');
      return true;
    } catch (e) {
      debugPrint('Error updating worker: $e');
      showGlobalSnackBar('Update failed.', isError: true);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteWorker(String workerId) async {
    if (!await _ensureOnline()) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await supabase.from('workers').delete().eq('id', workerId);
      _workers.removeWhere((w) => w.id == workerId);
      showGlobalSnackBar('Worker removed.');
      return true;
    } catch (e) {
      debugPrint('Error deleting worker: $e');
      String msg = 'Delete failed.';
      if (e is PostgrestException && e.code == '23503') {
        msg = 'Cannot delete worker! This worker is assigned to existing orders. Please reassign their orders first.';
      } else if (e.toString().contains('foreign key') || e.toString().contains('violates')) {
        msg = 'Cannot delete worker! This worker is assigned to existing orders. Please reassign their orders first.';
      }
      showGlobalSnackBar(msg, isError: true);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Assign a worker to an order with product-wise pricing.
  /// [pricingData] is a list of maps with keys: orderItemId, productName, quantity, workerRate, subtotal.
  /// Also persists earnings to worker_earnings table for proper accounting.
  Future<bool> assignWorkerToOrder(String workerId, String orderId,
      {required List<Map<String, dynamic>> pricingData}) async {
    if (!await _ensureOnline()) return false;

    // ── Worker Validation ──
    if (workerId.startsWith('temp_')) {
      showGlobalSnackBar('Cannot assign a temporary worker.', isError: true);
      return false;
    }

    final worker = _workers.firstWhere(
      (w) => w.id == workerId,
      orElse: () => WorkerModel(
        id: workerId,
        tailorId: '',
        name: 'Unknown Worker',
        salaryType: SalaryType.monthly,
        joiningDate: DateTime.now(),
        createdAt: DateTime.now(),
        isActive: false,
      ),
    );
    if (!worker.isActive) {
      showGlobalSnackBar('Cannot assign to an inactive worker.', isError: true);
      return false;
    }

    // ── Order Validation ──
    final order = _orderProvider.orders.firstWhere(
      (o) => o.id == orderId,
      orElse: () => OrderModel(
        id: orderId,
        userId: '',
        customerId: '',
        status: 'unknown',
        totalPrice: 0,
        advancePaid: 0,
        createdAt: DateTime.now(),
      ),
    );
    final orderStatus = order.status.toLowerCase();
    if (orderStatus == 'delivered' || orderStatus == 'cancelled') {
      showGlobalSnackBar('Cannot assign worker to a $orderStatus order.', isError: true);
      return false;
    }

    // ── Duplicate Assignment Prevention ──
    final existingAssignments = _assignments.where(
      (a) => a.orderId == orderId && a.status != 'completed' && a.status != 'cancelled',
    ).toList();
    if (existingAssignments.isNotEmpty) {
      showGlobalSnackBar('This order already has an active worker assignment.', isError: true);
      return false;
    }

    // ── Pricing Data Validation ──
    if (pricingData.isEmpty) {
      showGlobalSnackBar('Please enter worker rate for at least one product.', isError: true);
      return false;
    }
    for (final p in pricingData) {
      final rate = (p['workerRate'] as num?)?.toDouble() ?? 0.0;
      final productName = p['productName'] as String? ?? 'Product';
      if (rate < 0) {
        showGlobalSnackBar('Worker rate for $productName cannot be negative.', isError: true);
        return false;
      }
      final quantity = (p['quantity'] as num?)?.toInt() ?? 0;
      if (quantity <= 0) {
        showGlobalSnackBar('Quantity for $productName must be greater than 0.', isError: true);
        return false;
      }
    }

    // ── Total Worker Amount vs Order Total ──
    final totalWorkerAmount = pricingData.fold(0.0, (sum, p) {
      final rate = (p['workerRate'] as num?)?.toDouble() ?? 0.0;
      final qty = (p['quantity'] as num?)?.toInt() ?? 0;
      return sum + (rate * qty);
    });
    if (totalWorkerAmount > order.totalPrice) {
      showGlobalSnackBar(
        'Total worker amount (₹${totalWorkerAmount.toStringAsFixed(0)}) exceeds order total (₹${order.totalPrice.toStringAsFixed(0)}).',
        isError: true,
      );
      return false;
    }

    try {
      // ── Remove stale earnings for this order+worker to prevent duplicates ──
      await supabase
          .from('worker_earnings')
          .delete()
          .eq('worker_id', workerId)
          .eq('reference_order_id', orderId)
          .eq('earning_type', 'piece_rate');

      final timestamp = DateTime.now().toIso8601String();

      for (final p in pricingData) {
        final subtotal = (p['subtotal'] as num?)?.toDouble() ?? 0.0;
        if (subtotal <= 0) continue;

        final assignmentId = const Uuid().v4();
        final assignment = WorkerAssignmentModel(
          id: assignmentId,
          orderItemId: p['orderItemId'] as String,
          workerId: workerId,
          orderId: orderId,
          assignedAt: DateTime.now(),
          productName: p['productName'] as String? ?? '',
          quantity: (p['quantity'] as num?)?.toInt() ?? 1,
          workerRate: (p['workerRate'] as num?)?.toDouble() ?? 0.0,
          subtotal: subtotal,
        );

        await supabase.from('worker_assignments').insert(assignment.toJson());

        // ── Persist earnings into worker_earnings table ──
        await supabase.from('worker_earnings').insert({
          'id': const Uuid().v4(),
          'worker_id': workerId,
          'amount': subtotal,
          'earning_type': 'piece_rate',
          'reference_order_id': orderId,
          'notes': 'Assigned: ${p['productName']} × ${p['quantity']} @ ₹${p['workerRate']}',
          'earned_at': timestamp,
        });
      }

      await fetchAssignments();
      AppRefreshController().notifyWorkers();
      return true;
    } catch (e) {
      debugPrint('Error assigning worker: $e');
      return false;
    }
  }

  /// Assign a worker to an order with product-wise pricing from the pricing dialog.
  /// This is called by the Order Detail Screen after the pricing dialog.
  Future<bool> assignWorkerWithPricing({
    required String workerId,
    required String orderId,
    required List<Map<String, dynamic>> pricingData,
  }) async {
    final success = await assignWorkerToOrder(workerId, orderId, pricingData: pricingData);
    if (success) {
      // Refresh earnings data so UI updates instantly
      notifyListeners();
    }
    return success;
  }

  /// Update a single assignment's status (e.g., mark work completed).
  Future<bool> updateAssignmentStatus(String assignmentId, String newStatus) async {
    if (!await _ensureOnline()) return false;
    try {
      final updateData = <String, dynamic>{
        'status': newStatus,
      };
      if (newStatus == 'completed') {
        updateData['completed_at'] = DateTime.now().toIso8601String();
      } else if (newStatus == 'in_progress') {
        updateData['started_at'] = DateTime.now().toIso8601String();
      }

      await supabase.from('worker_assignments').update(updateData).eq('id', assignmentId);
      await fetchAssignments();
      return true;
    } catch (e) {
      debugPrint('Error updating assignment status: $e');
      return false;
    }
  }

  /// Get assignments for a specific order.
  List<WorkerAssignmentModel> assignmentsForOrder(String orderId) {
    return _assignments.where((a) => a.orderId == orderId).toList();
  }

  /// Get total worker earnings from assignments for a specific order.
  double totalEarningsForOrder(String orderId) {
    return _assignments
        .where((a) => a.orderId == orderId)
        .fold(0.0, (sum, a) => sum + a.subtotal);
  }

  // ── Activity Log ──

  Future<bool> logWorkerActivity({
    required String workerId,
    required String activityType,
    String? description,
    String? referenceType,
    String? referenceId,
  }) async {
    try {
      await supabase.from('worker_activity_log').insert({
        'id': const Uuid().v4(),
        'worker_id': workerId,
        'activity_type': activityType,
        'description': ?description,
        'reference_type': ?referenceType,
        'reference_id': ?referenceId,
      });
      return true;
    } catch (e) {
      debugPrint('Error logging worker activity: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchWorkerActivity(String workerId) async {
    try {
      final response = await supabase
          .from('worker_activity_log')
          .select()
          .eq('worker_id', workerId)
          .order('created_at', ascending: false)
          .limit(50);
      return (response as List).map((m) => Map<String, dynamic>.from(m)).toList();
    } catch (e) {
      debugPrint('Error fetching activity: $e');
      return [];
    }
  }

  // ── Performance Metrics ──

  Future<WorkerPerformanceMetrics> fetchWorkerPerformance(
    String workerId,
    List<OrderModel> allOrders,
  ) async {
    try {
      final dbStats = await supabase
          .from('worker_stats')
          .select()
          .eq('worker_id', workerId)
          .maybeSingle();

      // Compute from orders for real-time accuracy
      final workerOrders = allOrders.where((o) => o.assignedWorkerId == workerId).toList();
      final completed = workerOrders.where((o) => o.status == 'delivered').length;
      final active = workerOrders.where((o) =>
        !o.isCancelled && o.status != 'delivered').length;
      final delayed = workerOrders.where((o) =>
        !o.isCancelled && o.status != 'delivered' &&
        o.deliveryDate != null && o.deliveryDate!.isBefore(DateTime.now())).length;

      int alterationCount = 0;
      for (final order in workerOrders) {
        alterationCount += order.items.where((i) =>
          i.status.toLowerCase() == 'alteration').length;
      }

      final dbAvgDays = (dbStats?['avg_completion_days'] as num?)?.toDouble() ?? 0;
      final dbTotalCommission = (dbStats?['total_commission'] as num?)?.toDouble() ?? 0;
      final dbTotalEarnings = (dbStats?['total_earnings'] as num?)?.toDouble() ?? 0;

      return WorkerPerformanceMetrics(
        completedOrders: completed,
        activeOrders: active,
        delayedOrders: delayed,
        avgCompletionDays: dbAvgDays,
        totalCommission: dbTotalCommission,
        totalEarnings: dbTotalEarnings,
        pendingTasks: active,
        alterationCount: alterationCount,
      );
    } catch (e) {
      debugPrint('Error fetching performance: $e');
      return WorkerPerformanceMetrics();
    }
  }

  // ── Worker Earnings / Commission ──

  Future<bool> addWorkerEarning({
    required String workerId,
    required double amount,
    required String earningType,
    String? referenceOrderId,
    String? notes,
  }) async {
    if (!await _ensureOnline()) return false;
    try {
      await supabase.from('worker_earnings').insert({
        'id': const Uuid().v4(),
        'worker_id': workerId,
        'amount': amount,
        'earning_type': earningType,
        'reference_order_id': ?referenceOrderId,
        'notes': ?notes,
        'earned_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('Error adding worker earning: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchWorkerEarnings(String workerId) async {
    try {
      final response = await supabase
          .from('worker_earnings')
          .select()
          .eq('worker_id', workerId)
          .order('earned_at', ascending: false);
      return (response as List).map((m) => Map<String, dynamic>.from(m)).toList();
    } catch (e) {
      debugPrint('Error fetching earnings: $e');
      return [];
    }
  }

  Future<double> fetchPendingEarnings(String workerId) async {
    try {
      final paidResponse = await supabase
          .from('worker_payments')
          .select('amount')
          .eq('worker_id', workerId);
      final totalPaid = (paidResponse as List)
          .fold(0.0, (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0));

      final earningsResponse = await supabase
          .from('worker_earnings')
          .select('amount')
          .eq('worker_id', workerId);
      final totalEarned = (earningsResponse as List)
          .fold(0.0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0));

      final pending = totalEarned - totalPaid;
      return pending < 0 ? 0 : pending;
    } catch (e) {
      debugPrint('Error calculating pending earnings: $e');
      return 0;
    }
  }

  // ── Work Log & Payment Management (unchanged) ──

  Future<List<WorkLog>> fetchWorkLogs(String workerId) async {
    try {
      final response = await supabase.from('worker_work_log').select().eq('worker_id', workerId).order('work_date', ascending: false);
      return (response as List).map((m) => WorkLog.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Error fetching work logs: $e');
      return [];
    }
  }

  Future<List<WorkerPayment>> fetchPayments(String workerId) async {
    try {
      final response = await supabase.from('worker_payments').select().eq('worker_id', workerId).order('payment_date', ascending: false);
      return (response as List).map((m) => WorkerPayment.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Error fetching payments: $e');
      return [];
    }
  }

  Future<bool> addWorkLog(Map<String, dynamic> logData) async {
    if (!await _ensureOnline()) return false;
    try {
      final id = const Uuid().v4();
      final data = Map<String, dynamic>.from(logData);
      data['id'] = id;

      await supabase.from('worker_work_log').insert(data);
      return true;
    } catch (e) {
      debugPrint('Error adding work log: $e');
      return false;
    }
  }

  Future<bool> addPayment(Map<String, dynamic> paymentData) async {
    if (!await _ensureOnline()) return false;
    try {
      final id = const Uuid().v4();
      final data = Map<String, dynamic>.from(paymentData);
      data['id'] = id;
      await supabase.from('worker_payments').insert(data);
      return true;
    } catch (e) {
      debugPrint('Error adding payment: $e');
      return false;
    }
  }
}
