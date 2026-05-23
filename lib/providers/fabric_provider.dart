import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/fabric_model.dart';
import '../../main.dart';
import '../core/utils/connectivity_helper.dart';

class FabricProvider extends ChangeNotifier {
  SupabaseClient get _supabase => Supabase.instance.client;

  static const String purposeAllocated = 'allocated';
  static const String purposeConsumed = 'consumed';
  static const String purposeRestored = 'restored';

  List<ShopFabricModel> _shopFabrics = [];
  List<CustomerFabricModel> _customerFabrics = [];
  List<OrderItemFabricModel> _orderItemFabrics = [];

  bool _isLoading = false;
  String? _errorMessage;

  final Set<String> _consumedItemIds = {};
  final Set<String> _restoredItemIds = {};

  List<ShopFabricModel> get shopFabrics => _shopFabrics;
  List<CustomerFabricModel> get customerFabrics => _customerFabrics;
  List<OrderItemFabricModel> get orderItemFabrics => _orderItemFabrics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Full reset for logout/user switch — clears all state safely.
  void clearState() {
    _shopFabrics = [];
    _customerFabrics = [];
    _orderItemFabrics = [];
    _isLoading = false;
    _errorMessage = null;
    _consumedItemIds.clear();
    _restoredItemIds.clear();
    notifyListeners();
  }

  Future<bool> _ensureOnline() async {
    final isOnline = await ConnectivityHelper.hasInternet();
    if (!isOnline) {
      showGlobalSnackBar('Internet required. Please connect and try again.', isError: true);
      return false;
    }
    return true;
  }

  Future<void> fetchFabrics() async {
    if (!await _ensureOnline()) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final shopRes = await _supabase.from('fabrics').select().eq('shop_id', userId);
      _shopFabrics = (shopRes as List).map((e) => ShopFabricModel.fromJson(e)).toList();

      final customerRes = await _supabase.from('customer_fabrics').select();
      _customerFabrics = (customerRes as List).map((e) => CustomerFabricModel.fromJson(e)).toList();

      final orderItemRes = await _supabase.from('order_item_fabrics').select();
      _orderItemFabrics = (orderItemRes as List).map((e) => OrderItemFabricModel.fromJson(e)).toList();

      _rebuildInMemoryState();
    } catch (e) {
      debugPrint('FabricProvider Error: $e');
      _errorMessage = 'Failed to load fabrics from server.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _rebuildInMemoryState() {
    _consumedItemIds.clear();
    _restoredItemIds.clear();
    for (final alloc in _orderItemFabrics) {
      if (alloc.purpose == purposeConsumed) _consumedItemIds.add(alloc.orderItemId);
      if (alloc.purpose == purposeRestored) _restoredItemIds.add(alloc.orderItemId);
    }
  }

  Future<bool> addShopFabric(ShopFabricModel fabric) async {
    if (!await _ensureOnline()) return false;
    try {
      final user = _supabase.auth.currentUser;
      final finalFabric = fabric.copyWith(shopId: user?.id);
      final response = await _supabase
          .from('fabrics')
          .insert(finalFabric.toJson())
          .select()
          .single();
      final insertedFabric = ShopFabricModel.fromJson(response);
      _shopFabrics.insert(0, insertedFabric);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding fabric: $e');
      return false;
    }
  }

