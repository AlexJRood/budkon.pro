/// Core email pattern used for detection and extraction.
const String kEmailCorePattern =
    r'[^@\s]+@[^@\s]+\.[A-Za-z0-9]{2,}';

class RegexBuildResult {
  final String pattern;
  final String? key;
  final bool isEmail;
  final bool isAddress;

  const RegexBuildResult({
    required this.pattern,
    required this.key,
    required this.isEmail,
    required this.isAddress,
  });
}

class RegexQuickPreset {
  final String id;
  final String label;
  final String description;
  final String pattern;
  final String? key;
  final String suggestedOutputName;
  final bool normalizeDigits;

  const RegexQuickPreset({
    required this.id,
    required this.label,
    required this.description,
    required this.pattern,
    required this.suggestedOutputName,
    this.key,
    this.normalizeDigits = false,
  });
}

const String _kPhonePattern = r'(?:\+?\d[\d\s().-]{6,}\d)';
const String _kZipPattern = r'\d{2}-\d{3}';
const String _kDatePattern =
    r'(?:\d{4}[./-]\d{1,2}[./-]\d{1,2}|\d{1,2}[./-]\d{1,2}[./-]\d{2,4})';
const String _kAmountPattern =
    r'[+-]?\d[\d\s]*[.,]?\d{0,2}(?:\s?(?:PLN|EUR|USD|zł|ZŁ))?';

bool looksLikeEmail(String text) {
  final t = text.trim();
  if (!t.contains('@')) return false;

  final parts = t.split(RegExp(r'\s+'));
  final last = parts.isNotEmpty ? parts.last.trim() : t;

  final basicEmailRe =
      RegExp(r'^[^@\s]+@[^@\s]+\.[A-Za-z0-9]{2,}$');

  if (basicEmailRe.hasMatch(last)) {
    return true;
  }

  final coreRe =
      RegExp(kEmailCorePattern, caseSensitive: false);
  return coreRe.hasMatch(t);
}

bool isAddressKey(String key) {
  final normalized =
      key.replaceAll('.', '').trim().toUpperCase();
  const addressKeys = <String>[
    'UL',
    'AL',
    'ULICA',
    'ADRES',
    'ADDRESS',
    'STREET',
    'STR',
  ];
  return addressKeys.contains(normalized);
}

bool _looksLikePhone(String text) {
  return RegExp(_kPhonePattern).hasMatch(text);
}

bool _looksLikeZipCode(String text) {
  return RegExp(_kZipPattern).hasMatch(text);
}

bool _looksLikeDate(String text) {
  return RegExp(_kDatePattern).hasMatch(text);
}

bool _looksLikeAmount(String text) {
  final upper = text.toUpperCase();
  return upper.contains('PLN') ||
      upper.contains('EUR') ||
      upper.contains('USD') ||
      upper.contains('ZŁ') ||
      RegExp(r'\b\d[\d\s]*[.,]\d{2}\b').hasMatch(text);
}

bool _rangesOverlap(
  int startA,
  int endA,
  int startB,
  int endB,
) {
  return startA < endB && startB < endA;
}

/// Stricter key detection:
/// - accepts known labels (NIP, REGON, EMAIL, TEL...)
/// - accepts obvious label-like values with ":" / "-" / "–" at the end
/// - accepts short all-uppercase tokens
/// - rejects generic lowercase fragments like "example"
String detectKeyFromSelected(String selectedText) {
  final raw = selectedText.trim();
  if (raw.isEmpty) return '';
  if (raw.contains('@')) return '';
  if (RegExp(r'\d').hasMatch(raw)) return '';

  final endsLikeLabel = RegExp(r'[:;,\-–]\s*$').hasMatch(raw);

  String candidate = raw.replaceAll(RegExp(r'[:;,\-–]+\s*$'), '');
  candidate = candidate.trim();

  if (candidate.length <= 4) {
    candidate = candidate.replaceAll('.', '');
  }

  final upper = candidate.toUpperCase();

  if (upper.isEmpty) return '';

  const knownKeys = <String>{
    'NIP',
    'REGON',
    'KRS',
    'PESEL',
    'EMAIL',
    'E-MAIL',
    'MAIL',
    'TEL',
    'TELEFON',
    'PHONE',
    'ADRES',
    'ADDRESS',
    'UL',
    'ULICA',
    'AL',
    'CITY',
    'MIASTO',
    'KOD',
    'ZIP',
    'ZIPCODE',
    'VAT',
    'IBAN',
    'SWIFT',
    'NR',
    'NUMER',
  };

  if (knownKeys.contains(upper)) {
    return upper;
  }

  final onlyLetters = RegExp(
    r'^[A-ZĄĆĘŁŃÓŚŹŻ_-]+$',
    unicode: true,
  ).hasMatch(upper);

  if (endsLikeLabel && onlyLetters && upper.length <= 16) {
    return upper;
  }

  if (raw == raw.toUpperCase() && onlyLetters && upper.length <= 8) {
    return upper;
  }

  return '';
}

