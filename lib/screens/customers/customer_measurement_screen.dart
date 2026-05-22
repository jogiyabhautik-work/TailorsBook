import 'package:flutter/material.dart';
import '../../widgets/common/responsive_widgets.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/common/provider_wrappers.dart';
import '../../models/customer_model.dart';
import '../../core/utils/design_system.dart';
import '../../widgets/common/measurement_entry_view.dart';
import '../../models/measurement_template.dart';

class CustomerMeasurementScreen extends StatefulWidget {
  final Customer customer;
  final ProductTemplate? initialTemplate;

  const CustomerMeasurementScreen({super.key, required this.customer, this.initialTemplate});

  @override
  State<CustomerMeasurementScreen> createState() => _CustomerMeasurementScreenState();
}

class _CustomerMeasurementScreenState extends State<CustomerMeasurementScreen> {
  ProductTemplate? _activeTemplate;
  bool _formDirty = false;

  @override
  void initState() {
    super.initState();
    _activeTemplate = widget.initialTemplate;
  }

  Future<bool> _confirmDiscard() async {
    if (!_formDirty) return true;
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

  void _switchTemplate(ProductTemplate template) async {
    if (_activeTemplate?.id == template.id) return;
    final canSwitch = await _confirmDiscard();
    if (canSwitch && context.mounted) {
      setState(() {
        _activeTemplate = template;
        _formDirty = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandOrange = Theme.of(context).colorScheme.primary;
    final templateProvider = TemplateProviderWrapper.of(context);
    final templates = templateProvider.getTemplatesForCustomer(widget.customer.id);
    final existingTemplates = templates.existing;
    final unusedTemplates = templates.unused;

    // Default to first existing if active is null
    if (_activeTemplate == null && existingTemplates.isNotEmpty) {
      _activeTemplate = existingTemplates.first;
    }

    return PopScope(
      canPop: !_formDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canLeave = await _confirmDiscard();
        if (canLeave && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
      backgroundColor: DesignSystem.creamBg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: DesignSystem.white,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Measurement Card', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: DesignSystem.charcoal)),
            Text(widget.customer.name, style: TextStyle(fontSize: 11, color: brandOrange, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final canLeave = await _confirmDiscard();
              if (canLeave && context.mounted) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.close_rounded, color: DesignSystem.muted),
          ),
        ],
      ),
      body: Column(
          children: [
          // Garment Selector
          Container(
            height: 70,
            color: DesignSystem.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                ...existingTemplates.map((t) {
                  final isSelected = _activeTemplate?.id == t.id;
                  return _buildGarmentTab(t, isSelected, brandOrange, true);
                }),
                
                // Add New Product Button
                GestureDetector(
                  onTap: () => _showAddNewSelector(context, unusedTemplates, brandOrange),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: DesignSystem.surface,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: DesignSystem.border, width: 1.5, style: BorderStyle.solid),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline_rounded, size: 16, color: brandOrange),
                        const SizedBox(width: 8),
                        Text('ADD NEW', style: TextStyle(color: brandOrange, fontWeight: FontWeight.w900, fontSize: 13)),
                      ],
                  ),
                 ),
            ),
              ],
            ),
          ),
          Expanded(
             child: _activeTemplate == null 
               ? _buildEmptySelection(brandOrange, unusedTemplates)
               : ConstrainedContent(
                   child: MeasurementEntryView(
                     key: ValueKey(_activeTemplate?.id ?? 'none'),
                     customer: widget.customer,
                     initialTemplate: _activeTemplate,
                     onSave: () => Navigator.pop(context),
                     onDirtyChanged: (dirty) => _formDirty = dirty,
                   ),
                 ),
           ),
           ],
         ),
       ),
    );
  }

  Widget _buildGarmentTab(ProductTemplate t, bool isSelected, Color brandOrange, bool hasRecord) {
    return GestureDetector(
      onTap: () => _switchTemplate(t),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? brandOrange.withValues(alpha: 0.12) : DesignSystem.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? brandOrange : DesignSystem.border, width: 1.5),
        ),
        child: Row(
          children: [
            if (hasRecord) Icon(Icons.check_circle_rounded, size: 14, color: isSelected ? brandOrange : DesignSystem.success),
            if (hasRecord) const SizedBox(width: 8),
            Text(
              t.name.toUpperCase(), 
              style: TextStyle(
                color: isSelected ? brandOrange : DesignSystem.muted, 
                fontWeight: FontWeight.w900, 
                fontSize: 10,
                letterSpacing: 0.5,
              )
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNewSelector(BuildContext context, List<ProductTemplate> items, Color orange) {
    showKeyboardSafeModalBottomSheet(
      context: context,
      builder: (ctx) {
        final system = items.where((t) => t.isSystemTemplate).toList();
        final custom = items.where((t) => !t.isSystemTemplate).toList();
        
        return KeyboardSafeBottomSheet(
          maxHeightFactor: 0.8,
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ADD NEW SPEC', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Text('Which garment technical sheet do you want to start for ${widget.customer.name}?', style: TextStyle(color: DesignSystem.muted, fontSize: 13, height: 1.4)),
                const SizedBox(height: 24),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                    if (custom.isNotEmpty) ...[
                      const Text('CUSTOM TEMPLATES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: DesignSystem.muted, letterSpacing: 1)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: custom.map((t) => _buildTemplateTile(t, ctx, orange)).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (system.isNotEmpty) ...[
                      const Text('SYSTEM TEMPLATES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: DesignSystem.muted, letterSpacing: 1)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: system.map((t) => _buildTemplateTile(t, ctx, orange)).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
},
);
  }

  Widget _buildTemplateTile(ProductTemplate t, BuildContext ctx, Color orange) {
    return InkWell(
      onTap: () {
        _switchTemplate(t);
        Navigator.pop(ctx);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: DesignSystem.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DesignSystem.border, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline_rounded, size: 14, color: orange.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text(t.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySelection(Color orange, List<ProductTemplate> unusedTemplates) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.straighten_rounded, size: 80, color: DesignSystem.outlineVariant),
          const SizedBox(height: 16),
          Text('No item selected', style: TextStyle(color: DesignSystem.muted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _showAddNewSelector(context, unusedTemplates, orange),
            child: const Text('Add First Measurement'),
          ),
        ],
      ),
    );
  }
}
