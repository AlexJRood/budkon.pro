




// lib/importer/tabs/mapping/models.dart

/// Pojedyncza próbka zaznaczenia tekstu z komórki
class RegexSelectionSample {
  final String columnName;
  final String fullText;
  final int start;
  final int end;

  RegexSelectionSample({
    required this.columnName,
    required this.fullText,
    required this.start,
    required this.end,
  });

  String get selectedText {
    if (start < 0 || end <= start || start >= fullText.length) {
      return '';
    }
    final safeEnd = end.clamp(0, fullText.length);
    return fullText.substring(start, safeEnd);
  }
}