List<String> detectKeywordSuggestionsFromSamples(
  Iterable<String> samples,
) {
  final Set<String> out = {};

  for (final raw in samples) {
    final upper = raw.toUpperCase();

    if (upper.contains('NIP')) out.add('NIP');
    if (upper.contains('REGON')) out.add('REGON');
    if (upper.contains('KRS')) out.add('KRS');
    if (upper.contains('E-MAIL') || upper.contains('EMAIL')) {
      out.add('E-MAIL');
    }
    if (upper.contains('TEL') ||
        upper.contains('TELEFON') ||
        upper.contains('PHONE')) {
      out.add('TEL');
    }
    if (upper.contains('UL.') ||
        upper.contains('ULICA') ||
        upper.contains('ADRES') ||
        upper.contains('STREET')) {
      out.add('UL');
    }
    if (RegExp(r'\b\d{2}-\d{3}\b').hasMatch(upper)) {
      out.add('KOD');
    }
  }

  return out.toList()..sort();
}

List<RegexQuickPreset> buildQuickRegexPresets({
  required List<String> samples,
  String? preferredKey,
}) {
  final presets = <RegexQuickPreset>[];
  final safeSamples = samples.where((e) => e.trim().isNotEmpty).toList();
  final upperSamples = safeSamples.map((e) => e.toUpperCase()).toList();

  bool containsToken(String token) {
    return upperSamples.any((s) => s.contains(token.toUpperCase()));
  }

  void add(RegexQuickPreset preset) {
    if (presets.any((p) => p.id == preset.id)) return;
    presets.add(preset);
  }

  final key = preferredKey?.trim();
  final upperKey = key?.toUpperCase();

  if (safeSamples.any(looksLikeEmail)) {
    add(
      const RegexQuickPreset(
        id: 'email',
        label: 'Email',
        description: 'Wyciągnij adres e-mail.',
        pattern: '($kEmailCorePattern)',
        suggestedOutputName: 'email',
      ),
    );
  }

  if (containsToken('NIP') || upperKey == 'NIP') {
    add(
      const RegexQuickPreset(
        id: 'nip',
        label: 'NIP',
        description: 'Wyciągnij numer NIP i oczyść separatory.',
        pattern: r'NIP\D*(\d[\d\s-]*)',
        suggestedOutputName: 'nip',
        key: 'NIP',
        normalizeDigits: true,
      ),
    );
  }

  if (containsToken('REGON') || upperKey == 'REGON') {
    add(
      const RegexQuickPreset(
        id: 'regon',
        label: 'REGON',
        description: 'Wyciągnij numer REGON.',
        pattern: r'REGON\D*(\d[\d\s-]*)',
        suggestedOutputName: 'regon',
        key: 'REGON',
        normalizeDigits: true,
      ),
    );
  }

  if (containsToken('KRS') || upperKey == 'KRS') {
    add(
      const RegexQuickPreset(
        id: 'krs',
        label: 'KRS',
        description: 'Wyciągnij numer KRS.',
        pattern: r'KRS\D*(\d[\d\s-]*)',
        suggestedOutputName: 'krs',
        key: 'KRS',
        normalizeDigits: true,
      ),
    );
  }

  if (safeSamples.any(_looksLikePhone) ||
      upperKey == 'TEL' ||
      upperKey == 'PHONE' ||
      upperKey == 'TELEFON') {
    add(
      const RegexQuickPreset(
        id: 'phone',
        label: 'Telefon',
        description: 'Wyciągnij numer telefonu.',
        pattern: r'((?:\+?\d[\d\s().-]{6,}\d))',
        suggestedOutputName: 'phone',
        normalizeDigits: true,
      ),
    );
  }

  if (safeSamples.any(_looksLikeZipCode) || upperKey == 'KOD') {
    add(
      const RegexQuickPreset(
        id: 'zip',
        label: 'Kod pocztowy',
        description: 'Wyciągnij kod w formacie 00-000.',
        pattern: r'(\d{2}-\d{3})',
        suggestedOutputName: 'zip_code',
      ),
    );
  }

  if (safeSamples.any(_looksLikeDate)) {
    add(
      const RegexQuickPreset(
        id: 'date',
        label: 'Data',
        description: 'Wyciągnij datę.',
        pattern:
            r'(\d{4}[./-]\d{1,2}[./-]\d{1,2}|\d{1,2}[./-]\d{1,2}[./-]\d{2,4})',
        suggestedOutputName: 'date',
      ),
    );
  }

  if (safeSamples.any(_looksLikeAmount)) {
    add(
      const RegexQuickPreset(
        id: 'amount',
        label: 'Kwota',
        description: 'Wyciągnij kwotę.',
        pattern: r'([+-]?\d[\d\s]*[.,]?\d{0,2}(?:\s?(?:PLN|EUR|USD|zł|ZŁ))?)',
        suggestedOutputName: 'amount',
      ),
    );
  }

  if ((key != null && key.isNotEmpty) && !looksLikeEmail(key)) {
    final escaped = RegExp.escape(key);

    add(
      RegexQuickPreset(
        id: 'key_digits',
        label: 'Cyfry po "$key"',
        description: 'Dla wartości typu NIP, REGON, numer, telefon.',
        pattern: '$escaped\\D*(\\d[\\d\\s-]*)',
        suggestedOutputName: _slugifyKey(key),
        key: key,
        normalizeDigits: true,
      ),
    );

    add(
      RegexQuickPreset(
        id: 'key_to_space',
        label: 'Tekst po "$key" do spacji',
        description: 'Weź pierwszy fragment po słowie-kluczu.',
        pattern: '$escaped\\s*[:\\-–]?\\s*([^\\s]+)',
        suggestedOutputName: _slugifyKey(key),
        key: key,
      ),
    );

    add(
      RegexQuickPreset(
        id: 'key_to_comma',
        label: 'Tekst po "$key" do przecinka',
        description: 'Dla struktur typu: NIP 123, REGON 456',
        pattern: '$escaped\\s*[:\\-–]?\\s*([^,;]+)',
        suggestedOutputName: _slugifyKey(key),
        key: key,
      ),
    );

    add(
      RegexQuickPreset(
        id: 'key_to_end',
        label: 'Tekst po "$key" do końca',
        description: 'Weź wszystko po słowie-kluczu.',
        pattern: '$escaped\\s*[:\\-–]?\\s*(.+)\$',
        suggestedOutputName: _slugifyKey(key),
        key: key,
      ),
    );
  }

  if (upperKey != null && isAddressKey(upperKey)) {
    add(
      RegexQuickPreset(
        id: 'address',
        label: 'Adres po "$upperKey"',
        description: 'Wyciągnij adres po słowie-kluczu.',
        pattern:
            '${RegExp.escape(upperKey)}\\s*[:\\-–.,]*\\s*([^,;\\n]*?\\d[^,;\\n]*)',
        suggestedOutputName: 'address',
        key: upperKey,
      ),
    );
  }

  if (presets.isEmpty) {
    add(
      const RegexQuickPreset(
        id: 'generic_literal',
        label: 'Dokładny fragment',
        description: 'Dopasuj dokładnie zaznaczony fragment.',
        pattern: r'(.+)',
        suggestedOutputName: 'value',
      ),
    );
  }

  return presets;
}

