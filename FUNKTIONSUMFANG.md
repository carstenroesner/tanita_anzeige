# Tanita Anzeige - Funktionsumfang

Stand: 23.11.2026

Diese Datei ist fachlich deckungsgleich mit dem In-App-Screen Funktionsumfang (lib/content/feature_overview_content.dart). Beide Stellen werden gemeinsam gepflegt, ein Test prüft die Übereinstimmung.

## Zweck und Rahmen

- Tanita Anzeige stellt die Analysedaten einer Tanita-Körperanalysewaage (BC-601) übersichtlich dar: Dashboard, Verläufe und Referenzbereiche.
- Ohne Anmeldung bleiben alle Daten ausschließlich lokal im Browser. Mit Konto werden sie gesichert und zwischen Geräten abgeglichen.
- Die Referenzbereiche sind Orientierungswerte und keine medizinische Diagnose.

## Plattform und Technik

- Flutter (Dart) mit Material 3 und provider, Auslieferung als Web-App über GitHub Pages.
- Automatischer Test, Build und Deploy per GitHub Actions bei jedem Push auf master.
- Oberfläche in Deutsch (Standard), Englisch, Niederländisch und Spanisch. Dieser Funktionsumfang bleibt deutsch.

## Startbildschirm

- [x] Kacheln für die Slots der Waage: 4 Slots als Voreinstellung, in den Einstellungen auf 8 umschaltbar.
- [x] Jede belegte Kachel zeigt die Slot-Nummer groß, darunter das zuletzt bekannte Gewicht und das Datum des letzten Imports. Leere Slots sind als solche erkennbar.
- [x] Ein auffälliger Hinweis erscheint, wenn noch nie importiert wurde oder der letzte Import länger zurückliegt als eingestellt (Standard 14 Tage). Er führt direkt zur Dateiauswahl und lässt sich für diese Sitzung ausblenden.
- [x] Statuszeile zeigt, ob die Daten nur lokal liegen oder mit der Cloud abgeglichen werden.

## Import

- [x] Auswahl mehrerer Dateien oder eines ZIP-Archivs aus dem Waagen-Ordner (GRAPHV1). Unterordner in ZIP-Archiven werden durchlaufen.
- [x] Erkannt werden die Dateien PROF1 bis PROF8 (Profil: Geschlecht, Größe, Geburtsdatum, Aktivität) und DATA1 bis DATA8 (Messungen). Andere Dateien werden ignoriert.
- [x] Profile werden aktualisiert, noch unbekannte Messungen ergänzt; bereits vorhandene Messungen werden nicht doppelt angelegt.
- [x] Ergebnisansicht je Slot mit Anzahl gelesener und neuer Messungen sowie Hinweis auf auffällige Messungen.
- [x] Bei Anmeldung wird nach dem Import automatisch mit der Cloud abgeglichen.
- [ ] Eine Ordnerauswahl wie am Rechner ist im Browser und auf dem iPhone nicht möglich. Eine native Variante mit echter Ordnerauswahl ist für später vorgesehen.

## Dashboard und Verlauf

- [x] Dashboard je Slot mit den letzten Werten: Gewicht, Körperfett, BMI, Muskelmasse, Körperwasser, Viszeralfett, Grundumsatz, Stoffwechselalter und Knochenmasse.
- [x] Jede Kachel zeigt die Änderung zur Vormessung, eine Statusmarke (unter, im oder über dem Bereich) und einen kleinen Verlauf der letzten drei Monate.
- [x] Segment-Analyse mit Fett- und Muskelwerten für beide Arme, beide Beine und den Rumpf.
- [x] Antippen einer Kachel öffnet den großen Verlauf mit Zeitraumfilter 1W, 1M, 3M, 1J und Alles (bezogen auf die letzte Messung); voreingestellt sind 3 Monate. Mit den Pfeilen lässt sich um jeweils einen Zeitraum zurück- und wieder vorwärtsblättern (zum Beispiel ins vorherige Quartal), der gewählte Zeitraum wird mit Datum angezeigt sowie Minimum, Durchschnitt, Maximum und Änderung.
- [x] Der große Verlauf startet geglättet (weiche Kurve, Rohwerte blass sichtbar). Tippen auf das Diagramm schaltet zu den Rohdaten (zackig, mit allen Punkten) um und zurück. Die Voreinstellung lässt sich in den Einstellungen ändern.
- [x] Optik: unscharfer, überbelichteter Sport-Hintergrund aus abstrakten Silhouetten (keine erkennbaren Personen), Farbverlauf-Kacheln und kräftige Schrift.
- [x] Im Verlauf sind oberer und unterer Grenzwert und eine Optimum-Linie eingezeichnet. Das Optimum ist die Mitte des Bereichs. Beim Stoffwechselalter zeigt die Linie das tatsächliche Alter, das über den Zeitraum ansteigt; ohne genaues Geburtsdatum wird der 1. Januar des Geburtsjahres angenommen.
- [x] Auffällige Messungen (Gerätedatum vor 2015, stark abweichendes Gewicht) werden standardmäßig ausgeblendet; das lässt sich in den Einstellungen ändern.

## Referenzbereiche

- [x] BMI nach WHO (18,5 bis 24,9). Der Gewichtsbereich wird daraus mit der Körpergröße berechnet.
- [x] Körperfett nach Tanita Healthy Range, getrennt nach Geschlecht und Altersgruppe; Körperwasser und Viszeralfett nach Tanita-Richtwerten.
- [x] Für Muskelmasse, Grundumsatz und Knochenmasse gibt es keine anerkannte Referenz; hier wird nur der Verlauf gezeigt.

## Einstellungen

- [x] Sprache: Deutsch, Englisch, Niederländisch, Spanisch.
- [x] Import-Erinnerung in Tagen, Anzahl der Slots (4 oder 8), Verläufe geglättet starten, Auffälliges ausblenden und eigene Namen für die Slots.
- [x] Konto-Bereich mit Anmeldung über das zentrale Konto-Portal und Schaltfläche zum sofortigen Abgleich.

## Konto und Cloud

- [x] Anmeldung ist optional und gilt in allen Apps des Nutzers.
- [x] Abgleich führt Messungen aus allen Geräten zusammen (Vereinigung über Datum und Uhrzeit), nichts wird überschrieben oder gelöscht. Bei Ladefehlern wird nie ein leerer Bestand angenommen.
- [x] Beim Wechsel auf ein anderes Konto werden die lokalen Daten des vorigen Kontos entfernt.

## Navigation

- [x] Dreipunktemenü mit Konto, Einstellungen, Funktionsumfang, Problem melden und Über diese App.
- [x] Problem melden öffnet ein vorbefülltes GitHub-Issue.

## Änderungshistorie

- 23.11.2026: Erste Version mit Startbildschirm, Import, Dashboard, Verlauf, Einstellungen und Cloud-Abgleich.
- 23.11.2026: Alterslinie beim Stoffwechselalter steigt mit der Zeit; Zeitraum 3 Monate als Voreinstellung und für die Kachel-Verläufe.
- 23.11.2026: Blättern zwischen Zeiträumen, Sport-Hintergrund und neue Kachel-Optik.
- 23.11.2026: Verlauf per Tippen glätten oder als Rohdaten zeigen.
- 23.11.2026: Verläufe starten standardmäßig geglättet, einstellbar.

