import 'package:flutter/material.dart';

import '../content/feature_overview_content.dart';
import '../widgets/gradient_app_bar.dart';

/// Zeigt den Funktionsumfang der App (deckungsgleich mit FUNKTIONSUMFANG.md).
class FeatureOverviewScreen extends StatelessWidget {
  const FeatureOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: GradientAppBar(title: const Text('Funktionsumfang')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Stand: $featureOverviewStand',
                style: theme.textTheme.bodySmall,
              ),
              for (final section in featureOverviewSections) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 8),
                  child: Text(section.title, style: theme.textTheme.titleLarge),
                ),
                for (final item in section.items) _ItemRow(item: item),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final FeatureItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (IconData icon, Color color) = switch (item.status) {
      FeatureStatus.done => (Icons.check_circle, scheme.primary),
      FeatureStatus.open => (Icons.radio_button_unchecked, scheme.outline),
      FeatureStatus.info => (Icons.info_outline, scheme.secondary),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(item.text)),
        ],
      ),
    );
  }
}
