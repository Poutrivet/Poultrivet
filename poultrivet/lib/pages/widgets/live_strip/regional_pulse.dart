// ════════════════════════════════════════════════════════════════════════
// PouliVet — Live System
// File: regional_pulse.dart
// Step: 12 of 14 (v2 — color cleanup)
//
// Color cleanup: dropped the invented coral/peach/mint gradient end-colors.
// Bars now use PulseTheme.riskHigh / riskMedium / riskLow as SOLID colors,
// matching the Summary Cards and Trajectory chart's red exactly. Hard
// consistency — every HIGH-risk red on the page is the same red.
//
// The shimmer effect stays — that's what gives the bars their "live"
// feel. The decoration work is now done by shimmer alone, not gradient + shimmer.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import 'atoms/live_badge.dart';
import 'atoms/pulsing_dot.dart';
import 'atoms/shimmer_bar.dart';
import 'atoms/tween_number.dart';
import 'pulse_engine.dart';
import 'pulse_models.dart';
import 'pulse_theme.dart';

class RegionalPulse extends StatelessWidget {
  const RegionalPulse({super.key});

  @override
  Widget build(BuildContext context) {
    PulseEngine.instance.start();

    return StreamBuilder<PulseSnapshot>(
      stream: PulseEngine.instance.stream,
      initialData: PulseEngine.instance.snapshot,
      builder: (context, snap) {
        final regional = snap.data?.regional;
        if (regional == null || regional.isEmpty) {
          return const _LoadingCard();
        }
        return _RegionalCard(regional: regional);
      },
    );
  }
}

class _RegionalCard extends StatelessWidget {
  final Map<String, RegionalData> regional;
  const _RegionalCard({required this.regional});

  static const List<String> _displayOrder = [
    'central',
    'eastern',
    'northern',
    'western',
  ];

  @override
  Widget build(BuildContext context) {
    final orderedRegions = <RegionalData>[
      for (final key in _displayOrder)
        if (regional[key] != null) regional[key]!,
    ];

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
          const SizedBox(height: 4),
          _buildHelper(),
          const SizedBox(height: 12),
          for (int i = 0; i < orderedRegions.length; i++) ...[
            _RegionRow(region: orderedRegions[i]),
            if (i < orderedRegions.length - 1)
              const Divider(
                color: PulseTheme.greyPale,
                height: 1,
                thickness: 1,
              ),
          ],
          const SizedBox(height: 14),
          const Divider(color: PulseTheme.greyPale, height: 1),
          const SizedBox(height: 12),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌍  ', style: TextStyle(fontSize: 15)),
            Text(
              'Regional Pulse',
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

  Widget _buildHelper() {
    return const Text(
      "Risk distribution across Uganda's four regions",
      style: TextStyle(
        fontSize: 11,
        color: PulseTheme.grey,
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        _swatchLabel(color: PulseTheme.riskHigh, label: 'HIGH'),
        const SizedBox(width: 12),
        _swatchLabel(color: PulseTheme.riskMedium, label: 'MEDIUM'),
        const SizedBox(width: 12),
        _swatchLabel(color: PulseTheme.riskLow, label: 'LOW'),
        const Spacer(),
        Text(
          _currentTimeString(),
          style: const TextStyle(
            fontSize: 10,
            color: PulseTheme.darkText,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _swatchLabel({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: PulseTheme.grey,
            fontWeight: FontWeight.w600,
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
}

class _RegionRow extends StatelessWidget {
  final RegionalData region;
  const _RegionRow({required this.region});

  @override
  Widget build(BuildContext context) {
    final severityColor = _colorForSeverity(region.severity);
    final pulseStrength = _strengthForSeverity(region.severity);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 76,
                child: Text(
                  region.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: PulseTheme.darkText,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenNumber(
                    value: region.high.toDouble(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: severityColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'HIGH',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: severityColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              PulsingDot(
                color: severityColor,
                strength: pulseStrength,
                size: 8,
              ),
              const SizedBox(width: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenNumber(
                    value: region.total.toDouble(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: PulseTheme.darkText,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'districts',
                    style: TextStyle(
                      fontSize: 11,
                      color: PulseTheme.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ─── Stacked HIGH/MEDIUM/LOW bar — SOLID brand colors ─────
          ClipRRect(
            borderRadius: BorderRadius.circular(PulseTheme.barRadius),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (region.high > 0)
                    Expanded(
                      flex: region.high,
                      child: const ShimmerBar(
                        value: 1.0,
                        color: PulseTheme.riskHigh,
                        height: 12,
                        radius: 0,
                        shimmerEnabled: true,
                        shimmerIntensity: 0.45,
                      ),
                    ),
                  if (region.medium > 0)
                    Expanded(
                      flex: region.medium,
                      child: const ShimmerBar(
                        value: 1.0,
                        color: PulseTheme.riskMedium,
                        height: 12,
                        radius: 0,
                        shimmerEnabled: false,
                      ),
                    ),
                  if (region.low > 0)
                    Expanded(
                      flex: region.low,
                      child: const ShimmerBar(
                        value: 1.0,
                        color: PulseTheme.riskLow,
                        height: 12,
                        radius: 0,
                        shimmerEnabled: false,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _colorForSeverity(RegionSeverity s) {
    switch (s) {
      case RegionSeverity.high:
        return PulseTheme.riskHigh;
      case RegionSeverity.medium:
        return PulseTheme.riskMedium;
      case RegionSeverity.low:
        return PulseTheme.riskLow;
    }
  }

  static PulseStrength _strengthForSeverity(RegionSeverity s) {
    switch (s) {
      case RegionSeverity.high:
        return PulseStrength.high;
      case RegionSeverity.medium:
        return PulseStrength.normal;
      case RegionSeverity.low:
        return PulseStrength.soft;
    }
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(PulseTheme.cardRadius),
        boxShadow: PulseTheme.cardShadow(),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
