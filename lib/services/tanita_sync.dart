import 'dart:async';

import 'package:app_auth/app_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tanita_service.dart';

/// Gleicht die Messdaten für angemeldete Nutzer mit der Cloud ab.
///
/// Ohne Anmeldung passiert nichts: Die Daten bleiben lokal. Der gesamte Bestand
/// liegt als ein Wert unter dem Schlüssel `data`. Da es keine Löschfunktion
/// gibt, genügt das Zusammenführen: Messungen werden über Datum und Uhrzeit
/// vereinigt, das Profil des jüngeren Imports gewinnt. Nach dem Zusammenführen
/// wird hochgeladen, wenn lokal etwas neu ist. Bei Ladefehlern wird nie "leer"
/// angenommen und überschrieben.
class TanitaSync extends ChangeNotifier {
  TanitaSync(this.service, this.auth, this._prefs, {CloudStore? store})
      : _store = store ?? CloudStore(auth, appId: 'tanita_anzeige') {
    service.onSaved = _onLocalChange;
    auth.addListener(_onAuthChange);
    _wasLoggedIn = auth.loggedIn;
    if (_wasLoggedIn) unawaited(syncNow());
  }

  static const _dataKey = 'data';
  static const _lastKey = 'tanita_anzeige.sync.last';
  static const _dirtyKey = 'tanita_anzeige.sync.dirty';
  static const _userKey = 'tanita_anzeige.sync.user';
  static const _timeKey = 'tanita_anzeige.sync.time';

  final TanitaService service;
  final AuthService auth;
  final SharedPreferences _prefs;
  final CloudStore _store;

  bool _wasLoggedIn = false;
  bool _busy = false;
  bool _again = false;
  Timer? _timer;

  /// 'idle', 'running' oder 'failed'; leer, solange nicht angemeldet.
  String _state = '';
  String get state => _state;

  /// Zeitpunkt des letzten erfolgreichen Abgleichs (lokal).
  DateTime? get lastSync {
    final raw = _prefs.getString(_timeKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  void _onAuthChange() {
    final now = auth.loggedIn;
    if (now && !_wasLoggedIn) {
      unawaited(syncNow());
    } else if (!now && _wasLoggedIn) {
      _state = '';
      notifyListeners();
    }
    _wasLoggedIn = now;
  }

  void _onLocalChange() {
    if (!auth.loggedIn) return;
    unawaited(_prefs.setBool(_dirtyKey, true));
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), () => unawaited(syncNow()));
  }

  /// Führt den Abgleich jetzt aus (läuft auch nach Anmeldung und Änderungen
  /// automatisch).
  Future<void> syncNow() async {
    if (!auth.loggedIn) return;
    if (_busy) {
      _again = true;
      return;
    }
    _busy = true;
    _state = 'running';
    notifyListeners();
    try {
      await _run();
      _state = 'idle';
      await _prefs.setString(_timeKey, DateTime.now().toIso8601String());
    } catch (_) {
      _state = 'failed';
    } finally {
      _busy = false;
      notifyListeners();
    }
    if (_again) {
      _again = false;
      unawaited(syncNow());
    }
  }

  Future<void> _run() async {
    final userId = auth.userId;
    final knownUser = _prefs.getString(_userKey);
    if (knownUser != null && knownUser != userId) {
      // Anderes Konto auf demselben Gerät: Daten des vorigen Kontos nicht in
      // dieses Konto übernehmen.
      await service.clearLocal();
      await _prefs.remove(_lastKey);
      await _prefs.remove(_dirtyKey);
    }
    if (userId != null) await _prefs.setString(_userKey, userId);

    final remote = await _store.load(_dataKey);
    final last = _prefs.getString(_lastKey);
    final dirty = _prefs.getBool(_dirtyKey) ?? false;

    var changed = false;
    if (remote != null) changed = await service.mergeFromJson(remote.json);
    final hasLocal = service.dataJson().contains('"m"');

    if (remote == null && !hasLocal) return;
    if (remote == null || last == null || dirty || changed) {
      final stamp = await _store.save(_dataKey, service.dataJson());
      if (stamp == null) throw const AuthFailure('Speichern fehlgeschlagen');
      await _prefs.setString(_lastKey, stamp.toUtc().toIso8601String());
      await _prefs.setBool(_dirtyKey, false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    auth.removeListener(_onAuthChange);
    service.onSaved = null;
    super.dispose();
  }
}