String _slugifyKey(String key) {
  return key
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9ąćęłńóśźż]+', unicode: true), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

/// Simple build based only on selected text.
RegexBuildResult buildRegexFromSelection(String selectedText) {
  final text = selectedText.trim();
  if (text.isEmpty) {
    return const RegexBuildResult(
      pattern: r'(.+)',
      key: null,
      isEmail: false,
      isAddress: false,
    );
  }

  final rawKey = detectKeyFromSelected(text);
  final bool emailLike = looksLikeEmail(text);

  final bool hasAddressKey =
      rawKey.isNotEmpty && isAddressKey(rawKey);
  final bool addressLike = !emailLike && hasAddressKey;

  String pattern;

  if (emailLike) {
    String? emailKey =
        rawKey.isNotEmpty && !rawKey.contains('@')
            ? rawKey
            : null;

    final pureEmailRe = RegExp(
      '^$kEmailCorePattern\$',
      caseSensitive: false,
    );
    if (pureEmailRe.hasMatch(text)) {
      emailKey = null;
    }

    if (emailKey != null && emailKey.isNotEmpty) {
      pattern = r'.*?' +
          RegExp.escape(emailKey) +
          r'\s*[:\-–]?\s*(' +
          kEmailCorePattern +
          r')';
    } else {
      pattern = '($kEmailCorePattern)';
    }

    return RegexBuildResult(
      pattern: pattern,
      key: emailKey,
      isEmail: true,
      isAddress: false,
    );
  }

  if (addressLike && hasAddressKey) {
    pattern = r'["„”''\s]*' +
        RegExp.escape(rawKey) +
        r'\s*[:\-–.,]*\s*([^,;\n]*?\d[^,;\n]*)';

    return RegexBuildResult(
      pattern: pattern,
      key: rawKey,
      isEmail: false,
      isAddress: true,
    );
  }

  if (_looksLikeZipCode(text)) {
    return const RegexBuildResult(
      pattern: r'(\d{2}-\d{3})',
      key: null,
      isEmail: false,
      isAddress: false,
    );
  }

  if (_looksLikeDate(text)) {
    return const RegexBuildResult(
      pattern:
          r'(\d{4}[./-]\d{1,2}[./-]\d{1,2}|\d{1,2}[./-]\d{1,2}[./-]\d{2,4})',
      key: null,
      isEmail: false,
      isAddress: false,
    );
  }

  if (_looksLikePhone(text)) {
    return const RegexBuildResult(
      pattern: r'((?:\+?\d[\d\s().-]{6,}\d))',
      key: null,
      isEmail: false,
      isAddress: false,
    );
  }

  if (_looksLikeAmount(text)) {
    return const RegexBuildResult(
      pattern: r'([+-]?\d[\d\s]*[.,]?\d{0,2}(?:\s?(?:PLN|EUR|USD|zł|ZŁ))?)',
      key: null,
      isEmail: false,
      isAddress: false,
    );
  }

  if (rawKey.isNotEmpty) {
    if (RegExp(r'\d').hasMatch(text)) {
      pattern = '${RegExp.escape(rawKey)}\\D*(\\d[\\d\\s-]*)';
    } else {
      pattern = '${RegExp.escape(rawKey)}\\s*[:\\-–]?\\s*(.+)\$';
    }

    return RegexBuildResult(
      pattern: pattern,
      key: rawKey,
      isEmail: false,
      isAddress: false,
    );
  }

  // Fallback: literal exact selected fragment
  return RegexBuildResult(
    pattern: '(${RegExp.escape(text)})',
    key: null,
    isEmail: false,
    isAddress: false,
  );
}

