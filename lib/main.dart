import 'package:app_auth/app_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'services/tanita_service.dart';
import 'services/tanita_sync.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsService(prefs);
  final service = TanitaService(prefs);
  final auth = await AuthService.init();
  final sync = TanitaSync(service, auth, prefs);
  runApp(
    TanitaApp(settings: settings, service: service, auth: auth, sync: sync),
  );
}

class TanitaApp extends StatelessWidget {
  const TanitaApp({
    super.key,
    required this.settings,
    required this.service,
    required this.sync,
    this.auth,
  });

  final SettingsService settings;
  final TanitaService service;

  /// Nutzerverwaltung; ohne Angabe (z. B. in Tests) arbeitet die App rein lokal.
  final AuthService? auth;
  final TanitaSync sync;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>.value(value: settings),
        ChangeNotifierProvider<TanitaService>.value(value: service),
        ChangeNotifierProvider<AuthService>.value(
          value: auth ?? AuthService.offline(),
        ),
        ChangeNotifierProvider<TanitaSync>.value(value: sync),
      ],
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsService>().language;
    return MaterialApp(
      title: 'Tanita Anzeige',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: Locale(lang),
      supportedLocales: const [
        Locale('de'),
        Locale('en'),
        Locale('nl'),
        Locale('es'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const HomeScreen(),
    );
  }
}
