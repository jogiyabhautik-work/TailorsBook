import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shop_expense.dart';
import '../../main.dart';
import '../core/utils/connectivity_helper.dart';

class ExpenseProvider extends ChangeNotifier {
  SupabaseClient get _supabase => Supabase.instance.client;
  List<ShopExpense> _expenses = [];
  bool _isLoading = false;

  List<ShopExpense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  Future<bool> _ensureOnline() async {
    final isOnline = await ConnectivityHelper.hasInternet();
    if (!isOnline) {
      showGlobalSnackBar('Internet required. Please connect and try again.', isError: true);
      return false;
    }
    return true;
  }

  Future<void> fetchExpenses() async {
    if (!await _ensureOnline()) return;

    _isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('shop_expenses')
          .select()
          .eq('tailor_id', user.id)
          .order('date', ascending: false);

      _expenses = (response as List).map((e) => ShopExpense.fromJson(e)).toList();
    } catch (e) {
      debugPrint('ExpenseProvider Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addExpense(ShopExpense expense) async {
    if (!await _ensureOnline()) return false;
    try {
      await _supabase.from('shop_expenses').insert(expense.toJson());
      _expenses.insert(0, expense);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding expense: $e');
      return false;
    }
  }

  Future<bool> deleteExpense(String id) async {
    if (!await _ensureOnline()) return false;
    try {
      await _supabase.from('shop_expenses').delete().eq('id', id);
      _expenses.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting expense: $e');
      return false;
    }
  }

  void clearState() {
    _expenses = [];
    _isLoading = false;
    notifyListeners();
  }
}
