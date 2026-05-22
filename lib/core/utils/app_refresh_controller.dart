import 'package:flutter/foundation.dart';

/// Centralized refresh controller for TailorsBook.
/// Exposes events that screens can listen to for targeted refreshes.
/// Prevents stale UI after data changes without full app reloads.
class AppRefreshController extends ChangeNotifier {
  static final AppRefreshController _instance = AppRefreshController._();
  factory AppRefreshController() => _instance;
  AppRefreshController._();

  int _refreshToken = 0;
  int get refreshToken => _refreshToken;

  /// Bump token to signal all listeners to refresh.
  void notifyAll() {
    _refreshToken++;
    notifyListeners();
  }

  /// Refresh orders-related screens (Orders Tab, Home, Order Detail, etc.)
  void notifyOrders() {
    _refreshToken++;
    notifyListeners();
  }

  /// Refresh worker-related screens (Worker Tab, Worker Detail, Assigned Work).
  void notifyWorkers() {
    _refreshToken++;
    notifyListeners();
  }

  /// Refresh customer-related screens.
  void notifyCustomers() {
    _refreshToken++;
    notifyListeners();
  }

  /// Refresh dashboard/home stats.
  void notifyDashboard() {
    _refreshToken++;
    notifyListeners();
  }

  /// Refresh everything (use sparingly, e.g., after login or major sync).
  void notifyAllData() {
    _refreshToken++;
    notifyListeners();
  }
}
