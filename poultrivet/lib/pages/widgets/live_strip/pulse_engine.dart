// ════════════════════════════════════════════════════════════════════════
// PouliVet — Live System
// File: pulse_engine.dart
// Step: 2 of 14
//
// THE HEART OF THE LIVE SYSTEM.
//
// Purpose: A single streaming engine that powers every live widget on the
// Stats screen. Instead of every widget running its own timer, they all
// subscribe to this one engine.
//
// Design choices:
//   1. SINGLETON — exactly one engine per app lifetime. Access via
//      PulseEngine.instance from anywhere.
//   2. THREE TICKERS — each beating at its own natural rhythm (strip 3s,
//      trend 4s, regional/top 5s). This is intentional: it makes the screen
//      feel like a body with multiple heartbeats rather than one frantic clock.
//   3. BROADCAST STREAM — every widget subscribes via StreamBuilder.
//   4. ANCHORED MOCK DATA — values fluctuate around real anchors from your
//      /summary endpoint. To use real data later, swap one method.
//
// Future real-data path:
//   • Replace _generateNext* methods with calls to ApiService
//   • The PulseSnapshot model and Stream stay identical
//   • No widget code needs to change
// ════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math';

import 'pulse_models.dart';
import 'pulse_theme.dart';

/// The singleton streaming engine. Access via `PulseEngine.instance`.
class PulseEngine {
  // ─── Singleton plumbing ───────────────────────────────────────────
  PulseEngine._internal();
  static final PulseEngine instance = PulseEngine._internal();

  // ─── Internal state ───────────────────────────────────────────────
  final Random _rand = Random();
  final StreamController<PulseSnapshot> _controller =
      StreamController.broadcast();

  // Three independent timers — each ticks at its own rhythm.
  Timer? _stripTimer;
  Timer? _trendTimer;
  Timer? _topTimer;

  // Current state for each data domain.
  late Map<String, TimeSeries> _indicators;
  late Map<String, TimeSeries> _trajectory;
  late Map<String, RegionalData> _regional;
  late List<DistrictRanking> _topDistricts;

  bool _started = false;

  // ─── Public stream — what widgets subscribe to ────────────────────
  /// Every tick (from any of the 3 timers) emits a fresh snapshot.
  /// Widgets read whichever part of the snapshot they care about.
  Stream<PulseSnapshot> get stream => _controller.stream;

  /// Current state (for initial render before first tick).
  PulseSnapshot get snapshot => PulseSnapshot(
        indicators: _indicators,
        trajectory: _trajectory,
        regional: _regional,
        topDistricts: _topDistricts,
      );

  // ═════════════════════════════════════════════════════════════════
  // Lifecycle
  // ═════════════════════════════════════════════════════════════════

  /// Boot the engine. Safe to call multiple times — it's idempotent.
  void start() {
    if (_started) return;
    _started = true;

    _seedAll();

    // Emit initial snapshot so widgets render immediately.
    _emit();

    // Three timers, three rhythms. The screen breathes.
    _stripTimer =
        Timer.periodic(PulseTheme.pulseStripTick, (_) => _tickStrip());
    _trendTimer =
        Timer.periodic(PulseTheme.pulseTrendTick, (_) => _tickTrend());
    _topTimer = Timer.periodic(PulseTheme.pulseTopTick, (_) => _tickTop());
  }

  /// Shut the engine down. Currently unused (engine lives for app lifetime)
  /// but here for completeness if you ever need to stop it mid-session.
  void stop() {
    _stripTimer?.cancel();
    _trendTimer?.cancel();
    _topTimer?.cancel();
    _started = false;
  }

  /// Disposes the broadcast stream. Call only on app shutdown.
  void dispose() {
    stop();
    _controller.close();
  }

  // ═════════════════════════════════════════════════════════════════
  // SEEDING — initial state, anchored to real /summary values
  // ═════════════════════════════════════════════════════════════════

  void _seedAll() {
    _seedIndicators();
    _seedTrajectory();
    _seedRegional();
    _seedTopDistricts();
  }

  /// Four environmental indicators with realistic historical variation.
  void _seedIndicators() {
    _indicators = {
      'ndvi': TimeSeries.seeded(
          anchor: 0.54, variance: 0.04, points: 30, precision: 2),
      'moisture': TimeSeries.seeded(
          anchor: 0.13, variance: 0.04, points: 30, precision: 2),
      'temperature': TimeSeries.seeded(
          anchor: 25.3, variance: 0.6, points: 30, precision: 1),
      'water': TimeSeries.seeded(
          anchor: 51.0, variance: 2.5, points: 30, precision: 0),
    };
  }

