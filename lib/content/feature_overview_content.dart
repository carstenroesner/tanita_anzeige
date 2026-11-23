/// Status eines Eintrags im Funktionsumfang.
enum FeatureStatus { done, open, info }

class FeatureItem {
  const FeatureItem(this.text, [this.status = FeatureStatus.done]);

  final String text;
  final FeatureStatus status;
}

class FeatureSection {
  const FeatureSection(this.title, this.items);

  final String title;
  final List<FeatureItem> items;
}

/// Stand des Funktionsumfangs. Muss mit FUNKTIONSUMFANG.md im Repo-Root
/// übereinstimmen (wird per Test geprüft).
const String featureOverviewStand = '23.11.2026';

const List<FeatureSection> featureOverviewSections = [
  FeatureSection('Zweck und Rahmen', [
    FeatureItem(
      'Tanita Anzeige stellt die Analysedaten einer Tanita-Körperanalysewaage (BC-601) übersichtlich dar: Dashboard, Verläufe und Referenzbereiche.',
      FeatureStatus.info,
    ),
    FeatureItem(
      'Ohne Anmeldung bleiben alle Daten ausschließlich lokal im Browser. Mit Konto werden sie gesichert und zwischen Geräten abgeglichen.',
      FeatureStatus.info,
    ),
    FeatureItem(
      'Die Referenzbereiche sind Orientierungswerte und keine medizinische Diagnose.',
      FeatureStatus.info,
    ),
  ]),
  FeatureSection('Plattform und Technik', [
    FeatureItem(
      'Flutter (Dart) mit Material 3 und provider, Auslieferung als Web-App über GitHub Pages.',
      FeatureStatus.info,
    ),
    FeatureItem(
      'Automatischer Test, Build und Deploy per GitHub Actions bei jedem Push auf master.',
      FeatureStatus.info,
    ),
    FeatureItem(
      'Oberfläche in Deutsch (Standard), Englisch, Niederländisch und Spanisch. Dieser Funktionsumfang bleibt deutsch.',
      FeatureStatus.info,
    ),
  ]),
  FeatureSection('Startbildschirm', [
    FeatureItem(
      'Kacheln für die Slots der Waage: 4 Slots als Voreinstellung, in den Einstellungen auf 8 umschaltbar.',
    ),
    FeatureItem(
      'Jede belegte Kachel zeigt die Slot-Nummer groß, darunter das zuletzt bekannte Gewicht und das Datum des letzten Imports. Leere Slots sind als solche erkennbar.',
    ),
    FeatureItem(
      'Ein auffälliger Hinweis erscheint, wenn noch nie importiert wurde oder der letzte Import länger zurückliegt als eingestellt (Standard 14 Tage). Er führt direkt zur Dateiauswahl und lässt sich für diese Sitzung ausblenden.',
    ),
    FeatureItem(
      'Statuszeile zeigt, ob die Daten nur lokal liegen oder mit der Cloud abgeglichen werden.',
    ),
  ]),
  FeatureSection('Import', [
    FeatureItem(
      'Auswahl mehrerer Dateien oder eines ZIP-Archivs aus dem Waagen-Ordner (GRAPHV1). Unterordner in ZIP-Archiven werden durchlaufen.',
    ),
    FeatureItem(
      'Erkannt werden die Dateien PROF1 bis PROF8 (Profil: Geschlecht, Größe, Geburtsdatum, Aktivität) und DATA1 bis DATA8 (Messungen). Andere Dateien werden ignoriert.',
    ),
    FeatureItem(
      'Profile werden aktualisiert, noch unbekannte Messungen ergänzt; bereits vorhandene Messungen werden nicht doppelt angelegt.',
    ),
    FeatureItem(
      'Ergebnisansicht je Slot mit Anzahl gelesener und neuer Messungen sowie Hinweis auf auffällige Messungen.',
    ),
    FeatureItem(
      'Bei Anmeldung wird nach dem Import automatisch mit der Cloud abgeglichen.',
    ),
    FeatureItem(
      'Eine Ordnerauswahl wie am Rechner ist im Browser und auf dem iPhone nicht möglich. Eine native Variante mit echter Ordnerauswahl ist für später vorgesehen.',
      FeatureStatus.open,
    ),
  ]),
  FeatureSection('Dashboard und Verlauf', [
    FeatureItem(
      'Dashboard je Slot mit den letzten Werten: Gewicht, Körperfett, BMI, Muskelmasse, Körperwasser, Viszeralfett, Grundumsatz, Stoffwechselalter und Knochenmasse.',
    ),
    FeatureItem(
      'Jede Kachel zeigt die Änderung zur Vormessung, eine Statusmarke (unter, im oder über dem Bereich) und einen kleinen Verlauf der letzten drei Monate.',
    ),
    FeatureItem(
      'Segment-Analyse mit Fett- und Muskelwerten für beide Arme, beide Beine und den Rumpf.',
    ),
    FeatureItem(
      'Antippen einer Kachel öffnet den großen Verlauf mit Zeitraumfilter 1W, 1M, 3M, 1J und Alles (bezogen auf die letzte Messung); voreingestellt sind 3 Monate. Mit den Pfeilen lässt sich um jeweils einen Zeitraum zurück- und wieder vorwärtsblättern (zum Beispiel ins vorherige Quartal), der gewählte Zeitraum wird mit Datum angezeigt sowie Minimum, Durchschnitt, Maximum und Änderung.',
    ),
    FeatureItem(
      'Der große Verlauf startet geglättet (weiche Kurve, Rohwerte blass sichtbar). Tippen auf das Diagramm schaltet zu den Rohdaten (zackig, mit allen Punkten) um und zurück. Die Voreinstellung lässt sich in den Einstellungen ändern.',
    ),
    FeatureItem(
      'Überschriften im Design „Variante B“: weiße, schlanke Schrift auf einem leicht durchsichtigen Feld mit Verlaufsbalken darunter; Slot-Kacheln mit Verlauf-Kopfband.',
    ),
    FeatureItem(
      'Optik: unscharfer, überbelichteter Sport-Hintergrund aus abstrakten Silhouetten (keine erkennbaren Personen), Farbverlauf-Kopfband der Kacheln.',
    ),
    FeatureItem(
      'Im Verlauf sind oberer und unterer Grenzwert und eine Optimum-Linie eingezeichnet. Das Optimum ist die Mitte des Bereichs. Beim Stoffwechselalter zeigt die Linie das tatsächliche Alter, das über den Zeitraum ansteigt; ohne genaues Geburtsdatum wird der 1. Januar des Geburtsjahres angenommen.',
    ),
    FeatureItem(
      'Auffällige Messungen (Gerätedatum vor 2015, stark abweichendes Gewicht) werden standardmäßig ausgeblendet; das lässt sich in den Einstellungen ändern.',
    ),
  ]),
  FeatureSection('Referenzbereiche', [
    FeatureItem(
      'BMI nach WHO (18,5 bis 24,9). Der Gewichtsbereich wird daraus mit der Körpergröße berechnet.',
    ),
    FeatureItem(
      'Körperfett nach Tanita Healthy Range, getrennt nach Geschlecht und Altersgruppe; Körperwasser und Viszeralfett nach Tanita-Richtwerten.',
    ),
    FeatureItem(
      'Für Muskelmasse, Grundumsatz und Knochenmasse gibt es keine anerkannte Referenz; hier wird nur der Verlauf gezeigt.',
    ),
  ]),
  FeatureSection('Einstellungen', [
    FeatureItem(
      'Sprache: Deutsch, Englisch, Niederländisch, Spanisch.',
    ),
    FeatureItem(
      'Import-Erinnerung in Tagen, Anzahl der Slots (4 oder 8), Verläufe geglättet starten, Auffälliges ausblenden und eigene Namen für die Slots.',
    ),
    FeatureItem(
      'Konto-Bereich mit Anmeldung über das zentrale Konto-Portal und Schaltfläche zum sofortigen Abgleich.',
    ),
  ]),
  FeatureSection('Konto und Cloud', [
    FeatureItem(
      'Anmeldung ist optional und gilt in allen Apps des Nutzers.',
    ),
    FeatureItem(
      'Abgleich führt Messungen aus allen Geräten zusammen (Vereinigung über Datum und Uhrzeit), nichts wird überschrieben oder gelöscht. Bei Ladefehlern wird nie ein leerer Bestand angenommen.',
    ),
    FeatureItem(
      'Beim Wechsel auf ein anderes Konto werden die lokalen Daten des vorigen Kontos entfernt.',
    ),
  ]),
  FeatureSection('Navigation', [
    FeatureItem(
      'Dreipunktemenü mit Konto, Einstellungen, Funktionsumfang, Problem melden und Über diese App.',
    ),
    FeatureItem(
      'Problem melden öffnet ein vorbefülltes GitHub-Issue.',
    ),
  ]),
  FeatureSection('Änderungshistorie', [
    FeatureItem(
      '23.11.2026: Erste Version mit Startbildschirm, Import, Dashboard, Verlauf, Einstellungen und Cloud-Abgleich.',
      FeatureStatus.info,
    ),
    FeatureItem(
      '23.11.2026: Alterslinie beim Stoffwechselalter steigt mit der Zeit; Zeitraum 3 Monate als Voreinstellung und für die Kachel-Verläufe.',
      FeatureStatus.info,
    ),
    FeatureItem(
      '23.11.2026: Blättern zwischen Zeiträumen, Sport-Hintergrund und neue Kachel-Optik.',
      FeatureStatus.info,
    ),
    FeatureItem(
      '23.11.2026: Verlauf per Tippen glätten oder als Rohdaten zeigen.',
      FeatureStatus.info,
    ),
    FeatureItem(
      '23.11.2026: Verläufe starten standardmäßig geglättet, einstellbar.',
      FeatureStatus.info,
    ),
    FeatureItem(
      '23.11.2026: Überschriften-Design Variante B (helle Schrift, Verlaufsbalken, Kopfband).',
      FeatureStatus.info,
    ),
    FeatureItem(
      '23.11.2026: Überschriften weiß auf leicht durchsichtigem Feld.',
      FeatureStatus.info,
    ),
  ]),
];
