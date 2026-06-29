// ════════════════════════════════════════════════════════════════════════
// PouliVet — Live System
// File: atoms/shimmer_bar.dart
// Step: 6 of 14
//
// THE THIRD REUSABLE ATOM.
//
// Purpose: A progress bar that breathes. A continuous white highlight
// sweeps left-to-right across the bar's surface, making it feel like
// the system is actively monitoring — even when the value isn't changing.
//
// Used in:
//   • Regional Pulse rows (stacked HIGH/MEDIUM/LOW segments)
//   • Top 5 district progress bars (single-color gradient)
//
// Two layers, two animations:
//   1. The base fill — its WIDTH animates when the value changes
//      (e.g. district score drops 9 → 7, bar smoothly retracts).
//   2. The shimmer overlay — continuously sweeps left-to-right with a
//      soft white gradient, independent of width changes.
//
// Tunable:
//   • fill — single Color, or a List<Color> for gradient
//   • value — 0.0 to 1.0 (what fraction of the bar is filled)
//   • height — defaults to PulseTheme.barHeight
//   • shimmerIntensity — 0.0 (no shimmer) to 1.0 (very bright sweep)
//   • shimmerEnabled — set false for stacked-segment use where multiple
//     ShimmerBars sit side-by-side and only one needs to lead the sweep
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../pulse_theme.dart';

class ShimmerBar extends StatefulWidget {
  /// Value from 0.0 (empty) to 1.0 (full).
  final double value;

  /// Single color, used if [gradientColors] is null.
  final Color color;

  /// Optional gradient (e.g. dark-to-light variant of the color).
  /// If provided, this overrides [color].
  final List<Color>? gradientColors;

  /// Background track color (the unfilled portion).
  /// If null, uses a very pale grey.
  final Color? trackColor;

  /// Bar height in logical pixels.
  final double height;

  /// Border radius. Defaults to fully rounded ends.
  final double? radius;

  /// Strength of the shimmer sweep (0.0 = off, 0.5 = standard, 1.0 = bright).
  final double shimmerIntensity;

  /// Whether to render the shimmer sweep at all.
  final bool shimmerEnabled;

  /// Override the shimmer cycle. Leave null to use PulseTheme.shimmerSweep.
  final Duration? shimmerPeriod;

  const ShimmerBar({
    super.key,
    required this.value,
    required this.color,
    this.gradientColors,
    this.trackColor,
    this.height = PulseTheme.barHeight,
    this.radius,
    this.shimmerIntensity = 0.5,
    this.shimmerEnabled = true,
    this.shimmerPeriod,
  });

  @override
  State<ShimmerBar> createState() => _ShimmerBarState();
}

class _ShimmerBarState extends State<ShimmerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: widget.shimmerPeriod ?? PulseTheme.shimmerSweep,
    );
    if (widget.shimmerEnabled) {
      _shimmerCtrl.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ShimmerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the shimmer was toggled or its period changed, restart cleanly.
    final newPeriod = widget.shimmerPeriod ?? PulseTheme.shimmerSweep;
    if (_shimmerCtrl.duration != newPeriod) {
      _shimmerCtrl.duration = newPeriod;
    }
    if (widget.shimmerEnabled && !_shimmerCtrl.isAnimating) {
      _shimmerCtrl.repeat();
    } else if (!widget.shimmerEnabled && _shimmerCtrl.isAnimating) {
      _shimmerCtrl.stop();
    }
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.radius ?? PulseTheme.barRadius;
    final track = widget.trackColor ?? const Color(0xFFF0F2F0);
    final clampedValue = widget.value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        height: widget.height,
        color: track,
        child: Stack(
          children: [
            // ─── Layer 1: animated fill (width tweens on value change) ───
            AnimatedFractionallySizedBox(
              widthFactor: clampedValue,
              alignment: Alignment.centerLeft,
              duration: PulseTheme.barWidth,
              curve: PulseTheme.barTransition,
              child: Container(
                decoration: BoxDecoration(
                  gradient: widget.gradientColors != null
                      ? LinearGradient(colors: widget.gradientColors!)
                      : LinearGradient(
                          colors: [widget.color, widget.color],
                        ),
                ),
                // ─── Layer 2: shimmer sweep (only inside the filled area) ──
                child: widget.shimmerEnabled
                    ? AnimatedBuilder(
                        animation: _shimmerCtrl,
                        builder: (context, _) {
                          final t = _shimmerCtrl.value;
                          // Move highlight from -50% to 150% so it enters
                          // from outside the bar on the left, sweeps across,
                          // and exits on the right.
                          final alignmentX = -1.0 + (t * 2.4);
                          final highlightOpacity = widget.shimmerIntensity;
                          return ShaderMask(
                            blendMode: BlendMode.srcATop,
                            shaderCallback: (rect) {
                              return LinearGradient(
                                begin: Alignment(alignmentX - 0.3, 0),
                                end: Alignment(alignmentX + 0.3, 0),
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withOpacity(highlightOpacity),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ).createShader(rect);
                            },
                            child: Container(color: Colors.white),
                          );
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
