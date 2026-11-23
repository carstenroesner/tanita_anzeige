import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/metrics.dart';

/// Ein Punkt einer Verlaufskurve.
class ChartPoint {
  const ChartPoint(this.t, this.v);

  final DateTime t;
  final double v;
}

/// Kleiner Verlauf ohne Achsen (für die Dashboard-Kacheln).
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, this.height = 30});

  final List<double> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Verlauf',
      child: CustomPaint(
        size: Size(double.infinity, height),
        painter: _SparkPainter(values, Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color);

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    var lo = values.reduce(math.min);
    var hi = values.reduce(math.max);
    if (hi - lo < 1e-9) {
      lo -= 1;
      hi += 1;
    }
    Offset at(int i) {
      final x = values.length == 1
          ? size.width / 2
          : 3 + (size.width - 6) * i / (values.length - 1);
      final y = size.height - 4 - (size.height - 8) * (values[i] - lo) / (hi - lo);
      return Offset(x, y);
    }

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      at(values.length - 1),
      3.2,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.values != values || old.color != color;
}

/// Großer Verlauf mit Achsen, Referenzband, oberer/unterer Grenze und Optimum.
class RangeChart extends StatelessWidget {
  const RangeChart({
    super.key,
    required this.points,
    required this.xMin,
    required this.xMax,
    required this.xLabel,
    required this.numLabel,
    this.range,
    this.upperLabel,
    this.lowerLabel,
    this.optLabel,
    this.optEnd,
    this.smooth = false,
    this.height = 280,
  });

  final List<ChartPoint> points;
  final DateTime xMin;
  final DateTime xMax;
  final RefRange? range;
  final String Function(DateTime) xLabel;
  final String Function(double) numLabel;
  final String? upperLabel;
  final String? lowerLabel;
  final String? optLabel;

  /// Wert der Optimum-Linie am rechten Rand; [RefRange.opt] gilt dann links.
  final double? optEnd;

  /// Geglättete Kurve statt der Rohdaten.
  final bool smooth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Verlaufsdiagramm',
      child: CustomPaint(
        size: Size(double.infinity, height),
        painter: _ChartPainter(
          points: points,
          xMin: xMin,
          xMax: xMax,
          range: range,
          xLabel: xLabel,
          numLabel: numLabel,
          upperLabel: upperLabel,
          lowerLabel: lowerLabel,
          optLabel: optLabel,
          optEnd: optEnd,
          smooth: smooth,
          line: scheme.primary,
          grid: scheme.outlineVariant,
          text: scheme.onSurfaceVariant,
          band: scheme.primary.withAlpha(34),
          bandText: scheme.primary,
          surface: scheme.surface,
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.points,
    required this.xMin,
    required this.xMax,
    required this.range,
    required this.xLabel,
    required this.numLabel,
    required this.upperLabel,
    required this.lowerLabel,
    required this.optLabel,
    required this.optEnd,
    required this.smooth,
    required this.line,
    required this.grid,
    required this.text,
    required this.band,
    required this.bandText,
    required this.surface,
  });

  final List<ChartPoint> points;
  final DateTime xMin;
  final DateTime xMax;
  final RefRange? range;
  final String Function(DateTime) xLabel;
  final String Function(double) numLabel;
  final String? upperLabel;
  final String? lowerLabel;
  final String? optLabel;
  final double? optEnd;
  final bool smooth;
  final Color line;
  final Color grid;
  final Color text;
  final Color band;
  final Color bandText;
  final Color surface;

  static double _niceStep(double raw) {
    if (raw <= 0) return 1;
    final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final norm = raw / mag;
    final nice = norm <= 1 ? 1 : (norm <= 2 ? 2 : (norm <= 5 ? 5 : 10));
    return nice * mag;
  }

