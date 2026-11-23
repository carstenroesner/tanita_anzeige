/// Zahlen- und Datumsformate je Sprache.
String fmtNum(String lang, double v, [int decimals = 1]) {
  final s = v.toStringAsFixed(decimals);
  var out = lang == 'en' ? s : s.replaceAll('.', ',');
  if (decimals == 0 && v.abs() >= 1000) {
    final sep = lang == 'en' ? ',' : '.';
    final n = v.round().abs().toString();
    final buf = StringBuffer(v < 0 ? '-' : '');
    for (var i = 0; i < n.length; i++) {
      if (i > 0 && (n.length - i) % 3 == 0) buf.write(sep);
      buf.write(n[i]);
    }
    out = buf.toString();
  }
  return out;
}

String _two(int n) => n.toString().padLeft(2, '0');

String fmtDate(String lang, DateTime d) {
  switch (lang) {
    case 'en':
    case 'es':
      return '${_two(d.day)}/${_two(d.month)}/${d.year}';
    default:
      return '${_two(d.day)}.${_two(d.month)}.${d.year}';
  }
}

String fmtDateTime(String lang, DateTime d) =>
    '${fmtDate(lang, d)}, ${_two(d.hour)}:${_two(d.minute)}';

String fmtShortDate(String lang, DateTime d) {
  final y = _two(d.year % 100);
  return lang == 'en' || lang == 'es'
      ? '${_two(d.month)}/$y'
      : '${_two(d.month)}.$y';
}

String fmtDayMonth(String lang, DateTime d) => lang == 'en' || lang == 'es'
    ? '${_two(d.month)}/${_two(d.day)}'
    : '${_two(d.day)}.${_two(d.month)}.';
