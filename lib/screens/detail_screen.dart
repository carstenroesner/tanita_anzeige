import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/format.dart';
import '../l10n/strings.dart';
import '../models/metrics.dart';
import '../models/slot_view.dart';
import '../services/settings_service.dart';
import '../services/tanita_service.dart';
import '../widgets/backdrop.dart';
import '../widgets/charts.dart';
import '../widgets/status_chip.dart';

enum _Range { week, month, quarter, year, all }

/// Großer Verlauf einer Größe mit Zeitraumfilter und Referenzlinien.
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.slotNumber, required this.metric});

  final int slotNumber;
  final Metric metric;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Metric _metric = widget.metric;
  _Range _range = _Range.quarter;

  /// Wie viele Zeiträume zurückgeblättert wurde (0 = aktuellster).
  int _offset = 0;

  static Duration _length(_Range r) => switch (r) {
        _Range.week => const Duration(days: 7),
        _Range.month => const Duration(days: 30),
        _Range.quarter => const Duration(days: 90),
        _Range.year => const Duration(days: 365),
        _Range.all => Duration.zero,
      };

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final service = context.watch<TanitaService>();
    final lang = settings.language;
    final scheme = Theme.of(context).colorScheme;
    final data = service.slot(widget.slotNumber);
    final title =
        settings.nameOf(widget.slotNumber) ?? tr(lang, 'slot_title', [widget.slotNumber]);
    if (data == null) {
      return BackdropScaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text(context.t('dash_no_data'))),
      );
    }
    final view = SlotView(data, hideSuspicious: settings.hideSuspicious);
    final last = view.last;
    if (last == null) {
      return BackdropScaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text(context.t('dash_no_data'))),
      );
    }

    final info = _metric.info;
    final first = view.visible.first.at;
    final len = _length(_range);
    final paged = _range != _Range.all;
    final end = paged ? last.at.subtract(len * _offset) : last.at;
    final start = paged ? end.subtract(len) : first;
    final canBack = paged && start.isAfter(first);
    final canForward = paged && _offset > 0;
    final points = <ChartPoint>[
      for (final m in view.visible)
        if (!m.at.isBefore(start) &&
            !m.at.isAfter(end) &&
            _metric.valueOf(m) != null)
          ChartPoint(m.at, _metric.valueOf(m)!),
    ];
    var range = view.reference(_metric);
    double? optEnd;
    if (_metric == Metric.metaAge) {
      // Tatsächliches Alter: steigt über den Zeitraum an.
      final a0 = data.ageYearsAt(start);
      final a1 = data.ageYearsAt(end);
      range = a0 == null || a1 == null ? null : RefRange(opt: a0);
      optEnd = a1;
    }
    final lastValue = _metric.valueOf(last);
    final status = lastValue == null ? RefStatus.none : statusOf(range, lastValue);

    String num(double v) => fmtNum(lang, v, info.decimals);
    String withUnit(double v) =>
        '${num(v)}${info.unit.isEmpty ? '' : ' ${info.unit}'}';

    String? upper, lower, opt;
    if (range != null) {
      if (range.hasBand) {
        upper = tr(lang, 'ref_upper', [num(range.hi!)]);
        lower = tr(lang, 'ref_lower', [num(range.lo!)]);
      }
      if (range.opt != null) {
        opt = _metric == Metric.metaAge
            ? tr(lang, 'ref_age_line', [num(optEnd ?? range.opt!)])
            : tr(lang, 'ref_opt', [num(range.opt!)]);
      }
    }

    final values = [for (final p in points) p.v];
    double? mn, mx, avg, change;
    if (values.isNotEmpty) {
      mn = values.reduce((a, b) => a < b ? a : b);
      mx = values.reduce((a, b) => a > b ? a : b);
      avg = values.reduce((a, b) => a + b) / values.length;
      change = values.last - values.first;
    }
    String refText;
    switch (_metric) {
      case Metric.bmi:
      case Metric.weight:
        refText = tr(lang, 'ref_text_bmi');
      case Metric.fat:
        refText = tr(lang, 'ref_text_fat');
      case Metric.water:
        refText = tr(lang, 'ref_text_water');
      case Metric.visceral:
        refText = tr(lang, 'ref_text_visceral');
      case Metric.metaAge:
        refText = tr(lang, 'ref_text_age');
      default:
        refText = tr(lang, 'ref_text_none');
    }
    if (range?.hasBand == true && range?.opt != null) {
      refText = '$refText ${tr(lang, 'ref_opt_note')}';
    }

    return BackdropScaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final m in Metric.values)
                      if (m.valueOf(last) != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(tr(lang, m.info.nameKey)),
                            selected: m == _metric,
                            onSelected: (_) => setState(() => _metric = m),
                          ),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    lastValue == null ? '–' : num(lastValue),
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(info.unit, style: TextStyle(color: scheme.onSurfaceVariant)),
                  ),
                  const Spacer(),
                  if (status != RefStatus.none) StatusChip(status: status),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final r in _Range.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(tr(lang, _rangeKey(r))),
                          selected: r == _range,
                          onSelected: (_) => setState(() {
                            _range = r;
                            _offset = 0;
                          }),
                        ),
                      ),
                  ],
                ),
              ),
              if (paged)
                Row(
                  children: [
                    IconButton(
                      tooltip: tr(lang, 'range_prev'),
                      icon: const Icon(Icons.chevron_left),
                      onPressed: canBack ? () => setState(() => _offset++) : null,
                    ),
                    Expanded(
                      child: Text(
                        '${fmtDate(lang, start)} – ${fmtDate(lang, end)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      tooltip: tr(lang, 'range_next'),
                      icon: const Icon(Icons.chevron_right),
                      onPressed: canForward ? () => setState(() => _offset--) : null,
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              if (points.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text(tr(lang, 'detail_no_points'))),
                )
              else
                RangeChart(
                  points: points,
                  xMin: start,
                  xMax: end,
                  range: range,
                  xLabel: (t) => len <= const Duration(days: 100) && paged
                      ? fmtDayMonth(lang, t)
                      : fmtShortDate(lang, t),
                  numLabel: num,
                  upperLabel: upper,
                  lowerLabel: lower,
                  optLabel: opt,
                  optEnd: optEnd,
                ),
              const SizedBox(height: 8),
              Text(
                tr(lang, 'detail_info', [tr(lang, info.nameKey), points.length]),
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              if (mn != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Stat(label: tr(lang, 'stat_min'), value: withUnit(mn)),
                    _Stat(label: tr(lang, 'stat_avg'), value: withUnit(avg!)),
                    _Stat(label: tr(lang, 'stat_max'), value: withUnit(mx!)),
                    _Stat(
                      label: tr(lang, 'stat_change'),
                      value: '${change! > 0 ? '+' : (change < 0 ? '−' : '±')}'
                          '${num(change.abs())}',
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Text(
                refText,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _rangeKey(_Range r) => switch (r) {
      _Range.week => 'range_1w',
      _Range.month => 'range_1m',
      _Range.quarter => 'range_3m',
      _Range.year => 'range_1y',
      _Range.all => 'range_all',
    };

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
