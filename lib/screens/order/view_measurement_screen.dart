import 'package:flutter/material.dart';
import '../../widgets/common/responsive_widgets.dart';
import '../../widgets/common/measurement_entry_view.dart';
import '../../widgets/common/provider_wrappers.dart';
import '../../models/order_model.dart';
import '../../models/customer_model.dart';
import '../../models/measurement_template.dart';
import '../../models/measurement_record.dart';
import '../../providers/template_provider.dart';
import '../../core/utils/tailor_flow_helper.dart';
import 'package:tailorsbook/core/utils/design_system.dart';

class ViewMeasurementScreen extends StatefulWidget {
  final OrderModel order;
  final OrderItem item;
  final Customer customer;
  final String measurementId;

  const ViewMeasurementScreen({
    super.key,
    required this.order,
    required this.item,
    required this.customer,
    required this.measurementId,
  });

  @override
  State<ViewMeasurementScreen> createState() => _ViewMeasurementScreenState();
}

class _ViewMeasurementScreenState extends State<ViewMeasurementScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  bool _formDirty = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TemplateProviderWrapper.of(context, listen: false)
          .fetchCustomerMeasurementsPaginated(customerId: widget.customer.id);
    });
  }

  Future<bool> _confirmDiscard() async {
    if (!_formDirty || !_isEditing) return true;
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
      return discard ?? false;
    }

  @override
  Widget build(BuildContext context) {
    final templateProvider = TemplateProviderWrapper.of(context);
    final measurement = templateProvider.getMeasurementById(widget.measurementId);
    final brandOrange = Theme.of(context).colorScheme.primary;

    if (measurement == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Measurement Not Found')),
        body: const Center(child: Text('The linked measurement could not be found.')),
      );
    }

    ProductTemplate? matchingTemplate;
    try {
      matchingTemplate = templateProvider.getAllTemplates().firstWhere(
        (t) => t.id == measurement.templateId,
      );
    } catch (_) {}
    final templateNotFound = matchingTemplate == null;
    final template = matchingTemplate ?? ProductTemplate(
      id: measurement.templateId,
      name: measurement.templateName,
      category: TemplateCategory.both,
      fields: measurement.values.keys.map((k) => MeasurementField(id: k, label: k)).toList(),
    );

    final isReadOnly = widget.item.status.toLowerCase() == 'ready' || 
                       widget.item.status.toLowerCase() == 'delivered';

    final bool canPop = !_isEditing || !_formDirty;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await _confirmDiscard();
        if (discard && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: DesignSystem.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: DesignSystem.charcoal, size: 20),
          onPressed: () async {
            final discard = await _confirmDiscard();
            if (discard && context.mounted) Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Update Measurement' : 'View Measurement',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1C)),
            ),
            Text(
              '${widget.item.productName} â€¢ ${widget.customer.name}',
              style: TextStyle(fontSize: 11, color: brandOrange, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          if (!isReadOnly && !_isEditing)
            TextButton.icon(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('UPDATE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isEditing
              ? MeasurementEntryView(
                  customer: widget.customer,
                  initialTemplate: template,
                  onRecordSaved: (newRecord) async {
                    setState(() => _isLoading = true);
                    try {
                      final orderProvider = OrderProviderWrapper.of(context);
                      await orderProvider.linkMeasurementToItem(
                        widget.order.id,
                        widget.item.id,
                        newRecord.id,
                        templateId: template.id,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } finally {
                      if (context.mounted) setState(() => _isLoading = false);
                    }
                  },
                  onSave: () {},
                  onDirtyChanged: (dirty) => _formDirty = dirty,
                )
              : _buildStaticView(measurement, template, brandOrange, templateProvider, templateNotFound: templateNotFound),
    ),
    );
  }

  Widget _buildStaticView(
    MeasurementRecord measurement,
    ProductTemplate template,
    Color brandOrange,
    TemplateProvider provider, {
    bool templateNotFound = false,
  }) {
    final history = provider.getCustomerMeasurements(widget.customer.id)
        .where((m) => m.templateId == measurement.templateId && m.id != measurement.id)
        .toList();
    history.sort((a, b) => b.date.compareTo(a.date));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(measurement, brandOrange, templateNotFound: templateNotFound),
          const SizedBox(height: 24),
          
          const Text(
            'MEASUREMENT VALUES',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: DesignSystem.muted, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: template.fields.length,
            itemBuilder: (context, index) {
              final field = template.fields[index];
              final value = measurement.values[field.id] ?? 0.0;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                color: DesignSystem.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      field.label.toUpperCase(),
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: DesignSystem.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${value.toStringAsFixed(1)}"',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              );
            },
          ),
          
          if (measurement.stitchingInstructions?.isNotEmpty == true) ...[
            const SizedBox(height: 24),
            const Text(
              'STITCHING INSTRUCTIONS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: DesignSystem.muted, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DesignSystem.primaryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DesignSystem.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                measurement.stitchingInstructions!,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
              ),
            ),
          ],

          if (history.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Text(
              'PREVIOUS VERSIONS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: DesignSystem.muted, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final h = history[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFEEEEEE))),
                  child: ListTile(
                    title: Text(TailorFlowHelper.formatDate(h.date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('${h.values.length} fields recorded', style: const TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                       Navigator.pushReplacement(
                         context,
                         MaterialPageRoute(
                           builder: (_) => ViewMeasurementScreen(
                             order: widget.order,
                             item: widget.item,
                             customer: widget.customer,
                             measurementId: h.id,
                           ),
                         ),
                       );
                    },
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(MeasurementRecord measurement, Color brandOrange, {bool templateNotFound = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignSystem.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: templateNotFound ? DesignSystem.error.withValues(alpha: 0.1) : brandOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              templateNotFound ? Icons.warning_rounded : Icons.straighten_rounded,
              color: templateNotFound ? DesignSystem.error : brandOrange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Version: ${TailorFlowHelper.formatDate(measurement.date)}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                Text(
                  'Created: ${TailorFlowHelper.formatDate(measurement.createdAt)}',
                  style: TextStyle(color: DesignSystem.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (widget.item.measurementId == measurement.id)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: DesignSystem.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'LINKED',
                style: TextStyle(color: DesignSystem.success, fontWeight: FontWeight.bold, fontSize: 9),
              ),
            ),
          if (templateNotFound)
            const SizedBox(width: 8),
          if (templateNotFound)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: DesignSystem.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'DELETED',
                style: TextStyle(color: DesignSystem.error, fontWeight: FontWeight.bold, fontSize: 9),
              ),
            ),
        ],
      ),
    );
  }
}
