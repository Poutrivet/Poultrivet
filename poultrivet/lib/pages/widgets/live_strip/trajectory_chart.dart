// ════════════════════════════════════════════════════════════════════════
// PouliVet — Live System
// File: trajectory_chart.dart
// Step: 11 of 14
//
// THE FIRST BRAND-NEW LIVE WIDGET.
//
// Purpose: A streaming multi-line chart showing both the national HIGH-risk
// district count AND the three flagged diseases (Newcastle / Coccidiosis /
// Salmonella) over a 30-day rolling window. Replaces the static donut +
// disease frequency charts with one temporally-rich visualization.
//
// Visual hierarchy:
//   • HIGH Risk red line — THICK (2.6px) + area gradient underneath.
//     It IS the visual hero. The disease lines support its story.
//   • Three disease lines — thinner (1.8px), calm muted earth tones
//     (purple-grey / sienna / steel blue). They're there but don't compete.
//
// Layout:
//   • Card header with title + LiveBadge atom
//   • Split legend (RISK LEVEL section + DISEASES FLAGGED section)
//   • Chart with Y-axis labels (auto-scaled to nice round numbers)
//   • Footer with last-update timestamp
//
// Data flow:
//   • Subscribes to PulseEngine.instance.stream
//   • Reads the `trajectory` map from PulseSnapshot
//   • All four series share Y-axis scale (honest visual comparison)
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'atoms/live_badge.dart';
import 'atoms/trend_arrow.dart';
import 'atoms/tween_number.dart';
import 'pulse_engine.dart';
import 'pulse_models.dart';
import 'pulse_theme.dart';

class TrajectoryChart extends StatelessWidget {
  const TrajectoryChart({super.key});

