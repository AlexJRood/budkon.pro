import 'automation_resource.dart';

class AutomationCatalog {
  final List<AutomationSignalDefinition> signals;
  final List<AutomationActionDefinition> actions;
  final List<AutomationResourceDefinition> resources;

  const AutomationCatalog({
    this.signals = const [],
    this.actions = const [],
    this.resources = const [],
  });

  factory AutomationCatalog.fromJson(Map<String, dynamic> json) {
    return AutomationCatalog(
      signals: (json['signals'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => AutomationSignalDefinition.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      actions: (json['actions'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => AutomationActionDefinition.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      resources: (json['resources'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => AutomationResourceDefinition.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  AutomationSignalDefinition? signalByKey(String key) {
    for (final item in signals) {
      if (item.key == key) return item;
    }
    return null;
  }

  AutomationActionDefinition? actionByKey(String key) {
    for (final item in actions) {
      if (item.key == key) return item;
    }
    return null;
  }

  AutomationResourceDefinition? resourceByKey(String key) {
    for (final item in resources) {
      if (item.key == key) return item;
    }
    return null;
  }
}

class AutomationSignalDefinition {
  final String key;
  final String label;
  final String description;
  final Map<String, dynamic> payloadSchema;
  final Map<String, dynamic> examplePayload;
  final String appLabel;

  const AutomationSignalDefinition({
    required this.key,
    required this.label,
    this.description = '',
    this.payloadSchema = const {},
    this.examplePayload = const {},
    this.appLabel = '',
  });

  factory AutomationSignalDefinition.fromJson(Map<String, dynamic> json) {
    return AutomationSignalDefinition(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? json['key']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      payloadSchema: Map<String, dynamic>.from(json['payload_schema'] as Map? ?? const {}),
      examplePayload: Map<String, dynamic>.from(json['example_payload'] as Map? ?? const {}),
      appLabel: json['app_label']?.toString() ?? '',
    );
  }
}

class AutomationActionDefinition {
  final String key;
  final String label;
  final String description;
  final String appLabel;
  final Map<String, dynamic> configSchema;
  final Map<String, dynamic> inputSchema;
  final Map<String, dynamic> outputSchema;

  const AutomationActionDefinition({
    required this.key,
    required this.label,
    this.description = '',
    this.appLabel = '',
    this.configSchema = const {},
    this.inputSchema = const {},
    this.outputSchema = const {},
  });

  factory AutomationActionDefinition.fromJson(Map<String, dynamic> json) {
    return AutomationActionDefinition(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? json['key']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      appLabel: json['app_label']?.toString() ?? '',
      configSchema: Map<String, dynamic>.from(json['config_schema'] as Map? ?? const {}),
      inputSchema: Map<String, dynamic>.from(json['input_schema'] as Map? ?? const {}),
      outputSchema: Map<String, dynamic>.from(json['output_schema'] as Map? ?? const {}),
    );
  }
}
