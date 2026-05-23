import 'package:flutter/material.dart';
import '../../widgets/common/responsive_widgets.dart';
import '../../widgets/common/measurement_entry_view.dart';
import '../../widgets/common/provider_wrappers.dart';
import '../../models/order_model.dart';
import '../../models/customer_model.dart';
import '../../models/measurement_template.dart';
import '../../providers/template_provider.dart';
import '../../core/utils/tailor_flow_helper.dart';
import 'package:tailorsbook/core/utils/design_system.dart';

class ItemMeasurementSelectionScreen extends StatefulWidget {
  final OrderModel order;
  final OrderItem item;
  final Customer customer;

  const ItemMeasurementSelectionScreen({
    super.key,
    required this.order,
    required this.item,
    required this.customer,
  });

  @override
  State<ItemMeasurementSelectionScreen> createState() => _ItemMeasurementSelectionScreenState();
}

class _ItemMeasurementSelectionScreenState extends State<ItemMeasurementSelectionScreen> {
  ProductTemplate? _selectedTemplate;
  bool _showNewEntry = false;
  bool _isLoading = false;
  bool _formDirty = false;

  @override
  void initState() {
    super.initState();
    _tryAutoMatchTemplate();
  }

  void _tryAutoMatchTemplate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final templateProvider = TemplateProviderWrapper.of(context);
      final allTemplates = templateProvider.getAllTemplates();
      
      for (final t in allTemplates) {
        if (t.name.toLowerCase() == widget.item.productName.toLowerCase()) {
          setState(() => _selectedTemplate = t);
          break;
        }
      }
    });
  }

  Future<void> _linkMeasurement(String measurementId) async {
    setState(() => _isLoading = true);
    try {
      final orderProvider = OrderProviderWrapper.of(context);
      
      final success = await orderProvider.linkMeasurementToItem(
        widget.order.id,
        widget.item.id,
        measurementId,
        templateId: _selectedTemplate?.id,
      );

      if (context.mounted && success) {
        Navigator.pop(context, true);
      }
    } finally {
      if (context.mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandOrange = Theme.of(context).colorScheme.primary;
    final templateProvider = TemplateProviderWrapper.of(context);

    return PopScope(
      canPop: !_showNewEntry || !_formDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await showResponsiveDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Unsaved Changes', style: TextStyle(fontWeight: FontWeight.w900)),
            content: const Text('Discard your edits?'),
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
        if (discard == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: DesignSystem.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Link Measurement',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1C)),
            ),
            Text(
              '${widget.item.productName} for ${widget.customer.name}',
              style: TextStyle(fontSize: 11, color: brandOrange, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: DesignSystem.charcoal, size: 20),
          onPressed: () async {
            if (_showNewEntry && _formDirty) {
              final discard = await showResponsiveDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: const Text('Unsaved Changes', style: TextStyle(fontWeight: FontWeight.w900)),
                  content: const Text('Discard your edits?'),
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
              if (discard != true) return;
            }
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _showNewEntry && _selectedTemplate != null
               ? MeasurementEntryView(
                   key: ValueKey('item_entry_${widget.customer.id}_${_selectedTemplate?.id}'),
                   customer: widget.customer,
                   initialTemplate: _selectedTemplate,
                   onRecordSaved: (record) async {
                     await _linkMeasurement(record.id);
                   },
                   onSave: () {
                     // This is still called after onRecordSaved in MeasurementEntryView
                   },
                   onDirtyChanged: (dirty) => _formDirty = dirty,
                 )
               : _buildSelectionView(templateProvider, brandOrange),
     ),
     );
   }

  Widget _buildSelectionView(TemplateProvider templateProvider, Color brandOrange) {
    if (_selectedTemplate == null) {
      return _buildTemplatePicker(templateProvider, brandOrange);
    }

    final latestRecord = templateProvider.getLatestMeasurement(
      widget.customer.id,
      _selectedTemplate!.id,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGarmentInfoCard(brandOrange),
          const SizedBox(height: 24),
          
          const Text(
            'SELECT OPTION',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: DesignSystem.muted, letterSpacing: 1),
          ),
          const SizedBox(height: 16),

          if (latestRecord != null) ...[
            _buildOptionCard(
              title: 'Use Latest Measurement',
              subtitle: 'Last updated ${TailorFlowHelper.formatDate(latestRecord.date)}',
              icon: Icons.history_rounded,
              color: DesignSystem.primary,
              onTap: () => _linkMeasurement(latestRecord.id),
            ),
            const SizedBox(height: 16),
          ],

          _buildOptionCard(
            title: 'Take New Measurement',
            subtitle: 'Record fresh measurements for this order',
            icon: Icons.add_circle_outline_rounded,
            color: brandOrange,
            onTap: () => setState(() => _showNewEntry = true),
          ),
          
          const SizedBox(height: 32),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _selectedTemplate = null),
              child: const Text('Change Garment Type/Template'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatePicker(TemplateProvider provider, Color brandOrange) {
    final templates = provider.getAllTemplates();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Could not auto-match "${widget.item.productName}".\nPlease select the correct garment type:',
            style: TextStyle(color: DesignSystem.charcoal, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final t = templates[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () => setState(() => _selectedTemplate = t),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGarmentInfoCard(Color brandOrange) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignSystem.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: brandOrange.withValues(alpha: 0.1),
            child: Icon(Icons.checkroom_rounded, color: brandOrange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedTemplate!.name,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                Text(
                  'Matching template found',
                    style: TextStyle(color: DesignSystem.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
        color: DesignSystem.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  Text(
                    subtitle,
                  style: TextStyle(color: DesignSystem.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: DesignSystem.muted),
          ],
        ),
      ),
    );
  }
}
