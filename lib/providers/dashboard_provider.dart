import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessMetrics {
  final double monthlyRevenue;
  final double pendingBalanceSum;
  final int totalOrders;
  final int activeOrders;
  final int completedOrders;
  final int cancelledOrders;
  final int activeCustomers;
  final int repeatCustomers;
  final Map<String, int> topGarmentTypes;
  final Map<String, int> workerProductivity;
  final int alterationFrequency;
  final Map<String, double> fabricUsage;
  final double lastMonthRevenue;
  final double revenueGrowthPercent;

  BusinessMetrics({
    this.monthlyRevenue = 0,
    this.pendingBalanceSum = 0,
    this.totalOrders = 0,
    this.activeOrders = 0,
    this.completedOrders = 0,
    this.cancelledOrders = 0,
    this.activeCustomers = 0,
    this.repeatCustomers = 0,
    this.topGarmentTypes = const {},
    this.workerProductivity = const {},
    this.alterationFrequency = 0,
    this.fabricUsage = const {},
    this.lastMonthRevenue = 0,
    this.revenueGrowthPercent = 0,
  });
}

class DashboardProvider extends ChangeNotifier {
  SupabaseClient get _supabase => Supabase.instance.client;
  BusinessMetrics _metrics = BusinessMetrics();
  bool _isLoading = false;
  String? _error;

