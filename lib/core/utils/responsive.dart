import 'package:flutter/material.dart';

// ── Breakpoints ─────────────────────────────────────────────────────────────
class Breakpoints {
  static const double smallPhone = 360;
  static const double regularPhone = 480;
  static const double largePhone = 600;
  static const double tablet = 900;

  static bool isSmallPhone(BuildContext context) => screenWidth(context) < smallPhone;
  static bool isRegularPhone(BuildContext context) =>
      screenWidth(context) >= smallPhone && screenWidth(context) < regularPhone;
  static bool isLargePhone(BuildContext context) =>
      screenWidth(context) >= regularPhone && screenWidth(context) < largePhone;
  static bool isTablet(BuildContext context) =>
      screenWidth(context) >= largePhone && screenWidth(context) < tablet;
  static bool isLargeTablet(BuildContext context) => screenWidth(context) >= tablet;

  static bool isPhone(BuildContext context) => screenWidth(context) < largePhone;
  static bool isTabletOrWider(BuildContext context) => screenWidth(context) >= largePhone;
}

// ── Width / Height ──────────────────────────────────────────────────────────
double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;
double bottomInset(BuildContext context) => MediaQuery.of(context).viewInsets.bottom;
double topInset(BuildContext context) => MediaQuery.of(context).viewInsets.top;
double bottomPadding(BuildContext context) => MediaQuery.of(context).padding.bottom;
double topPadding(BuildContext context) => MediaQuery.of(context).padding.top;

// ── Nav Bar & Safe Area Helpers ─────────────────────────────────────────────
/// Height of the floating pill navigation bar (72px container + 8px bottom gap)
const double kNavBarHeight = 72.0;
const double kNavBarBottomGap = 8.0;
const double kNavBarTotalHeight = kNavBarHeight + kNavBarBottomGap; // 80px

/// Minimum bottom padding to prevent tiny overflow (3px) issues.
const double kMinBottomPadding = 8.0;

/// System top padding (status bar, notch).
double topSafePadding(BuildContext context) => MediaQuery.of(context).padding.top;

/// System bottom padding (gesture nav, nav bar).
double bottomSafePadding(BuildContext context) => MediaQuery.of(context).padding.bottom;

/// Keyboard inset (0 when keyboard is closed).
double keyboardInset(BuildContext context) => MediaQuery.of(context).viewInsets.bottom;

/// Returns true if the keyboard is currently visible.
bool isKeyboardOpen(BuildContext context) => keyboardInset(context) > 0;

/// Total bottom space needed to clear the floating nav bar + system insets.
/// Use as bottom padding for scrollable content inside tab screens.
double navBarSafeBottom(BuildContext context) {
  return bottomSafePadding(context) + kNavBarTotalHeight;
}

/// Effective bottom padding — clears nav bar when keyboard is closed,
/// returns keyboard inset when keyboard is open (so content scrolls above keyboard).
double effectiveBottomPadding(BuildContext context) {
  if (isKeyboardOpen(context)) {
    return keyboardInset(context) + kMinBottomPadding;
  }
  return navBarSafeBottom(context) + kMinBottomPadding;
}

/// Extra bottom padding for full-screen pages pushed via Navigator
/// (screens that don't have the floating nav bar).
double screenBottomPadding(BuildContext context) {
  return bottomSafePadding(context) + kMinBottomPadding;
}

/// Bottom padding for dialogs to respect keyboard and system UI.
double dialogBottomPadding(BuildContext context) {
  if (isKeyboardOpen(context)) {
    return keyboardInset(context) + kMinBottomPadding;
  }
  return bottomSafePadding(context) + kMinBottomPadding;
}

/// Combined top padding for custom app bars (status bar + optional extra).
double appBarTopPadding(BuildContext context, {double extra = 12}) {
  return topSafePadding(context) + extra;
}

// ── Responsive Spacing ──────────────────────────────────────────────────────
double hp(BuildContext context, double value) => screenWidth(context) * value;
double vp(BuildContext context, double value) => screenHeight(context) * value;

class R {
  /// Returns a value based on screen size: [smallPhone], [regular], [largePhone], [tablet], [largeTablet]
  static T value<T>(BuildContext context, {
    required T regular,
    T? smallPhone,
    T? largePhone,
    T? tablet,
    T? largeTablet,
  }) {
    final w = screenWidth(context);
    if (w < Breakpoints.smallPhone) return smallPhone ?? regular;
    if (w < Breakpoints.regularPhone) return regular;
    if (w < Breakpoints.largePhone) return largePhone ?? regular;
    if (w < Breakpoints.tablet) return tablet ?? largePhone ?? regular;
    return largeTablet ?? tablet ?? largePhone ?? regular;
  }

  /// Horizontal page padding (body margin)
  static double pagePadding(BuildContext context) =>
      R.value(context, regular: 20, smallPhone: 16, tablet: 32, largeTablet: 48);

  /// Card padding inside
  static double cardPadding(BuildContext context) =>
      R.value(context, regular: 16, smallPhone: 12, tablet: 20);

  /// Gap between widgets in a section
  static double gap(BuildContext context) =>
      R.value(context, regular: 12, smallPhone: 8, tablet: 16);

  /// Gap between sections
  static double sectionGap(BuildContext context) =>
      R.value(context, regular: 24, smallPhone: 16, tablet: 32);

  /// Avatar / icon size
  static double avatarRadius(BuildContext context) =>
      R.value(context, regular: 22, smallPhone: 18, tablet: 26);
}

// ── Responsive Grid Helpers ─────────────────────────────────────────────────
class GridCount {
  static int columns(BuildContext context) {
    final w = screenWidth(context);
    if (w < 480) return 1;
    if (w < 600) return 2;
    if (w < 900) return 2;
    return 3;
  }
}

// ── Responsive Max Width Container ──────────────────────────────────────────
class ConstrainedContent extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  const ConstrainedContent({super.key, required this.child, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: maxWidth ?? R.value(context, regular: double.infinity, tablet: 720, largeTablet: 900),
        child: child,
      ),
    );
  }
}
