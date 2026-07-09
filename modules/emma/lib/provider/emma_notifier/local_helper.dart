part of '../emma_notifier.dart';

const Object _emmaManifestValueUnresolved = Object();

String _normalizeLocalToolLookupKey(dynamic value) {
  final text = (value ?? '').toString().trim();

  if (text.isEmpty) return '';

  return text
      .replaceAll('.', '_')
      .replaceAll('-', '_')
      .replaceAll(RegExp(r'[^a-zA-Z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '')
      .toLowerCase();
}

Map<String, dynamic> _emmaManifestMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<String> _emmaManifestStringList(dynamic value) {
  if (value is! List) return const <String>[];

  return value
      .map((e) => e?.toString().trim() ?? '')
      .where((e) => e.isNotEmpty)
      .toList(growable: false);
}

List<Map<String, dynamic>> _emmaManifestListOfMaps(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];

  return value
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);
}

void _indexLocalToolDefinition(_EmmaLocalToolDefinition def) {
  void put(
    dynamic raw, {
    bool override = false,
    String source = '',
  }) {
    final lookupKey = _normalizeLocalToolLookupKey(raw);
    if (lookupKey.isEmpty) return;

    final existing = _emmaLocalToolManifestByKey[lookupKey];

    if (existing == null || existing.key == def.key || override) {
      _emmaLocalToolManifestByKey[lookupKey] = def;
      return;
    }

    if (kDebugMode) {
      debugPrint(
        'Emma: local tool manifest lookup collision: '
        '$lookupKey from=$source existing=${existing.key} ignored=${def.key}',
      );
    }
  }

  put(def.key, override: true, source: 'key');
  put(def.backendActionKey, source: 'backendActionKey');
  put(def.localExecutorKey, source: 'localExecutorKey');

  final rawToolSchema = _emmaManifestMap(def.toolSchema);
  final rawFunction = _emmaManifestMap(rawToolSchema['function']);

  put(rawToolSchema['key'], source: 'toolSchema.key');
  put(rawToolSchema['name'], source: 'toolSchema.name');
  put(rawFunction['name'], source: 'toolSchema.function.name');

  for (final alias in def.aliases) {
    put(alias, source: 'alias');
  }

  for (final keyword in def.keywords) {
    put(keyword, source: 'keyword');
  }
}

void _rebuildLocalToolManifestIndex(
  Iterable<_EmmaLocalToolDefinition> definitions,
) {
  _emmaLocalToolManifestByKey.clear();

  for (final def in definitions) {
    _indexLocalToolDefinition(def);
  }

  if (kDebugMode) {
    final uniqueDefs = _uniqueLocalToolDefinitionsFromManifest();

    debugPrint(
      'Emma: local tool manifest rebuilt. '
      'defs=${uniqueDefs.length}, lookup_keys=${_emmaLocalToolManifestByKey.length}',
    );
  }
}

_EmmaLocalToolDefinition? _localToolDefinition(dynamic rawToolName) {
  final lookupKey = _normalizeLocalToolLookupKey(rawToolName);
  if (lookupKey.isEmpty) return null;

  return _emmaLocalToolManifestByKey[lookupKey];
}

List<_EmmaLocalToolDefinition> _uniqueLocalToolDefinitionsFromManifest() {
  final seen = <String>{};
  final out = <_EmmaLocalToolDefinition>[];

  for (final def in _emmaLocalToolManifestByKey.values) {
    if (seen.add(def.key)) {
      out.add(def);
    }
  }

  out.sort((a, b) => a.key.compareTo(b.key));
  return out;
}

Map<String, dynamic> _effectiveParametersSchemaForLocalToolDef(
  _EmmaLocalToolDefinition def,
) {
  if (def.parametersSchema.isNotEmpty) {
    return Map<String, dynamic>.from(def.parametersSchema);
  }

  final rawToolSchema = _emmaManifestMap(def.toolSchema);
  final rawFunction = _emmaManifestMap(rawToolSchema['function']);
  final rawParameters = _emmaManifestMap(rawFunction['parameters']);

  if (rawParameters.isNotEmpty) {
    return rawParameters;
  }

  return <String, dynamic>{
    'type': 'object',
    'additionalProperties': true,
    'properties': <String, dynamic>{},
  };
}

