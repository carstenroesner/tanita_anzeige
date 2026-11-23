import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tanita_anzeige/services/tanita_parser.dart';
import 'package:tanita_anzeige/services/tanita_service.dart';

String line(String d, String t, double w) =>
    '{0,16,~0,2,MO,"BC-601",DT,"$d",Ti,"$t",Bt,0,GE,2,AG,29,Hm,158.0,AL,2,Wk,$w,MI,21.7,FW,24.0,ww,55.8,CS,64';

ImportFile file(String name, String text) =>
    ImportFile(name, Uint8List.fromList(utf8.encode(text)));

Future<TanitaService> newService() async {
  SharedPreferences.setMockInitialValues({});
  return TanitaService(await SharedPreferences.getInstance());
}

void main() {
  test('Import ergänzt neue Messungen ohne Doppelte', () async {
    final s = await newService();
    final data = file(
      'DATA/DATA4.CSV',
      '${line('09/08/2021', '20:17:15', 54.1)}\n${line('10/08/2021', '07:25:17', 53.4)}\n',
    );
    final r1 = await s.importFiles([data], now: DateTime(2026, 11, 23));
    expect(r1.slots.single.slot, 4);
    expect(r1.slots.single.added, 2);
    expect(s.slot(4)!.measurements.length, 2);
    expect(s.lastImport, DateTime(2026, 11, 23));

    final r2 = await s.importFiles([data]);
    expect(r2.slots.single.added, 0);
    expect(s.slot(4)!.measurements.length, 2);
  });

  test('Fremde Dateien führen zu leerem Ergebnis', () async {
    final s = await newService();
    final r = await s.importFiles([file('notiz.txt', 'hallo')]);
    expect(r.isEmpty, isTrue);
  });

  test('mergeFromJson vereinigt Bestände', () async {
    final a = await newService();
    final b = await newService();
    await a.importFiles([file('DATA1.CSV', line('01/01/2022', '08:00:00', 70))]);
    await b.importFiles([file('DATA1.CSV', line('02/01/2022', '08:00:00', 69))]);
    await a.mergeFromJson(b.dataJson());
    expect(a.slot(1)!.measurements.length, 2);
  });
}
