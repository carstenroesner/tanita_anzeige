import '../l10n/strings.dart';
import 'measurement.dart';
import 'metrics.dart';

/// Sicht auf einen Slot: optional ohne auffällige Messungen.
class SlotView {
  SlotView(this.slot, {required bool hideSuspicious})
      : flagged = suspiciousKeys(slot.measurements) {
    visible = hideSuspicious
        ? [
            for (final m in slot.measurements)
              if (!flagged.contains(m.key)) m,
          ]
        : List<Measurement>.of(slot.measurements);
  }

  final SlotData slot;
  final Set<String> flagged;
  late final List<Measurement> visible;

  Measurement? get last => visible.isEmpty ? null : visible.last;
  Measurement? get previous =>
      visible.length < 2 ? null : visible[visible.length - 2];

  /// Letzte Werte einer Größe, älteste zuerst.
  List<double> recent(Metric m, [int n = 30]) {
    final start = visible.length > n ? visible.length - n : 0;
    return [
      for (var i = start; i < visible.length; i++)
        if (m.valueOf(visible[i]) != null) m.valueOf(visible[i])!,
    ];
  }

  /// Referenzbereich für die Größe [m] zum Zeitpunkt der letzten Messung.
  RefRange? reference(Metric m) {
    final l = last;
    return referenceFor(
      m,
      gender: slot.gender,
      height: slot.height,
      age: slot.ageAt(l?.at ?? DateTime.now()),
    );
  }
}

/// Kurzbeschreibung des Profils, zum Beispiel „männlich · 55 J. · 186 cm“.
String profileLine(String lang, SlotData slot) {
  final g = slot.gender;
  final h = slot.height;
  final age = slot.ageAt(DateTime.now());
  if (g == null || h == null || age == null) return '';
  return tr(lang, 'profile_line', [
    tr(lang, g == 2 ? 'sex_f' : 'sex_m'),
    age,
    h.round(),
  ]);
}
