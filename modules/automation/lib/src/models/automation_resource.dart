class AutomationResourceDefinition {
  final String key;
  final String label;
  final String description;
  final String appLabel;
  final String modelName;
  final List<String> lookupFields;
  final List<String> readableFields;
  final List<String> writableFields;
  final List<String> creatableFields;
  final Map<String, dynamic> fieldSchema;
  final bool allowCreate;
  final bool allowUpdate;
  final bool allowRead;

  const AutomationResourceDefinition({
    required this.key,
    required this.label,
    this.description = '',
    this.appLabel = '',
    this.modelName = '',
    this.lookupFields = const [],
    this.readableFields = const [],
    this.writableFields = const [],
    this.creatableFields = const [],
    this.fieldSchema = const {},
    this.allowCreate = false,
    this.allowUpdate = true,
    this.allowRead = true,
  });

  factory AutomationResourceDefinition.fromJson(Map<String, dynamic> json) {
    List<String> list(String key) => (json[key] as List? ?? const [])
        .map((item) => item.toString())
        .toList();

    return AutomationResourceDefinition(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? json['key']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      appLabel: json['app_label']?.toString() ?? '',
      modelName: json['model_name']?.toString() ?? '',
      lookupFields: list('lookup_fields'),
      readableFields: list('readable_fields'),
      writableFields: list('writable_fields'),
      creatableFields: list('creatable_fields'),
      fieldSchema: Map<String, dynamic>.from(json['field_schema'] as Map? ?? const {}),
      allowCreate: json['allow_create'] == true,
      allowUpdate: json['allow_update'] != false,
      allowRead: json['allow_read'] != false,
    );
  }
}
