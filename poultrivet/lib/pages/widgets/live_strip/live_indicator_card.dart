// ════════════════════════════════════════════════════════════════════════
// PouliVet — Live System
// File: live_indicator_card.dart
// Step: 9 of 14
//
// REFACTORED.
//
// Purpose: One card showing a single environmental indicator. Color-themed
// end-to-end — every element (label, big number, line, area, dot, status,
// trend) draws from the indicator's own color family.
//
// What changed from the previous version:
//   • Now takes a TimeSeries from the PulseEngine (not its own stream).
//   • Uses PulsingDot atom (was inline 50-line StatefulWidget).
//   • Uses TweenNumber atom (was inline TweenAnimationBuilder + formatter).
//   • Uses TrendArrow atom (was inline up/down/flat logic).
//   • Visual output is IDENTICAL. Code is roughly half the size.
//
// Visual hierarchy:
//   • Big serif number (Georgia 34) — the value
//   • Indicator label in small caps (matches card color)
//   • Smooth fl_chart line + area gradient (matches card color)
//   • Pulsing dot + status text at the bottom
//   • Trend pill in top-right
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'atoms/pulsing_dot.dart';
import 'atoms/trend_arrow.dart';
import 'atoms/tween_number.dart';
import 'indicator_data.dart';
import 'pulse_models.dart';
import 'pulse_theme.dart';

class LiveIndicatorCard extends StatelessWidget {
  /// The indicator's identity — colors, thresholds, labels.
  final IndicatorDefinition definition;

  /// The current streaming data — history, anchor, current, delta.
  final TimeSeries series;

  const LiveIndicatorCard({
    super.key,
    required this.definition,
    required this.series,
  });

  @override
  Widget build(BuildContext context) {
    final def = definition;
    final t = def.theme;
    final current = series.current;
    final statusLabel = def.thresholds.labelFor(current);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, t.cream],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.pale, width: 1),
        boxShadow: PulseTheme.cardShadow(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Top accent bar — gradient using the indicator's colors ─
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [t.strong, t.mid]),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Label (small caps in card color) ───────────────
                  Text(
                    def.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: t.strong,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ─── Value row: TweenNumber + unit + trend pill ─────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      // The big number — animated smoothly via TweenNumber atom
                      TweenNumber(
                        value: current,
                        formatter: (v) => v.toStringAsFixed(def.precision),
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: t.deep,
                          height: 1.0,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (def.unit.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          def.unit,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: t.strong,
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Trend pill — TrendArrow atom does all the work
                      TrendArrow(
                        delta: series.delta,
                        semantic: TrendSemantic.risk,
                        style: TrendArrowStyle.pill,
                        precision: def.precision,
                        flatThreshold: def.variance * 0.1,
                        fontSize: 12,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ─── The flowing fl_chart line ──────────────────────
                  SizedBox(
                    height: 70,
                    child: _buildChart(),
                  ),
                  const SizedBox(height: 12),

                  // ─── Status row: PulsingDot atom + status text ──────
                  Row(
                    children: [
                      PulsingDot(
                        color: t.mid,
                        strength: PulseStrength.normal,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: t.strong,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    final t = definition.theme;
    final history = series.history;
    if (history.length < 2) return const SizedBox.shrink();

    // Auto-scale Y axis with 20% padding so line never touches the edges
    final minVal = history.reduce((a, b) => a < b ? a : b);
    final maxVal = history.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);
    final padded = range * 0.2;
    final yMin = minVal - padded;
    final yMax = maxVal + padded;

    final spots = <FlSpot>[
      for (int i = 0; i < history.length; i++) FlSpot(i.toDouble(), history[i]),
    ];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (history.length - 1).toDouble(),
        minY: yMin,
        maxY: yMax,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            preventCurveOverShooting: true,
            color: t.strong,
            barWidth: 2.2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  t.strong.withOpacity(0.30),
                  t.strong.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }
}
