import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/shop_expense.dart';
import '../../main.dart';
import '../core/utils/connectivity_helper.dart';
import '../core/utils/local_database.dart';

class ExpenseProvider extends ChangeNotifier {
  SupabaseClient get _supabase => Supabase.instance.client;
  List<ShopExpense> _expenses = [];
  bool _isLoading = false;
  bool _isSyncing = false;

  List<ShopExpense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;

  ExpenseProvider() {
    _loadLocalExpenses();
  }

  void _loadLocalExpenses() {
    try {
      final localExpenses = LocalDatabase.getAll<ShopExpense>(LocalDatabase.expenseBoxName);
      _expenses = localExpenses
          .where((e) => e.deletedAt == null)
          .toList();
      
      _expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading local expenses: $e');
    }
  }

  Future<void> fetchExpenses() async {
    _loadLocalExpenses();

    final isOnline = await ConnectivityHelper.hasInternet();
    if (!isOnline) return;

    _isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('shop_expenses')
          .select()
          .eq('tailor_id', user.id);

      final serverExpenses = (response as List)
          .map((e) => ShopExpense.fromJson(e))
          .toList();

      final box = LocalDatabase.getBox<ShopExpense>(LocalDatabase.expenseBoxName);
      
      // Update local storage with server data
      for (var serverExp in serverExpenses) {
        final localExp = box.get(serverExp.id);
        if (localExp == null || serverExp.updatedAt.isAfter(localExp.updatedAt)) {
          await box.put(serverExp.id, serverExp);
        }
      }

      // Upload pending local changes
      await _syncPendingExpenses();

      _loadLocalExpenses();
    } catch (e) {
      debugPrint('ExpenseProvider fetch Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addExpense({
    required String title,
    required double amount,
    required DateTime expenseDate,
    String? category,
    String? notes,
    String? receiptUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final newExpense = ShopExpense(
      id: const Uuid().v4(),
      tailorId: user.id,
      title: title,
      amount: amount,
      expenseDate: expenseDate,
      category: category,
      notes: notes,
      receiptUrl: receiptUrl,
      syncStatus: 'pending',
    );

    try {
      final box = LocalDatabase.getBox<ShopExpense>(LocalDatabase.expenseBoxName);
      await box.put(newExpense.id, newExpense);
      
      _loadLocalExpenses();
      _syncPendingExpenses(); // Attempt background sync
      return true;
    } catch (e) {
      debugPrint('Error adding expense locally: $e');
      return false;
    }
  }

  Future<bool> deleteExpense(String id) async {
    try {
      final box = LocalDatabase.getBox<ShopExpense>(LocalDatabase.expenseBoxName);
      final expense = box.get(id);
      if (expense != null) {
        final deletedExpense = ShopExpense(
          id: expense.id,
          tailorId: expense.tailorId,
          title: expense.title,
          amount: expense.amount,
          expenseDate: expense.expenseDate,
          category: expense.category,
          notes: expense.notes,
          receiptUrl: expense.receiptUrl,
          createdAt: expense.createdAt,
          updatedAt: DateTime.now(),
          syncStatus: 'pending_delete',
          deletedAt: DateTime.now(),
        );
        await box.put(id, deletedExpense);
        
        _loadLocalExpenses();
        _syncPendingExpenses(); // Attempt background sync
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting expense locally: $e');
      return false;
    }
  }

  Future<void> _syncPendingExpenses() async {
    if (_isSyncing) return;
    final isOnline = await ConnectivityHelper.hasInternet();
    if (!isOnline) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final box = LocalDatabase.getBox<ShopExpense>(LocalDatabase.expenseBoxName);
      final pendingExpenses = box.values.where((e) => e.syncStatus != 'synced').toList();

      for (var expense in pendingExpenses) {
        if (expense.syncStatus == 'pending') {
          await _supabase.from('shop_expenses').upsert(expense.toJson());
          
          final syncedExpense = ShopExpense(
            id: expense.id,
            tailorId: expense.tailorId,
            title: expense.title,
            amount: expense.amount,
            expenseDate: expense.expenseDate,
            category: expense.category,
            notes: expense.notes,
            receiptUrl: expense.receiptUrl,
            createdAt: expense.createdAt,
            updatedAt: expense.updatedAt,
            syncStatus: 'synced',
          );
          await box.put(expense.id, syncedExpense);
        } else if (expense.syncStatus == 'pending_delete') {
          await _supabase.from('shop_expenses').delete().eq('id', expense.id);
          await box.delete(expense.id);
        }
      }
    } catch (e) {
      debugPrint('Error syncing expenses: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void clearState() {
    _expenses = [];
    _isLoading = false;
    _isSyncing = false;
    notifyListeners();
  }
}
