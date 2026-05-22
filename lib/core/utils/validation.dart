class Validation {
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid number';
    }
    if (amount < 0) {
      return 'Amount cannot be negative';
    }
    return null;
  }

  static String? validateMeasurement(String? value) {
    if (value == null || value.isEmpty) return null;
    final measurement = double.tryParse(value);
    if (measurement != null && measurement < 0) {
      return 'Measurement cannot be negative';
    }
    return null;
  }

  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateOrderPrice(double totalPrice, double advancePaid) {
    if (totalPrice <= 0) return 'Total price must be greater than zero';
    if (advancePaid < 0) return 'Advance paid cannot be negative';
    if (advancePaid > totalPrice) return 'Advance cannot be more than total price';
    return null;
  }

  static bool canDeliver(double totalPrice, double advancePaid) {
    return (totalPrice - advancePaid) <= 0;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    if (RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Phone number cannot contain letters';
    }
    if (cleanPhone.length < 10 || cleanPhone.length > 13) {
      return 'Enter a valid phone number (10-13 digits)';
    }
    return null;
  }

  static String? validatePincode(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final cleanPincode = value.trim();
    final pincodeRegex = RegExp(r'^[1-9][0-9]{5}$');
    if (!pincodeRegex.hasMatch(cleanPincode)) {
      return 'Enter a valid 6-digit Indian pincode';
    }
    return null;
  }

  static String? validateCustomerName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Customer name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Name is too long (max 50 characters)';
    }
    return null;
  }

  static String? validateGST(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final gstRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
    if (!gstRegex.hasMatch(value.trim().toUpperCase())) {
      return 'Enter a valid 15-character Indian GSTIN';
    }
    return null;
  }

  static String? validateSyncPayload({
    required String? userId,
    required String? customerId,
    required double totalPrice,
    required List items,
  }) {
    if (userId == null || userId.isEmpty) return 'Missing User Identity';
    if (customerId == null || customerId.isEmpty) return 'Missing Customer Reference';
    if (totalPrice < 0) return 'Total price cannot be negative';
    if (items.isEmpty) return 'Order must contain at least one item';
    return null;
  }

  // ── Order Item Validation ──

  static String? validateOrderItem({
    required String productName,
    required int quantity,
    required double unitPrice,
  }) {
    if (productName.trim().isEmpty) {
      return 'Product name is required';
    }
    if (quantity <= 0) {
      return 'Quantity must be greater than 0';
    }
    if (unitPrice < 0) {
      return 'Price cannot be negative';
    }
    return null;
  }

  static String? validateAdvanceAmount(double advance, double totalPrice) {
    if (advance < 0) {
      return 'Advance amount cannot be negative';
    }
    if (advance > totalPrice) {
      return 'Advance amount cannot exceed total order amount';
    }
    return null;
  }

  // ── Date Validation ──

  static String? validateDeliveryDate(DateTime? deliveryDate) {
    if (deliveryDate == null) {
      return 'Delivery date is required';
    }
    final today = DateTime.now();
    final deliveryDay = DateTime(deliveryDate.year, deliveryDate.month, deliveryDate.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    if (deliveryDay.isBefore(todayDay)) {
      return 'Delivery date cannot be in the past';
    }
    return null;
  }

  static String? validateTrialDate(DateTime? trialDate, DateTime? deliveryDate) {
    if (trialDate == null) return null;
    if (deliveryDate == null) {
      return 'Delivery date must be set before trial date';
    }
    final deliveryDay = DateTime(deliveryDate.year, deliveryDate.month, deliveryDate.day);
    final trialDay = DateTime(trialDate.year, trialDate.month, trialDate.day);
    if (trialDay.isAtSameMomentAs(deliveryDay) || trialDay.isAfter(deliveryDay)) {
      return 'Trial date must be before delivery date';
    }
    final diff = deliveryDay.difference(trialDay).inDays;
    if (diff < 1) {
      return 'Trial date must be at least 1 day before delivery date';
    }
    return null;
  }

  // ── Work Mode Validation ──

  static String? validateWorkMode(String? workMode) {
    if (workMode == null || workMode.isEmpty) {
      return 'Please select how this order will be handled';
    }
    if (!['self_stitch', 'worker_assigned'].contains(workMode)) {
      return 'Invalid work mode selected';
    }
    return null;
  }

  // ── Worker Assignment Validation ──

  static String? validateWorkerAssignment({
    required String? workerId,
    required bool workerIsActive,
    required List<Map<String, dynamic>> pricingData,
    required double totalOrderAmount,
  }) {
    if (workerId == null || workerId.isEmpty) {
      return 'Worker is required';
    }
    if (!workerIsActive) {
      return 'Cannot assign to an inactive worker';
    }
    if (pricingData.isEmpty) {
      return 'Please enter worker rate for at least one product';
    }
    for (final p in pricingData) {
      final rate = (p['workerRate'] as num?)?.toDouble() ?? 0.0;
      final productName = p['productName'] as String? ?? 'Product';
      if (rate < 0) {
        return 'Worker rate for $productName cannot be negative';
      }
      final quantity = (p['quantity'] as num?)?.toInt() ?? 0;
      if (quantity <= 0) {
        return 'Quantity for $productName must be greater than 0';
      }
    }
    final totalWorkerAmount = pricingData.fold(0.0, (sum, p) {
      final rate = (p['workerRate'] as num?)?.toDouble() ?? 0.0;
      final qty = (p['quantity'] as num?)?.toInt() ?? 0;
      return sum + (rate * qty);
    });
    if (totalWorkerAmount > totalOrderAmount) {
      return 'Total worker amount (₹${totalWorkerAmount.toStringAsFixed(0)}) exceeds order total (₹${totalOrderAmount.toStringAsFixed(0)})';
    }
    return null;
  }

  // ── Payment Validation ──

  static String? validatePayment({
    required double paymentAmount,
    required double pendingBalance,
  }) {
    if (paymentAmount <= 0) {
      return 'Payment amount must be greater than 0';
    }
    if (paymentAmount > pendingBalance + 0.01) {
      return 'Paid amount cannot exceed pending balance of ₹${pendingBalance.toStringAsFixed(0)}';
    }
    return null;
  }

  // ── Status Transition Validation ──

  static String? validateStatusTransition(String fromStatus, String toStatus) {
    final from = fromStatus.toLowerCase().trim();
    final to = toStatus.toLowerCase().trim();
    if (from == to) return null;
    const allowed = {
      'pending': {'stitching', 'cancelled'},
      'stitching': {'trialing', 'cancelled'},
      'trialing': {'alteration', 'ready', 'cancelled'},
      'alteration': {'trialing', 'ready', 'cancelled'},
      'ready': {'delivered', 'cancelled'},
      'delivered': <String>{},
      'cancelled': {'pending'},
    };
    if (!allowed.containsKey(from)) {
      return 'Invalid current status: $from';
    }
    if (!allowed[from]!.contains(to)) {
      return 'Cannot move from ${_statusLabel(from)} to ${_statusLabel(to)}';
    }
    return null;
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'pending': return 'Pending';
      case 'stitching': return 'Stitching';
      case 'trialing': return 'Fitting';
      case 'alteration': return 'Alteration';
      case 'ready': return 'Ready';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }
}
