import 'package:flutter/material.dart';
import '../../core/utils/design_system.dart';

import '../../widgets/common/provider_wrappers.dart';
import '../common/responsive_widgets.dart';
import '../common/app_widgets.dart';

class RecordWorkerPaymentDialog extends StatefulWidget {
  final String workerId;
  final VoidCallback onSuccess;

  const RecordWorkerPaymentDialog({
    super.key,
    required this.workerId,
    required this.onSuccess,
  });

  @override
  State<RecordWorkerPaymentDialog> createState() => _RecordWorkerPaymentDialogState();
}

class _RecordWorkerPaymentDialogState extends State<RecordWorkerPaymentDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _type = 'salary';
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _savePayment() async {
    final amountString = _amountController.text.trim();
    if (amountString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an amount')));
      return;
    }
    final amount = double.tryParse(amountString) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amount must be greater than zero')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final wp = WorkerProviderWrapper.of(context, listen: false);
      final success = await wp.addPayment({
        'worker_id': widget.workerId,
        'amount': amount,
        'payment_type': _type,
        'notes': _notesController.text.trim(),
        'payment_date': DateTime.now().toIso8601String().split('T')[0],
      });
      if (!context.mounted) return;
      Navigator.pop(context);
      
      if (success) {
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully'), backgroundColor: DesignSystem.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save payment. Please try again.'), backgroundColor: DesignSystem.error),
        );
      }
    } catch (e) {
      debugPrint('Error adding payment: $e');
      if (!context.mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.'), backgroundColor: DesignSystem.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardSafeDialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('RECORD PAYMENT',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 20),
              AppDropdown<String>(
                value: _type,
                label: 'Payment Type',
                hint: 'Select type',
                items: const [
                  DropdownMenuItem(value: 'salary', child: Text('Salary Payment')),
                  DropdownMenuItem(value: 'advance', child: Text('Advance Payout')),
                ],
                onChanged: (val) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  setState(() => _type = val!);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount (₹)', hintText: '0.00'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
              ),
              const SizedBox(height: 24),
              if (_isSaving)
                const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _savePayment,
                    style: ElevatedButton.styleFrom(backgroundColor: DesignSystem.success),
                    child: const Text('Save Payment'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
