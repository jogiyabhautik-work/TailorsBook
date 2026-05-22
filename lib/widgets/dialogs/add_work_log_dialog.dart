import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/utils/design_system.dart';


import '../../widgets/common/provider_wrappers.dart';
import '../common/responsive_widgets.dart';

class AddWorkLogDialog extends StatefulWidget {
  final String workerId;
  final VoidCallback onSuccess;

  const AddWorkLogDialog({
    super.key,
    required this.workerId,
    required this.onSuccess,
  });

  @override
  State<AddWorkLogDialog> createState() => _AddWorkLogDialogState();
}

class _AddWorkLogDialogState extends State<AddWorkLogDialog> {
  final _qtyController = TextEditingController();
  final _rateController = TextEditingController();
  TextEditingController? _autoCompleteCtrl;

  String _selectedProduct = '';
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkLog() async {
    final item = _selectedProduct.isNotEmpty
        ? _selectedProduct
        : (_autoCompleteCtrl?.text.trim() ?? '');
    final qty = int.tryParse(_qtyController.text);
    final rate = double.tryParse(_rateController.text);

    if (item.isEmpty || qty == null || qty <= 0 || rate == null || rate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields with valid values')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final wp = WorkerProviderWrapper.of(context, listen: false);
      final success = await wp.addWorkLog({
        'worker_id': widget.workerId,
        'item_name': item,
        'quantity': qty,
        'rate_per_piece': rate,
        'work_date': _date.toIso8601String().split('T')[0],
      });

      if (!context.mounted) return;
      Navigator.pop(context);

      if (success) {
        widget.onSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add work log. Please try again.'),
            backgroundColor: DesignSystem.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding work log: $e');
      if (!context.mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: DesignSystem.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = TemplateProviderWrapper.of(context, listen: false).getAllTemplates();
    final options = templates.map((t) => t.name).toList();

    return KeyboardSafeDialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('NEW WORK LOG',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 20),
              const Text('GARMENT TYPE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DesignSystem.muted)),
              Autocomplete<String>(
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) return options;
                  return options.where((o) =>
                      o.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (selection) => _selectedProduct = selection,
                fieldViewBuilder: (fieldCtx, ctrl, focus, onFieldSubmitted) {
                  _autoCompleteCtrl = ctrl;
                  return TextField(
                    controller: ctrl,
                    focusNode: focus,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Blouse...',
                      prefixIcon: Icon(Icons.search, size: 18),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('QTY',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DesignSystem.muted)),
                        TextField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '1'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('RATE (₹)',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DesignSystem.muted)),
                        TextField(
                          controller: _rateController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '200'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DesignSystem.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_rounded, size: 18, color: DesignSystem.primary),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMM dd, yyyy').format(_date),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isSaving)
                const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator())),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveWorkLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignSystem.orange,
                    foregroundColor: DesignSystem.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('SUBMIT WORK LOG', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
