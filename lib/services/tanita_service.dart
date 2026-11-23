import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/measurement.dart';
import 'tanita_parser.dart';

/// Ergebnis des Imports für einen Slot.
class SlotImportResult {
  const SlotImportResult({
    required this.slot,
    required this.profile,
    required this.profileUpdated,
    required this.read,
    required this.added,
    required this.flagged,
  });

  final int slot;
  final Profile? profile;
  final bool profileUpdated;

  /// Anzahl gelesener Messungen und davon neu ergänzte.
  final int read;
  final int added;

  /// Anzahl auffälliger Messungen unter den neu ergänzten.
  final int flagged;
}

class ImportResult {
  const ImportResult({required this.slots, required this.filesRead});

  final List<SlotImportResult> slots;
  final int filesRead;

  bool get isEmpty => slots.isEmpty;
  int get flaggedTotal => slots.fold(0, (a, s) => a + s.flagged);
  int get addedTotal => slots.fold(0, (a, s) => a + s.added);
}

/// Hält alle Slots (1 bis 8) und speichert sie lokal.
class TanitaService extends ChangeNotifier {
  TanitaService(this._prefs) {
    _load();
  }

  static const _key = 'tanita_anzeige.data';

  final SharedPreferences _prefs;
  final Map<int, SlotData> _slots = {};

  /// Wird nach jeder lokalen Änderung aufgerufen (löst den Cloud-Abgleich aus).
  VoidCallback? onSaved;

  SlotData? slot(int n) {
    final s = _slots[n];
    return (s != null && s.hasData) ? s : null;
  }

  bool hasSlot(int n) => slot(n) != null;

  /// Zeitpunkt des letzten Imports über alle Slots.
  DateTime? get lastImport {
    DateTime? latest;
    for (final s in _slots.values) {
      final li = s.lastImport;
      if (li != null && (latest == null || li.isAfter(latest))) latest = li;
    }
    return latest;
  }

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      _slots
        ..clear()
        ..addAll(_parseSlots(raw));
    } catch (_) {
      _slots.clear();
    }
  }

  static Map<int, SlotData> _parseSlots(String json) {
    final map = (jsonDecode(json) as Map).cast<String, dynamic>();
    final slots = (map['slots'] as Map? ?? const {}).cast<String, dynamic>();
    final result = <int, SlotData>{};
    for (final e in slots.entries) {
      final n = int.tryParse(e.key);
      if (n == null) continue;
      result[n] = SlotData.fromJson((e.value as Map).cast<String, dynamic>());
    }
    return result;
  }

  /// Gesamter Bestand als JSON (gleichbleibende Reihenfolge).
  String dataJson() {
    final keys = _slots.keys.where((k) => _slots[k]!.hasData).toList()..sort();
    return jsonEncode({
      'v': 1,
      'slots': {for (final k in keys) '$k': _slots[k]!.toJson()},
    });
  }

  Future<void> _save() async {
    await _prefs.setString(_key, dataJson());
    notifyListeners();
    onSaved?.call();
  }

  /// Liest die gewählten Dateien (auch aus ZIP-Dateien samt Unterordnern):
  /// Profile werden aktualisiert, unbekannte Messungen ergänzt.
  Future<ImportResult> importFiles(List<ImportFile> picked, {DateTime? now}) async {
    final files = expandZips(picked);
    final profiles = <int, List<Profile>>{};
    final data = <int, List<Measurement>>{};
    var filesRead = 0;
    for (final f in files) {
      final kind = classifyName(f.name);
      if (kind == null) continue;
      filesRead++;
      final text = decodeText(f.bytes);
      if (kind.isProfile) {
        final p = parseProfile(text);
        if (p != null) profiles.putIfAbsent(kind.slot, () => []).add(p);
      } else {
        final list = parseData(text);
        if (list.isNotEmpty) data.putIfAbsent(kind.slot, () => []).addAll(list);
      }
    }

    final stamp = now ?? DateTime.now();
    final results = <SlotImportResult>[];
    final slotNumbers = {...profiles.keys, ...data.keys}.toList()..sort();
    for (final n in slotNumbers) {
      final slot = _slots.putIfAbsent(n, () => SlotData());
      var profileUpdated = false;
      Profile? newProfile;
      final plist = profiles[n];
      if (plist != null && plist.isNotEmpty) {
        newProfile = plist.last;
        if (slot.profile != newProfile) profileUpdated = true;
        slot.profile = newProfile;
        slot.profileAt = stamp;
      }
      final known = {for (final m in slot.measurements) m.key};
      final incoming = data[n] ?? const <Measurement>[];
      final added = <Measurement>[];
      for (final m in incoming) {
        if (known.add(m.key)) added.add(m);
      }
      slot.measurements
        ..addAll(added)
        ..sort((a, b) => a.at.compareTo(b.at));
      final bad = suspiciousKeys(slot.measurements);
      slot.lastImport = stamp;
      results.add(
        SlotImportResult(
          slot: n,
          profile: newProfile ?? slot.profile,
          profileUpdated: profileUpdated,
          read: incoming.length,
          added: added.length,
          flagged: added.where((m) => bad.contains(m.key)).length,
        ),
      );
    }
    if (results.isNotEmpty) await _save();
    return ImportResult(slots: results, filesRead: filesRead);
  }

  /// Führt den Bestand aus der Cloud mit dem lokalen zusammen (nichts geht
  /// verloren). Gibt `true` zurück, wenn sich lokal etwas geändert hat.
  Future<bool> mergeFromJson(String json) async {
    final before = dataJson();
    final remote = _parseSlots(json);
    for (final e in remote.entries) {
      final r = e.value;
      final l = _slots.putIfAbsent(e.key, () => SlotData());
      final known = {for (final m in l.measurements) m.key};
      for (final m in r.measurements) {
        if (known.add(m.key)) l.measurements.add(m);
      }
      l.measurements.sort((a, b) => a.at.compareTo(b.at));
      final rp = r.profileAt;
      final lp = l.profileAt;
      if (r.profile != null && (lp == null || (rp != null && rp.isAfter(lp)))) {
        l.profile = r.profile;
        l.profileAt = rp;
      }
      final rli = r.lastImport;
      final lli = l.lastImport;
      if (rli != null && (lli == null || rli.isAfter(lli))) l.lastImport = rli;
    }
    final changed = before != dataJson();
    if (changed) {
      await _prefs.setString(_key, dataJson());
      notifyListeners();
    }
    return changed;
  }

  /// Leert alle lokalen Daten (anderes Konto auf demselben Gerät).
  Future<void> clearLocal() async {
    _slots.clear();
    await _prefs.remove(_key);
    notifyListeners();
  }
}
