import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/design_system.dart';
import '../../core/utils/responsive.dart';

enum WorkModeChoice { selfStitch, assignWorker }

class SelectWorkModeDialog extends StatefulWidget {
  final Function(WorkModeChoice) onSelected;
  final bool allowClose;

  const SelectWorkModeDialog({
    super.key,
    required this.onSelected,
    this.allowClose = true,
  });

  @override
  State<SelectWorkModeDialog> createState() => _SelectWorkModeDialogState();
}

class _SelectWorkModeDialogState extends State<SelectWorkModeDialog> {
  WorkModeChoice? _selectedMode;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radiusLg)),
      backgroundColor: DesignSystem.surfaceContainerLowest,
      child: Padding(
        padding: EdgeInsets.all(R.cardPadding(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('How will you handle this order?', style: DesignSystem.cardTitle),
                      const SizedBox(height: DesignSystem.s4),
                      Text('Choose who will stitch this order', style: DesignSystem.caption),
                    ],
                  ),
                ),
                if (widget.allowClose)
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close_rounded, color: DesignSystem.secondary, size: 24),
                  ),
              ],
            ),
            const SizedBox(height: DesignSystem.lg),

            // Self-Stitch Option
            _workModeOption(
              title: 'I will stitch this order',
              subtitle: 'You\'ll handle the stitching yourself',
              icon: Icons.person_rounded,
              description: 'Full control • No worker assignment • All actions in Order Detail',
              isSelected: _selectedMode == WorkModeChoice.selfStitch,
              onTap: () => setState(() => _selectedMode = WorkModeChoice.selfStitch),
            ),

            const SizedBox(height: DesignSystem.md),

            // Assign Worker Option
            _workModeOption(
              title: 'Assign to a worker',
              subtitle: 'Worker will handle the stitching',
              icon: Icons.group_rounded,
              description: 'Set rates • Track worker progress • Receive when done',
              isSelected: _selectedMode == WorkModeChoice.assignWorker,
              onTap: () => setState(() => _selectedMode = WorkModeChoice.assignWorker),
            ),

            const SizedBox(height: DesignSystem.lg),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.allowClose ? () => Navigator.pop(context) : null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: DesignSystem.outlineVariant),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignSystem.radiusBtn),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: DesignSystem.secondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DesignSystem.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedMode == null
                        ? null
                        : () {
                            widget.onSelected(_selectedMode!);
                            Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignSystem.primaryContainer,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignSystem.radiusBtn),
                      ),
                      disabledBackgroundColor: DesignSystem.muted.withValues(alpha: 0.5),
                    ),
                    child: Text(
                      'Confirm',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _workModeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? DesignSystem.primaryContainer.withValues(alpha: 0.08) : DesignSystem.surface,
          borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
          border: Border.all(
            color: isSelected ? DesignSystem.primaryContainer : DesignSystem.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: EdgeInsets.all(R.cardPadding(context)),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? DesignSystem.primaryContainer.withValues(alpha: 0.15) : DesignSystem.surface,
                borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
              ),
              child: Icon(icon, color: DesignSystem.primaryContainer, size: 24),
            ),
            const SizedBox(width: DesignSystem.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: DesignSystem.cardTitle),
                  const SizedBox(height: DesignSystem.s2),
                  Text(subtitle, style: DesignSystem.caption),
                  const SizedBox(height: DesignSystem.s4),
                  Text(
                    description,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: DesignSystem.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignSystem.s12),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? DesignSystem.primaryContainer : DesignSystem.outlineVariant,
                  width: 2,
                ),
                color: isSelected ? DesignSystem.primaryContainer : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check_rounded, size: 14, color: DesignSystem.surfaceContainerLowest)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
