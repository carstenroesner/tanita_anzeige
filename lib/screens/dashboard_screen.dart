import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/format.dart';
import '../l10n/strings.dart';
import '../models/measurement.dart';
import '../models/metrics.dart';
import '../models/slot_view.dart';
import '../services/settings_service.dart';
import '../services/tanita_service.dart';
import '../widgets/backdrop.dart';
import '../widgets/charts.dart';
import 'detail_screen.dart';
import '../widgets/gradient_app_bar.dart';

/// Dashboard eines Slots: letzte Werte mit kleinem Verlauf.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.slotNumber});

  final int slotNumber;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final service = context.watch<TanitaService>();
    final lang = settings.language;
    final data = service.slot(slotNumber);
    final title = settings.nameOf(slotNumber) ?? tr(lang, 'slot_title', [slotNumber]);

    if (data == null) {
      return BackdropScaffold(
        appBar: GradientAppBar(title: Text(title)),
        body: Center(child: Text(context.t('dash_no_data'))),
      );
    }
    final view = SlotView(data, hideSuspicious: settings.hideSuspicious);
    final last = view.last;
    if (last == null) {
      return BackdropScaffold(
        appBar: GradientAppBar(title: Text(title)),
        body: Center(child: Text(context.t('dash_no_data'))),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return BackdropScaffold(
      appBar: GradientAppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                [
                  profileLine(lang, data),
                  tr(lang, 'dash_last', [fmtDateTime(lang, last.at)]),
                ].where((s) => s.isNotEmpty).join(' · '),
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 260,
                  mainAxisExtent: 156,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                children: [
                  for (final m in Metric.values)
                    if (m.valueOf(last) != null)
                      _KpiCard(
                        metric: m,
                        view: view,
                        slotNumber: slotNumber,
                        lang: lang,
                      ),
                ],
              ),
              const SizedBox(height: 20),
              _Segments(last: last, lang: lang),
              const SizedBox(height: 16),
              Text(
                context.t('dash_disclaimer'),
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.metric,
    required this.view,
    required this.slotNumber,
    required this.lang,
  });

  final Metric metric;
  final SlotView view;
  final int slotNumber;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final info = metric.info;
    final v = metric.valueOf(view.last!)!;
    final prev = view.previous == null ? null : metric.valueOf(view.previous!);
    final status = statusOf(view.reference(metric), v);
    String? delta;
    if (prev != null) {
      final d = v - prev;
      final sign = d > 0 ? '+' : (d < 0 ? '−' : '±');
      delta = tr(lang, 'delta_prev', [
        '$sign${fmtNum(lang, d.abs(), info.decimals)}',
      ]);
    }
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DetailScreen(slotNumber: slotNumber, metric: metric),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tr(lang, info.nameKey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ),
                  if (status != RefStatus.none) _dot(scheme, status),
                ],
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${fmtNum(lang, v, info.decimals)}${info.unit.isEmpty ? '' : ' ${info.unit}'}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
              if (delta != null)
                Text(
                  delta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                ),
              const Spacer(),
              Sparkline(values: view.recent(metric), height: 34),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(ColorScheme scheme, RefStatus s) {
    final color = switch (s) {
      RefStatus.ok => scheme.primary,
      RefStatus.under => scheme.tertiary,
      RefStatus.over => scheme.secondary,
      RefStatus.none => scheme.outline,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Segments extends StatelessWidget {
  const _Segments({required this.last, required this.lang});

  final Measurement last;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, String)>[
      ('seg_ra', 'Fr', 'mr'),
      ('seg_la', 'Fl', 'ml'),
      ('seg_rl', 'FR', 'mR'),
      ('seg_ll', 'FL', 'mL'),
      ('seg_trunk', 'FT', 'mT'),
    ];
    final has = rows.any((r) => last[r.$2] != null || last[r.$3] != null);
    if (!has) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    String f(double? v, String unit) =>
        v == null ? '–' : '${fmtNum(lang, v)} $unit';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(lang, 'dash_segments'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(flex: 3, child: SizedBox()),
                Expanded(
                  flex: 2,
                  child: Text(
                    tr(lang, 'dash_fat'),
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    tr(lang, 'dash_muscle'),
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(tr(lang, r.$1))),
                    Expanded(
                      flex: 2,
                      child: Text(f(last[r.$2], '%'), textAlign: TextAlign.end),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(f(last[r.$3], 'kg'), textAlign: TextAlign.end),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
