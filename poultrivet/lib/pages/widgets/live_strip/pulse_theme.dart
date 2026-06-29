// ════════════════════════════════════════════════════════════════════════
// PouliVet — Live System
// File: pulse_theme.dart
// Step: 1 of 14
//
// Purpose: The foundation. ALL colors, durations, and animation curves
//          used by every live widget on the Stats screen live here.
//          Change something once, it propagates everywhere.
//
// Philosophy: There are 10 colors on this screen — no more, no less.
//   • 3 risk-semantic colors (red/amber/green — universal danger/warning/safe)
//   • 4 indicator colors (the 4 environmental indicators)
//   • 3 disease colors (categorical, muted, calm — for the trajectory chart)
//
// Every other design decision (timings, curves, sizes) is also centralised
// here so the live system feels cohesive — like one engine breathing.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

/// The PouliVet live-system palette. 10 colors, each with a role.
class PulseTheme {
  PulseTheme._(); // Pure static class — never instantiated.

  // ─── RISK SEMANTIC (red/amber/green) ──────────────────────────────
  // Used wherever risk severity needs immediate visual reading.
  // Universal cultural meaning: red = danger, amber = warn, green = safe.
  static const Color riskHigh = Color(0xFFE74C3C); // urgent
  static const Color riskMedium = Color(0xFFF39C12); // caution
  static const Color riskLow = Color(0xFF2ECC71); // safe

  // Soft tints for backgrounds, fills, and pill bg's
  static const Color riskHighSoft = Color(0xFFFBE0DC);
  static const Color riskMediumSoft = Color(0xFFFBF1D0);
  static const Color riskLowSoft = Color(0xFFD8F3DC);

  // ─── ENVIRONMENTAL INDICATOR PALETTE ──────────────────────────────
  // Used ONLY in the Live Indicator Strip. Each indicator has its own
  // semantic color (vegetation → green, moisture → blue, etc).
  // Full 5-tone palettes live in indicator_data.dart.
  static const Color vegetationStrong = Color(0xFF2D6A4F);
  static const Color moistureStrong = Color(0xFF0369A1);
  static const Color temperatureStrong = Color(0xFFC28100);
  static const Color waterStrong = Color(0xFF0F8B8D);

  // ─── DISEASE CATEGORICAL PALETTE ──────────────────────────────────
  // Used in the Combined Trajectory chart. Muted earth tones so the
  // HIGH Risk red can be the visual hero. These are categorical — no
  // "good/bad" semantics, just identity colors per disease.
  static const Color diseaseNewcastle = Color(0xFF7C5295); // muted purple-grey
  static const Color diseaseCoccidiosis =
      Color(0xFFA0522D); // sienna earth brown
  static const Color diseaseSalmonella = Color(0xFF2C7DA0); // steel blue

  // ─── NEUTRALS ─────────────────────────────────────────────────────
  static const Color ink = Color(0xFF1A2E22);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color grey = Color(0xFF566B5C);
  static const Color greyPale = Color(0xFFE5EAE6);
  static const Color greyPale2 = Color(0xFFF0F2F0);
  static const Color cream = Color(0xFFFAF7F0);
  static const Color gold = Color(0xFFD4A017);
  static const Color forest = Color(0xFF1B4332);
  static const Color sage = Color(0xFF52B788);

  // ═════════════════════════════════════════════════════════════════
  // ANIMATION TIMINGS — every duration the live system uses
  // Centralised so the whole screen feels rhythmically coherent
  // ═════════════════════════════════════════════════════════════════

  /// How often the indicator strip ticks — fast, because env. conditions
  /// feel like they're sampling continuously.
  static const Duration pulseStripTick = Duration(seconds: 3);

  /// Trajectory chart — slightly slower (daily-scale data feels less frantic).
  static const Duration pulseTrendTick = Duration(seconds: 4);

  /// Regional pulse + Top 5 — slowest (district reclassifications are rare).
  static const Duration pulseRegionalTick = Duration(milliseconds: 4500);
  static const Duration pulseTopTick = Duration(seconds: 5);

  /// Number count-up tween duration.
  static const Duration numberTween = Duration(milliseconds: 600);

  /// Bar width animation when values shift.
  static const Duration barWidth = Duration(milliseconds: 800);

  /// Continuous shimmer sweep cycle.
  static const Duration shimmerSweep = Duration(milliseconds: 3500);

  /// Pulsing dot cycle (general).
  static const Duration dotPulse = Duration(milliseconds: 1500);

  /// Pulsing dot cycle (HIGH severity — slightly slower, more deliberate
  /// "this matters" feel).
  static const Duration dotPulseHigh = Duration(milliseconds: 1600);

  // ═════════════════════════════════════════════════════════════════
  // ANIMATION CURVES — the personality of motion
  // ═════════════════════════════════════════════════════════════════

  /// Numbers counting up — fast start, slow finish (anticipation).
  static const Curve countUp = Curves.easeOutCubic;

  /// Bar width transitions — smooth material-y deceleration.
  static const Curve barTransition = Curves.easeInOutCubic;

  /// Reorder animation in Top 5 — smooth ease-out.
  static const Curve reorder = Curves.easeOutQuart;

  // ═════════════════════════════════════════════════════════════════
  // SIZE TOKENS — keep proportions consistent across widgets
  // ═════════════════════════════════════════════════════════════════

  static const double cardRadius = 20;
  static const double cardPadding = 20;
  static const double cardShadowBlur = 10;
  static const double dotSize = 8;
  static const double barHeight = 10;
  static const double barRadius = 100;
  static const double sectionGap = 16;

  /// The standard card shadow used by every live card.
  static List<BoxShadow> cardShadow() => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: cardShadowBlur,
          offset: const Offset(0, 4),
        ),
      ];
}
