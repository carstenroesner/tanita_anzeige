import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tanita_anzeige/content/feature_overview_content.dart';

void main() {
  test('FUNKTIONSUMFANG.md ist deckungsgleich mit dem In-App-Screen', () {
    final md = File('FUNKTIONSUMFANG.md').readAsStringSync();
    expect(md, contains('Stand: $featureOverviewStand'));

    var itemCount = 0;
    for (final section in featureOverviewSections) {
      expect(md, contains('## ${section.title}'));
      for (final item in section.items) {
        itemCount++;
        final prefix = switch (item.status) {
          FeatureStatus.done => '- [x] ',
          FeatureStatus.open => '- [ ] ',
          FeatureStatus.info => '- ',
        };
        expect(
          md,
          contains('$prefix${item.text}'),
          reason: 'Fehlt in FUNKTIONSUMFANG.md: ${item.text}',
        );
      }
    }

    final mdItems = md.split('\n').where((l) => l.startsWith('- ')).length;
    expect(mdItems, itemCount);
  });
}
