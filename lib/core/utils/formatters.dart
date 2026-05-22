import 'package:intl/intl.dart';

class Formatters {
  /// Centralized currency formatter that always uses the correct ₹ symbol
  static String currency(num value, {bool decimal = false}) {
    final formatStr = decimal ? '#,##,##0.00' : '#,##,##0';
    final fmt = NumberFormat(formatStr, 'en_IN');
    return '₹${fmt.format(value)}';
  }
}