Map<String, dynamic> _localEngineToolSchemaFromManifestDef(
  _EmmaLocalToolDefinition def,
) {
  final rawToolSchema = _emmaManifestMap(def.toolSchema);
  final rawFunction = _emmaManifestMap(rawToolSchema['function']);

  final parameters = _effectiveParametersSchemaForLocalToolDef(def);

  final description = def.description.trim().isNotEmpty
      ? def.description.trim()
      : (rawFunction['description'] ?? def.title ?? def.key).toString();

  return <String, dynamic>{
    'type': 'function',

    // Frontend/runtime metadata.
    'key': def.key,
    'module_key': def.moduleKey,
    'required_app_module': def.requiredAppModule,
    'title': def.title,
    'description': description,
    'permission_code': def.permissionCode,
    'consent_setting_key': def.consentSettingKey,
    'execution_mode': def.executionMode,
    'frontend_mode': def.frontendMode,
    'backend_action_key': def.backendActionKey,
    'local_executor_key': def.localExecutorKey,
    'requires_online': def.requiresOnline,
    'offline_queueable': def.offlineQueueable,
    'requires_confirmation': def.requiresConfirmation,
    'destructive': def.destructive,
    'syncable': def.syncable,
    'keywords': def.keywords,
    'aliases': def.aliases,
    'examples': def.examples,
    'parameters_schema': parameters,
    'output_schema': def.outputSchema,
    'block_schema': def.blockSchema,

    // Shape consumed by the local LLM prompt.
    'function': <String, dynamic>{
      ...rawFunction,
      'name': def.key,
      'description': description,
      'parameters': parameters,
    },
  };
}

String _toolNameFromLocalEngineToolSchema(Map<String, dynamic> tool) {
  final fn = _emmaManifestMap(tool['function']);

  return (fn['name'] ?? tool['key'] ?? tool['name'] ?? '')
      .toString()
      .trim();
}

String _blockTypeFromLocalToolDefinition(_EmmaLocalToolDefinition def) {
  final schemaType = (def.blockSchema['type'] ??
          def.blockSchema['block_type'] ??
          def.blockSchema['kind'] ??
          '')
      .toString()
      .trim();

  if (schemaType.isNotEmpty) return schemaType;

  final rawToolSchema = _emmaManifestMap(def.toolSchema);
  final schemaToolType = (rawToolSchema['block_type'] ??
          rawToolSchema['render_type'] ??
          rawToolSchema['ui_block_type'] ??
          '')
      .toString()
      .trim();

  if (schemaToolType.isNotEmpty) return schemaToolType;

  if (def.moduleKey == 'calendar') return 'calendar_event';
  if (def.moduleKey == 'tms') return 'tms_task';
  if (def.moduleKey == 'email') return 'email_draft';
  if (def.moduleKey == 'notes') return 'info';
  if (def.moduleKey == 'memos') return 'memo_daily';
  if (def.moduleKey == 'ui') return 'ui_anchor_action';

  return 'info';
}

String _entityTypeForLocalToolDefinition(_EmmaLocalToolDefinition def) {
  final explicit = (def.blockSchema['entity_type'] ??
          def.blockSchema['entityType'] ??
          def.blockSchema['entity'] ??
          '')
      .toString()
      .trim();

  if (explicit.isNotEmpty) return explicit;

  final blockType = _blockTypeFromLocalToolDefinition(def);

  switch (blockType) {
    case 'calendar_event':
      return 'calendar_event';
    case 'tms_task':
    case 'task':
      return 'task';
    case 'email_draft':
      return 'email_draft';
    case 'memo_daily':
      return 'memo';
    case 'ui_anchor_action':
      return 'ui_action';
  }

  if (def.moduleKey.trim().isNotEmpty) {
    return '${def.moduleKey.trim()}_entity';
  }

  return 'local_entity';
}









