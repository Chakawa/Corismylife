class ParsedPhoneWithIndicatif {
  const ParsedPhoneWithIndicatif({
    required this.indicatif,
    required this.phoneNumber,
  });

  final String indicatif;
  final String phoneNumber;
}

ParsedPhoneWithIndicatif parsePhoneWithIndicatif({
  required String rawValue,
  required List<String> indicatifs,
  required String fallbackIndicatif,
}) {
  final trimmedValue = rawValue.trim();
  if (trimmedValue.isEmpty) {
    return ParsedPhoneWithIndicatif(
      indicatif: fallbackIndicatif,
      phoneNumber: '',
    );
  }

  final compactValue = trimmedValue.replaceAll(RegExp(r'\s+'), '');
  final sortedIndicatifs = [...indicatifs]
    ..sort((left, right) => right.length.compareTo(left.length));

  for (final indicatif in sortedIndicatifs) {
    if (compactValue.startsWith(indicatif)) {
      return ParsedPhoneWithIndicatif(
        indicatif: indicatif,
        phoneNumber: compactValue.substring(indicatif.length),
      );
    }
  }

  return ParsedPhoneWithIndicatif(
    indicatif: fallbackIndicatif,
    phoneNumber: compactValue,
  );
}

String buildPhoneWithIndicatif({
  required String indicatif,
  required String phoneNumber,
}) {
  var compactPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
  if (compactPhone.startsWith(indicatif)) {
    compactPhone = compactPhone.substring(indicatif.length);
  }

  return compactPhone.isEmpty ? indicatif : '$indicatif$compactPhone';
}

String normalizeInternationalPhoneNumber(String rawValue) {
  return rawValue.trim().replaceAll(RegExp(r'\s+'), '');
}
