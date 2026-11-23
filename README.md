# Tanita Anzeige

Web-App (Flutter) zur Darstellung der Analysedaten einer Tanita-Körperanalysewaage (BC-601): Slots, Import aus dem Waagen-Ordner, Dashboard, Verläufe mit Referenzbereichen. Optionaler Login mit Cloud-Abgleich über das gemeinsame Modul `app_auth`.

- Live: https://carstenroesner.github.io/tanita_anzeige/
- Funktionsumfang: siehe [FUNKTIONSUMFANG.md](FUNKTIONSUMFANG.md) (auch in der App über das Menü erreichbar)
- Die Referenzbereiche sind Orientierungswerte, keine medizinische Diagnose.

## Entwicklung

```
flutter pub get
flutter test
flutter run -d chrome
```

Die Texte der Oberfläche (Deutsch, Englisch, Niederländisch, Spanisch) liegen in `lib/l10n/strings_data.dart`. Rohdaten der Waage (`*.CSV`) gehören nicht ins Repository.

Bei jedem Push auf `master` testet, baut und veröffentlicht GitHub Actions die Web-App (`.github/workflows/deploy-web.yml`).
