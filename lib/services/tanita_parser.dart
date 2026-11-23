import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../models/measurement.dart';

/// Eine vom Nutzer gewählte Datei (Name, gegebenenfalls mit Pfad, und Inhalt).
class ImportFile {
  const ImportFile(this.name, this.bytes);

  final String name;
  final Uint8List bytes;
}

/// Zerlegt eine Zeile wie `{0,16,~0,2,...,MO,"BC-601",DT,"03/02/2019",...}` in
/// Kürzel und Wert. Kürzel sind genau zwei Buchstaben, danach folgt der Wert.
Map<String, String> tokenizeLine(String line) {
  final parts = line.trim().split(',');
  final result = <String, String>{};
  final isKey = RegExp(r'^[A-Za-z]{2}$');
  var i = 0;
  while (i < parts.length - 1) {
    final k = parts[i].trim();
    if (isKey.hasMatch(k)) {
      result[k] = parts[i + 1].trim().replaceAll('"', '').replaceAll('}', '');
      i += 2;
    } else {
      i += 1;
    }
  }
  return result;
}

/// Datum im Format TT/MM/JJJJ.
DateTime? parseDmy(String? d) {
  if (d == null) return null;
  final m = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(d.trim());
  if (m == null) return null;
  final day = int.parse(m.group(1)!);
  final month = int.parse(m.group(2)!);
  final year = int.parse(m.group(3)!);
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  return DateTime(year, month, day);
}

/// Liest den Text einer DATAn.CSV. Ungültige Zeilen werden übersprungen.
List<Measurement> parseData(String text) {
  final result = <Measurement>[];
  for (final line in const LineSplitter().convert(text)) {
    final t = line.trim();
    if (!t.startsWith('{')) continue;
    final tok = tokenizeLine(t);
    final date = parseDmy(tok['DT']);
    final time = RegExp(r'^(\d{1,2}):(\d{2}):(\d{2})$').firstMatch(tok['Ti'] ?? '');
    if (date == null || time == null) continue;
    final values = <String, double>{};
    for (final f in kFields) {
      final v = double.tryParse(tok[f] ?? '');
      if (v != null) values[f] = v;
    }
    if (!values.containsKey('Wk')) continue;
    result.add(
      Measurement(
        at: DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(time.group(1)!),
          int.parse(time.group(2)!),
          int.parse(time.group(3)!),
        ),
        values: values,
        age: int.tryParse(tok['AG'] ?? ''),
        gender: int.tryParse(tok['GE'] ?? ''),
        height: double.tryParse(tok['Hm'] ?? ''),
      ),
    );
  }
  return result;
}

/// Liest den Text einer PROFn.CSV; `null`, wenn die Datei leer ist.
Profile? parseProfile(String text) {
  for (final line in const LineSplitter().convert(text)) {
    final t = line.trim();
    if (!t.startsWith('{')) continue;
    final tok = tokenizeLine(t);
    final profile = Profile(
      gender: int.tryParse(tok['GE'] ?? ''),
      height: double.tryParse(tok['Hm'] ?? ''),
      birth: parseDmy(tok['DB']),
      activity: int.tryParse(tok['AL'] ?? ''),
    );
    if (profile.gender == null &&
        profile.height == null &&
        profile.birth == null) {
      continue;
    }
    return profile;
  }
  return null;
}

/// Ergebnis der Namenserkennung: Profil- oder Messdatei und Slot (1 bis 8).
class FileKind {
  const FileKind(this.isProfile, this.slot);

  final bool isProfile;
  final int slot;
}

/// Erkennt `PROF1.CSV` bis `PROF8.CSV` und `DATA1.CSV` bis `DATA8.CSV` (Groß-
/// und Kleinschreibung egal, Pfad egal). Alles andere (zum Beispiel
/// `DATA1 Kopie.CSV`) wird ignoriert.
FileKind? classifyName(String name) {
  final base = name.split(RegExp(r'[\\/]')).last.toUpperCase();
  final m = RegExp(r'^(PROF|DATA)([1-8])\.CSV$').firstMatch(base);
  if (m == null) return null;
  return FileKind(m.group(1) == 'PROF', int.parse(m.group(2)!));
}

String decodeText(Uint8List bytes) => utf8.decode(bytes, allowMalformed: true);

/// Packt ZIP-Dateien aus, inklusive aller Unterordner. Andere Dateien bleiben
/// unverändert.
List<ImportFile> expandZips(List<ImportFile> files) {
  final out = <ImportFile>[];
  for (final f in files) {
    if (f.name.toLowerCase().endsWith('.zip')) {
      try {
        final archive = ZipDecoder().decodeBytes(f.bytes);
        for (final entry in archive) {
          if (!entry.isFile) continue;
          final data = entry.content;
          if (data is List<int>) {
            out.add(ImportFile(entry.name, Uint8List.fromList(data)));
          }
        }
      } catch (_) {
        // Beschädigtes ZIP: ignorieren, der Import meldet "nichts gefunden".
      }
    } else {
      out.add(f);
    }
  }
  return out;
}