/// Smarter build based on full cell context.
/// If user selected part of an email / phone / zip / date etc.,
/// we try to match the whole meaningful token instead of treating
/// the fragment as a "key".
RegexBuildResult buildRegexFromSampleContext({
  required String fullText,
  required int selectionStart,
  required int selectionEnd,
}) {
  if (fullText.isEmpty) {
    return buildRegexFromSelection('');
  }

  final safeStart = selectionStart.clamp(0, fullText.length);
  final safeEnd = selectionEnd.clamp(0, fullText.length);

  if (safeEnd <= safeStart) {
    return buildRegexFromSelection('');
  }

  final selected = fullText.substring(safeStart, safeEnd).trim();
  if (selected.isEmpty) {
    return buildRegexFromSelection('');
  }

  final emailRe = RegExp(kEmailCorePattern, caseSensitive: false);
  for (final m in emailRe.allMatches(fullText)) {
    if (_rangesOverlap(safeStart, safeEnd, m.start, m.end)) {
      return const RegexBuildResult(
        pattern: '($kEmailCorePattern)',
        key: null,
        isEmail: true,
        isAddress: false,
      );
    }
  }

  final phoneRe = RegExp(_kPhonePattern);
  for (final m in phoneRe.allMatches(fullText)) {
    if (_rangesOverlap(safeStart, safeEnd, m.start, m.end)) {
      return const RegexBuildResult(
        pattern: r'((?:\+?\d[\d\s().-]{6,}\d))',
        key: null,
        isEmail: false,
        isAddress: false,
      );
    }
  }

  final zipRe = RegExp(_kZipPattern);
  for (final m in zipRe.allMatches(fullText)) {
    if (_rangesOverlap(safeStart, safeEnd, m.start, m.end)) {
      return const RegexBuildResult(
        pattern: r'(\d{2}-\d{3})',
        key: null,
        isEmail: false,
        isAddress: false,
      );
    }
  }

  final dateRe = RegExp(_kDatePattern);
  for (final m in dateRe.allMatches(fullText)) {
    if (_rangesOverlap(safeStart, safeEnd, m.start, m.end)) {
      return const RegexBuildResult(
        pattern:
            r'(\d{4}[./-]\d{1,2}[./-]\d{1,2}|\d{1,2}[./-]\d{1,2}[./-]\d{2,4})',
        key: null,
        isEmail: false,
        isAddress: false,
      );
    }
  }

  final amountRe = RegExp(_kAmountPattern, caseSensitive: false);
  for (final m in amountRe.allMatches(fullText)) {
    if (_rangesOverlap(safeStart, safeEnd, m.start, m.end)) {
      return const RegexBuildResult(
        pattern:
            r'([+-]?\d[\d\s]*[.,]?\d{0,2}(?:\s?(?:PLN|EUR|USD|zł|ZŁ))?)',
        key: null,
        isEmail: false,
        isAddress: false,
      );
    }
  }

  return buildRegexFromSelection(selected);
}