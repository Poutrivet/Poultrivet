// ════════════════════════════════════════════════════════════════════════
// PouliVet — Live System
// File: top5_districts_live.dart
// Step: 13 of 14 (v2 — color cleanup)
//
// Color cleanup: dropped the invented coral/peach/mint gradient end-colors.
// The progress bars now use PulseTheme.riskHigh / riskMedium / riskLow as
// SOLID colors, matching the Summary Cards exactly.
//
// What stays:
//   • Continuous shimmer sweep (the "alive" feel comes from shimmer alone)
//   • Pulsing dot with severity-driven strength
//   • Trend arrow with semantic colors
//   • TweenNumber for smooth score animation
//   • Live reordering via ValueKey
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import 'atoms/live_badge.dart';
import 'atoms/pulsing_dot.dart';
import 'atoms/shimmer_bar.dart';
import 'atoms/trend_arrow.dart';
import 'atoms/tween_number.dart';
import 'pulse_engine.dart';
import 'pulse_models.dart';
import 'pulse_theme.dart';

class Top5DistrictsLive extends StatelessWidget {
  const Top5DistrictsLive({super.key});

  @override
  Widget build(BuildContext context) {
    PulseEngine.instance.start();

    return StreamBuilder<PulseSnapshot>(
      stream: PulseEngine.instance.stream,
      initialData: PulseEngine.instance.snapshot,
      builder: (context, snap) {
        final districts = snap.data?.topDistricts;
        if (districts == null || districts.isEmpty) {
          return const _LoadingCard();
        }
        return _Top5Card(districts: districts);
      },
    );
  }
}

class _Top5Card extends StatelessWidget {
  final List<DistrictRanking> districts;
  const _Top5Card({required this.districts});

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 16),
          for (int i = 0; i < districts.length; i++) ...[
            _DistrictRow(
              key: ValueKey(districts[i].name),
              district: districts[i],
              rank: i + 1,
            ),
            if (i < districts.length - 1) const SizedBox(height: 14),
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
            Text('⚠️  ', style: TextStyle(fontSize: 15)),
            Text(
              'Top 5 Highest Risk Districts',
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

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'This week · auto-monitoring',
          style: TextStyle(fontSize: 10, color: PulseTheme.grey),
        ),
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

  String _currentTimeString() {
    final now = DateTime.now();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(now.hour)}:${pad(now.minute)}:${pad(now.second)}';
  }
}

class _DistrictRow extends StatelessWidget {
  final DistrictRanking district;
  final int rank;

  const _DistrictRow({
    super.key,
    required this.district,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final tierColor = _colorForTier(district.tier);
    final pulseStrength = _strengthForTier(district.tier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: rank + name + dot + trend + score badge
        Row(
          children: [
            SizedBox(
              width: 16,
              child: Text(
                '$rank.',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: PulseTheme.grey,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                district.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: PulseTheme.darkText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            PulsingDot(
              color: tierColor,
              strength: pulseStrength,
              size: 7,
            ),
            const SizedBox(width: 10),
            TrendArrow(
              delta: district.delta.toDouble(),
              semantic: TrendSemantic.risk,
              style: TrendArrowStyle.bare,
              showValue: false,
              fontSize: 13,
              flatThreshold: 0.5,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: tierColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenNumber(
                    value: district.score.toDouble(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: tierColor,
                    ),
                  ),
                  Text(
                    '/10',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: tierColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // ─── Progress bar — SOLID brand color, shimmer for liveness ──
        ShimmerBar(
          value: district.fraction,
          color: tierColor,
          height: 10,
          shimmerEnabled: true,
          shimmerIntensity: 0.5,
        ),
        const SizedBox(height: 4),

        Text(
          district.diseases,
          style: const TextStyle(
            fontSize: 11,
            color: PulseTheme.grey,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  static Color _colorForTier(DistrictRiskTier t) {
    switch (t) {
      case DistrictRiskTier.high:
        return PulseTheme.riskHigh;
      case DistrictRiskTier.medium:
        return PulseTheme.riskMedium;
      case DistrictRiskTier.low:
        return PulseTheme.riskLow;
    }
  }

  static PulseStrength _strengthForTier(DistrictRiskTier t) {
    switch (t) {
      case DistrictRiskTier.high:
        return PulseStrength.high;
      case DistrictRiskTier.medium:
        return PulseStrength.normal;
      case DistrictRiskTier.low:
        return PulseStrength.soft;
    }
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(PulseTheme.cardRadius),
        boxShadow: PulseTheme.cardShadow(),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
