import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Einstellungen der App (nur lokal gespeichert).
class SettingsService extends ChangeNotifier {
  SettingsService(this._prefs) {
    _load();
  }

  static const _key = 'tanita_anzeige.settings';

  final SharedPreferences _prefs;

  String _language = 'de';
  int _remindDays = 14;
  int _slotCount = 4;
  bool _hideSuspicious = true;
  final Map<int, String> _names = {};

  /// Der Hinweis „Import fällig“ wurde in dieser Sitzung weggeklickt.
  bool dueDismissed = false;

  String get language => _language;
  int get remindDays => _remindDays;
  int get slotCount => _slotCount;
  bool get hideSuspicious => _hideSuspicious;

  String? nameOf(int slot) {
    final n = _names[slot]?.trim();
    return (n == null || n.isEmpty) ? null : n;
  }

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      final m = (jsonDecode(raw) as Map).cast<String, dynamic>();
      _language = (m['lang'] as String?) ?? 'de';
      _remindDays = (m['remind'] as num?)?.toInt() ?? 14;
      _slotCount = (m['slots'] as num?)?.toInt() == 8 ? 8 : 4;
      _hideSuspicious = (m['hide'] as bool?) ?? true;
      final names = (m['names'] as Map?)?.cast<String, dynamic>() ?? const {};
      for (final e in names.entries) {
        final n = int.tryParse(e.key);
        if (n != null) _names[n] = '${e.value}';
      }
    } catch (_) {
      // Beschädigte Einstellungen: Standardwerte verwenden.
    }
  }

  Future<void> _save() async {
    await _prefs.setString(
      _key,
      jsonEncode({
        'lang': _language,
        'remind': _remindDays,
        'slots': _slotCount,
        'hide': _hideSuspicious,
        'names': {for (final e in _names.entries) '${e.key}': e.value},
      }),
    );
    notifyListeners();
  }

  Future<void> setLanguage(String v) {
    _language = v;
    return _save();
  }

  Future<void> setRemindDays(int v) {
    _remindDays = v.clamp(1, 90);
    return _save();
  }

  Future<void> setSlotCount(int v) {
    _slotCount = v == 8 ? 8 : 4;
    return _save();
  }

  Future<void> setHideSuspicious(bool v) {
    _hideSuspicious = v;
    return _save();
  }

  Future<void> setName(int slot, String name) {
    final n = name.trim();
    if (n.isEmpty) {
      _names.remove(slot);
    } else {
      _names[slot] = n;
    }
    return _save();
  }

  void dismissDue() {
    dueDismissed = true;
    notifyListeners();
  }
}
