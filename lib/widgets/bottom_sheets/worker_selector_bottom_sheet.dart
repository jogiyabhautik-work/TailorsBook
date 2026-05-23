import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/design_system.dart';
import '../../models/worker_model.dart';
import '../../providers/order_provider.dart';
import '../common/responsive_widgets.dart';

/// Bottom sheet worker selector for mobile-friendly worker assignment.
/// Replaces the problematic DropdownButton that opens over the field.
class WorkerSelectorBottomSheet {
  static Future<String?> show({
    required BuildContext context,
    required List<WorkerModel> workers,
    required List<WorkerModel> activeWorkers,
    required OrderProvider orderProvider,
    String? currentValue,
  }) async {
    return showKeyboardSafeModalBottomSheet<String>(
      context: context,
      builder: (ctx) => _WorkerSelectorSheet(
        workers: workers,
        activeWorkers: activeWorkers,
        orderProvider: orderProvider,
        currentValue: currentValue,
      ),
    );
  }
}

class _WorkerSelectorSheet extends StatelessWidget {
  final List<WorkerModel> workers;
  final List<WorkerModel> activeWorkers;
  final OrderProvider orderProvider;
  final String? currentValue;

  const _WorkerSelectorSheet({
    required this.workers,
    required this.activeWorkers,
    required this.orderProvider,
    this.currentValue,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: DesignSystem.surfaceContainerLowest,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DesignSystem.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DesignSystem.primaryContainer.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.engineering_rounded,
                        size: 18,
                        color: DesignSystem.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Assign Worker',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: DesignSystem.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: DesignSystem.outlineVariant),
              // Worker list
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.only(bottom: keyboardHeight > 0 ? keyboardHeight : 16),
                  children: [
                    // Unassigned option
                    _WorkerOption(
                      name: 'Unassigned',
                      subtitle: 'No worker assigned',
                      icon: Icons.person_off_rounded,
                      iconColor: Colors.orange,
                      isSelected: currentValue == null,
                      onTap: () => Navigator.pop(context, '__unassigned__'),
                    ),
                    const SizedBox(height: 8),
                    // Active workers
                    if (activeWorkers.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                        child: Text(
                          'ACTIVE WORKERS',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: DesignSystem.muted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      ...activeWorkers.map((w) {
                        final activeCount = orderProvider.activeOrderCountForWorker(w.id);
                        return _WorkerOption(
                          name: w.name,
                          subtitle: activeCount > 0 ? '$activeCount active orders' : 'Available',
                          icon: Icons.engineering_rounded,
                          iconColor: DesignSystem.primaryContainer,
                          isSelected: currentValue == w.id,
                          warningBadge: activeCount >= 5 ? '$activeCount' : null,
                          onTap: () => Navigator.pop(context, w.id),
                        );
                      }),
                    ],
                    // Inactive workers
                    if (workers.any((w) => !w.isActive)) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                        child: Text(
                          'INACTIVE WORKERS',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: DesignSystem.muted.withValues(alpha: 0.6),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      ...workers.where((w) => !w.isActive).map((w) {
                        return _WorkerOption(
                          name: w.name,
                          subtitle: 'Inactive',
                          icon: Icons.engineering_rounded,
                          iconColor: DesignSystem.muted.withValues(alpha: 0.4),
                          isSelected: false,
                          disabled: true,
                          onTap: () {},
                        );
                      }),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WorkerOption extends StatelessWidget {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final String? warningBadge;
  final bool disabled;
  final VoidCallback onTap;

  const _WorkerOption({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    this.warningBadge,
    this.disabled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? DesignSystem.primaryContainer.withValues(alpha: 0.08)
              : (disabled ? DesignSystem.surface.withValues(alpha: 0.5) : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? DesignSystem.primaryContainer.withValues(alpha: 0.3)
                : (disabled ? Colors.transparent : DesignSystem.outlineVariant),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: disabled
                          ? DesignSystem.muted.withValues(alpha: 0.5)
                          : DesignSystem.charcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: DesignSystem.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (warningBadge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '\u26A0\uFE0F $warningBadge',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade600,
                  ),
                ),
              ),
            ],
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: DesignSystem.primaryContainer,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