  @override
  Widget build(BuildContext context) {
    PulseEngine.instance.start();

    return StreamBuilder<PulseSnapshot>(
      stream: PulseEngine.instance.stream,
      initialData: PulseEngine.instance.snapshot,
      builder: (context, snap) {
        final trajectory = snap.data?.trajectory;
        if (trajectory == null || trajectory.isEmpty) {
          return const _LoadingCard();
        }
        return _TrajectoryCard(trajectory: trajectory);
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// The actual card (extracted so the StreamBuilder body stays readable)
// ════════════════════════════════════════════════════════════════════════

class _TrajectoryCard extends StatelessWidget {
  final Map<String, TimeSeries> trajectory;
  const _TrajectoryCard({required this.trajectory});

  @override
  Widget build(BuildContext context) {
    final risk = trajectory['risk'];
    final ncd = trajectory['ncd'];
    final cocci = trajectory['cocci'];
    final salm = trajectory['salm'];

    if (risk == null || ncd == null || cocci == null || salm == null) {
      return const _LoadingCard();
    }

    return Container(
      padding: const EdgeInsets.all(PulseTheme.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(PulseTheme.cardRadius),
        boxShadow: PulseTheme.cardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          _buildLegend(risk, ncd, cocci, salm),
          const SizedBox(height: 4),
          _buildChartArea(risk, ncd, cocci, salm),
          const SizedBox(height: 8),
          _buildAxisLabels(),
          const SizedBox(height: 12),
          const Divider(color: PulseTheme.greyPale, height: 1),
          const SizedBox(height: 12),
          _buildFooter(),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('⚡  ', style: TextStyle(fontSize: 15)),
            Text(
              'National Risk & Disease Trend',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: PulseTheme.darkText,
              ),
            ),
          ],
        ),
        LiveBadge(),
      ],
    );
  }

  // ─── Split Legend ──────────────────────────────────────────────────
  Widget _buildLegend(
    TimeSeries risk,
    TimeSeries ncd,
    TimeSeries cocci,
    TimeSeries salm,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 1: RISK LEVEL (HIGH Risk solo)
        const _LegendSectionLabel(label: 'RISK LEVEL'),
        const SizedBox(height: 6),
        _legendRow(
          color: PulseTheme.riskHigh,
          label: 'HIGH Risk Districts',
          series: risk,
          fullWidth: true,
        ),
        const SizedBox(height: 12),

        // Section 2: DISEASES FLAGGED · DISTRICTS (3 in a 2-column grid)
        const _LegendSectionLabel(label: 'DISEASES FLAGGED · DISTRICTS'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _legendRow(
                color: PulseTheme.diseaseNewcastle,
                label: 'Newcastle',
                series: ncd,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _legendRow(
                color: PulseTheme.diseaseCoccidiosis,
                label: 'Coccidiosis',
                series: cocci,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _legendRow(
                color: PulseTheme.diseaseSalmonella,
                label: 'Salmonella',
                series: salm,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }

  /// One row of the legend: colored dot + label + count + trend arrow.
  Widget _legendRow({
    required Color color,
    required String label,
    required TimeSeries series,
    bool fullWidth = false,
  }) {
    final content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: PulseTheme.darkText,
          ),
        ),
        const Spacer(),
        TweenNumber(
          value: series.current,
          formatter: (v) => v.round().toString(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: PulseTheme.darkText,
          ),
        ),
        const SizedBox(width: 4),
        TrendArrow(
          delta: series.delta,
          semantic: TrendSemantic.risk,
          style: TrendArrowStyle.bare,
          showValue: false,
          fontSize: 13,
        ),
      ],
    );
    return content;
  }

  // ─── Chart with Y-axis labels ──────────────────────────────────────
  Widget _buildChartArea(
    TimeSeries risk,
    TimeSeries ncd,
    TimeSeries cocci,
    TimeSeries salm,
  ) {
    // Compute shared Y-axis range across all 4 series
    final range = _computeSharedRange([risk, ncd, cocci, salm]);

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Y-axis labels column (5 evenly spaced labels)
          SizedBox(
            width: 28,
            child: _YAxisLabels(min: range.min, max: range.max),
          ),
          const SizedBox(width: 6),
          // The chart itself
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 29,
                minY: range.min,
                maxY: range.max,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (range.max - range.min) / 4,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: PulseTheme.greyPale,
                    strokeWidth: 1,
                    dashArray: [2, 4],
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  // Salmonella (thin, calm)
                  _thinLine(salm, PulseTheme.diseaseSalmonella),
                  // Coccidiosis (thin, calm)
                  _thinLine(cocci, PulseTheme.diseaseCoccidiosis),
                  // Newcastle (thin, calm)
                  _thinLine(ncd, PulseTheme.diseaseNewcastle),
                  // HIGH Risk — THICK + filled area, the visual hero
                  _heroLine(risk, PulseTheme.riskHigh),
                ],
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  /// Thin line for disease series — calm, supporting the story.
  LineChartBarData _thinLine(TimeSeries s, Color color) {
    return LineChartBarData(
      spots: _toSpots(s.history),
      isCurved: true,
      curveSmoothness: 0.35,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 1.8,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
    );
  }

  /// Thick line + area gradient for HIGH Risk — the hero of the chart.
  LineChartBarData _heroLine(TimeSeries s, Color color) {
    return LineChartBarData(
      spots: _toSpots(s.history),
      isCurved: true,
      curveSmoothness: 0.35,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 2.6,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.25), color.withOpacity(0)],
        ),
      ),
    );
  }

  /// Convert history list to FlSpot list.
  List<FlSpot> _toSpots(List<double> history) {
    return [
      for (int i = 0; i < history.length; i++) FlSpot(i.toDouble(), history[i]),
    ];
  }

  // ─── Axis labels along the bottom ──────────────────────────────────
  Widget _buildAxisLabels() {
    return const Padding(
      padding: EdgeInsets.only(left: 34, right: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('30 days ago', style: _axisStyle),
          Text('15 days ago', style: _axisStyle),
          Text('Today', style: _axisStyle),
        ],
      ),
    );
  }

  static const TextStyle _axisStyle = TextStyle(
    fontSize: 10,
    color: PulseTheme.grey,
    fontWeight: FontWeight.w500,
  );

  // ─── Footer ────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Last 30 days · 134 districts',
          style: TextStyle(fontSize: 11, color: PulseTheme.grey),
        ),
        Text(
          _currentTimeString(),
          style: const TextStyle(
            fontSize: 11,
            color: PulseTheme.darkText,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  String _currentTimeString() {
    final now = DateTime.now();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(now.hour)}:${pad(now.minute)}:${pad(now.second)}';
  }

  // ─── Shared Y-axis range computation ───────────────────────────────
  _AxisRange _computeSharedRange(List<TimeSeries> seriesList) {
    double globalMin = double.infinity;
    double globalMax = double.negativeInfinity;
    for (final s in seriesList) {
      for (final v in s.history) {
        if (v < globalMin) globalMin = v;
        if (v > globalMax) globalMax = v;
      }
    }
    // Pad 15%
    final span = globalMax - globalMin;
    final padded = span * 0.15;
    globalMin = (globalMin - padded).clamp(0, double.infinity);
    globalMax = globalMax + padded;

    // Round to nice numbers for clean axis labels
    final niceMax = _niceRound(globalMax);
    final niceMin = globalMin.floorToDouble();

    return _AxisRange(min: niceMin, max: niceMax);
  }

  double _niceRound(double v) {
    if (v < 10) return v.ceilToDouble();
    if (v < 100) return (v / 5).ceil() * 5.0;
    return (v / 10).ceil() * 10.0;
  }
}

// ════════════════════════════════════════════════════════════════════════
// Helper widgets and types
// ════════════════════════════════════════════════════════════════════════

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(PulseTheme.cardRadius),
        boxShadow: PulseTheme.cardShadow(),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _LegendSectionLabel extends StatelessWidget {
  final String label;
  const _LegendSectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: PulseTheme.grey,
      ),
    );
  }
}

class _YAxisLabels extends StatelessWidget {
  final double min;
  final double max;
  const _YAxisLabels({required this.min, required this.max});

  @override
  Widget build(BuildContext context) {
    // 5 labels: top → bottom (max → min)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (int i = 0; i < 5; i++)
          Text(
            (max - ((max - min) * (i / 4))).round().toString(),
            style: const TextStyle(
              fontSize: 9,
              color: PulseTheme.grey,
              fontWeight: FontWeight.w500,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
      ],
    );
  }
}

class _AxisRange {
  final double min;
  final double max;
  const _AxisRange({required this.min, required this.max});
}
