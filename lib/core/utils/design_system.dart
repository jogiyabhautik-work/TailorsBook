import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'responsive.dart';

class DesignSystem {
  // ── Stitch Color Palette ─────────────────────────────────────────────────
  static const Color primary = Color(0xFFC0641A);
  static const Color primaryContainer = Color(0xFFE67E22);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color outlineVariant = Color(0xFFEBEBEB);
  static const Color secondary = Color(0xFF8A8A8A);
  static const Color tertiaryContainer = Color(0xFF4CAF50);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorContainer = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningContainer = Color(0xFFFFF3E0);
  static const Color info = Color(0xFF2196F3);
  static const Color infoContainer = Color(0xFFE3F2FD);
  
  // Legacy aliases for backward compatibility
  static const Color orange = primaryContainer;
  static const Color orangeLight = Color(0xFFFFF3E8);
  static const Color primaryLight = orangeLight;
  static const Color orangeDark = primary;
  static const Color charcoal = Color(0xFF1C1C1C);
  static const Color creamBg = surface;
  static const Color white = surfaceContainerLowest;
  static const Color muted = secondary;
  static const Color inactiveIcon = Color(0xFF666666);
  static const Color border = outlineVariant;
  static const Color success = tertiaryContainer;

  // ── Spacing System (4px base — Stitch grid) ──────────────────────────────
  static const double gridMargin = 20;
  static const double gridGutter = 12;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  
  // Fine-grained spacing
  static const double s2 = 2;
  static const double s3 = 3;
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s14 = 14;
  static const double s16 = 16;
  static const double s18 = 18;
  static const double s20 = 20;
  static const double s22 = 22;
  static const double s24 = 24;
  static const double s28 = 28;
  static const double s32 = 32;
  static const double s36 = 36;
  static const double s40 = 40;
  static const double s48 = 48;
  static const double s56 = 56;
  static const double s64 = 64;
  static const double s80 = 80;
  static const double s100 = 100;
  static const double s120 = 120;

  // ── Corner Radii ─────────────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusXxl = 24;
  static const double radiusBtn = 14;
  static const double radiusPill = 28;
  static const double radiusFull = 9999;

  // ── Card Elevation / Shadow (Stitch soft shadows) ────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: primaryContainer.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get pillShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get searchShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  // ── Typography (Manrope — Stitch scale) ──────────────────────────────────
  static TextStyle get pageTitle => GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: charcoal,
      );

  static TextStyle get sectionTitle => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: secondary,
      );

  static TextStyle get cardTitle => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: charcoal,
      );

  static TextStyle get bodyText => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: charcoal,
      );

  static TextStyle get caption => GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: secondary,
      );

  static TextStyle get badgeText => GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      );

  static TextStyle get buttonText => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get greetingText => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: secondary,
      );

  static TextStyle get statValue => GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: charcoal,
      );

  static TextStyle get statLabel => GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: secondary,
      );

  // ── Decorations ──────────────────────────────────────────────────────────
  static BoxDecoration get card => BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: outlineVariant),
        boxShadow: cardShadow,
      );

  static BoxDecoration get cardElevated => BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radiusXl),
        boxShadow: elevatedShadow,
      );

  static BoxDecoration get cardSoft => BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radiusXl),
        boxShadow: softShadow,
      );

  static BoxDecoration get glassCard => BoxDecoration(
        color: surfaceContainerLowest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(radiusXl),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.5)),
        boxShadow: cardShadow,
      );

  static BoxDecoration badgeDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radiusSm),
      );

  static TextStyle badgeStyle(Color color) => GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
        color: color,
      );

  static BoxDecoration chipDecoration({bool isActive = false, Color color = primaryContainer}) => BoxDecoration(
        color: isActive ? color : surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radiusPill),
        border: Border.all(color: isActive ? color : outlineVariant, width: 1.5),
      );

  static TextStyle chipStyle({bool isActive = false}) => GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isActive ? surfaceContainerLowest : charcoal,
      );

  static BoxDecoration get pillChipActive => BoxDecoration(
        color: primaryContainer,
        borderRadius: BorderRadius.circular(radiusPill),
      );

  static BoxDecoration get pillChipInactive => BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radiusPill),
        border: Border.all(color: outlineVariant),
      );

  static BoxDecoration get pillNavDecoration => BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radiusFull),
        boxShadow: pillShadow,
        border: Border.all(color: outlineVariant.withValues(alpha: 0.3)),
      );

  // ── Button Styles ────────────────────────────────────────────────────────
  static ButtonStyle primaryButton(Color bg) => ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: surfaceContainerLowest,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: s14, horizontal: s24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusBtn),
        ),
        textStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      );

  static ButtonStyle get secondaryButton => OutlinedButton.styleFrom(
        foregroundColor: charcoal,
        side: const BorderSide(color: outlineVariant),
        padding: const EdgeInsets.symmetric(vertical: s14, horizontal: s24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusBtn),
        ),
        textStyle: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );

  static ButtonStyle get fabButton => ElevatedButton.styleFrom(
        backgroundColor: primaryContainer,
        foregroundColor: surfaceContainerLowest,
        elevation: 4,
        padding: const EdgeInsets.all(s16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        shadowColor: primaryContainer.withValues(alpha: 0.3),
      );

  // ── Input Decoration ─────────────────────────────────────────────────────
  static InputDecoration inputField({
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? label,
  }) =>
      InputDecoration(
        hintText: hint,
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: s20, color: secondary) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: s16,
          vertical: s14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusBtn),
          borderSide: BorderSide(color: outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusBtn),
          borderSide: BorderSide(color: outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusBtn),
          borderSide: BorderSide(
            color: primaryContainer,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusBtn),
          borderSide: BorderSide(color: error.withValues(alpha: 0.5)),
        ),
        hintStyle: GoogleFonts.manrope(
          fontSize: 13,
          color: secondary,
        ),
        labelStyle: GoogleFonts.manrope(
          fontSize: 13,
          color: secondary,
        ),
      );

  static InputDecoration searchDecoration({
    String? hint,
    Widget? suffixIcon,
  }) =>
      InputDecoration(
        hintText: hint ?? 'Search',
        prefixIcon: Icon(Icons.search_rounded, color: secondary, size: s20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: s16,
          vertical: s12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusBtn),
          borderSide: BorderSide(color: outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusBtn),
          borderSide: BorderSide(color: outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusBtn),
          borderSide: BorderSide(color: primaryContainer, width: 1.5),
        ),
        hintStyle: GoogleFonts.manrope(
          fontSize: 13,
          color: secondary,
        ),
      );

  static InputDecoration dropdownDecoration({
    String? label,
    Widget? suffixIcon,
  }) =>
        InputDecoration(
          labelText: label,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: surfaceContainerLowest,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: s16,
            vertical: s14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: BorderSide(color: outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: BorderSide(color: outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: BorderSide(color: primaryContainer, width: 1.5),
          ),
          labelStyle: GoogleFonts.manrope(
            fontSize: 13,
            color: secondary,
          ),
        );

  /// Calculates bottom padding so scrollable content clears the floating nav bar.
  /// Uses centralized responsive helpers for consistency.
  static double bottomNavSafePadding(BuildContext context) {
    return navBarSafeBottom(context);
  }
}
