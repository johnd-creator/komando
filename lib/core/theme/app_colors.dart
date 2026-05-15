import 'package:flutter/material.dart';

/// Central color token system for 1Komando.
/// Use these constants instead of inline Color(0xFF...) literals.
///
/// Migration: replace Color(0xFF...) literals with AppColors.xxx.
/// Visual output must remain identical — tokens replicate existing colors.
class AppColors {
  const AppColors._();

  // ─── Primary ──────────────────────────────────────────────────────────────
  /// Main brand blue — buttons, headers, active states
  static const Color primary = Color(0xFF1565C0);

  /// Lighter brand blue — gradients, hover states
  static const Color primaryLight = Color(0xFF1E88E5);

  /// Darker brand blue — pressed states, deep gradients
  static const Color primaryDark = Color(0xFF0D47A1);

  // ─── Status ───────────────────────────────────────────────────────────────
  /// Success / paid / approved
  static const Color success = Color(0xFF22C55E);

  /// Warning / pending / unpaid
  static const Color warning = Color(0xFFF97316);

  /// Error / rejected / overdue
  static const Color error = Color(0xFFEF4444);

  /// Info / submitted / in-progress
  static const Color info = Color(0xFF3B82F6);

  // ─── Surface ──────────────────────────────────────────────────────────────
  /// Default scaffold background
  static const Color surface = Color(0xFFF5F7FA);

  /// Alternate surface (cards, panels)
  static const Color surfaceAlt = Color(0xFFF7F9FC);

  /// Card / container background
  static const Color cardBackground = Colors.white;

  // ─── Border & Divider ─────────────────────────────────────────────────────
  /// Default border color
  static const Color border = Color(0xFFE1E8F2);

  /// Tab / divider color
  static const Color divider = Color(0xFFE3EBF8);

  // ─── Text ─────────────────────────────────────────────────────────────────
  /// Primary text — headings, important content
  static const Color textPrimary = Color(0xFF1A1A2E);

  /// Secondary text — labels, captions
  static const Color textSecondary = Color(0xFF536683);

  /// Muted text — hints, placeholders, timestamps
  static const Color textMuted = Color(0xFF64748B);

  // ─── Gradients ────────────────────────────────────────────────────────────
  /// Standard primary gradient (top-left → bottom-right)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  /// Success gradient
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
  );

  /// Warning gradient
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
  );
}
