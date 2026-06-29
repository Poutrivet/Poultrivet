// ════════════════════════════════════════════════════════════════════════
// PouliVet — Live System
// File: pulse_models.dart
// Step: 3 of 14
//
// Purpose: The data classes that flow through the PulseEngine.
//
// Four classes, each with one job:
//   • TimeSeries        — a stream of values with anchor/variance/history
//   • RegionalData      — risk distribution for one of Uganda's 4 regions
//   • DistrictRanking   — one district in the Top 5 with score + previous
//   • PulseSnapshot     — what the engine emits per tick (the whole picture)
//
// Design notes:
//   • Mutable on purpose — the engine updates these in place each tick.
//     Immutability would force a rebuild every 3s and waste allocations.
//   • TimeSeries.seeded() lets the engine create realistic 30-day history
//     with one line: `TimeSeries.seeded(anchor: 0.54, variance: 0.04)`.
//   • Every series has a `current`, `previous`, and `delta` so widgets
//     can compute trend arrows without doing the math themselves.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math';

// ════════════════════════════════════════════════════════════════════════
// TIME SERIES — a flowing history of values
// ════════════════════════════════════════════════════════════════════════

/// A streaming time series. Holds the rolling history, the current anchor,
/// and the variance for noise generation. The engine pushes new values; the
/// oldest drops off the left when history exceeds capacity.
class TimeSeries {
  /// The target real-world value this series should orbit around.
  /// For indicators this is the latest /summary reading.
  final double anchor;

  /// How much the value can plausibly drift per tick (in same units).
  final double variance;

  /// How many decimal places to display.
  final int precision;

  /// Maximum number of points to retain (older points drop off).
  final int capacity;

  /// The rolling history. Oldest at index 0, newest at the end.
  final List<double> history;

  /// The previous value (the one before `current`). Used for trend arrows.
  double previous;

  TimeSeries({
    required this.anchor,
    required this.variance,
    required this.precision,
    required this.capacity,
    required this.history,
    required this.previous,
  });

  /// The most recent value.
  double get current => history.isEmpty ? anchor : history.last;

  /// Signed difference from the previous value (positive = trending up).
  double get delta => current - previous;

  /// Push a new value into history, drop the oldest if at capacity.
  /// Also captures `previous` so widgets can compute deltas.
  void push(double value) {
    previous = current;
    history.add(value);
    if (history.length > capacity) {
      history.removeAt(0);
    }
  }

  /// Factory that creates a TimeSeries pre-seeded with plausible history.
  /// Uses a sinusoidal trend + small random drift around the anchor, then
  /// pins the last value to exactly the anchor so the displayed current
  /// reading matches the real /summary value.
  factory TimeSeries.seeded({
    required double anchor,
    required double variance,
    required int points,
    required int precision,
  }) {
    final rand = Random();
    final list = <double>[];
    for (int i = 0; i < points; i++) {
      final drift = (rand.nextDouble() - 0.5) * variance * 1.5;
      final trend = sin(i * 0.25) * variance;
      list.add((anchor + drift + trend).clamp(0, double.infinity));
    }
    // Pin last point to anchor so displayed value matches reality.
    list[list.length - 1] = anchor;
    return TimeSeries(
      anchor: anchor,
      variance: variance,
      precision: precision,
      capacity: points,
      history: list,
      previous: anchor,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// REGIONAL DATA — risk distribution for one of Uganda's 4 regions
// ════════════════════════════════════════════════════════════════════════

/// A single region's risk distribution: how many districts in each level.
/// The engine shifts districts between levels each tick to simulate change.
class RegionalData {
  /// Display name (e.g. "CENTRAL", "EASTERN").
  final String name;

  /// Number of districts currently classified HIGH risk.
  int high;

  /// Number of districts currently classified MEDIUM risk.
  int medium;

  /// Number of districts currently classified LOW risk.
  int low;

  RegionalData({
    required this.name,
    required this.high,
    required this.medium,
    required this.low,
  });

  /// Total districts in this region.
  int get total => high + medium + low;

  /// Fraction of districts that are HIGH risk (0.0 - 1.0).
  double get highFraction => total == 0 ? 0 : high / total;

  /// Fraction MEDIUM (0.0 - 1.0).
  double get mediumFraction => total == 0 ? 0 : medium / total;

  /// Fraction LOW (0.0 - 1.0).
  double get lowFraction => total == 0 ? 0 : low / total;

  /// What "severity tier" should this region's pulsing dot show?
  /// HIGH (urgent red glow) if many districts in HIGH, otherwise scales down.
  RegionSeverity get severity {
    if (high >= 4) return RegionSeverity.high;
    if (high >= 2) return RegionSeverity.medium;
    return RegionSeverity.low;
  }
}

/// How urgent does a region look at a glance?
enum RegionSeverity { high, medium, low }

// ════════════════════════════════════════════════════════════════════════
// DISTRICT RANKING — one district in the Top 5 list
// ════════════════════════════════════════════════════════════════════════

/// A single district in the Top 5 highest-risk list.
/// Has both `score` (current) and `previousScore` so the UI can show
/// trend arrows without holding extra state.
class DistrictRanking {
  /// District name (e.g. "Buikwe").
  final String name;

  /// Current risk score, 1-10.
  int score;

  /// Previous tick's score. Used to compute trend arrow.
  int previousScore;

  /// Comma-separated diseases flagged for this district.
  final String diseases;

  DistrictRanking({
    required this.name,
    required this.score,
    required this.previousScore,
    required this.diseases,
  });

  /// Signed change vs previous tick (positive = risk going up = bad).
  int get delta => score - previousScore;

  /// Score as a 0-1 fraction (for progress bar width).
  double get fraction => score.clamp(1, 10) / 10.0;

  /// Risk tier for this district's badge color.
  DistrictRiskTier get tier {
    if (score >= 7) return DistrictRiskTier.high;
    if (score >= 4) return DistrictRiskTier.medium;
    return DistrictRiskTier.low;
  }
}

/// Risk tier for the badge/dot color on a top-district row.
enum DistrictRiskTier { high, medium, low }

// ════════════════════════════════════════════════════════════════════════
// PULSE SNAPSHOT — the whole picture at one moment in time
// ════════════════════════════════════════════════════════════════════════

/// What the PulseEngine emits on every tick. A complete snapshot of all
/// four data domains. Widgets read whichever domain they care about.
///
/// Note: the maps and list reference the engine's internal state directly
/// (not copies) for efficiency. Since the engine is single-threaded and
/// rebuilds happen on Dart's event loop, there's no race condition.
class PulseSnapshot {
  /// Four environmental indicators keyed by 'ndvi' / 'moisture' / etc.
  final Map<String, TimeSeries> indicators;

  /// Four trajectory series keyed by 'risk' / 'ncd' / 'cocci' / 'salm'.
  final Map<String, TimeSeries> trajectory;

  /// Four regional risk distributions keyed by 'central' / etc.
  final Map<String, RegionalData> regional;

  /// Top 5 districts, sorted by score descending.
  final List<DistrictRanking> topDistricts;

  PulseSnapshot({
    required this.indicators,
    required this.trajectory,
    required this.regional,
    required this.topDistricts,
  });
}
