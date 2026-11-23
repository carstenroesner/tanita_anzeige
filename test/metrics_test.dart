import 'package:flutter_test/flutter_test.dart';
import 'package:tanita_anzeige/models/metrics.dart';

void main() {
  test('BMI-Bereich nach WHO', () {
    final r = referenceFor(Metric.bmi, gender: 1, height: 180, age: 40)!;
    expect(r.lo, 18.5);
    expect(r.hi, 24.9);
    expect(statusOf(r, 17.4), RefStatus.under);
    expect(statusOf(r, 22), RefStatus.ok);
    expect(statusOf(r, 31.6), RefStatus.over);
  });

  test('Gewichtsbereich aus BMI und Größe', () {
    final r = referenceFor(Metric.weight, gender: 1, height: 180, age: 40)!;
    expect(r.lo, closeTo(18.5 * 1.8 * 1.8, 1e-9));
    expect(r.hi, closeTo(24.9 * 1.8 * 1.8, 1e-9));
  });

  test('Körperfett nach Geschlecht und Alter', () {
    final m = referenceFor(Metric.fat, gender: 1, height: 180, age: 50)!;
    expect((m.lo, m.hi), (11.0, 21.0));
    final f = referenceFor(Metric.fat, gender: 2, height: 160, age: 30)!;
    expect((f.lo, f.hi), (21.0, 33.0));
    expect(referenceFor(Metric.fat, gender: null, height: 1, age: 1), isNull);
  });

  test('Ohne Referenz: Muskel, Grundumsatz, Knochen', () {
    for (final m in [Metric.muscle, Metric.bmr, Metric.bone]) {
      expect(referenceFor(m, gender: 1, height: 180, age: 40), isNull);
    }
    expect(statusOf(null, 1), RefStatus.none);
  });
}
