class AmountParser {
  const AmountParser._();

  /// Parse a monetary value from dynamic sources (num/string/formatted text).
  /// Handles values like:
  /// - "10 000", "10\u00A0000", "10\u202F000"
  /// - "1,234.56", "1.234,56", "10000 FCFA"
  static double parse(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();

    var raw = value.toString().trim();
    if (raw.isEmpty) return fallback;

    raw = raw
        .replaceAll('\u00A0', '')
        .replaceAll('\u202F', '')
        .replaceAll(' ', '')
      .replaceAll(RegExp(r'fcfa|xof|xaf', caseSensitive: false), '')
        .replaceAll(RegExp(r'[^0-9,.-]'), '');

    if (raw.isEmpty || raw == '-' || raw == '.' || raw == ',') {
      return fallback;
    }

    final hasComma = raw.contains(',');
    final hasDot = raw.contains('.');

    // If both separators exist, keep the last one as decimal separator.
    if (hasComma && hasDot) {
      final lastComma = raw.lastIndexOf(',');
      final lastDot = raw.lastIndexOf('.');

      if (lastComma > lastDot) {
        raw = raw.replaceAll('.', '');
        raw = raw.replaceAll(',', '.');
      } else {
        raw = raw.replaceAll(',', '');
      }
    } else if (hasComma) {
      final commas = ','.allMatches(raw).length;
      if (commas > 1) {
        raw = raw.replaceAll(',', '');
      } else {
        final fractionalLength = raw.length - raw.lastIndexOf(',') - 1;
        if (fractionalLength == 3) {
          raw = raw.replaceAll(',', '');
        } else {
          raw = raw.replaceAll(',', '.');
        }
      }
    } else if (hasDot) {
      final dots = '.'.allMatches(raw).length;
      if (dots > 1) {
        final parts = raw.split('.');
        final last = parts.removeLast();
        raw = '${parts.join()}.$last';
      }
    }

    return double.tryParse(raw) ?? fallback;
  }
}
