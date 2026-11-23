import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tanita_anzeige/services/tanita_parser.dart';

const dataLine =
    '{0,16,~0,2,~1,2,~2,3,~3,4,MO,"BC-601",DT,"09/08/2021",Ti,"20:17:15",Bt,0,GE,2,AG,29,Hm,158.0,AL,2,Wk,54.1,MI,21.7,FW,24.0,Fr,3.1,Fl,14.9,FR,33.1,FL,33.5,FT,20.3,mW,39.0,mr,2.5,ml,2.1,mR,6.4,mL,6.2,mT,21.8,bW,2.1,IF,2,rD,2052,rA,16,ww,55.8,CS,64';

void main() {
  test('tokenizeLine liest Schlüssel und Werte', () {
    final t = tokenizeLine(dataLine);
    expect(t['Wk'], '54.1');
    expect(t['DT'], '09/08/2021');
    expect(t['MO'], 'BC-601');
  });

  test('parseData liest eine Messung', () {
    final list = parseData('$dataLine\n');
    expect(list.length, 1);
    final m = list.single;
    expect(m.at, DateTime(2021, 8, 9, 20, 17, 15));
    expect(m['Wk'], 54.1);
    expect(m['FW'], 24.0);
    expect(m['IF'], 2);
    expect(m.gender, 2);
    expect(m.height, 158.0);
  });

  test('parseData ignoriert Zeilen ohne Datum oder Gewicht', () {
    expect(parseData('kaputt\n{0,16,Wk,50.0}\n'), isEmpty);
  });

  test('classifyName erkennt nur PROFn und DATAn', () {
    expect(classifyName('SYSTEM/PROF3.CSV')!.isProfile, isTrue);
    expect(classifyName('DATA/data4.csv')!.slot, 4);
    expect(classifyName('DATA1 Kopie.CSV'), isNull);
    expect(classifyName('PROF9.CSV'), isNull);
  });

  test('decodeText und ImportFile', () {
    final f = ImportFile('DATA1.CSV', Uint8List.fromList(utf8.encode(dataLine)));
    expect(parseData(decodeText(f.bytes)).length, 1);
  });
}
