import 'package:app_auth/app_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tanita_anzeige/main.dart';
import 'package:tanita_anzeige/services/settings_service.dart';
import 'package:tanita_anzeige/services/tanita_service.dart';
import 'package:tanita_anzeige/services/tanita_sync.dart';

Future<TanitaApp> newApp(WidgetTester tester) async {
  final app = await tester.runAsync(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = AuthService.offline();
    final service = TanitaService(prefs);
    return TanitaApp(
      settings: SettingsService(prefs),
      service: service,
      auth: auth,
      sync: TanitaSync(service, auth, prefs),
    );
  });
  return app!;
}

void main() {
  testWidgets('Startbildschirm zeigt 4 Slots und den Import-Hinweis', (tester) async {
    await tester.pumpWidget(await newApp(tester));
    await tester.pumpAndSettle();

    expect(find.text('Tanita Anzeige'), findsWidgets);
    for (final n in ['1', '2', '3', '4']) {
      expect(find.text(n), findsOneWidget);
    }
    expect(find.text('5'), findsNothing);
    expect(find.text('Import fällig'), findsOneWidget);
  });

  testWidgets('Menü enthält die Standard-Einträge', (tester) async {
    await tester.pumpWidget(await newApp(tester));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Menü'));
    await tester.pumpAndSettle();
    expect(find.text('Funktionsumfang'), findsOneWidget);
    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('Problem melden'), findsOneWidget);
    expect(find.text('Über diese App'), findsOneWidget);
  });

  testWidgets('Sprache lässt sich auf Englisch umstellen', (tester) async {
    await tester.pumpWidget(await newApp(tester));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Menü'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Einstellungen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
  });
}
