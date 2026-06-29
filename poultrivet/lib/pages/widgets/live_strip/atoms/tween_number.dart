// ════════════════════════════════════════════════════════════════════════
// PouliVet — Live System
// File: atoms/tween_number.dart
// Step: 7 of 14
//
// THE FOURTH REUSABLE ATOM.
//
// Purpose: A number that COUNTS instead of SNAPS.
//
// When the value changes from 11 to 14, the user sees: 11 → 12 → 13 → 14
// over ~600ms with an ease-out curve. This is the polish detail that
// makes the live system feel sophisticated rather than mechanical.
//
// Used everywhere:
//   • Indicator card values (0.54 → 0.56)
//   • Trajectory legend numbers (47 → 49)
//   • Top 5 scores (8 → 9)
//   • Regional HIGH counts (6 → 7)
//
// Smart behavior:
//   • Remembers the previously displayed value across rebuilds, so
//     consecutive changes tween smoothly (11 → 12 → 14 not 0 → 12 → 14).
//   • Tabular figures by default — digits don't jitter while counting.
//   • Format function pluggable — handles ints, decimals, units uniformly.
//   • Optional initial-entry animation from 0 → value.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../pulse_theme.dart';

/// Format function signature. Takes the current tweened value, returns a String.
typedef NumberFormatter = String Function(double value);

class TweenNumber extends StatefulWidget {
  /// Target value to display.
  final double value;

  /// Format the value into a string. Defaults to `value.toStringAsFixed(0)`.
  /// Override for decimals, units, etc.
  ///
  /// Examples:
  /// ```dart
  /// formatter: (v) => v.toStringAsFixed(2),         // "0.54"
  /// formatter: (v) => '${v.round()}°C',             // "25°C"
  /// formatter: (v) => '${v.round()}/10',            // "9/10"
  /// ```
  final NumberFormatter? formatter;

  /// Text style for the rendered number.
  final TextStyle? style;

  /// Tween duration. Defaults to PulseTheme.numberTween (600ms).
  final Duration? duration;

  /// Animation curve. Defaults to PulseTheme.countUp (easeOutCubic).
  final Curve curve;

  /// If true, the first appearance counts from 0 → value.
  /// Otherwise the first render shows the value immediately.
  final bool animateOnEntry;

  /// Use tabular (fixed-width) digit spacing. Prevents jitter when digits
  /// of different widths swap during counting. Default true.
  final bool tabularFigures;

  const TweenNumber({
    super.key,
    required this.value,
    this.formatter,
    this.style,
    this.duration,
    this.curve = PulseTheme.countUp,
    this.animateOnEntry = true,
    this.tabularFigures = true,
  });

  @override
  State<TweenNumber> createState() => _TweenNumberState();
}

class _TweenNumberState extends State<TweenNumber> {
  // The "from" value of the current tween — what was displayed before
  // the latest value change.
  late double _fromValue;

  @override
  void initState() {
    super.initState();
    // On entry: start from 0 (animateOnEntry=true) or from the value itself.
    _fromValue = widget.animateOnEntry ? 0.0 : widget.value;
  }

  @override
  void didUpdateWidget(covariant TweenNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the value changes, set _fromValue to the OLD value so the tween
    // starts from where the user last saw the number, not from zero.
    if (oldWidget.value != widget.value) {
      _fromValue = oldWidget.value;
    }
  }

  String _defaultFormat(double v) => v.round().toString();

  @override
  Widget build(BuildContext context) {
    final formatter = widget.formatter ?? _defaultFormat;
    final duration = widget.duration ?? PulseTheme.numberTween;

    // Build the final TextStyle with tabular figures if requested
    TextStyle? effectiveStyle = widget.style;
    if (widget.tabularFigures) {
      effectiveStyle = (effectiveStyle ?? const TextStyle()).copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _fromValue, end: widget.value),
      duration: duration,
      curve: widget.curve,
      builder: (context, tweenedValue, _) {
        return Text(
          formatter(tweenedValue),
          style: effectiveStyle,
        );
      },
    );
  }
}
