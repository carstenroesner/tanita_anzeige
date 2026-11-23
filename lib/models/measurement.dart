/// Kürzel der Messwerte in den Tanita-CSV-Dateien (BC-601).
///
/// Wk Gewicht (kg), MI BMI, FW Körperfett (%), Fr/Fl Fett Arm rechts/links (%),
/// FR/FL Fett Bein rechts/links (%), FT Fett Rumpf (%), mW Muskelmasse (kg),
/// mr/ml Muskel Arm rechts/links, mR/mL Muskel Bein rechts/links, mT Muskel
/// Rumpf (kg), bW Knochenmasse (kg), IF Viszeralfett, rD Grundumsatz (kcal),
/// rA Stoffwechselalter, ww Körperwasser (%).
const List<String> kFields = [
  'Wk', 'MI', 'FW', 'Fr', 'Fl', 'FR', 'FL', 'FT', //
  'mW', 'mr', 'ml', 'mR', 'mL', 'mT', 'bW', 'IF', 'rD', 'rA', 'ww',
];

/// Eine Messung der Waage.
class Measurement {
  const Measurement({
    required this.at,
    required this.values,
    this.age,
    this.gender,
    this.height,
  });

  final DateTime at;
  final Map<String, double> values;

  /// Alter, Geschlecht (1 männlich, 2 weiblich) und Größe laut Waage.
  final int? age;
  final int? gender;
  final double? height;

  /// Eindeutiger Schlüssel (Datum und Uhrzeit der Messung).
  String get key => at.toIso8601String();

  double? operator [](String k) => values[k];

  Map<String, dynamic> toJson() => {
        't': key,
        if (age != null) 'a': age,
        if (gender != null) 'g': gender,
        if (height != null) 'h': height,
        'v': values,
      };

  factory Measurement.fromJson(Map<String, dynamic> j) {
    final raw = (j['v'] as Map).cast<String, dynamic>();
    return Measurement(
      at: DateTime.parse(j['t'] as String),
      values: {
        for (final e in raw.entries) e.key: (e.value as num).toDouble(),
      },
      age: (j['a'] as num?)?.toInt(),
      gender: (j['g'] as num?)?.toInt(),
      height: (j['h'] as num?)?.toDouble(),
    );
  }
}

/// Einstellungen eines Slots aus der Datei PROFn.CSV.
class Profile {
  const Profile({this.gender, this.height, this.birth, this.activity});

  /// 1 männlich, 2 weiblich.
  final int? gender;
  final double? height;
  final DateTime? birth;
  final int? activity;

  int? ageAt(DateTime d) {
    final b = birth;
    if (b == null) return null;
    var a = d.year - b.year;
    if (d.month < b.month || (d.month == b.month && d.day < b.day)) a--;
    return a;
  }

  Map<String, dynamic> toJson() => {
        if (gender != null) 'g': gender,
        if (height != null) 'h': height,
        if (birth != null) 'b': birth!.toIso8601String(),
        if (activity != null) 'l': activity,
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        gender: (j['g'] as num?)?.toInt(),
        height: (j['h'] as num?)?.toDouble(),
        birth: j['b'] == null ? null : DateTime.parse(j['b'] as String),
        activity: (j['l'] as num?)?.toInt(),
      );

  @override
  bool operator ==(Object other) =>
      other is Profile &&
      other.gender == gender &&
      other.height == height &&
      other.birth == birth &&
      other.activity == activity;

  @override
  int get hashCode => Object.hash(gender, height, birth, activity);
}

/// Alle Daten eines Slots.
class SlotData {
  SlotData({
    this.profile,
    this.profileAt,
    List<Measurement>? measurements,
    this.lastImport,
  }) : measurements = measurements ?? [];

  Profile? profile;
  DateTime? profileAt;
  final List<Measurement> measurements;
  DateTime? lastImport;

  bool get hasData => measurements.isNotEmpty || profile != null;

  Measurement? get last => measurements.isEmpty ? null : measurements.last;

  /// Geschlecht aus dem Profil, sonst aus der letzten Messung.
  int? get gender => profile?.gender ?? last?.gender;

  double? get height => profile?.height ?? last?.height;

  /// Alter zum Zeitpunkt [d] (Geburtsdatum aus dem Profil, sonst Angabe der
  /// Waage bei der letzten Messung).
  int? ageAt(DateTime d) => profile?.ageAt(d) ?? last?.age;

  Map<String, dynamic> toJson() => {
        if (profile != null) 'p': profile!.toJson(),
        if (profileAt != null) 'pa': profileAt!.toIso8601String(),
        if (lastImport != null) 'li': lastImport!.toIso8601String(),
        'm': [for (final m in measurements) m.toJson()],
      };

  factory SlotData.fromJson(Map<String, dynamic> j) {
    final list = <Measurement>[
      for (final e in (j['m'] as List? ?? const []))
        Measurement.fromJson((e as Map).cast<String, dynamic>()),
    ]..sort((a, b) => a.at.compareTo(b.at));
    return SlotData(
      profile: j['p'] == null
          ? null
          : Profile.fromJson((j['p'] as Map).cast<String, dynamic>()),
      profileAt:
          j['pa'] == null ? null : DateTime.parse(j['pa'] as String),
      measurements: list,
      lastImport: j['li'] == null ? null : DateTime.parse(j['li'] as String),
    );
  }
}

/// Erkennt auffällige Messungen: Geräte-Datum vor 2015 (Uhr der Waage nicht
/// gestellt) oder ein Gewicht, das stark vom Median des Slots abweicht
/// (vermutlich eine andere Person auf der Waage).
Set<String> suspiciousKeys(List<Measurement> all) {
  final result = <String>{};
  final weights = [
    for (final m in all)
      if (m['Wk'] != null) m['Wk']!,
  ]..sort();
  final median = weights.isEmpty ? null : weights[weights.length ~/ 2];
  for (final m in all) {
    if (m.at.year < 2015) {
      result.add(m.key);
      continue;
    }
    final w = m['Wk'];
    if (median != null && w != null && (w < median * 0.7 || w > median * 1.4)) {
      result.add(m.key);
    }
  }
  return result;
}
