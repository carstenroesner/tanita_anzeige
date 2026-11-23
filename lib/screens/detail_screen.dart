import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/format.dart';
import '../l10n/strings.dart';
import '../models/metrics.dart';
import '../models/slot_view.dart';
import '../services/settings_service.dart';
import '../services/tanita_service.dart';
import '../widgets/charts.dart';
import '../widgets/status_chip.dart';

enum _Range { week, month, year, all }

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
  _Range _range = _Range.all;

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
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text(context.t('dash_no_data'))),
      );
    }
    final view = SlotView(data, hideSuspicious: settings.hideSuspicious);
    final last = view.last;
    if (last == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text(context.t('dash_no_data'))),
      );
    }

    final info = _metric.info;
    final end = last.at;
    final start = switch (_range) {
      _Range.week => end.subtract(const Duration(days: 7)),
      _Range.month => end.subtract(const Duration(days: 30)),
      _Range.year => end.subtract(const Duration(days: 365)),
      _Range.all => view.visible.first.at,
    };
    final points = <ChartPoint>[
      for (final m in view.visible)
        if (!m.at.isBefore(start) && _metric.valueOf(m) != null)
          ChartPoint(m.at, _metric.valueOf(m)!),
    ];
    final range = view.reference(_metric);
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
            ? tr(lang, 'ref_age_line', [num(range.opt!)])
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

    return Scaffold(
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
              SegmentedButton<_Range>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: _Range.week, label: Text(tr(lang, 'range_1w'))),
                  ButtonSegment(value: _Range.month, label: Text(tr(lang, 'range_1m'))),
                  ButtonSegment(value: _Range.year, label: Text(tr(lang, 'range_1y'))),
                  ButtonSegment(value: _Range.all, label: Text(tr(lang, 'range_all'))),
                ],
                selected: {_range},
                onSelectionChanged: (s) => setState(() => _range = s.first),
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
                  xLabel: (t) => fmtShortDate(lang, t),
                  numLabel: num,
                  upperLabel: upper,
                  lowerLabel: lower,
                  optLabel: opt,
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
