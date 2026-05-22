import 'package:flutter/material.dart';


import '../../models/measurement_template.dart';
import '../../models/measurement_record.dart';
import '../../models/customer_model.dart';
import '../../providers/template_provider.dart';
import '../../main.dart';
import 'provider_wrappers.dart';
import '../../core/utils/responsive.dart';
import 'responsive_widgets.dart';

class MeasurementEntryView extends StatefulWidget {
  final Customer customer;
  final ProductTemplate? initialTemplate;
  final VoidCallback onSave;
  final Function(MeasurementRecord)? onRecordSaved;
  final ValueChanged<bool>? onDirtyChanged;

  const MeasurementEntryView({super.key, required this.customer, required this.onSave, this.onRecordSaved, this.initialTemplate, this.onDirtyChanged});

  @override
  State<MeasurementEntryView> createState() => _MeasurementEntryViewState();
}

class _MeasurementEntryViewState extends State<MeasurementEntryView> {
  final Map<String, TextEditingController> _fieldControllers = {};
  final Map<String, FocusNode> _fieldFocusNodes = {};
  final TextEditingController _instructionsController = TextEditingController();
  final FocusNode _instructionsFocusNode = FocusNode();
  String _tailorType = 'Both';
  String _categoryFilter = 'all';
  final Set<String> _autofilledFields = {};
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  ProductTemplate? _selectedTemplate;
  List<ProductTemplate> _cachedFilteredTemplates = [];
  String _lastCategoryFilter = 'all';
  int _lastCacheVersion = -1;