  Future<bool> updateShopFabric(ShopFabricModel fabric) async {
    if (!await _ensureOnline()) return false;
    _errorMessage = null;
    try {
      final data = fabric.toJson();
      data.remove('id'); // Primary key cannot be part of the update payload
      
      await _supabase.from('fabrics').update(data).eq('id', fabric.id);
      
      final index = _shopFabrics.indexWhere((f) => f.id == fabric.id);
      if (index != -1) {
        _shopFabrics[index] = fabric;
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating fabric: $e');
      _errorMessage = 'Failed to update fabric: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteShopFabric(String id) async {
    if (!await _ensureOnline()) return false;
    try {
      await _supabase.from('fabrics').delete().eq('id', id);
      _shopFabrics.removeWhere((f) => f.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting fabric: $e');
      return false;
    }
  }

  /// Validates that a shop fabric has enough quantity available.
  String? validateFabricQuantity(String shopFabricId, double requiredMeters) {
    if (requiredMeters <= 0) return 'Quantity must be greater than 0';
    final fabric = _shopFabrics.where((f) => f.id == shopFabricId).firstOrNull;
    if (fabric == null) return 'Fabric not found in inventory';
    if (fabric.quantityMeters < requiredMeters) {
      return 'Insufficient stock. Available: ${fabric.quantityMeters}m, Required: ${requiredMeters}m';
    }
    return null;
  }

  /// Gets available quantity for a shop fabric.
  double availableQuantity(String shopFabricId) {
    final fabric = _shopFabrics.where((f) => f.id == shopFabricId).firstOrNull;
    return fabric?.quantityMeters ?? 0.0;
  }

  /// Allocates fabric to an order item (called during order creation).
  Future<bool> allocateFabric({
    required String orderItemId,
    required String fabricSource,
    String? shopFabricId,
    double? metersAllocated,
  }) async {
    if (!await _ensureOnline()) return false;

    if (fabricSource == 'SHOP') {
      if (shopFabricId == null || metersAllocated == null) return false;
      final validationError = validateFabricQuantity(shopFabricId, metersAllocated);
      if (validationError != null) {
        showGlobalSnackBar(validationError, isError: true);
        return false;
      }
    }

    try {
      final id = const Uuid().v4();
      final allocation = {
        'id': id,
        'order_item_id': orderItemId,
        'fabric_source': fabricSource,
        'shop_fabric_id': ?shopFabricId,
        'meters_allocated': metersAllocated ?? 0.0,
        'purpose': purposeAllocated,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('order_item_fabrics').insert(allocation);

      final model = OrderItemFabricModel.fromJson(allocation);
      _orderItemFabrics.add(model);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error allocating fabric: $e');
      showGlobalSnackBar('Failed to allocate fabric.', isError: true);
      return false;
    }
  }

  /// Checks if a fabric allocation exists and can be consumed.
  bool _canConsume(String orderItemId) {
    if (_consumedItemIds.contains(orderItemId)) return false;
    final alloc = _orderItemFabrics.where((a) => a.orderItemId == orderItemId && a.fabricSource == 'SHOP').firstOrNull;
    if (alloc == null) return false;
    return alloc.purpose == purposeAllocated;
  }

  /// Consumes fabric when an item moves to Stitching.
  /// Deducts from shop stock and marks allocation as consumed.
  Future<bool> consumeFabricForStitching(String orderItemId) async {
    if (!await _ensureOnline()) return false;

    if (!_canConsume(orderItemId)) {
      return false;
    }

    final allocs = _orderItemFabrics
        .where((a) => a.orderItemId == orderItemId && a.fabricSource == 'SHOP');
    if (allocs.isEmpty) {
      showGlobalSnackBar('Fabric allocation not found for this item.', isError: true);
      return false;
    }
    final alloc = allocs.first;
    final shopFabricId = alloc.shopFabricId;
    final meters = alloc.metersAllocated;

    if (shopFabricId == null || meters <= 0) return false;

    final fabricIndex = _shopFabrics.indexWhere((f) => f.id == shopFabricId);
    if (fabricIndex == -1) {
      showGlobalSnackBar('Fabric not found in inventory.', isError: true);
      return false;
    }

    final currentQty = _shopFabrics[fabricIndex].quantityMeters;
    if (currentQty < meters) {
      showGlobalSnackBar(
        'Insufficient fabric stock (${currentQty}m available, ${meters}m needed). Restock fabric first.',
        isError: true,
      );
      return false;
    }

    try {
      final newQuantity = currentQty - meters;
      await _supabase.from('fabrics').update({'quantity_meters': newQuantity, 'updated_at': DateTime.now().toIso8601String()}).eq('id', shopFabricId);

      await _supabase.from('order_item_fabrics').update({
        'purpose': purposeConsumed,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('order_item_id', orderItemId).eq('fabric_source', 'SHOP');

      _shopFabrics[fabricIndex] = _shopFabrics[fabricIndex].copyWith(quantityMeters: newQuantity);

      final allocIndex = _orderItemFabrics.indexWhere((a) => a.orderItemId == orderItemId && a.fabricSource == 'SHOP');
      if (allocIndex != -1) {
        _orderItemFabrics[allocIndex] = _orderItemFabrics[allocIndex].copyWith(purpose: purposeConsumed);
      }

      _consumedItemIds.add(orderItemId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error consuming fabric: $e');
      showGlobalSnackBar('Failed to consume fabric from stock.', isError: true);
      return false;
    }
  }

  /// Restores fabric when an item is cancelled (undoes consumption).
  Future<bool> restoreFabricForItem(String orderItemId) async {
    if (!await _ensureOnline()) return false;

    final alloc = _orderItemFabrics.where((a) => a.orderItemId == orderItemId && a.fabricSource == 'SHOP').firstOrNull;
    if (alloc == null) return false;

    if (alloc.purpose != purposeConsumed) {
      return false;
    }

    final shopFabricId = alloc.shopFabricId;
    final meters = alloc.metersAllocated;

    if (shopFabricId == null || meters <= 0) return false;

    final fabricIndex = _shopFabrics.indexWhere((f) => f.id == shopFabricId);
    if (fabricIndex == -1) {
      showGlobalSnackBar('Original fabric no longer in inventory. Restoration logged.', isError: true);
      return false;
    }

    try {
      final currentQty = _shopFabrics[fabricIndex].quantityMeters;
      final newQuantity = currentQty + meters;

      await _supabase.from('fabrics').update({'quantity_meters': newQuantity, 'updated_at': DateTime.now().toIso8601String()}).eq('id', shopFabricId);

      await _supabase.from('order_item_fabrics').update({
        'purpose': purposeRestored,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('order_item_id', orderItemId).eq('fabric_source', 'SHOP');

      _shopFabrics[fabricIndex] = _shopFabrics[fabricIndex].copyWith(quantityMeters: newQuantity);

      final allocIndex = _orderItemFabrics.indexWhere((a) => a.orderItemId == orderItemId && a.fabricSource == 'SHOP');
      if (allocIndex != -1) {
        _orderItemFabrics[allocIndex] = _orderItemFabrics[allocIndex].copyWith(purpose: purposeRestored);
      }

      _consumedItemIds.remove(orderItemId);
      _restoredItemIds.add(orderItemId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error restoring fabric: $e');
      showGlobalSnackBar('Failed to restore fabric to inventory.', isError: true);
      return false;
    }
  }

  /// Re-allocates fabric when a cancelled item is restored to pending.
  Future<bool> reallocateFabricForRestoredItem(String orderItemId) async {
    if (!await _ensureOnline()) return false;

    final allocIndex = _orderItemFabrics.indexWhere((a) => a.orderItemId == orderItemId && a.fabricSource == 'SHOP');
    if (allocIndex == -1) return false;

    if (_orderItemFabrics[allocIndex].purpose != purposeRestored) return false;

    try {
      await _supabase.from('order_item_fabrics').update({
        'purpose': purposeAllocated,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('order_item_id', orderItemId).eq('fabric_source', 'SHOP');

      _orderItemFabrics[allocIndex] = _orderItemFabrics[allocIndex].copyWith(purpose: purposeAllocated);
      _restoredItemIds.remove(orderItemId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error re-allocating fabric: $e');
      return false;
    }
  }

  /// Gets fabric allocations for items from local cache.
  List<OrderItemFabricModel> getAllocationsForItems(List<String> orderItemIds) {
    return _orderItemFabrics.where((a) => orderItemIds.contains(a.orderItemId)).toList();
  }

  /// Gets fabric allocation info for a specific order item.
  OrderItemFabricModel? getAllocationForItem(String orderItemId) {
    return _orderItemFabrics.where((a) => a.orderItemId == orderItemId).firstOrNull;
  }

  /// Gets display-friendly fabric info for an order item.
  Map<String, dynamic>? getFabricDisplayInfo(String orderItemId) {
    final alloc = getAllocationForItem(orderItemId);
    if (alloc == null) return null;

    String sourceLabel = alloc.fabricSource == 'SHOP' ? 'Shop Stock' : 'Customer Provided';
    String statusLabel;
    switch (alloc.purpose) {
      case purposeConsumed:
        statusLabel = 'Consumed';
        break;
      case purposeRestored:
        statusLabel = 'Restored';
        break;
      default:
        statusLabel = 'Allocated';
    }

    String? fabricName;
    double? availableStock;
    if (alloc.shopFabricId != null) {
      final fabric = _shopFabrics.where((f) => f.id == alloc.shopFabricId).firstOrNull;
      fabricName = fabric?.name;
      availableStock = fabric?.quantityMeters;
    }

    return {
      'source': sourceLabel,
      'source_raw': alloc.fabricSource,
      'fabric_name': fabricName,
      'meters': alloc.metersAllocated,
      'status': statusLabel,
      'purpose': alloc.purpose,
      'available_stock': availableStock,
    };
  }

  /// Checks if fabric for an item has been consumed from inventory.
  bool isFabricConsumed(String orderItemId) => _consumedItemIds.contains(orderItemId);

  String? checkFabricGuardrails(String orderItemId, bool fabricReceivedGlobal) {
    if (!fabricReceivedGlobal) {
      return 'Fabric has not been marked as received for this order.';
    }
    return null;
  }
}
