// lib/emma/settings/ai_dynamic_setting.dart
// lib/emma/settings/ai_dynamic_setting.dart

class AiDynamicSetting {
  final String key;        // "calendar.allow_prompt"
  final String module;     // "calendar"
  final String name;       // "allow_prompt"
  final String fieldType;  // "bool" | "int" | "str" | "choice"
  final String label;
  final String category;   // "privacy", "limits", "ui", ...
  final String description;
  final dynamic value;
  final dynamic defaultValue; // 👈 TU trzymamy backendowe "default"
  final List<AiSettingChoice> choices;

  AiDynamicSetting({
    required this.key,
    required this.module,
    required this.name,
    required this.fieldType,
    required this.label,
    required this.category,
    required this.description,
    required this.value,
    required this.defaultValue,
    required this.choices,
  });

  factory AiDynamicSetting.fromJson(Map<String, dynamic> json) {
    final rawChoices = json['choices'];
    final choicesJson = rawChoices is List ? rawChoices : const [];

    return AiDynamicSetting(
      key: json['key'] as String,
      module: (json['module'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      fieldType: (json['field_type'] ?? 'str') as String,
      label: (json['label'] ?? json['key']) as String,
      category: (json['category'] ?? 'general') as String,
      description: (json['description'] ?? '') as String,
      value: json['value'],
      defaultValue: json['default'], // 👈 mapujemy z backendu
      choices: choicesJson
          .whereType<Map>()
          .map((e) => AiSettingChoice.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
    );
  }

  AiDynamicSetting copyWith({dynamic value}) {
    return AiDynamicSetting(
      key: key,
      module: module,
      name: name,
      fieldType: fieldType,
      label: label,
      category: category,
      description: description,
      value: value ?? this.value,
      defaultValue: defaultValue,
      choices: choices,
    );
  }
}



class AiSettingChoice {
  final String value;
  final String label;

  AiSettingChoice({required this.value, required this.label});

  factory AiSettingChoice.fromJson(Map<String, dynamic> json) {
    final val = json['value'];
    final lab = json['label'];
    final valueStr = (val ?? '').toString();
    final labelStr = (lab ?? val ?? '').toString();

    return AiSettingChoice(
      value: valueStr,
      label: labelStr,
    );
  }
}
