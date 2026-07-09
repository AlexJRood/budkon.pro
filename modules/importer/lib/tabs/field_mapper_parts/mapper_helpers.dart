part of importer_field_mapper;

class _TargetFieldSpec {
  final String name;
  final String type;
  final String? relatedModel;
  final bool required;

  const _TargetFieldSpec({
    required this.name,
    required this.type,
    required this.relatedModel,
    required this.required,
  });

  bool get isRelation {
    final lowerType = type.toLowerCase();

    return lowerType == 'foreignkey' ||
        lowerType == 'onetoonefield' ||
        lowerType == 'manytomanyfield' ||
        relatedModel != null;
  }
}

List<_TargetFieldSpec> _extractFieldSpecsFromRawSpec(dynamic rawSpec) {
  if (rawSpec is! List) return [];

  final specs = <_TargetFieldSpec>[];

  for (final raw in rawSpec) {
    if (raw is! Map) continue;

    final map = Map<String, dynamic>.from(raw);

    final name = (map['field_name'] ?? '').toString().trim();
    if (name.isEmpty) continue;

    final type = (map['field_type'] ?? '').toString().trim();

    final relatedModelRaw =
        map['field_related_model'] ?? map['related_model'];

    final relatedModelText = relatedModelRaw?.toString().trim();

    specs.add(
      _TargetFieldSpec(
        name: name,
        type: type,
        relatedModel: relatedModelText == null || relatedModelText.isEmpty
            ? null
            : relatedModelText,
        required: map['field_required'] == true || map['required'] == true,
      ),
    );
  }

  specs.sort((a, b) {
    if (a.isRelation != b.isRelation) {
      return a.isRelation ? -1 : 1;
    }

    if (a.required != b.required) {
      return a.required ? -1 : 1;
    }

    return a.name.compareTo(b.name);
  });

  return specs;
}

List<String> _extractFieldNamesFromRawSpec(dynamic rawSpec) {
  return _extractFieldSpecsFromRawSpec(rawSpec)
      .map((spec) => spec.name)
      .toSet()
      .toList()
    ..sort();
}

List<String> _samplesForColumn({
  required List<String> previewColumns,
  required List<List<String>> previewData,
  required String columnName,
  int maxItems = 3,
}) {
  final colIndex = previewColumns.indexOf(columnName);
  if (colIndex == -1) return [];

  final out = <String>[];

  for (final row in previewData.take(maxItems)) {
    final value = colIndex < row.length ? row[colIndex] : '';

    if (value.trim().isNotEmpty) {
      out.add(value);
    }
  }

  return out;
}

bool _hasValidEmmaEntityPlan(dynamic value) {
  final map = _asStringMap(value);

  if (map.isEmpty) return false;

  final entities = map['entities'];
  final relations = map['relations'];

  return (entities is List && entities.isNotEmpty) ||
      (relations is List && relations.isNotEmpty);
}

Map<String, dynamic> _asStringMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

int _emmaInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _formatConfidence(dynamic value) {
  if (value == null) return '';

  if (value is num) {
    return value.toStringAsFixed(2);
  }

  final parsed = double.tryParse(value.toString());
  if (parsed == null) return value.toString();

  return parsed.toStringAsFixed(2);
}

ButtonStyle _outlinedActionStyle(ThemeColors theme) {
  return OutlinedButton.styleFrom(
    foregroundColor: theme.textColor,
    backgroundColor: theme.dashboardContainer,
    side: BorderSide(
      color: theme.dashboardBoarder.withAlpha(130),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

ButtonStyle _filledActionStyle(ThemeColors theme) {
  return ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: theme.themeColor,
    disabledForegroundColor: Colors.white.withAlpha(170),
    disabledBackgroundColor: theme.themeColor.withAlpha(120),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
  );
}
