// ════════════════════════════════════════════════════════════════════════
// PouliVet — Live System
// File: atoms/trend_arrow.dart
// Step: 5 of 14
//
// THE SECOND REUSABLE ATOM.
//
// Purpose: A small ↑ ↓ → indicator with semantically-correct colors.
//
// THE KEY INSIGHT — risk vs. neutral semantics:
//   For most data (revenue, profit, performance): up = green = good.
//   For RISK data: up = red = bad (risk is growing — alarm!).
//
//   Default behavior here is RISK semantic (because most of PouliVet's
//   numbers are risk-related). When trending an indicator like a stock
//   chart, pass TrendSemantic.neutral instead.
//
// Variants:
//   • Bare arrow + delta text — for compact rows (Top 5, dense legends)
//   • Pill-wrapped with soft tinted background — for emphasis (trajectory legend)
//
// Threshold-awareness:
//   Tiny deltas (e.g. NDVI shifting by 0.0001) shouldn't trigger fake
//   "up" signals. The atom takes a `flatThreshold` — deltas inside this
//   range render as "→" (flat) regardless of sign.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../pulse_theme.dart';

/// Which semantic meaning should the arrow colors carry?
enum TrendSemantic {
  /// Up = bad = red. Down = good = green. Use for risk-related data.
  risk,

  /// Up = good = green. Down = bad = red. Use for performance/value data.
  neutral,
}

/// Visual style of the arrow.
enum TrendArrowStyle {
  /// Just the arrow + delta text, no background.
  bare,

  /// Wrapped in a soft-tinted pill (emphasized).
  pill,
}

/// A semantic-aware trend arrow with optional delta value.
///
/// Example:
/// ```dart
/// TrendArrow(
///   delta: -2.3,
///   semantic: TrendSemantic.risk,    // negative = green (risk dropped)
///   style: TrendArrowStyle.pill,
///   precision: 1,
/// )
/// ```
class TrendArrow extends StatelessWidget {
  /// Signed change from previous value.
  final double delta;

  /// Risk semantic (up = bad) or neutral (up = good).
  final TrendSemantic semantic;

  /// Visual style — bare arrow or pill.
  final TrendArrowStyle style;

  /// Decimal places for the delta value. 0 for counts, 1-2 for ratios.
  final int precision;

  /// Deltas smaller than this (in absolute value) render as "flat" (→).
  /// Prevents noise from triggering fake trend signals.
  final double flatThreshold;

  /// Whether to show the delta value next to the arrow.
  /// If false, only the arrow renders.
  final bool showValue;

  /// Font size for the arrow + value text.
  final double fontSize;

  const TrendArrow({
    super.key,
    required this.delta,
    this.semantic = TrendSemantic.risk,
    this.style = TrendArrowStyle.bare,
    this.precision = 0,
    this.flatThreshold = 0.5,
    this.showValue = true,
    this.fontSize = 13,
  });

  /// Resolve direction (up/down/flat) using the threshold.
  _Direction get _direction {
    if (delta.abs() < flatThreshold) return _Direction.flat;
    return delta > 0 ? _Direction.up : _Direction.down;
  }

  /// Resolve color based on direction + semantic.
  Color get _color {
    return switch (_direction) {
      _Direction.up => semantic == TrendSemantic.risk
          ? PulseTheme.riskHigh // risk grew → red
          : PulseTheme.riskLow, // value grew → green
      _Direction.down => semantic == TrendSemantic.risk
          ? PulseTheme.riskLow // risk shrank → green
          : PulseTheme.riskHigh, // value shrank → red
      _Direction.flat => PulseTheme.grey,
    };
  }

  /// Soft background tint for the pill style — same color as text, very faded.
  Color get _pillBackground {
    if (_direction == _Direction.flat) return PulseTheme.greyPale;
    final base = _color;
    return base.withOpacity(0.12);
  }

  /// The arrow character.
  String get _arrow {
    return switch (_direction) {
      _Direction.up => '↑',
      _Direction.down => '↓',
      _Direction.flat => '→',
    };
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _color;
    final deltaAbs = delta.abs();

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _arrow,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: textColor,
            height: 1.0,
          ),
        ),
        if (showValue) ...[
          const SizedBox(width: 2),
          Text(
            deltaAbs.toStringAsFixed(precision),
            style: TextStyle(
              fontSize: fontSize - 1,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.0,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );

    if (style == TrendArrowStyle.bare) return content;

    // Pill style — soft tinted background, rounded
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: _pillBackground,
        borderRadius: BorderRadius.circular(100),
      ),
      child: content,
    );
  }
}

/// Internal direction enum for cleaner switch logic.
enum _Direction { up, down, flat }
