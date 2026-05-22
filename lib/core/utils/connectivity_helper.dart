import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityHelper {
  static DateTime _lastCheckTime = DateTime(0);
  static bool _cachedResult = true;
  static const Duration _cacheDuration = Duration(seconds: 5);

  /// Verifies if the device has actual internet access with short-term caching.
  static Future<bool> hasInternet() async {
    final now = DateTime.now();

    // Return cached result if still valid (reduces false negatives from rapid checks)
    if (now.difference(_lastCheckTime) < _cacheDuration) {
      return _cachedResult;
    }

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        _cacheResult(false);
        return false;
      }

      _cacheResult(true);
      return true;
    } catch (e) {
      // On error, assume online and let Supabase calls handle actual failures
      _cacheResult(true);
      return true;
    }
  }

  static void _cacheResult(bool result) {
    _lastCheckTime = DateTime.now();
    _cachedResult = result;
  }

  /// Forces a fresh connectivity check (bypasses cache).
  static Future<bool> forceCheck() async {
    _lastCheckTime = DateTime(0);
    return hasInternet();
  }

  static Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      Connectivity().onConnectivityChanged;
}