  BusinessMetrics get metrics => _metrics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Full reset for logout/user switch — clears all state safely.
  void clearState() {
    _metrics = BusinessMetrics();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> fetchMetrics({int monthsBack = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

      // Step 1: Parallel independent queries
      final results = await Future.wait([
        _supabase
            .from('orders')
            .select('id, status, total_price, advance_paid, customer_id, created_at')
            .eq('user_id', userId)
            .filter('deleted_at', 'is', 'null'),
        _supabase
            .from('customers')
            .select('id')
            .eq('tailor_id', userId)
            .filter('deleted_at', 'is', 'null'),
        _supabase
            .from('workers')
            .select('id, name')
            .eq('tailor_id', userId)
            .filter('deleted_at', 'is', 'null'),
      ]);

      final ordersResp = results[0];
      final customersResp = results[1];
      final workersResp = results[2];

      final orders = (ordersResp as List).cast<Map<String, dynamic>>();
      final totalCustomers = (customersResp as List).length;
      final workers = (workersResp as List).cast<Map<String, dynamic>>();

      // Helper: parse created_at to local time
      DateTime? parseLocal(String? raw) {
        final dt = DateTime.tryParse(raw ?? '');
        return dt?.toLocal();
      }

      // Single pass: categorize and compute all metrics
      final ordersNonCancelled = <Map<String, dynamic>>[];
      int totalOrders = 0, activeOrders = 0, completedOrders = 0, cancelledOrders = 0;
      double monthlyRevenue = 0, lastMonthRevenue = 0, pendingBalanceSum = 0;
      final customerOrderCounts = <String, int>{};
      // Precompute assigned_worker_id → order count
      final workerOrderBuckets = <String, int>{};
      for (final w in workers) {
        workerOrderBuckets[w['id']?.toString() ?? ''] = 0;
      }

      for (final o in orders) {
        totalOrders++;
        final created = parseLocal(o['created_at']?.toString());
        final status = (o['status'] as String?)?.toLowerCase() ?? '';
        final totalPrice = (o['total_price'] as num?)?.toDouble() ?? 0;
        final isCancelled = status == 'cancelled';
        final isDelivered = status == 'delivered';

        // Month categorization & revenue
        if (created != null) {
          if (!created.isBefore(monthStart) && !created.isAfter(monthEnd)) {
            if (!isCancelled) monthlyRevenue += totalPrice;
          }
          if (!created.isBefore(lastMonthStart) && !created.isAfter(lastMonthEnd)) {
            if (!isCancelled) lastMonthRevenue += totalPrice;
          }
        }

        // Status counts
        if (isCancelled) {
          cancelledOrders++;
        } else if (isDelivered) {
          completedOrders++;
        } else {
          activeOrders++;
        }

        // Non-cancelled orders for due calculations
        if (!isCancelled) {
          ordersNonCancelled.add(o);
          final paid = (o['advance_paid'] as num?)?.toDouble() ?? 0;
          pendingBalanceSum += totalPrice - paid;
        }

        // Customer order count
        final cid = o['customer_id']?.toString();
        if (cid != null) {
          customerOrderCounts[cid] = (customerOrderCounts[cid] ?? 0) + 1;
        }

        // Worker bucket count (only for tracked workers)
        final wid = o['assigned_worker_id']?.toString();
        if (wid != null && workerOrderBuckets.containsKey(wid)) {
          workerOrderBuckets[wid] = workerOrderBuckets[wid]! + 1;
        }
      }

      final repeatCustomers = customerOrderCounts.values.where((c) => c > 1).length;

      // Revenue growth
      final revenueGrowthPercent = lastMonthRevenue > 0
          ? ((monthlyRevenue - lastMonthRevenue) / lastMonthRevenue) * 100
          : 0.0;

      // Worker productivity (build from precomputed buckets)
      final workerNameById = <String, String>{};
      for (final w in workers) {
        final wid = w['id']?.toString() ?? '';
        final name = w['name']?.toString() ?? 'Unknown';
        workerNameById[wid] = name;
      }
      final workerProductivityRaw = <String, int>{};
      for (final entry in workerOrderBuckets.entries) {
        final name = workerNameById[entry.key] ?? entry.key;
        if (name.isNotEmpty) {
          workerProductivityRaw[name] = entry.value;
        }
      }
      final sortedWorkers = workerProductivityRaw.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final workerProductivity = Map.fromEntries(sortedWorkers.take(10));

      // Step 2: order_items (depends on orders)
      final garmentCounts = <String, int>{};
      int alterationFrequency = 0;
      final fabricUsage = <String, double>{};
      var topGarmentTypes = <String, int>{};
      
      final orderIds = orders.map((o) => o['id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
      if (orderIds.isNotEmpty) {
        final itemsResp = await _supabase
            .from('order_items')
            .select('id, product_name, status')
            .inFilter('order_id', orderIds);

        final items = (itemsResp as List).cast<Map<String, dynamic>>();
        for (final item in items) {
          final name = item['product_name']?.toString() ?? 'Unknown';
          garmentCounts[name] = (garmentCounts[name] ?? 0) + 1;
          if ((item['status'] as String?)?.toLowerCase() == 'alteration') {
            alterationFrequency++;
          }
        }
        final sortedGarments = garmentCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        topGarmentTypes = Map.fromEntries(sortedGarments.take(5));

        // Step 3: fabric (depends on items)
        final itemIds = items.map((i) => i['id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
        if (itemIds.isNotEmpty) {
          final fabricsResp = await _supabase
              .from('order_item_fabrics')
              .select('fabric_source, meters_allocated, shop_fabric_id')
              .inFilter('order_item_id', itemIds);
          final fabrics = (fabricsResp as List).cast<Map<String, dynamic>>();

          // Collect shop fabric IDs to resolve names
          final shopFabricIds = fabrics
              .where((f) => f['fabric_source'] == 'SHOP' && f['shop_fabric_id'] != null)
              .map((f) => f['shop_fabric_id'] as String)
              .toSet()
              .toList();

          Map<String, String> fabricNameMap = {};
          if (shopFabricIds.isNotEmpty) {
            final namesResp = await _supabase
                .from('fabrics')
                .select('id, name')
                .inFilter('id', shopFabricIds);
            for (final fn in (namesResp as List).cast<Map<String, dynamic>>()) {
              fabricNameMap[fn['id']?.toString() ?? ''] = fn['name']?.toString() ?? 'Unknown';
            }
          }

          for (final f in fabrics) {
            final source = f['fabric_source']?.toString() ?? 'Unknown';
            final name = (source == 'SHOP' && f['shop_fabric_id'] != null)
                ? (fabricNameMap[f['shop_fabric_id']] ?? 'Shop Fabric')
                : source;
            final meters = (f['meters_allocated'] as num?)?.toDouble() ?? 0;
            fabricUsage[name] = (fabricUsage[name] ?? 0) + meters;
          }
        }
      }

      _metrics = BusinessMetrics(
        monthlyRevenue: monthlyRevenue,
        lastMonthRevenue: lastMonthRevenue,
        revenueGrowthPercent: revenueGrowthPercent,
        pendingBalanceSum: pendingBalanceSum,
        totalOrders: totalOrders,
        activeOrders: activeOrders,
        completedOrders: completedOrders,
        cancelledOrders: cancelledOrders,
        activeCustomers: totalCustomers,
        repeatCustomers: repeatCustomers,
        topGarmentTypes: topGarmentTypes,
        workerProductivity: workerProductivity,
        alterationFrequency: alterationFrequency,
        fabricUsage: fabricUsage,
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('[DashboardProvider] Error fetching metrics: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
