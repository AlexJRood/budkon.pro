class DocumentTemplateField {
  final String id;
  final String templateId;
  final String key;
  final String label;
  final String fieldType;
  final bool required;
  final String defaultValue;
  final String placeholder;
  final String helpText;
  final List<dynamic> options;
  final Map<String, dynamic> validation;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DocumentTemplateField({
    required this.id,
    required this.templateId,
    required this.key,
    required this.label,
    required this.fieldType,
    required this.required,
    required this.defaultValue,
    required this.placeholder,
    required this.helpText,
    required this.options,
    required this.validation,
    required this.order,
    this.createdAt,
    this.updatedAt,
  });

  factory DocumentTemplateField.fromJson(Map<String, dynamic> json) {
    return DocumentTemplateField(
      id: json['id']?.toString() ?? '',
      templateId: json['template']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      fieldType: json['field_type']?.toString() ?? 'text',
      required: json['required'] == true,
      defaultValue: json['default_value']?.toString() ?? '',
      placeholder: json['placeholder']?.toString() ?? '',
      helpText: json['help_text']?.toString() ?? '',
      options: json['options'] is List ? List<dynamic>.from(json['options']) : [],
      validation: json['validation'] is Map
          ? Map<String, dynamic>.from(json['validation'])
          : <String, dynamic>{},
      order: _toInt(json['order']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'template': templateId,
      'key': key,
      'label': label,
      'field_type': fieldType,
      'required': required,
      'default_value': defaultValue,
      'placeholder': placeholder,
      'help_text': helpText,
      'options': options,
      'validation': validation,
      'order': order,
    };
  }

  DocumentTemplateField copyWith({
    String? id,
    String? templateId,
    String? key,
    String? label,
    String? fieldType,
    bool? required,
    String? defaultValue,
    String? placeholder,
    String? helpText,
    List<dynamic>? options,
    Map<String, dynamic>? validation,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DocumentTemplateField(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      key: key ?? this.key,
      label: label ?? this.label,
      fieldType: fieldType ?? this.fieldType,
      required: required ?? this.required,
      defaultValue: defaultValue ?? this.defaultValue,
      placeholder: placeholder ?? this.placeholder,
      helpText: helpText ?? this.helpText,
      options: options ?? this.options,
      validation: validation ?? this.validation,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DocumentTemplate {
  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> deltaJson;
  final Map<String, dynamic> styleJson;
  final String? logo;
  final String? fontFile;
  final String? ownerId;
  final String? ownerUsername;
  final String? companyId;
  final String? companyName;
  final String? teamId;
  final String? teamName;
  final bool isGlobal;
  final List<dynamic> tags;
  final String? forkedFromId;
  final List<DocumentTemplateField> formFields;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DocumentTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.deltaJson,
    required this.styleJson,
    this.logo,
    this.fontFile,
    this.ownerId,
    this.ownerUsername,
    this.companyId,
    this.companyName,
    this.teamId,
    this.teamName,
    this.isGlobal = false,
    this.tags = const [],
    this.forkedFromId,
    this.formFields = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentTemplate.fromJson(Map<String, dynamic> json) {
    final fieldsRaw = json['form_fields'] ?? json['fields'];

    return DocumentTemplate(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      deltaJson: _normalizeMap(json['delta_json'], fallback: {
        'ops': [
          {'insert': '\n'},
        ],
      }),
      styleJson: _normalizeMap(json['style_json']),
      logo: json['logo']?.toString(),
      fontFile: json['font_file']?.toString(),
      ownerId: json['owner']?.toString(),
      ownerUsername: json['owner_username']?.toString(),
      companyId: json['company']?.toString(),
      companyName: json['company_name']?.toString(),
      teamId: json['team']?.toString(),
      teamName: json['team_name']?.toString(),
      isGlobal: json['is_global'] == true,
      tags: json['tags'] is List ? List<dynamic>.from(json['tags']) : [],
      forkedFromId: json['forked_from_id']?.toString(),
      formFields: fieldsRaw is List
          ? fieldsRaw
              .whereType<Map>()
              .map((item) => DocumentTemplateField.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
      createdAt: _parseDate(json['date_created'] ?? json['created_at']) ??
          DateTime.now(),
      updatedAt: _parseDate(json['date_updated'] ?? json['updated_at']) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'description': description,
      'delta_json': deltaJson,
      'style_json': styleJson,
      if (logo != null) 'logo': logo,
      if (fontFile != null) 'font_file': fontFile,
      if (companyId != null) 'company': companyId,
      if (teamId != null) 'team': teamId,
      'is_global': isGlobal,
      'tags': tags,
    };
  }

  DocumentTemplate copyWith({
    String? id,
    String? name,
    String? description,
    Map<String, dynamic>? deltaJson,
    Map<String, dynamic>? styleJson,
    String? logo,
    String? fontFile,
    String? ownerId,
    String? ownerUsername,
    String? companyId,
    String? companyName,
    String? teamId,
    String? teamName,
    bool? isGlobal,
    List<dynamic>? tags,
    String? forkedFromId,
    List<DocumentTemplateField>? formFields,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DocumentTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      deltaJson: deltaJson ?? this.deltaJson,
      styleJson: styleJson ?? this.styleJson,
      logo: logo ?? this.logo,
      fontFile: fontFile ?? this.fontFile,
      ownerId: ownerId ?? this.ownerId,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      isGlobal: isGlobal ?? this.isGlobal,
      tags: tags ?? this.tags,
      forkedFromId: forkedFromId ?? this.forkedFromId,
      formFields: formFields ?? this.formFields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

Map<String, dynamic> _normalizeMap(
  dynamic value, {
  Map<String, dynamic> fallback = const {},
}) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is List) return {'ops': value};
  return Map<String, dynamic>.from(fallback);
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}