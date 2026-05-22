import 'package:flutter/material.dart';
import '../../widgets/common/responsive_widgets.dart';
import '../../widgets/common/provider_wrappers.dart';
import '../../models/measurement_record.dart';
import '../../models/measurement_template.dart';
import 'package:tailorsbook/core/utils/design_system.dart';

class MeasurementEditScreen extends StatefulWidget {
  final MeasurementRecord record;
  final ProductTemplate template;

  const MeasurementEditScreen({
    super.key, 
    required this.record,
    required this.template,
  });

  @override
  State<MeasurementEditScreen> createState() => _MeasurementEditScreenState();
}

class _MeasurementEditScreenState extends State<MeasurementEditScreen> {
  final Map<String, TextEditingController> _controllers = {};
  late TextEditingController _instructionsController;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    for (var field in widget.template.fields) {
      final value = widget.record.values[field.id];
      _controllers[field.id] = TextEditingController(text: value != null ? value.toString() : '');
    }
    _instructionsController = TextEditingController(text: widget.record.stitchingInstructions ?? '');
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _instructionsController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedChanges) return true;

    final discard = await showResponsiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Unsaved Changes', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CONTINUE EDITING', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: DesignSystem.error),
            child: const Text('DISCARD', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    return discard ?? false;
  }

  Future<bool> _warnEmptyFields() async {
    final emptyFields = widget.template.fields.where((f) {
      final text = _controllers[f.id]?.text ?? '';
      return text.trim().isEmpty || double.tryParse(text) == 0.0;
    }).toList();

    if (emptyFields.isEmpty) return true;

    final proceed = await showResponsiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Missing Measurements', style: TextStyle(fontWeight: FontWeight.w900)),
        content: KeyboardSafeDialogScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${emptyFields.length} field${emptyFields.length > 1 ? 's' : ''} ${emptyFields.length > 1 ? 'have' : 'has'} no value:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DesignSystem.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DesignSystem.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: emptyFields.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 14, color: DesignSystem.primary),
                      const SizedBox(width: 8),
                      Text(f.label, style: TextStyle(fontSize: 13, color: DesignSystem.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You can save with missing values, but the tailor may not have enough information to stitch accurately.',
              style: TextStyle(fontSize: 12, color: DesignSystem.muted, height: 1.4),
            ),
          ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('EDIT', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.primary,
              foregroundColor: DesignSystem.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('SAVE ANYWAY', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    return proceed ?? false;
  }

  Future<void> _save() async {
    final canSave = await _warnEmptyFields();
    if (!canSave) return;

    setState(() => _isSaving = true);

    try {
      final Map<String, double> newValues = {};
      for (var entry in _controllers.entries) {
        final val = double.tryParse(entry.value.text);
        newValues[entry.key] = val ?? 0.0;
      }

      final provider = TemplateProviderWrapper.of(context);
      
      // Merge with the existing record to preserve ID and references
      final updatedRecord = MeasurementRecord(
        id: widget.record.id,
        customerId: widget.record.customerId,
        customerName: widget.record.customerName,
        templateId: widget.record.templateId,
        templateName: widget.record.templateName,
        date: widget.record.date, // keep original date
        values: newValues,
        stitchingInstructions: _instructionsController.text.trim(),
      );

      await provider.updateMeasurementInDB(updatedRecord);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Measurements updated successfully!'), backgroundColor: DesignSystem.success),
        );
        Navigator.pop(context, updatedRecord);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating: $e'), backgroundColor: DesignSystem.error),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandOrange = Theme.of(context).colorScheme.primary;
    final brandBlack = const Color(0xFF1C1C1C);

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canLeave = await _confirmDiscard();
        if (canLeave && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: DesignSystem.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: brandBlack),
          onPressed: () async {
            final canLeave = await _confirmDiscard();
            if (canLeave && context.mounted) Navigator.pop(context);
          },
        ),
        title: Text(
          'Edit ${widget.record.templateName}',
          style: TextStyle(color: brandBlack, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: DesignSystem.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: DesignSystem.charcoal.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  ...widget.template.fields.map((field) => Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3, 
                          child: Text(field.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))
                        ),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _controllers[field.id],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            onChanged: (_) => _markDirty(),
                            decoration: InputDecoration(
                              hintText: '0.0',
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              suffixText: field.unit,
                              suffixStyle: TextStyle(color: DesignSystem.muted, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Text('Additional Stitching Instructions', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: brandBlack)),
            const SizedBox(height: 12),
            TextField(
              controller: _instructionsController,
              maxLines: 4,
              onChanged: (_) => _markDirty(),
              decoration: InputDecoration(
                hintText: 'e.g. Boat neck design, Loose fitting...',
                filled: true,
                fillColor: DesignSystem.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: DesignSystem.outlineVariant)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: DesignSystem.outlineVariant)),
              ),
            ),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandOrange,
                  foregroundColor: DesignSystem.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  shadowColor: brandOrange.withValues(alpha: 0.4),
                ),
                child: _isSaving 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: DesignSystem.white, strokeWidth: 2))
                  : const Text('UPDATE MEASUREMENTS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      ),
    );
  }
}
