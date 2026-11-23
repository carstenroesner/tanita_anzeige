import 'measurement.dart';

/// Darstellbare Messwerte.
enum Metric { weight, fat, bmi, muscle, water, visceral, bmr, metaAge, bone }

class MetricInfo {
  const MetricInfo(this.field, this.nameKey, this.unit, this.decimals);

  /// Kürzel in den CSV-Dateien.
  final String field;
  final String nameKey;
  final String unit;
  final int decimals;
}

const Map<Metric, MetricInfo> kMetricInfo = {
  Metric.weight: MetricInfo('Wk', 'm_weight', 'kg', 1),
  Metric.fat: MetricInfo('FW', 'm_fat', '%', 1),
  Metric.bmi: MetricInfo('MI', 'm_bmi', '', 1),
  Metric.muscle: MetricInfo('mW', 'm_muscle', 'kg', 1),
  Metric.water: MetricInfo('ww', 'm_water', '%', 1),
  Metric.visceral: MetricInfo('IF', 'm_visceral', '', 0),
  Metric.bmr: MetricInfo('rD', 'm_bmr', 'kcal', 0),
  Metric.metaAge: MetricInfo('rA', 'm_age', '', 0),
  Metric.bone: MetricInfo('bW', 'm_bone', 'kg', 1),
};

extension MetricX on Metric {
  MetricInfo get info => kMetricInfo[this]!;
  double? valueOf(Measurement m) => m[info.field];
}

/// Referenzbereich: unterer und oberer Grenzwert sowie Optimum (Mitte).
class RefRange {
  const RefRange({this.lo, this.hi, this.opt});

  final double? lo;
  final double? hi;
  final double? opt;

  bool get hasBand => lo != null && hi != null;
}

enum RefStatus { under, ok, over, none }

RefStatus statusOf(RefRange? r, double value) {
  if (r == null || !r.hasBand) return RefStatus.none;
  if (value < r.lo!) return RefStatus.under;
  if (value > r.hi!) return RefStatus.over;
  return RefStatus.ok;
}

/// BMI-Grenzen der WHO für Erwachsene (unabhängig von Alter und Geschlecht).
const double kBmiLow = 18.5;
const double kBmiHigh = 24.9;

/// Referenzbereich für [m]. Quellen: WHO (BMI), Tanita Healthy Range
/// (Körperfett nach Gallagher et al. 2000, Körperwasser, Viszeralfett).
/// [gender]: 1 männlich, 2 weiblich.
RefRange? referenceFor(
  Metric m, {
  required int? gender,
  required double? height,
  required int? age,
}) {
  switch (m) {
    case Metric.bmi:
      return const RefRange(
        lo: kBmiLow,
        hi: kBmiHigh,
        opt: (kBmiLow + kBmiHigh) / 2,
      );
    case Metric.weight:
      if (height == null || height <= 0) return null;
      final h = height / 100;
      final sq = h * h;
      return RefRange(
        lo: kBmiLow * sq,
        hi: kBmiHigh * sq,
        opt: (kBmiLow + kBmiHigh) / 2 * sq,
      );
    case Metric.fat:
      if (gender == null || age == null) return null;
      final (double lo, double hi) = gender == 2
          ? (age <= 39 ? (21.0, 33.0) : (age <= 59 ? (23.0, 34.0) : (24.0, 36.0)))
          : (age <= 39 ? (8.0, 19.0) : (age <= 59 ? (11.0, 21.0) : (13.0, 25.0)));
      return RefRange(lo: lo, hi: hi, opt: (lo + hi) / 2);
    case Metric.water:
      if (gender == null) return null;
      return gender == 2
          ? const RefRange(lo: 45, hi: 60, opt: 52.5)
          : const RefRange(lo: 50, hi: 65, opt: 57.5);
    case Metric.visceral:
      return const RefRange(lo: 1, hi: 12);
    case Metric.metaAge:
      return age == null ? null : RefRange(opt: age.toDouble());
    case Metric.muscle:
    case Metric.bmr:
    case Metric.bone:
      return null;
  }
}
