import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';
import 'strings_data.dart';

/// Unterstützte Sprachen (Deutsch ist die Primärsprache).
const List<String> kLanguages = ['de', 'en', 'nl', 'es'];

const Map<String, String> kLanguageNames = {
  'de': 'Deutsch',
  'en': 'English',
  'nl': 'Nederlands',
  'es': 'Español',
};

/// Übersetzt [key] in [lang]; Platzhalter {0}, {1} ... werden ersetzt.
String tr(String lang, String key, [List<Object?> args = const []]) {
  var s = kStrings[lang]?[key] ?? kStrings['de']![key] ?? key;
  for (var i = 0; i < args.length; i++) {
    s = s.replaceAll('{$i}', '${args[i]}');
  }
  return s;
}

extension TrContext on BuildContext {
  /// Übersetzung in der aktuell gewählten Sprache (nur in build() verwenden).
  String t(String key, [List<Object?> args = const []]) =>
      tr(watch<SettingsService>().language, key, args);
}
