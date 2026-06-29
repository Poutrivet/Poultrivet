// ════════════════════════════════════════════════════════════════════════
// PouliVet — Live Indicator Strip
// File: indicator_data.dart
// Purpose: Data models and indicator definitions (colors, thresholds, labels)
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

/// Defines the visual + behavioural identity of one indicator.
/// Every element in a card (number, line, dot, pill) draws from this palette.
class IndicatorTheme {
  final Color deep; // big number color
  final Color strong; // label + line color
  final Color mid; // status dot + area gradient color
  final Color pale; // trend pill background
  final Color cream; // card background tint

  const IndicatorTheme({
    required this.deep,
    required this.strong,
    required this.mid,
    required this.pale,
    required this.cream,
  });
}

/// Thresholds for status labelling (e.g. "Healthy", "Stressed").
class IndicatorThresholds {
  final double high;
  final double low;
  final String highLabel;
  final String midLabel;
  final String lowLabel;

  const IndicatorThresholds({
    required this.high,
    required this.low,
    required this.highLabel,
    required this.midLabel,
    required this.lowLabel,
  });

  String labelFor(double value) {
    if (value >= high) return highLabel;
    if (value <= low) return lowLabel;
    return midLabel;
  }
}

/// Complete definition of one indicator — its identity, theme, thresholds.
class IndicatorDefinition {
  final String key;
  final String label; // "VEGETATION", "MOISTURE", etc.
  final String unit; // "", "°C", "%"
  final int precision; // decimal places shown
  final double anchorValue; // current real value from /summary
  final double variance; // realistic per-step variation
  final IndicatorTheme theme;
  final IndicatorThresholds thresholds;

  const IndicatorDefinition({
    required this.key,
    required this.label,
    required this.unit,
    required this.precision,
    required this.anchorValue,
    required this.variance,
    required this.theme,
    required this.thresholds,
  });
}

// ────────────────────────────────────────────────────────────────────────
// THE FOUR INDICATORS — anchored to your real /summary values
// ────────────────────────────────────────────────────────────────────────

const IndicatorDefinition kNdvi = IndicatorDefinition(
  key: 'ndvi',
  label: 'VEGETATION',
  unit: '',
  precision: 2,
  anchorValue: 0.54,
  variance: 0.04,
  theme: IndicatorTheme(
    deep: Color(0xFF14532D),
    strong: Color(0xFF2D6A4F),
    mid: Color(0xFF52B788),
    pale: Color(0xFFD8F3DC),
    cream: Color(0xFFF2F9F3),
  ),
  thresholds: IndicatorThresholds(
    high: 0.55,
    low: 0.40,
    highLabel: 'Healthy',
    midLabel: 'Moderate',
    lowLabel: 'Stressed',
  ),
);

const IndicatorDefinition kMoisture = IndicatorDefinition(
  key: 'moisture',
  label: 'MOISTURE',
  unit: '',
  precision: 2,
  anchorValue: 0.13,
  variance: 0.04,
  theme: IndicatorTheme(
    deep: Color(0xFF0C4A6E),
    strong: Color(0xFF0369A1),
    mid: Color(0xFF38BDF8),
    pale: Color(0xFFE0F2FE),
    cream: Color(0xFFF3FAFE),
  ),
  thresholds: IndicatorThresholds(
    high: 0.18,
    low: 0.08,
    highLabel: 'Wet',
    midLabel: 'Normal',
    lowLabel: 'Dry',
  ),
);

const IndicatorDefinition kTemperature = IndicatorDefinition(
  key: 'temperature',
  label: 'TEMPERATURE',
  unit: '°C',
  precision: 1,
  anchorValue: 25.3,
  variance: 0.6,
  theme: IndicatorTheme(
    deep: Color(0xFF8B5A00),
    strong: Color(0xFFC28100),
    mid: Color(0xFFE6B833),
    pale: Color(0xFFFBF1D0),
    cream: Color(0xFFFBF7E8),
  ),
  thresholds: IndicatorThresholds(
    high: 28,
    low: 20,
    highLabel: 'Hot',
    midLabel: 'Normal',
    lowLabel: 'Cool',
  ),
);

const IndicatorDefinition kWater = IndicatorDefinition(
  key: 'water',
  label: 'WATER',
  unit: '%',
  precision: 0,
  anchorValue: 51,
  variance: 2.5,
  theme: IndicatorTheme(
    deep: Color(0xFF0E5E60),
    strong: Color(0xFF0F8B8D),
    mid: Color(0xFF36BFC5),
    pale: Color(0xFFCFF0F2),
    cream: Color(0xFFEEF8F8),
  ),
  thresholds: IndicatorThresholds(
    high: 60,
    low: 30,
    highLabel: 'High',
    midLabel: 'Normal',
    lowLabel: 'Low',
  ),
);

const List<IndicatorDefinition> kAllIndicators = [
  kNdvi,
  kMoisture,
  kTemperature,
  kWater,
];
