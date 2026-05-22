import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/customer_model.dart';
import '../../main.dart';
import '../core/utils/connectivity_helper.dart';

class CustomerProvider extends ChangeNotifier {
  List<Customer> _customers = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 20;

  List<Customer> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';

  List<Customer> get customers => _customers;
  List<Customer> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  String normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  Customer? findByNormalizedPhone(String phone) {
    final normalized = normalizePhone(phone);
    if (normalized.isEmpty) return null;
    for (final customer in _customers) {
      if (normalizePhone(customer.phone) == normalized) {
        return customer;
      }
    }
    return null;
  }

  Future<void> searchCustomers(String query) async {
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }

    if (!await _ensureOnline()) return;

    _isSearching = true;
    _searchQuery = query;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('customers')
          .select()
          .eq('tailor_id', user.id)
          .filter('deleted_at', 'is', null)
          .or('name.ilike.%$query%,phone.ilike.%$query%')
          .order('name');

      _searchResults = (response as List).map((c) => Customer.fromMap(c)).toList();
      _hasError = false;
    } catch (e) {
      debugPrint('Error searching customers: $e');
      _hasError = true;
      _errorMessage = 'Search failed. Please try again.';
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    if (_searchResults.isNotEmpty || _isSearching) {
      _searchResults = [];
      _isSearching = false;
      _searchQuery = '';
      _hasError = false;
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Full reset for logout/user switch — clears all state safely.
  void clearState() {
    _customers = [];
    _isLoading = false;
    _hasError = false;
    _errorMessage = null;
    _hasMore = true;
    _currentPage = 0;
    _searchResults = [];
    _isSearching = false;
    _searchQuery = '';
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

  Future<void> fetchCustomers({bool refresh = false}) async {
    if (_isLoading) return;
    if (!refresh && !_hasMore) return;

    if (!await _ensureOnline()) {
      _hasError = true;
      _errorMessage = 'Internet required to load customers.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    if (refresh) {
      _currentPage = 0;
      _hasMore = true;
    }
    notifyListeners();

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('customers')
          .select()
          .eq('tailor_id', user.id)
          .filter('deleted_at', 'is', null)
          .order('name')
          .range(_currentPage * _pageSize, (_currentPage + 1) * _pageSize - 1);

      final List<Customer> fetched = (response as List).map((c) => Customer.fromMap(c)).toList();
      
      if (refresh) {
        _customers = fetched;
      } else {
        _customers.addAll(fetched);
      }
      
      _hasMore = fetched.length == _pageSize;
      _currentPage++;
      _hasError = false;
    } catch (e) {
      debugPrint('Error fetching customers: $e');
      _hasError = true;
      _errorMessage = 'Failed to load customers from server.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _isPhoneDuplicate(String phone, {String? excludeId}) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      final normalized = normalizePhone(phone);
      if (normalized.isEmpty) return false;

      final response = await supabase
          .from('customers')
          .select('id, phone')
          .eq('tailor_id', user.id)
          .filter('deleted_at', 'is', null);

      for (final row in response as List) {
        final dbPhone = normalizePhone(row['phone']?.toString() ?? '');
        if (dbPhone == normalized) {
          final dbId = row['id']?.toString() ?? '';
          if (excludeId == null || dbId != excludeId) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error checking duplicate phone: $e');
      return false;
    }
  }

  Future<Customer?> createCustomer(Customer customer) async {
    if (!await _ensureOnline()) return null;

    final isDuplicate = await _isPhoneDuplicate(customer.phone);
    if (isDuplicate) {
      showGlobalSnackBar('A customer with this phone number already exists.', isError: true);
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final user = supabase.auth.currentUser;
      final finalCustomer = customer.copyWith(
        id: (customer.id.isEmpty || customer.id.startsWith('temp_'))
            ? const Uuid().v4()
            : customer.id,
        tailorId: user?.id,
        syncStatus: 'synced',
      );

      await supabase.from('customers').insert(finalCustomer.toMap());
      _customers.insert(0, finalCustomer);
      _customers.sort((a, b) => a.name.compareTo(b.name));
      
      showGlobalSnackBar('Customer added: ${finalCustomer.name}');
      return finalCustomer;
    } catch (e) {
      debugPrint('Error creating customer: $e');
      showGlobalSnackBar('Failed to save customer.', isError: true);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCustomer(Customer customer) async {
    if (!await _ensureOnline()) return false;

    final isDuplicate = await _isPhoneDuplicate(customer.phone, excludeId: customer.id);
    if (isDuplicate) {
      showGlobalSnackBar('Another customer already uses this phone number.', isError: true);
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await supabase.from('customers').update(customer.toMap()).eq('id', customer.id);
      
      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = customer;
        _customers.sort((a, b) => a.name.compareTo(b.name));
      }
      
      showGlobalSnackBar('Customer profile updated.');
      return true;
    } catch (e) {
      debugPrint('Error updating customer: $e');
      showGlobalSnackBar('Update failed.', isError: true);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCustomer(String customerId) async {
    if (!await _ensureOnline()) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now().toIso8601String();
      await supabase.from('customers').update({'deleted_at': now}).eq('id', customerId);
      _customers.removeWhere((c) => c.id == customerId);
      showGlobalSnackBar('Customer removed. Historical data preserved.');
      return true;
    } catch (e) {
      debugPrint('Error soft-deleting customer: $e');
      showGlobalSnackBar('Delete failed. Please try again.', isError: true);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
