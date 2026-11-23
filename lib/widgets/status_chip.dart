import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/metrics.dart';

/// Kleine Marke mit Text („im Bereich“, „unter Bereich“ ...). Die Bedeutung
/// steht immer im Text, nicht nur in der Farbe.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final RefStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg, String key) = switch (status) {
      RefStatus.ok => (scheme.primaryContainer, scheme.onPrimaryContainer, 'st_ok'),
      RefStatus.under => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
          'st_under'
        ),
      RefStatus.over => (
          scheme.secondaryContainer,
          scheme.onSecondaryContainer,
          'st_over'
        ),
      RefStatus.none => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
          'st_none'
        ),
    };
    return LabeledChip(text: context.t(key), background: bg, foreground: fg);
  }
}

class LabeledChip extends StatelessWidget {
  const LabeledChip({
    super.key,
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
