// ════════════════════════════════════════════════════════════════════════
// PouliVet — Live Indicator Strip
// File: indicator_stream_service.dart
// Purpose: Generates anchored mock streaming data for the indicators.
//          Each tick, a new value is added on the right, oldest drops left.
//          Later, swap the _generateNextValue logic for a real API call.
// ════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math';
import 'indicator_data.dart';

/// Holds the streaming history for a single indicator.
class IndicatorStream {
  final IndicatorDefinition definition;
  final List<double> history; // last N points (oldest first)
  double previous; // for computing trend delta

  IndicatorStream({
    required this.definition,
    required this.history,
    required this.previous,
  });

  double get current => history.isEmpty ? definition.anchorValue : history.last;
  double get delta => current - previous;
}

/// Service that maintains streaming data for all indicators and broadcasts
/// updates via a Stream. Listeners (UI widgets) rebuild on each tick.
class IndicatorStreamService {
  static const int historyPoints = 30;
  static const Duration tickInterval = Duration(seconds: 3);

  final Random _rand = Random();
  final Map<String, IndicatorStream> _streams = {};
  Timer? _timer;

  // Broadcast stream so multiple widgets can listen.
  final StreamController<Map<String, IndicatorStream>> _controller =
      StreamController.broadcast();

  Stream<Map<String, IndicatorStream>> get stream => _controller.stream;
  Map<String, IndicatorStream> get currentSnapshot => _streams;

  /// Initialise streams with seeded history anchored to current real values.
  void start() {
    if (_streams.isEmpty) {
      for (final def in kAllIndicators) {
        _streams[def.key] = IndicatorStream(
          definition: def,
          history: _seedHistory(def.anchorValue, def.variance),
          previous: def.anchorValue,
        );
      }
    }

    // Emit initial snapshot so UI renders immediately.
    _controller.add(_streams);

    // Start the tick loop.
    _timer?.cancel();
    _timer = Timer.periodic(tickInterval, (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }

  /// One tick: advance every indicator by one new plausible value.
  void _tick() {
    for (final entry in _streams.entries) {
      final s = entry.value;
      s.previous = s.current;
      final next = _generateNextValue(
        s.current,
        s.definition.anchorValue,
        s.definition.variance,
      );
      s.history.add(next);
      // Drop oldest to keep the flowing-left effect.
      if (s.history.length > historyPoints) {
        s.history.removeAt(0);
      }
    }
    _controller.add(_streams);
  }

  /// Seed initial history with realistic variation around the anchor.
  /// Ensures the LAST point is exactly the anchor (current real value).
  List<double> _seedHistory(double anchor, double variance) {
    final points = <double>[];
    for (int i = 0; i < historyPoints; i++) {
      final drift = (_rand.nextDouble() - 0.5) * variance;
      final trend = sin(i * 0.3) * variance * 0.5;
      points.add(anchor + drift + trend);
    }
    points[points.length - 1] = anchor;
    return points;
  }

  /// Generate next plausible value with mean-reversion + noise.
  /// Pulls back toward the anchor so values don't drift away forever.
  double _generateNextValue(double prev, double anchor, double variance) {
    final meanReversion = (anchor - prev) * 0.15;
    final noise = (_rand.nextDouble() - 0.5) * variance;
    return prev + meanReversion + noise;
  }
}
