import 'package:flutter/material.dart';
import '../../widgets/common/provider_wrappers.dart';
import '../../core/utils/design_system.dart';
import '../../models/measurement_record.dart';
import '../../models/measurement_template.dart';
import '../../providers/template_provider.dart';
import 'measurement_edit_screen.dart';
import '../../core/utils/tailor_flow_helper.dart';
import '../../widgets/common/responsive_widgets.dart';

class MeasurementViewScreen extends StatefulWidget {
  final MeasurementRecord record;
  const MeasurementViewScreen({super.key, required this.record});

  @override
  State<MeasurementViewScreen> createState() => _MeasurementViewScreenState();
}

class _MeasurementViewScreenState extends State<MeasurementViewScreen> {
  bool _isComparing = false;

  @override
  Widget build(BuildContext context) {
    final brandOrange = Theme.of(context).colorScheme.primary;
    final brandBlack = const Color(0xFF1C1C1C);

    final provider = TemplateProviderWrapper.of(context);
    
    final freshRecord = provider.measurements.firstWhere(
      (m) => m.id == widget.record.id,
      orElse: () => widget.record,
    );

    final templates = provider.getAllTemplates();
    final template = templates.firstWhere(
      (t) => t.id == freshRecord.templateId,
      orElse: () => ProductTemplate(
        id: 'unknown',
        name: freshRecord.templateName,
        category: TemplateCategory.both,
        fields: [],
      ),
    );

    return Scaffold(
      backgroundColor: DesignSystem.surface,
      appBar: AppBar(
        backgroundColor: DesignSystem.surface,
        elevation: 0,
        title: Text(
          freshRecord.customerName,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: brandBlack),
        ),
        actions: [
          if (!_isComparing)
            TextButton.icon(
              onPressed: () async {
                try {
                  setState(() => _isComparing = true);
                  final versions = provider.getMeasurementVersions(
                    freshRecord.customerId,
                    freshRecord.templateId,
                  );
                  final previousRecord = versions
                      .where((v) => v.date.isBefore(freshRecord.date))
                      .fold<MeasurementRecord?>(null, (prev, curr) =>
                          prev == null || curr.date.isAfter(prev.date) ? curr : prev);
                  if (previousRecord == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No previous measurements to compare')),
                      );
                    }
                    return;
                  }
                  final oldValues = previousRecord.values;
                  final newValues = freshRecord.values;
                  final diff = provider.compareMeasurementValues(oldValues, newValues);

                  if (!context.mounted) return;
                  showKeyboardSafeModalBottomSheet(
                    context: context,
                    builder: (ctx) {
                      return KeyboardSafeBottomSheet(
                        padding: const EdgeInsets.all(20),
                        maxHeightFactor: 0.85,
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            Text('Measurement Diff', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: brandBlack)),
                            const SizedBox(height: 12),
                            Text(
                              'Comparing ${TailorFlowHelper.formatDate(previousRecord.date)}'
                              ' to ${TailorFlowHelper.formatDate(freshRecord.date)}',
                              style: TextStyle(color: DesignSystem.muted, fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            ...diff.entries.map((entry) {
                              final field = entry.key;
                              final values = entry.value;
                              String label = field;
                              try {
                                final f = template.fields.firstWhere(
                                  (f) => f.id == field,
                                  orElse: () => MeasurementField(id: field, label: field),
                                );
                                label = f.label;
                              } catch (_) {}
                              final oldValue = values['old'] ?? 0.0;
                              final newValue = values['new'] ?? 0.0;
                              final deltaValue = values['delta'] ?? 0.0;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: DesignSystem.surface,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
                                    Text('${oldValue.toStringAsFixed(1)} -> ${newValue.toStringAsFixed(1)} (${deltaValue >= 0 ? '+' : ''}${deltaValue.toStringAsFixed(1)})', style: const TextStyle(fontWeight: FontWeight.w900)),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error comparing: $e')));
                  }
                } finally {
                  if (context.mounted) setState(() => _isComparing = false);
                }
              },
              icon: Icon(Icons.compare_arrows_rounded, color: brandOrange),
              label: Text('Compare', style: TextStyle(color: brandOrange, fontWeight: FontWeight.w700)),
            ),
          IconButton(
            icon: Icon(Icons.edit_rounded, color: brandOrange),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MeasurementEditScreen(
                    record: freshRecord,
                    template: template,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: DesignSystem.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: DesignSystem.charcoal.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Measurements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: brandBlack,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...freshRecord.values.entries.map((entry) {
                    String label = entry.key;
                    String unit = 'inch';
                    try {
                      final field = template.fields.firstWhere(
                        (f) => f.id == entry.key,
                        orElse: () => MeasurementField(id: entry.key, label: entry.key),
                      );
                      label = field.label;
                      unit = field.unit;
                    } catch (e) {
                      label = label.replaceAll('_', ' ');
                      label = label.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '').join(' ');
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 15,
                              color: DesignSystem.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${entry.value} $unit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: brandBlack,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            if (freshRecord.stitchingInstructions != null && freshRecord.stitchingInstructions!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: DesignSystem.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: DesignSystem.charcoal.withValues(alpha: 0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stitching Instructions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: brandBlack,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      freshRecord.stitchingInstructions!,
                      style: TextStyle(
                        fontSize: 15,
                        color: DesignSystem.muted,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            _PreviousVersionsSection(
              record: freshRecord,
              provider: provider,
              template: template,
              brandBlack: brandBlack,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviousVersionsSection extends StatelessWidget {
  final MeasurementRecord record;
  final TemplateProvider provider;
  final ProductTemplate template;
  final Color brandBlack;

  const _PreviousVersionsSection({
    required this.record,
    required this.provider,
    required this.template,
    required this.brandBlack,
  });

  @override
  Widget build(BuildContext context) {
    final versions = provider
        .getMeasurementVersions(record.customerId, record.templateId)
        .where((v) => v.id != record.id)
        .toList();

    if (versions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Text(
          'PREVIOUS VERSIONS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: DesignSystem.muted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        ...versions.map((v) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: DesignSystem.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              title: Text(
                TailorFlowHelper.formatDate(v.date),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
              subtitle: Text(
                '${v.values.length} fields',
                style: TextStyle(color: DesignSystem.muted, fontSize: 11),
              ),
              trailing: Icon(Icons.chevron_right_rounded, color: DesignSystem.outlineVariant),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MeasurementViewScreen(record: v),
                  ),
                );
              },
            ),
          ),
        )),
      ],
    );
  }
}
