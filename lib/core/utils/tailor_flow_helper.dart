import 'package:intl/intl.dart';

class TailorFlowHelper {
  static const String statusPending = 'pending';
  static const String statusStitching = 'stitching';
  static const String statusTrialing = 'trialing';
  static const String statusAlteration = 'alteration';
  static const String statusReady = 'ready';
  static const String statusDelivered = 'delivered';
  static const String statusCancelled = 'cancelled';

  static const List<String> lifecycle = [
    statusPending,
    statusStitching,
    statusTrialing,
    statusAlteration,
    statusReady,
    statusDelivered,
    statusCancelled,
  ];

  static const Set<String> activeStates = {
    statusPending,
    statusStitching,
    statusTrialing,
    statusAlteration,
    statusReady,
  };

  static String normalize(String value) => value.trim().toLowerCase();

  static bool isValidStatus(String value) => lifecycle.contains(normalize(value));

  static const Map<String, int> statusLevels = {
    statusPending: 0,
    statusStitching: 1,
    statusTrialing: 2,
    statusAlteration: 3,
    statusReady: 4,
    statusDelivered: 5,
    statusCancelled: -1,
  };

  static String getAggregatedStatus(List<String> statuses) {
    if (statuses.isEmpty) return statusPending;

    final normalized = statuses.map((s) => normalize(s)).toList();
    if (normalized.length == 1) return normalized.first;

    final active = normalized.where((s) => s != statusCancelled).toList();
    if (active.isEmpty) return statusCancelled;

    if (active.every((s) => s == statusDelivered)) return statusDelivered;

    if (active.every((s) => s == statusReady || s == statusDelivered)) return statusReady;

    active.sort((a, b) => (statusLevels[b] ?? 0).compareTo(statusLevels[a] ?? 0));
    return active.first;
  }

  static String getStatusLabel(String status) {
    final s = normalize(status);
    switch (s) {
      case 'trialing':
        return 'Fitting';
      case 'alteration':
        return 'Alteration';
      case 'stitching':
        return 'Stitching';
      case 'pending':
        return 'Pending';
      case 'ready':
        return 'Ready';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return s.isEmpty ? 'Unknown' : s[0].toUpperCase() + s.substring(1);
    }
  }

  static bool canTransition(String from, String to) {
    final current = normalize(from);
    final next = normalize(to);
    if (!isValidStatus(current)) return false;
    if (!isValidStatus(next)) return false;
    if (current == next) return true;

    const allowed = {
      statusPending: <String>{statusStitching, statusCancelled},
      statusStitching: <String>{statusTrialing, statusCancelled},
      statusTrialing: <String>{statusAlteration, statusReady, statusCancelled},
      statusAlteration: <String>{statusTrialing, statusReady, statusCancelled},
      statusReady: <String>{statusDelivered, statusCancelled},
      statusDelivered: <String>{},
      statusCancelled: <String>{statusPending},
    };

    return allowed[current]?.contains(next) ?? false;
  }

  static String? nextStatus(String current) {
    switch (normalize(current)) {
      case statusPending:
        return statusStitching;
      case statusStitching:
        return statusTrialing;
      case statusTrialing:
        return statusAlteration;
      case statusAlteration:
        return statusReady;
      case statusReady:
        return statusDelivered;
      default:
        return null;
    }
  }

  static String generateOrderToken() {
    // Increased entropy: TB + 6 chars of base36 timestamp + 2 random-ish chars from microseconds
    final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final micro = DateTime.now().microsecondsSinceEpoch % 1000;
    final suffix = (stamp.length > 6 ? stamp.substring(stamp.length - 6) : stamp) + 
                   micro.toRadixString(36).padLeft(2, '0');
    return 'TB${suffix.toUpperCase()}';
  }

  static List<Map<String, dynamic>> appendHistory({
    required List<Map<String, dynamic>> current,
    required String fromStatus,
    required String toStatus,
    String? note,
  }) {
    return [
      ...current,
      {
        'from': normalize(fromStatus),
        'to': normalize(toStatus),
        'at': DateTime.now().toIso8601String(),
        'label': getStatusLabel(toStatus),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    ];
  }

  static String buildWhatsAppConfirmation({
    required String customerName,
    required String orderToken,
    required String status,
    required String deliveryDate,
    required String total,
    required String advance,
  }) {
    return [
      'Hello $customerName,',
      'Your TailorsBook order ($orderToken) is confirmed.',
      'Status: ${status.toUpperCase()}',
      'Delivery: $deliveryDate',
      'Total: ₹$total',
      'Advance: ₹$advance',
      'Thank you.',
    ].join('\n');
  }

  static Map<String, Map<String, double>> diffMeasurementValues(
    Map<String, double> oldValues,
    Map<String, double> newValues,
  ) {
    final keys = {...oldValues.keys, ...newValues.keys};
    final diff = <String, Map<String, double>>{};
    for (final key in keys) {
      diff[key] = {
        'old': oldValues[key] ?? 0.0,
        'new': newValues[key] ?? 0.0,
        'delta': (newValues[key] ?? 0.0) - (oldValues[key] ?? 0.0),
      };
    }
    return diff;
  }

  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy').format(date);
  }
}