  void _label(
    Canvas canvas,
    String s,
    Offset o, {
    Color? color,
    FontWeight weight = FontWeight.w400,
    bool alignRight = false,
    bool alignCenter = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: color ?? text,
          fontSize: 11,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    var dx = o.dx;
    if (alignRight) dx -= tp.width;
    if (alignCenter) dx -= tp.width / 2;
    tp.paint(canvas, Offset(dx, o.dy));
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 5.0;
    const gap = 4.0;
    final total = (b - a).distance;
    if (total <= 0) return;
    final dir = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      final end = math.min(d + dash, total);
      canvas.drawLine(a + dir * d, a + dir * end, paint);
      d += dash + gap;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    const left = 44.0;
    const right = 12.0;
    const top = 14.0;
    const bottom = 28.0;
    final plot = Rect.fromLTRB(left, top, size.width - right, size.height - bottom);
    if (plot.width <= 0 || plot.height <= 0) return;

    final vals = <double>[
      for (final p in points) p.v,
      if (range?.lo != null) range!.lo!,
      if (range?.hi != null) range!.hi!,
      if (range?.opt != null) range!.opt!,
      if (optEnd != null) optEnd!,
    ];
    if (vals.isEmpty) return;
    var lo = vals.reduce(math.min);
    var hi = vals.reduce(math.max);
    if (hi - lo < 1e-9) {
      lo -= 1;
      hi += 1;
    }
    final pad = (hi - lo) * 0.1;
    final yMin = lo - pad;
    final yMax = hi + pad;
    double y(double v) => plot.bottom - plot.height * (v - yMin) / (yMax - yMin);
    final span = xMax.difference(xMin).inMilliseconds;
    double x(DateTime t) => span <= 0
        ? plot.center.dx
        : plot.left + plot.width * t.difference(xMin).inMilliseconds / span;

    // Raster und Beschriftung der y-Achse
    final step = _niceStep((yMax - yMin) / 4);
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    var v = (yMin / step).ceil() * step;
    while (v <= yMax + 1e-9) {
      final yy = y(v);
      canvas.drawLine(Offset(plot.left, yy), Offset(plot.right, yy), gridPaint);
      _label(canvas, numLabel(v), Offset(plot.left - 6, yy - 6), alignRight: true);
      v += step;
    }

    // Referenzband mit Grenzen und Optimum
    final r = range;
    if (r != null && r.hasBand) {
      final bandTop = y(r.hi!).clamp(plot.top, plot.bottom).toDouble();
      final bandBot = y(r.lo!).clamp(plot.top, plot.bottom).toDouble();
      canvas.drawRect(
        Rect.fromLTRB(plot.left, bandTop, plot.right, bandBot),
        Paint()..color = band,
      );
      final limit = Paint()
        ..color = bandText
        ..strokeWidth = 1.5;
      if (y(r.hi!) >= plot.top && y(r.hi!) <= plot.bottom) {
        _dashed(canvas, Offset(plot.left, y(r.hi!)), Offset(plot.right, y(r.hi!)), limit);
        if (upperLabel != null) {
          _label(canvas, upperLabel!, Offset(plot.left + 6, y(r.hi!) - 15),
              color: bandText, weight: FontWeight.w600);
        }
      }
      if (y(r.lo!) >= plot.top && y(r.lo!) <= plot.bottom) {
        _dashed(canvas, Offset(plot.left, y(r.lo!)), Offset(plot.right, y(r.lo!)), limit);
        if (lowerLabel != null) {
          _label(canvas, lowerLabel!, Offset(plot.left + 6, y(r.lo!) + 3),
              color: bandText, weight: FontWeight.w600);
        }
      }
    }
    if (r != null && r.opt != null) {
      final startV = r.opt!;
      final endV = optEnd ?? startV;
      final y0 = y(startV);
      final y1 = y(endV);
      final optPaint = Paint()
        ..color = text
        ..strokeWidth = 1.2;
      final total = plot.width;
      for (var d = 0.0; d < total; d += 6) {
        final e = math.min(d + 2, total);
        canvas.drawLine(
          Offset(plot.left + d, y0 + (y1 - y0) * d / total),
          Offset(plot.left + e, y0 + (y1 - y0) * e / total),
          optPaint,
        );
      }
      if (optLabel != null) {
        final ly = (y1 - 15).clamp(plot.top, plot.bottom - 14).toDouble();
        _label(canvas, optLabel!, Offset(plot.right - 4, ly),
            color: text, weight: FontWeight.w600, alignRight: true);
      }
    }

    // x-Achse
    for (var i = 0; i < 4; i++) {
      final t = xMin.add(Duration(milliseconds: (span * i / 3).round()));
      final px = x(t);
      final lx = px.clamp(plot.left + 18, plot.right - 18).toDouble();
      _label(canvas, xLabel(t), Offset(lx, plot.bottom + 8), alignCenter: true);
    }

    // Kurve
    if (points.isEmpty) return;
    final linePaint = Paint()
      ..color = line
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = line;
    final raw = [for (final p in points) Offset(x(p.t), y(p.v))];
    final shown = smooth ? [for (final o in smoothed(raw)) o] : raw;

    final path = Path()..moveTo(shown.first.dx, shown.first.dy);
    if (smooth && shown.length > 2) {
      // Catmull-Rom als Bézier-Kurve
      for (var i = 0; i < shown.length - 1; i++) {
        final p0 = shown[i == 0 ? 0 : i - 1];
        final p1 = shown[i];
        final p2 = shown[i + 1];
        final p3 = shown[i + 2 < shown.length ? i + 2 : i + 1];
        path.cubicTo(
          p1.dx + (p2.dx - p0.dx) / 6,
          p1.dy + (p2.dy - p0.dy) / 6,
          p2.dx - (p3.dx - p1.dx) / 6,
          p2.dy - (p3.dy - p1.dy) / 6,
          p2.dx,
          p2.dy,
        );
      }
    } else {
      for (var i = 1; i < shown.length; i++) {
        path.lineTo(shown[i].dx, shown[i].dy);
      }
    }
    canvas.drawPath(path, linePaint);

    if (smooth) {
      // Rohwerte nur blass als Punkte
      final faint = Paint()..color = line.withAlpha(70);
      for (final o in raw) {
        canvas.drawCircle(o, 2.2, faint);
      }
    } else {
      for (final o in raw) {
        canvas.drawCircle(o, 2.2, dot);
      }
    }
    final lastO = shown.last;
    canvas.drawCircle(lastO, 6.5, Paint()..color = surface);
    canvas.drawCircle(lastO, 4.5, dot);
  }

  /// Gewichteter gleitender Durchschnitt (1-2-3-2-1) über die y-Werte.
  static List<Offset> smoothed(List<Offset> src) {
    if (src.length < 3) return src;
    const w = [1.0, 2.0, 3.0, 2.0, 1.0];
    final out = <Offset>[];
    for (var i = 0; i < src.length; i++) {
      var sum = 0.0;
      var wsum = 0.0;
      for (var k = -2; k <= 2; k++) {
        final j = i + k;
        if (j < 0 || j >= src.length) continue;
        sum += src[j].dy * w[k + 2];
        wsum += w[k + 2];
      }
      out.add(Offset(src[i].dx, sum / wsum));
    }
    return out;
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => true;
}
