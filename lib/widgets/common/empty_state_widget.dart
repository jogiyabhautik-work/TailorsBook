import 'package:flutter/material.dart';

import '../../core/utils/design_system.dart';
import '../../core/utils/responsive.dart';
import 'package:google_fonts/google_fonts.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onRetry;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onRetry,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(R.value(context, regular: 32, smallPhone: 24, tablet: 48)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(R.value(context, regular: 20, smallPhone: 16)),
              decoration: BoxDecoration(
                color: DesignSystem.primaryContainer.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: R.value(context, regular: 48, smallPhone: 40),
                color: DesignSystem.primaryContainer,
              ),
            ),
            SizedBox(height: R.value(context, regular: 20, smallPhone: 16)),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: DesignSystem.charcoal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: DesignSystem.muted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null || (onAction != null && actionLabel != null)) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 44,
                child: onRetry != null
                    ? ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignSystem.primaryContainer,
                          foregroundColor: DesignSystem.surfaceContainerLowest,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DesignSystem.radiusBtn),
                          ),
                          textStyle: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: onAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignSystem.primaryContainer,
                          foregroundColor: DesignSystem.surfaceContainerLowest,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DesignSystem.radiusBtn),
                          ),
                          textStyle: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(actionLabel!),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