  @override
  void dispose() {
    for (var controller in _fieldControllers.values) {
      controller.dispose();
    }
    for (var node in _fieldFocusNodes.values) {
      node.dispose();
    }
    _instructionsController.dispose();
    _instructionsFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final user = supabase.auth.currentUser;
    if (user != null && user.userMetadata != null) {
      _tailorType = user.userMetadata!['tailor_type'] ?? 'Both';
    }
    
    // Pre-select template if provided
    if (widget.initialTemplate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        _onTemplateSelected(widget.initialTemplate!);
      });
    }
  }

  Future<void> _onTemplateSelected(ProductTemplate template) async {
    final canSwitch = await _confirmDiscard();
    if (!canSwitch) return;

    setState(() {
      _selectedTemplate = template;
      _fieldControllers.clear();
      _autofilledFields.clear();
      _hasUnsavedChanges = false;
      
      final latest = TemplateProviderWrapper.of(context).getLatestMeasurement(widget.customer.id, template.id);
      
      for (var field in template.fields) {
        final val = latest?.values[field.id]?.toString() ?? '';
        _fieldControllers[field.id] = TextEditingController(text: val);
        _fieldFocusNodes[field.id] = FocusNode();
        if (val.isNotEmpty) {
          _autofilledFields.add(field.id);
        }
      }
      _instructionsController.text = latest?.stitchingInstructions ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final templateProvider = TemplateProviderWrapper.of(context);

    return Column(
      children: [
        // Responsive Template Header
        _buildTemplateBar(templateProvider),

        if (_selectedTemplate != null)
          Expanded(child: _buildMeasurementForm())
        else
          Expanded(child: _buildSelectTemplateState(templateProvider)),
      ],
    );
  }

  Widget _buildTemplateBar(TemplateProvider provider) {
    final brandOrange = Theme.of(context).colorScheme.primary;

    if (_selectedTemplate != null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: brandOrange.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [BoxShadow(color: brandOrange.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selected Product', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(
                    _selectedTemplate!.name,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF1C1C1C)),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () async {
                final canSwitch = await _confirmDiscard();
                if (canSwitch && context.mounted) {
                  setState(() {
                    _selectedTemplate = null;
                    _hasUnsavedChanges = false;
                  });
                }
              },
              icon: Icon(Icons.swap_horiz_rounded, size: 18, color: brandOrange),
              label: Text(
                'Change',
                style: TextStyle(color: brandOrange, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMeasurementForm() {
    final brandOrange = Theme.of(context).colorScheme.primary;
    final gridItems = _selectedTemplate!.fields;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        R.pagePadding(context),
        R.gap(context),
        R.pagePadding(context),
        effectiveBottomPadding(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Measurement Technical Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final crossAxisCount = w < 420 ? 2 : (w < 900 ? 3 : 4);
              final childAspectRatio = 1.4; // Adjusted for better fit

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: gridItems.length,
                itemBuilder: (ctx, index) {
                  final field = gridItems[index];
                  final isLastField = index == gridItems.length - 1;
                  final focusNode = _fieldFocusNodes[field.id];
                  final controller = _fieldControllers[field.id];
                  
                  // Skip if controller or focusNode missing (shouldn't happen but safety check)
                  if (focusNode == null || controller == null) {
                    return const SizedBox.shrink();
                  }
                  return ListenableBuilder(
                    listenable: focusNode,
                    builder: (context, child) {
                      final hasFocus = focusNode.hasFocus;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hasFocus ? brandOrange.withValues(alpha: 0.02) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: hasFocus ? brandOrange : const Color(0xFFEEEEEE),
                            width: hasFocus ? 2 : 1.5,
                          ),
                          boxShadow: hasFocus ? [BoxShadow(color: brandOrange.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))] : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                field.label.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9,
                                  letterSpacing: 0.5,
                                  color: hasFocus ? brandOrange : Colors.grey.shade400,
                                ),
                              ),
                            ),
                            if (_autofilledFields.contains(field.id) && controller.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'PREVIOUS',
                                  style: TextStyle(
                                    fontSize: 7,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.blue.shade300,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            TextField(
                              controller: controller,
                              focusNode: focusNode,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textInputAction: isLastField ? TextInputAction.done : TextInputAction.next,
                              textAlign: TextAlign.start,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1C1C1C)),
                              onSubmitted: (_) {
                                if (isLastField) {
                                  FocusScope.of(context).requestFocus(_instructionsFocusNode);
                                } else {
                                  final nextIndex = index + 1;
                                  if (nextIndex < gridItems.length) {
                                    final nextField = gridItems[nextIndex];
                                    FocusScope.of(context).requestFocus(_fieldFocusNodes[nextField.id]);
                                  }
                                }
                              },
                              decoration: InputDecoration(
                                hintText: '0.0',
                                hintStyle: TextStyle(color: Colors.grey.shade300),
                                suffixText: '"',
                                suffixStyle: TextStyle(color: hasFocus ? brandOrange : Colors.grey.shade400, fontWeight: FontWeight.bold),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: brandOrange, width: 1.5),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onChanged: (v) {
                                _markDirty();
                                setState(() {
                                  _autofilledFields.remove(field.id);
                                });
                              }, 
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          
          const SizedBox(height: 32),
          _buildSectionHeader('MASTER INSTRUCTIONS & NOTES'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _instructionsController,
              focusNode: _instructionsFocusNode,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              onChanged: (_) => _markDirty(),
              decoration: InputDecoration(
                hintText: 'e.g. Boat neck design, Princess cut, Special sleeve length...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
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
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('SAVE MEASUREMENTS', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectTemplateState(TemplateProvider provider) {
    final cv = provider.cacheVersion;
    if (_categoryFilter != _lastCategoryFilter || cv != _lastCacheVersion) {
      _lastCategoryFilter = _categoryFilter;
      _lastCacheVersion = cv;
      _cachedFilteredTemplates = provider.getMostUsedTemplates().where((t) {
        final type = _tailorType.toLowerCase();
        if (type == 'ladies' && t.category == TemplateCategory.gents) return false;
        if (type == 'gents' && t.category == TemplateCategory.ladies) return false;
        if (_categoryFilter == 'ladies') {
          return t.category == TemplateCategory.ladies || t.category == TemplateCategory.both;
        }
        if (_categoryFilter == 'gents') {
          return t.category == TemplateCategory.gents || t.category == TemplateCategory.both;
        }
        return true;
      }).toList();
    }
    final templates = _cachedFilteredTemplates;
    final brandOrange = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        R.pagePadding(context),
        R.gap(context),
        R.pagePadding(context),
        effectiveBottomPadding(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Garment Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Most used products appear first', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildCategoryChip('All', 'all')),
              const SizedBox(width: 8),
              Expanded(child: _buildCategoryChip('Ladies', 'ladies')),
              const SizedBox(width: 8),
              Expanded(child: _buildCategoryChip('Gents', 'gents')),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final crossAxisCount = w < 420 ? 2 : (w < 900 ? 3 : 4);
              final childAspectRatio = w < 420 ? 1.05 : 1.15;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: childAspectRatio,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: templates.length,
                  itemBuilder: (ctx, index) {
                    final t = templates[index];
                    return InkWell(
                      onTap: () => _onTemplateSelected(t).then((_) => null),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              backgroundColor: brandOrange.withValues(alpha: 0.1),
                              child: Icon(Icons.checkroom_rounded, color: brandOrange),
                            ),
                            const SizedBox(height: 12),
                            Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
  }

  Widget _buildCategoryChip(String label, String value) {
    final selected = _categoryFilter == value;
    final orange = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: () => setState(() => _categoryFilter = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? orange.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? orange : const Color(0xFFEEEEEE)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? orange : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: Colors.grey,
        letterSpacing: 1.0,
      ),
    );
  }

  void _markDirty() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
      widget.onDirtyChanged?.call(true);
    }
  }

  void _resetDirty() {
    if (_hasUnsavedChanges) {
      _hasUnsavedChanges = false;
      widget.onDirtyChanged?.call(false);
    }
  }

  Future<bool> _warnEmptyFields() async {
    final emptyFields = _selectedTemplate!.fields.where((f) {
      final text = _fieldControllers[f.id]?.text ?? '';
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
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: emptyFields.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(f.label, style: TextStyle(fontSize: 13, color: Colors.orange.shade900, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You can save with missing values, but the tailor may not have enough information to stitch accurately.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
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
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('SAVE ANYWAY', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    return proceed ?? false;
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DISCARD', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    return discard ?? false;
  }

  void _save() async {
    final provider = TemplateProviderWrapper.of(context);
    
    final canSave = await _warnEmptyFields();
    if (!canSave || !mounted) return;

    setState(() => _isSaving = true);
    
    final Map<String, double> values = {};
    for (var entry in _fieldControllers.entries) {
      values[entry.key] = double.tryParse(entry.value.text) ?? 0.0;
    }

    final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    
    final record = MeasurementRecord(
      id: tempId, 
      customerId: widget.customer.id,
      customerName: widget.customer.name,
      templateId: _selectedTemplate!.id,
      templateName: _selectedTemplate!.name,
      date: DateTime.now(),
      values: values,
      stitchingInstructions: _instructionsController.text,
    );

    try {
      final savedRecord = await provider.addMeasurementToDB(record);
      if (!mounted) return;
      
      if (savedRecord != null) {
        _resetDirty();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Measurements saved successfully!'), backgroundColor: Colors.green));
        if (widget.onRecordSaved != null) {
          widget.onRecordSaved!(savedRecord);
        }
        widget.onSave();
      } else {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save measurements'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
