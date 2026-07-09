// docs/widgets/template_editor/template_editor_models.dart

enum TemplateEditorFieldType {
  text,
  textarea,
  email,
  phone,
  number,
  money,
  date,
  datetime,
  dropdown,
  multiselect,
  checkbox,
  boolean,
}

enum TemplateEditorTokenKind {
  field,
  segmentStart,
  segmentEnd,
}

class TemplateEditorFieldOption {
  final String value;
  final String label;

  const TemplateEditorFieldOption({
    required this.value,
    required this.label,
  });
}

class TemplateEditorFieldSpec {
  final String label;
  final String? key;
  final TemplateEditorFieldType type;
  final bool required;
  final int? maxLength;
  final num? min;
  final num? max;
  final String? defaultPrefix;
  final String? defaultValue;
  final String? helpText;
  final List<TemplateEditorFieldOption> options;

  const TemplateEditorFieldSpec({
    required this.label,
    this.key,
    this.type = TemplateEditorFieldType.text,
    this.required = false,
    this.maxLength,
    this.min,
    this.max,
    this.defaultPrefix,
    this.defaultValue,
    this.helpText,
    this.options = const [],
  });
}

class TemplateEditorSegmentSpec {
  final String label;
  final bool skipable;

  const TemplateEditorSegmentSpec({
    required this.label,
    this.skipable = true,
  });
}

class TemplateEditorTokenMatch {
  final TemplateEditorTokenKind kind;
  final int start;
  final int end;
  final String raw;

  const TemplateEditorTokenMatch({
    required this.kind,
    required this.start,
    required this.end,
    required this.raw,
  });
}