  /// Four trajectory series: HIGH risk count + 3 disease counts.
  /// Anchored to your real /summary values:
  ///   11 HIGH-risk districts (out of 134)
  ///   ~47 districts flagged with Newcastle
  ///   ~38 with Coccidiosis
  ///   ~12 with Salmonella
  void _seedTrajectory() {
    _trajectory = {
      'risk': TimeSeries.seeded(
          anchor: 11, variance: 1.3, points: 30, precision: 0),
      'ncd': TimeSeries.seeded(
          anchor: 47, variance: 2.5, points: 30, precision: 0),
      'cocci': TimeSeries.seeded(
          anchor: 38, variance: 2.0, points: 30, precision: 0),
      'salm': TimeSeries.seeded(
          anchor: 12, variance: 1.5, points: 30, precision: 0),
    };
  }

  /// Four Uganda regions with realistic risk distributions.
  /// Central tends highest (Lake Victoria adjacency), Northern lowest.
  void _seedRegional() {
    _regional = {
      'central': RegionalData(name: 'CENTRAL', high: 6, medium: 28, low: 6),
      'eastern': RegionalData(name: 'EASTERN', high: 2, medium: 22, low: 10),
      'northern': RegionalData(name: 'NORTHERN', high: 1, medium: 14, low: 15),
      'western': RegionalData(name: 'WESTERN', high: 2, medium: 16, low: 12),
    };
  }

  /// Top 5 highest-risk districts. Real names from your /summary endpoint.
  void _seedTopDistricts() {
    _topDistricts = [
      DistrictRanking(
          name: 'Buikwe',
          score: 9,
          previousScore: 9,
          diseases: 'Newcastle Disease, Salmonella'),
      DistrictRanking(
          name: 'Gomba',
          score: 8,
          previousScore: 8,
          diseases: 'Coccidiosis, Newcastle Disease'),
      DistrictRanking(
          name: 'Mpigi',
          score: 8,
          previousScore: 8,
          diseases: 'Newcastle Disease'),
      DistrictRanking(
          name: 'Mukono',
          score: 7,
          previousScore: 7,
          diseases: 'Salmonella, Coccidiosis'),
      DistrictRanking(
          name: 'Butambala',
          score: 7,
          previousScore: 7,
          diseases: 'Newcastle Disease'),
    ];
  }

  // ═════════════════════════════════════════════════════════════════
  // TICKERS — three different rhythms, three different domains
  // ═════════════════════════════════════════════════════════════════

  /// Strip tick — environmental indicators flow.
  void _tickStrip() {
    for (final s in _indicators.values) {
      final next = _generateNextValue(s.current, s.anchor, s.variance);
      s.push(next);
    }
    _emit();
  }

  /// Trend tick — trajectory series flow.
  void _tickTrend() {
    for (final s in _trajectory.values) {
      final next = _generateNextValue(s.current, s.anchor, s.variance);
      s.push(next < 0 ? 0 : next); // counts can't go negative
    }
    _emit();
  }

  /// Top/Regional tick — regional and top districts shift.
  void _tickTop() {
    _shiftRegional();
    _shiftTopDistricts();
    _emit();
  }

  /// For each region, with 40% probability one district shifts between
  /// risk levels. Total district count per region stays constant —
  /// when one district leaves HIGH, one enters MEDIUM (or vice versa).
  void _shiftRegional() {
    for (final r in _regional.values) {
      if (_rand.nextDouble() >= 0.4) continue;

      final dir = _rand.nextBool() ? 1 : -1;
      final which = _rand.nextDouble();

      if (which < 0.4 && r.high + dir >= 0 && r.medium - dir >= 0) {
        // HIGH ↔ MEDIUM swap
        r.high += dir;
        r.medium -= dir;
      } else if (r.medium + dir >= 0 && r.low - dir >= 0) {
        // MEDIUM ↔ LOW swap
        r.medium += dir;
        r.low -= dir;
      }
    }
  }

  /// For each top district, 40% chance score shifts by ±1 (clamped 1-10).
  /// After all shifts, the list is re-sorted by score desc.
  void _shiftTopDistricts() {
    // Save previous scores for trend computation
    for (final d in _topDistricts) {
      d.previousScore = d.score;
    }

    // Apply random shifts
    for (final d in _topDistricts) {
      if (_rand.nextDouble() < 0.4) {
        final dir = _rand.nextBool() ? 1 : -1;
        d.score = (d.score + dir).clamp(1, 10);
      }
    }

    // Re-sort by current score desc, ties broken by name for stability
    _topDistricts.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      if (cmp != 0) return cmp;
      return a.name.compareTo(b.name);
    });
  }

  // ═════════════════════════════════════════════════════════════════
  // Random walk generator — the math behind "plausible variation"
  // ═════════════════════════════════════════════════════════════════

  /// Mean-reverting random walk: pulls back toward the anchor while
  /// adding noise. This is what makes the streams feel real — values
  /// drift but never wander far from the truth.
  double _generateNextValue(double current, double anchor, double variance) {
    const meanReversionFactor = 0.15;
    final pullToAnchor = (anchor - current) * meanReversionFactor;
    final noise = (_rand.nextDouble() - 0.5) * variance;
    return current + pullToAnchor + noise;
  }

  // ═════════════════════════════════════════════════════════════════
  // Emit — broadcast the current snapshot to all subscribers
  // ═════════════════════════════════════════════════════════════════

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(snapshot);
  }
}
