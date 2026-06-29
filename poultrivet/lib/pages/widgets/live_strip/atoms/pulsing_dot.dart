// ════════════════════════════════════════════════════════════════════════
// PouliVet — Live System
// File: atoms/pulsing_dot.dart
// Step: 4 of 14
//
// THE FIRST REUSABLE ATOM.
//
// Purpose: A small pulsing dot. Used everywhere on the Stats screen —
// next to "Live" badges, on regional pulse rows, on Top 5 district rows,
// inside indicator cards. One atom, infinite combinations.
//
// Three strengths:
//   • PulseStrength.high     → urgent. Used when HIGH risk needs to scream.
//                              Has an outward radiating glow (like a sonar ping).
//   • PulseStrength.normal   → gentle. The everyday "I am alive" signal.
//   • PulseStrength.soft     → barely-there. Ambient — for places where
//                              motion shouldn't compete for attention.
//
// Tunable:
//   • size — 6 to 14 px works well
//   • color — any color from PulseTheme or custom
//   • period — defaults to PulseTheme.dotPulse but overridable
//
// Why it matters:
//   Before this atom, we re-implemented pulsing in every widget. Each
//   implementation slightly different. Now there's exactly one source of
//   truth for what "pulsing" looks like in PouliVet.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../pulse_theme.dart';

/// How intensely should this dot pulse?
enum PulseStrength {
  /// Urgent. Includes an outward radiating glow.
  high,

  /// Standard "I am alive" pulse. The default for most use cases.
  normal,

  /// Barely-perceptible. Use in dense layouts where motion shouldn't compete.
  soft,
}

/// A small dot that gently pulses. The visual heartbeat of the live system.
///
/// Example:
/// ```dart
/// PulsingDot(color: PulseTheme.riskHigh, strength: PulseStrength.high)
/// ```
class PulsingDot extends StatefulWidget {
  /// The dot's main color.
  final Color color;

  /// How intensely should it pulse?
  final PulseStrength strength;

  /// Diameter of the dot in logical pixels. Defaults to 8.
  final double size;

  /// Override the default pulse cycle. Leave null to use PulseTheme defaults.
  final Duration? period;

  const PulsingDot({
    super.key,
    required this.color,
    this.strength = PulseStrength.normal,
    this.size = PulseTheme.dotSize,
    this.period,
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.period ?? _defaultPeriod(),
    )..repeat(reverse: true);
  }

  Duration _defaultPeriod() {
    // High-severity dots pulse slightly slower — gives them weight,
    // makes them feel deliberate rather than frantic.
    return widget.strength == PulseStrength.high
        ? PulseTheme.dotPulseHigh
        : PulseTheme.dotPulse;
  }

  @override
  void didUpdateWidget(covariant PulsingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If period or strength changed, restart the controller with the new duration.
    final newPeriod = widget.period ?? _defaultPeriod();
    if (_ctrl.duration != newPeriod) {
      _ctrl.duration = newPeriod;
      _ctrl
        ..stop()
        ..reset()
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Scale + opacity ranges based on strength.
    final scaleRange = switch (widget.strength) {
      PulseStrength.high => 0.4, // 1.0 → 1.4
      PulseStrength.normal => 0.3, // 1.0 → 1.3
      PulseStrength.soft => 0.15, // 1.0 → 1.15
    };
    final opacityDrop = switch (widget.strength) {
      PulseStrength.high => 0.3, // 1.0 → 0.7
      PulseStrength.normal => 0.4, // 1.0 → 0.6
      PulseStrength.soft => 0.25, // 1.0 → 0.75
    };

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final progress = _ctrl.value;
        final scale = 1.0 + (progress * scaleRange);
        final opacity = 1.0 - (progress * opacityDrop);

        // For HIGH strength, add an outward-radiating halo behind the dot.
        // The halo grows + fades as the dot pulses — that "sonar ping" feel.
        Widget dot = Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        );

        if (widget.strength == PulseStrength.high) {
          final haloSize = widget.size * (1.0 + progress * 1.8);
          final haloOpacity = (1.0 - progress) * 0.35;
          dot = Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Outward halo
              Container(
                width: haloSize,
                height: haloSize,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(haloOpacity),
                  shape: BoxShape.circle,
                ),
              ),
              // The dot itself
              dot,
            ],
          );
        }

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: dot,
          ),
        );
      },
    );
  }
}
