import 'package:flutter/material.dart';
import '../../models/measurement_template.dart';
import '../../core/utils/design_system.dart';
import '../common/responsive_widgets.dart';

class AddGarmentDialogResult {
  final String name;
  final int quantity;
  final double price;

  AddGarmentDialogResult({
    required this.name,
    required this.quantity,
    required this.price,
  });
}

class AddGarmentDialog extends StatefulWidget {
  final List<ProductTemplate> templates;

  const AddGarmentDialog({super.key, required this.templates});

  @override
  State<AddGarmentDialog> createState() => _AddGarmentDialogState();
}

class _AddGarmentDialogState extends State<AddGarmentDialog> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  
  // Track if we added the listener to avoid duplicates
  TextEditingController? _autoCompleteCtrl;

  @override
  void dispose() {
    if (_autoCompleteCtrl != null) {
      _autoCompleteCtrl!.removeListener(_syncNameController);
    }
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _syncNameController() {
    if (_autoCompleteCtrl != null) {
      _nameController.text = _autoCompleteCtrl!.text;
    }
  }

  void _onAdd() {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final qty = int.tryParse(_qtyController.text) ?? 1;

    if (name.isNotEmpty && price > 0 && qty > 0) {
      Navigator.pop(
        context,
        AddGarmentDialogResult(name: name, quantity: qty, price: price),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid name, quantity, and price.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radiusLg)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: const Text('Add Garment', style: TextStyle(fontWeight: FontWeight.w800)),
      content: KeyboardSafeDialogScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue val) => widget.templates
                  .where((t) => t.name.toLowerCase().contains(val.text.toLowerCase()))
                  .map((t) => t.name),
              onSelected: (s) => _nameController.text = s,
              fieldViewBuilder: (ctx, ctrl, focus, onSub) {
                if (_autoCompleteCtrl != ctrl) {
                  if (_autoCompleteCtrl != null) {
                    _autoCompleteCtrl!.removeListener(_syncNameController);
                  }
                  _autoCompleteCtrl = ctrl;
                  _autoCompleteCtrl!.addListener(_syncNameController);
                  // Initialize text to match state if needed
                  if (_nameController.text.isNotEmpty && ctrl.text.isEmpty) {
                    ctrl.text = _nameController.text;
                  }
                }
                
                return TextField(
                  controller: ctrl,
                  focusNode: focus,
                  decoration: const InputDecoration(labelText: 'Garment Name (e.g. Shirt)', prefixIcon: Icon(Icons.search)),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyController,
                    decoration: const InputDecoration(labelText: 'Qty'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        ElevatedButton(
          onPressed: _onAdd,
          child: const Text('ADD'),
        ),
      ],
    );
  }
}
