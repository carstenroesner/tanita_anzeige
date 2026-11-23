import 'package:flutter_test/flutter_test.dart';
import 'package:tanita_anzeige/models/measurement.dart';

void main() {
  test('Ohne Geburtsdatum gilt der 1. Januar des Geburtsjahres', () {
    final slot = SlotData();
    slot.measurements.add(
      Measurement(
        at: DateTime(2021, 8, 9, 20, 17),
        values: const {'Wk': 54.1},
        age: 29,
      ),
    );
    expect(slot.birthDate, DateTime(1992, 1, 1));
    expect(slot.ageAt(DateTime(2021, 8, 9)), 29);
    expect(slot.ageAt(DateTime(2022, 1, 1)), 30);
  });

  test('Alter steigt über die Zeit an', () {
    final slot = SlotData();
    slot.measurements.add(
      Measurement(at: DateTime(2021, 8, 9), values: const {'Wk': 54.1}, age: 29),
    );
    final a0 = slot.ageYearsAt(DateTime(2021, 1, 1))!;
    final a1 = slot.ageYearsAt(DateTime(2022, 1, 1))!;
    expect(a1 - a0, closeTo(1.0, 0.01));
  });

  test('Mit Geburtsdatum aus dem Profil wird dieses verwendet', () {
    final slot = SlotData(profile: Profile(birth: DateTime(1990, 6, 15)));
    expect(slot.birthDate, DateTime(1990, 6, 15));
    expect(slot.ageAt(DateTime(2020, 6, 14)), 29);
    expect(slot.ageAt(DateTime(2020, 6, 15)), 30);
  });
}
