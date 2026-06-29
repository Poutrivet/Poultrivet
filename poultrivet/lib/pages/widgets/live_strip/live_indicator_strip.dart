// ════════════════════════════════════════════════════════════════════════
// PouliVet — Live System
// File: live_indicator_strip.dart
// Step: 10 of 14
//
// REFACTORED.
//
// Purpose: The full strip widget hosting 4 LiveIndicatorCard children.
// Subscribes to the PulseEngine singleton and rebuilds on every tick.
//
// What changed from the previous version:
//   • No longer runs its own IndicatorStreamService — subscribes directly
//     to PulseEngine.instance.
//   • Uses LiveBadge atom (was a hand-rolled status bar).
//   • No StatefulWidget needed — StreamBuilder handles state.
//   • Cleaner responsive grid with explicit breakpoints constant.
//
// Architecture: One engine, many widgets. This is the first widget that
// proves the pattern — same engine instance will power trajectory, regional,
// and top5 widgets in the next steps.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import 'atoms/live_badge.dart';
import 'indicator_data.dart';
import 'live_indicator_card.dart';
import 'pulse_engine.dart';
import 'pulse_models.dart';
import 'pulse_theme.dart';

class LiveIndicatorStrip extends StatelessWidget {
  /// Optional title shown above the strip.
  final String? title;
  final String? subtitle;

  /// Whether to show the "LIVE · streaming every 3s" status bar below.
  final bool showStatusBar;

  const LiveIndicatorStrip({
    super.key,
    this.title = 'National Environmental Pulse',
    this.subtitle = "Live satellite indicators across Uganda's 134 districts",
    this.showStatusBar = true,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure the engine is running — safe to call repeatedly.
    PulseEngine.instance.start();

    return StreamBuilder<PulseSnapshot>(
      stream: PulseEngine.instance.stream,
      initialData: PulseEngine.instance.snapshot,
      builder: (context, snap) {
        final indicators = snap.data?.indicators;
        if (indicators == null || indicators.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) _buildHeader(),
            const SizedBox(height: 14),
            _buildStrip(context, indicators),
            if (showStatusBar) ...[
              const SizedBox(height: 14),
              _buildStatusBar(),
            ],
          ],
        );
      },
    );
  }

  // ─── Header (label + title + subtitle) ────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'POULIVET · NATIONAL PULSE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            color: PulseTheme.gold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title!,
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: PulseTheme.forest,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 13,
              color: PulseTheme.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  // ─── Responsive grid: 4-up wide, 2x2 medium, stacked narrow ──────
  Widget _buildStrip(BuildContext context, Map<String, TimeSeries> data) {
    final width = MediaQuery.of(context).size.width;
    final columns = _columnsForWidth(width);

    // Build the cards in canonical indicator order (NDVI, Moisture, Temp, Water).
    // Skip any indicator that doesn't have data yet (defensive).
    final cards = <Widget>[
      for (final def in kAllIndicators)
        if (data[def.key] != null)
          LiveIndicatorCard(
            definition: def,
            series: data[def.key]!,
          ),
    ];

    // Single column — stack vertically with consistent gaps
    if (columns == 1) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    // Multi-column grid
    return _buildGrid(cards, columns);
  }

  /// Breakpoints: ≥1000px = 4 columns, ≥560px = 2 columns, else 1 column.
  int _columnsForWidth(double width) {
    if (width >= 1000) return 4;
    if (width >= 560) return 2;
    return 1;
  }

  /// Build a multi-column grid from a flat list of cards.
  /// Pads incomplete last row with empty Expanded widgets so alignment stays clean.
  Widget _buildGrid(List<Widget> cards, int columns) {
    final rows = <Widget>[];
    for (int i = 0; i < cards.length; i += columns) {
      final rowChildren = <Widget>[];
      for (int j = 0; j < columns; j++) {
        final cardIdx = i + j;
        if (cardIdx < cards.length) {
          rowChildren.add(Expanded(child: cards[cardIdx]));
        } else {
          rowChildren.add(const Expanded(child: SizedBox.shrink()));
        }
        if (j < columns - 1) {
          rowChildren.add(const SizedBox(width: 12));
        }
      }
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rowChildren,
          ),
        ),
      );
      if (i + columns < cards.length) {
        rows.add(const SizedBox(height: 12));
      }
    }
    return Column(children: rows);
  }

  // ─── Status bar below the strip (LiveBadge atom + description) ────
  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PulseTheme.greyPale),
      ),
      child: Row(
        children: const [
          LiveBadge(),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Streaming satellite indicators · auto-refreshing every 3 seconds',
              style: TextStyle(
                fontSize: 12,
                color: PulseTheme.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

