import 'package:flutter/material.dart';

import '../../core/utils/design_system.dart';
import '../../core/utils/responsive.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

// â”€â”€ AppSearchBar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class AppSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final bool showLoading;

  const AppSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.suffixIcon,
    this.showLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignSystem.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DesignSystem.radiusBtn),
        border: Border.all(color: DesignSystem.outlineVariant),
        boxShadow: DesignSystem.searchShadow,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(Icons.search_rounded, color: DesignSystem.muted, size: 20),
          suffixIcon: showLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DesignSystem.primaryContainer,
                    ),
                  ),
                )
              : suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          hintStyle: GoogleFonts.manrope(fontSize: 13, color: DesignSystem.muted),
        ),
      ),
    );
  }
}

// â”€â”€ AppDropdown â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class AppDropdown<T> extends StatefulWidget {
  final T? value;
  final List<DropdownMenuItem<T>>? items;
  final String? hint;
  final String? label;
  final ValueChanged<T?>? onChanged;
  final double? height;
  final IconData? prefixIcon;
  final String? errorText;
  final bool? enabled;

  const AppDropdown({
    super.key,
    this.value,
    this.items,
    this.hint,
    this.label,
    this.onChanged,
    this.height,
    this.prefixIcon,
    this.errorText,
    this.enabled,
  });

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.enabled == false;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final hasValue = widget.value != null;
    final hasPrefix = widget.prefixIcon != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDisabled ? DesignSystem.muted.withValues(alpha: 0.5) : DesignSystem.muted,
            ),
          ),
          const SizedBox(height: 6),
        ],
        DropdownButtonHideUnderline(
          child: DropdownButtonFormField<T>(
            initialValue: widget.value,
            items: widget.items,
            onChanged: isDisabled ? null : widget.onChanged,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: hasPrefix
                  ? Icon(widget.prefixIcon, size: 20, color: DesignSystem.muted)
                  : null,
              filled: true,
              fillColor: isDisabled ? const Color(0xFFF1F3F5) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError ? const Color(0xFFD32F2F) : DesignSystem.outlineVariant,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError ? const Color(0xFFD32F2F) : DesignSystem.outlineVariant,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError ? const Color(0xFFD32F2F) : const Color(0xFFE67E22),
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: hasPrefix ? 44 : 16,
                vertical: 12,
              ),
              hintStyle: GoogleFonts.manrope(fontSize: 13, color: DesignSystem.muted),
            ),
            dropdownColor: Colors.white,
            icon: Icon(
              Icons.expand_more_rounded,
              color: hasError
                  ? const Color(0xFFD32F2F)
                  : DesignSystem.muted,
              size: 20,
            ),
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
              color: hasValue ? DesignSystem.charcoal : DesignSystem.muted,
            ),
            isExpanded: true,
            borderRadius: BorderRadius.circular(12),
            menuMaxHeight: 300,
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.errorText!,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFD32F2F),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// â”€â”€ AppFilterChip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final int? count;
  final Color? selectedColor;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.onTap,
    this.count,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: R.value(context, regular: 14, smallPhone: 12),
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? (selectedColor ?? DesignSystem.primaryContainer) : DesignSystem.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
          border: Border.all(
            color: isSelected ? (selectedColor ?? DesignSystem.primaryContainer) : DesignSystem.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? DesignSystem.surfaceContainerLowest : DesignSystem.charcoal,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? DesignSystem.surfaceContainerLowest.withValues(alpha: 0.2)
                      : DesignSystem.surface,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                ),
                child: Text(
                  count.toString(),
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? DesignSystem.surfaceContainerLowest : DesignSystem.muted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// â”€â”€ AppCardContainer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class AppCardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  const AppCardContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? EdgeInsets.all(R.cardPadding(context)),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
        border: Border.all(color: borderColor ?? DesignSystem.outlineVariant),
        boxShadow: boxShadow ?? DesignSystem.cardShadow,
      ),
      child: child,
    );
    if (onTap != null) {
      return Padding(
        padding: margin ?? EdgeInsets.only(bottom: R.gap(context)),
        child: GestureDetector(onTap: onTap, child: card),
      );
    }
    return Padding(
      padding: margin ?? EdgeInsets.only(bottom: R.gap(context)),
      child: card,
    );
  }
}

// â”€â”€ ErrorStateWidget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorStateWidget({
    super.key,
    this.title = 'Something went wrong',
    this.subtitle = 'Please check your connection and try again',
    this.onRetry,
    this.icon = Icons.cloud_off_rounded,
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
                color: DesignSystem.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: R.value(context, regular: 48, smallPhone: 40),
                color: DesignSystem.error,
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
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
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
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// â”€â”€ ShimmerCardLoader â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class ShimmerCardLoader extends StatefulWidget {
  final double height;
  final int count;
  final double borderRadius;

  const ShimmerCardLoader({
    super.key,
    this.height = 120,
    this.count = 4,
    this.borderRadius = 16,
  });

  @override
  State<ShimmerCardLoader> createState() => _ShimmerCardLoaderState();
}

class _ShimmerCardLoaderState extends State<ShimmerCardLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          children: List.generate(widget.count, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: index < widget.count - 1 ? 12 : 0),
              child: _ShimmerCard(
                height: widget.height,
                borderRadius: widget.borderRadius,
                animation: _controller,
              ),
            );
          }),
        );
      },
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final double height;
  final double borderRadius;
  final AnimationController animation;

  const _ShimmerCard({
    required this.height,
    required this.borderRadius,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: DesignSystem.surfaceContainerLowest,
        border: Border.all(color: DesignSystem.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 1),
        child: ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFF0F0F0),
                Color(0xFFE8E8E8),
                Color(0xFFF0F0F0),
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: GradientRotation(animation.value * 2 * math.pi),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcOver,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 80,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€ LoadingSection (for whole section loading) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class LoadingSection extends StatelessWidget {
  final int cardCount;
  final double cardHeight;

  const LoadingSection({
    super.key,
    this.cardCount = 3,
    this.cardHeight = 120,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerCardLoader(count: cardCount, height: cardHeight);
  }
}

// â”€â”€ SectionHeader â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final IconData? icon;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: R.gap(context)),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: DesignSystem.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 14, color: DesignSystem.primaryContainer),
            ),
            const SizedBox(width: 8),
          ],
          Text(title, style: DesignSystem.sectionTitle),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

// â”€â”€ StatusBadge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignSystem.radiusSm),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
