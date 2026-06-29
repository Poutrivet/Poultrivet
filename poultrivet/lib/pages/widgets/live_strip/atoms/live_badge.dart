// ════════════════════════════════════════════════════════════════════════
// PouliVet — Live System
// File: atoms/live_badge.dart
// Step: 8 of 14
//
// THE FIFTH AND FINAL REUSABLE ATOM.
//
// Purpose: A small "● Live" indicator that sits in the corner of every
// live card. Tells the user at a glance "this data is streaming."
//
// COMPOSES `PulsingDot` — first example of atoms building on atoms.
// Rather than re-implementing pulse logic, this widget uses our existing
// PulsingDot atom and just adds the label + container styling.
//
// Two variants:
//   • LiveBadgeStyle.minimal  → just dot + label, no background.
//                               Used inside cards next to titles.
//   • LiveBadgeStyle.pill     → full pill with green-tinted background.
//                               Used standalone for emphasis (e.g. status bars).
//
// Optional timestamp display — shows last-update time alongside, in cases
// where data freshness matters explicitly to the user.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../pulse_theme.dart';
import 'pulsing_dot.dart';

/// Visual style of the badge.
enum LiveBadgeStyle {
  /// Just dot + "LIVE" text, no background. For in-card corners.
  minimal,

  /// Full pill with green-tinted background. For standalone emphasis.
  pill,
}

class LiveBadge extends StatelessWidget {
  /// Visual style — minimal or pill.
  final LiveBadgeStyle style;

  /// Color of the pulsing dot and (in pill style) the text.
  /// Defaults to PulseTheme.sage (the live system's signature live-green).
  final Color color;

  /// Label text. Defaults to "Live".
  final String label;

  /// Optional timestamp string to show next to the label.
  /// Pass null to hide. Example: "Updated 14:32:08".
  final String? timestamp;

  /// Font size for the label.
  final double fontSize;

  const LiveBadge({
    super.key,
    this.style = LiveBadgeStyle.minimal,
    this.color = PulseTheme.sage,
    this.label = 'Live',
    this.timestamp,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    // The atomic core — pulsing dot + label
    final core = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PulsingDot(
          color: color,
          strength: PulseStrength.normal,
          size: 6,
        ),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: style == LiveBadgeStyle.pill ? color : PulseTheme.grey,
          ),
        ),
        if (timestamp != null) ...[
          const SizedBox(width: 8),
          Text(
            timestamp!,
            style: TextStyle(
              fontSize: fontSize - 1,
              fontWeight: FontWeight.w600,
              color: PulseTheme.grey,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );

    if (style == LiveBadgeStyle.minimal) return core;

    // Pill style — wrap in a soft-tinted rounded container
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: core,
    );
  }
}
