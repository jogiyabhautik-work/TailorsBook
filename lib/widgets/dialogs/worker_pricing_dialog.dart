import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/order_model.dart';
import '../../core/utils/design_system.dart';
import '../common/responsive_widgets.dart';

class ProductPricingEntry {
  final String orderItemId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final TextEditingController rateController;
  double subtotal;

  ProductPricingEntry({
    required this.orderItemId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    TextEditingController? rateController,
    this.subtotal = 0.0,
  }) : rateController = rateController ?? TextEditingController();
}

class WorkerPricingDialogResult {
  final List<Map<String, dynamic>> pricingData;
  final double totalWorkerEarnings;

  WorkerPricingDialogResult({
    required this.pricingData,
    required this.totalWorkerEarnings,
  });
}

class WorkerPricingDialog extends StatefulWidget {
  final List<OrderItem> items;
  final double totalOrderAmount;

  const WorkerPricingDialog({
    super.key,
    required this.items,
    this.totalOrderAmount = 0.0,
  });

  @override
  State<WorkerPricingDialog> createState() => _WorkerPricingDialogState();
}

class _WorkerPricingDialogState extends State<WorkerPricingDialog> {
  late List<ProductPricingEntry> _entries;
  final _formKey = GlobalKey<FormState>();
  bool _hasErrors = false;

  @override
  void initState() {
    super.initState();
    _entries = widget.items
        .where((item) => item.status.toLowerCase() != 'cancelled')
        .map((item) => ProductPricingEntry(
              orderItemId: item.id,
              productName: item.productName,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
            ))
        .toList();
    for (final e in _entries) {
      e.rateController.addListener(_updateSubtotals);
    }
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.rateController.removeListener(_updateSubtotals);
      e.rateController.dispose();
    }
    super.dispose();
  }

  void _updateSubtotals() {
    setState(() {
      for (final e in _entries) {
        final rate = double.tryParse(e.rateController.text) ?? 0.0;
        e.subtotal = rate * e.quantity;
      }
      _hasErrors = false;
    });
  }

  double get _totalEarnings =>
      _entries.fold(0.0, (sum, e) => sum + e.subtotal);

  bool _validateAll() {
    bool valid = true;
    for (final e in _entries) {
      final rate = double.tryParse(e.rateController.text);
      if (rate == null || rate < 0) {
        valid = false;
        break;
      }
    }
    setState(() => _hasErrors = !valid);
    return valid;
  }

  void _submit() {
    if (!_validateAll()) return;

    final pricingData = _entries
        .where((e) => (double.tryParse(e.rateController.text) ?? 0) > 0)
        .map((e) => {
              'orderItemId': e.orderItemId,
              'productName': e.productName,
              'quantity': e.quantity,
              'workerRate': double.tryParse(e.rateController.text) ?? 0.0,
              'subtotal': e.subtotal,
            })
        .toList();

    if (pricingData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter worker rate for at least one product.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate: total worker amount vs order total
    if (widget.totalOrderAmount > 0 && _totalEarnings > widget.totalOrderAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Total worker amount (₹${_totalEarnings.toStringAsFixed(0)}) exceeds order total (₹${widget.totalOrderAmount.toStringAsFixed(0)}). Please adjust rates.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    Navigator.of(context).pop(WorkerPricingDialogResult(
      pricingData: pricingData,
      totalWorkerEarnings: _totalEarnings,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final brandOrange = Theme.of(context).colorScheme.primary;

    return KeyboardSafeDialog(
      maxWidth: 560,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                decoration: BoxDecoration(
                  color: brandOrange.withValues(alpha: 0.05),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: brandOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.payments_rounded,
                              color: brandOrange, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Worker Pricing',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Set worker payment rate for each product',
                      style: TextStyle(
                        color: DesignSystem.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    shrinkWrap: true,
                    children: [
                      if (_entries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'No active items to assign',
                              style: TextStyle(color: DesignSystem.muted),
                            ),
                          ),
                        )
                      else
                        ..._entries.asMap().entries.map((entry) {
                          final index = entry.key;
                          final e = entry.value;
                          return _buildPricingRow(
                              index, e, brandOrange, _entries.length);
                        }),
                      if (_hasErrors)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Please enter valid non-negative rates for all products',
                            style: TextStyle(
                              color: DesignSystem.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                decoration: BoxDecoration(
                  color: DesignSystem.creamBg,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: DesignSystem.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Worker Earnings',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          Text(
                            '₹${_totalEarnings.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: brandOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandOrange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'SAVE & ASSIGN',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildPricingRow(
      int index, ProductPricingEntry entry, Color brandOrange, int total) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignSystem.creamBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DesignSystem.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.checkroom_rounded,
                    size: 18, color: Colors.blue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Qty: ${entry.quantity} x ₹${entry.unitPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: DesignSystem.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Worker Rate (₹)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: DesignSystem.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: entry.rateController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        hintText: 'Enter rate',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: DesignSystem.muted.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: DesignSystem.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: DesignSystem.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: brandOrange.withValues(alpha: 0.5)),
                        ),
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    if ((double.tryParse(entry.rateController.text) ?? 0) > entry.unitPrice) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 12, color: Colors.orange.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Rate exceeds selling price (₹${entry.unitPrice.toStringAsFixed(0)})',
                            style: TextStyle(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: brandOrange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'SUBTOTAL',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: brandOrange,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '₹${entry.subtotal.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: brandOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
