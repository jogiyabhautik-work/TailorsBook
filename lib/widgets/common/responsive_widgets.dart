import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/design_system.dart';

/// Standardized app scaffold for full-screen pushed pages (not tab screens).
///
/// Handles SafeArea (top notch, bottom gesture area), keyboard insets,
/// and responsive padding automatically.
///
/// Use this instead of raw Scaffold for all push-navigated screens.
class ScreenScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool extendBodyBehindAppBar;
  final bool resizeToAvoidBottomInset;
  final bool safeTop;
  final bool safeBottom;
  final EdgeInsets? bodyPadding;

  const ScreenScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset = true,
    this.safeTop = true,
    this.safeBottom = true,
    this.bodyPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? DesignSystem.surface,
      appBar: appBar,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: SafeArea(
        top: safeTop,
        bottom: safeBottom,
        child: body,
      ),
    );
  }
}

/// Standardized app scaffold that handles SafeArea, bottom nav spacing,
/// keyboard handling, and responsive padding automatically.
///
/// Use this instead of raw Scaffold for all main screens.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool extendBodyBehindAppBar;
  final bool resizeToAvoidBottomInset;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? DesignSystem.surface,
      appBar: appBar,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: SafeArea(
        child: body,
      ),
    );
  }
}

/// Tab screen body wrapper that automatically adds bottom padding
/// to clear the floating navigation bar.
///
/// Use this as the root widget inside tab screens (HomeTab, OrdersTab, etc.)
/// that live inside the home_page.dart Stack layout.
class TabScreenBody extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const TabScreenBody({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = effectiveBottomPadding(context);
    return Padding(
      padding: padding ?? EdgeInsets.only(bottom: bottomPad),
      child: child,
    );
  }
}

/// Scrollable tab screen body with automatic bottom padding and keyboard handling.
/// Combines TabScreenBody with SingleChildScrollView.
class ScrollableTabBody extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final ScrollController? controller;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  const ScrollableTabBody({
    super.key,
    required this.child,
    this.padding,
    this.controller,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      keyboardDismissBehavior: keyboardDismissBehavior,
      padding: padding ?? EdgeInsets.fromLTRB(
        R.pagePadding(context),
        R.value(context, regular: 16, smallPhone: 12),
        R.pagePadding(context),
        effectiveBottomPadding(context),
      ),
      child: ConstrainedContent(child: child),
    );
  }
}

/// Responsive page body with consistent padding, scroll, and max-width.
class ResponsivePageBody extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool sliver;
  final ScrollController? scrollController;

  const ResponsivePageBody({
    super.key,
    required this.child,
    this.padding,
    this.sliver = false,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? EdgeInsets.all(R.pagePadding(context));
    if (sliver) {
      return SliverPadding(
        padding: effectivePadding,
        sliver: SliverToBoxAdapter(child: _content(context)),
      );
    }
    return Padding(padding: effectivePadding, child: _content(context));
  }

  Widget _content(BuildContext context) {
    return ConstrainedContent(child: child);
  }
}

/// Responsive card with consistent padding.
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? EdgeInsets.all(R.cardPadding(context)),
      decoration: DesignSystem.card,
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

/// Responsive section title with optional icon.
class ResponsiveSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;

  const ResponsiveSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
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
              child: Icon(icon, size: 16, color: DesignSystem.primaryContainer),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(title, style: DesignSystem.sectionTitle)),
          ?trailing,
        ],
      ),
    );
  }
}

/// Responsive empty state.
class ResponsiveEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;

  const ResponsiveEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onAction,
    this.actionLabel,
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
              child: Icon(icon, size: R.value(context, regular: 48, smallPhone: 40), color: DesignSystem.primaryContainer),
            ),
            SizedBox(height: R.value(context, regular: 20, smallPhone: 16)),
            Text(title, style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700, color: DesignSystem.charcoal), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: GoogleFonts.manrope(fontSize: 13, color: DesignSystem.muted, height: 1.4), textAlign: TextAlign.center),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignSystem.primaryContainer,
                    foregroundColor: DesignSystem.surfaceContainerLowest,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignSystem.radiusBtn),
                    ),
                    textStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700),
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

/// Responsive grid for cards (1 col phone, 2 col tablet).
class ResponsiveCardGrid extends StatelessWidget {
  final List<Widget> children;
  final double? childAspectRatio;

  const ResponsiveCardGrid({
    super.key,
    required this.children,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final cols = GridCount.columns(context);
    if (cols == 1) {
      return Column(children: children);
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: R.gap(context),
        mainAxisSpacing: R.gap(context),
        childAspectRatio: childAspectRatio ?? (cols == 2 ? 1.6 : 1.4),
      ),
      itemCount: children.length,
      itemBuilder: (_, i) => children[i],
    );
  }
}

class _KeyboardAwareDialog extends StatelessWidget {
  final Widget child;

  const _KeyboardAwareDialog({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: R.value(context, regular: 400, tablet: 500, largeTablet: 560).toDouble(),
      ),
      child: child,
    );
  }
}

class KeyboardSafeDialogScrollView extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final ScrollController? controller;

  const KeyboardSafeDialogScrollView({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: SingleChildScrollView(
        controller: controller,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: padding,
        child: child,
      ),
    );
  }
}

class KeyboardSafeDialog extends StatelessWidget {
  final Widget child;
  final EdgeInsets insetPadding;
  final double? maxWidth;
  final double maxHeightFactor;
  final ShapeBorder shape;

  const KeyboardSafeDialog({
    super.key,
    required this.child,
    this.insetPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    this.maxWidth,
    this.maxHeightFactor = 0.9,
    this.shape = const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: insetPadding,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? R.value(context, regular: 400, tablet: 520, largeTablet: 600),
          maxHeight: MediaQuery.of(context).size.height * maxHeightFactor,
        ),
        child: child,
      ),
    );
  }
}

class KeyboardSafeBottomSheet extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double maxHeightFactor;
  final Color backgroundColor;
  final BorderRadiusGeometry borderRadius;

  const KeyboardSafeBottomSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.maxHeightFactor = 0.9,
    this.backgroundColor = DesignSystem.white,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(30)),
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardHeight = media.viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: media.size.height * maxHeightFactor,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
          ),
          padding: padding.copyWith(bottom: padding.bottom + (keyboardHeight == 0 ? media.padding.bottom : 0)),
          child: child,
        ),
      ),
    );
  }
}

Future<T?> showKeyboardSafeModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    builder: builder,
  );
}

Future<T?> showResponsiveDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) {
      return _KeyboardAwareDialog(
        child: builder(ctx),
      );
    },
  );
}

class KeyboardAwareDialogContent extends StatelessWidget {
  final Widget child;

  const KeyboardAwareDialogContent({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Rely on Flutter's built-in dialog behavior instead of double-padding.
    return child;
  }
}
