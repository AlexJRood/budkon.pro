part of '../emma_notifier.dart';

class _EmmaParsedLocalToolResult {
  final String toolName;
  final Map<String, dynamic> arguments;
  final String assistantMessage;
  final Map<String, dynamic> optimisticBlock;
  final String? toolCallId;

  const _EmmaParsedLocalToolResult({
    required this.toolName,
    required this.arguments,
    required this.assistantMessage,
    required this.optimisticBlock,
    required this.toolCallId,
  });
}

class _EmmaNormalizedLocalToolRun {
  final String toolName;
  final String visibleContent;
  final String clientActionId;
  final String? localEntityId;
  final String syncStatus;
  final Map<String, dynamic> arguments;
  final List<Map<String, dynamic>> blocks;
  final List<Map<String, dynamic>> toolResults;

  const _EmmaNormalizedLocalToolRun({
    required this.toolName,
    required this.visibleContent,
    required this.clientActionId,
    required this.localEntityId,
    required this.syncStatus,
    required this.arguments,
    required this.blocks,
    required this.toolResults,
  });
}

extension EmmaNotifierLocalToolsRuntime on ChatAiMessagesNotifier {
  static final RegExp _emmaToolResultRe = RegExp(
    r'<emma_tool_result>\s*([\s\S]*?)\s*</emma_tool_result>',
    caseSensitive: false,
  );

  _EmmaParsedLocalToolResult? _parseLocalToolResult(String content) {
    final text = content.trim();
    if (text.isEmpty) return null;

    final taggedMatch = _emmaToolResultRe.firstMatch(text);

    if (taggedMatch != null) {
      final rawJson = (taggedMatch.group(1) ?? '').trim();

      final parsed = _tryParseLocalToolJson(
        rawJson,
        debugOnFailure: true,
      );

      if (parsed != null) return parsed;
    }

    final stripped = _stripJsonCodeFence(text).trim();

    if (stripped.startsWith('{') && stripped.endsWith('}')) {
      final parsedPlainJson = _tryParseLocalToolJson(
        stripped,
        debugOnFailure: true,
      );

      if (parsedPlainJson != null) return parsedPlainJson;
    }

    final extractedJson = _extractFirstJsonObject(text);

    if (extractedJson != null) {
      final parsedExtracted = _tryParseLocalToolJson(
        extractedJson,
        debugOnFailure: true,
      );

      if (parsedExtracted != null) return parsedExtracted;
    }

    return null;
  }

  String _repairCommonMalformedLocalToolJson(String raw) {
    var text = _stripJsonCodeFence(raw).trim();

    while (text.startsWith('{{') && text.endsWith('}}') && text.length >= 4) {
      text = text.substring(1, text.length - 1).trim();
    }

    text = text
        .replaceAll(RegExp(r',\s*}'), '}')
        .replaceAll(RegExp(r',\s*]'), ']');

    return text.trim();
  }

  _EmmaParsedLocalToolResult? _tryParseLocalToolJson(
    String raw, {
    bool debugOnFailure = false,
  }) {
    final normalized = _repairCommonMalformedLocalToolJson(raw);

    if (normalized.isEmpty) return null;
    if (!normalized.startsWith('{')) return null;

    try {
      final decoded = jsonDecode(normalized);
      if (decoded is! Map) return null;

      final map = Map<String, dynamic>.from(decoded);

      final directParsed = _tryParseLocalToolMap(map);
      if (directParsed != null) return directParsed;

      final toolCalls = map['tool_calls'];

      if (toolCalls is List && toolCalls.isNotEmpty) {
        for (final rawCall in toolCalls.whereType<Map>()) {
          final call = Map<String, dynamic>.from(rawCall);
          final functionRaw = call['function'];

          if (functionRaw is! Map) continue;

          final function = Map<String, dynamic>.from(functionRaw);

          final name = (function['name'] ?? '').toString().trim();
          if (name.isEmpty) continue;

          final arguments = _decodeArgumentsMap(function['arguments']);

          return _EmmaParsedLocalToolResult(
            toolName: name,
            arguments: arguments,
            assistantMessage: (map['assistant_message'] ??
                    map['message'] ??
                    'Wykonałam akcję.')
                .toString()
                .trim(),
            optimisticBlock: _extractOptimisticBlockFromMap(map),
            toolCallId: call['id']?.toString(),
          );
        }
      }

      final functionCallRaw = map['function_call'];

      if (functionCallRaw is Map) {
        final functionCall = Map<String, dynamic>.from(functionCallRaw);

        final name = (functionCall['name'] ?? '').toString().trim();

        if (name.isNotEmpty) {
          return _EmmaParsedLocalToolResult(
            toolName: name,
            arguments: _decodeArgumentsMap(functionCall['arguments']),
            assistantMessage: (map['assistant_message'] ??
                    map['message'] ??
                    'Wykonałam akcję.')
                .toString()
                .trim(),
            optimisticBlock: _extractOptimisticBlockFromMap(map),
            toolCallId: functionCall['id']?.toString(),
          );
        }
      }

      return null;
    } catch (e) {
      if (debugOnFailure && kDebugMode) {
        debugPrint('Emma: local tool json parse failed: $e');
        debugPrint('Emma: local tool raw candidate: $normalized');
      }

      return null;
    }
  }

  _EmmaParsedLocalToolResult? _tryParseLocalToolMap(
    Map<String, dynamic> map,
  ) {
    final toolName = (map['tool_name'] ??
            map['name'] ??
            map['tool'] ??
            map['function_name'] ??
            '')
        .toString()
        .trim();

    if (toolName.isEmpty) return null;

    return _EmmaParsedLocalToolResult(
      toolName: toolName,
      arguments: _decodeArgumentsMap(map['arguments']),
      assistantMessage:
          (map['assistant_message'] ?? map['message'] ?? '').toString().trim(),
      optimisticBlock: _extractOptimisticBlockFromMap(map),
      toolCallId: map['tool_call_id']?.toString(),
    );
  }

  Map<String, dynamic> _decodeArgumentsMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);

    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);

        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }

    return <String, dynamic>{};
  }

  Map<String, dynamic> _extractOptimisticBlockFromMap(
    Map<String, dynamic> map,
  ) {
    final optimisticRaw =
        map['optimistic_block'] ?? map['block'] ?? map['optimistic_result'];

    if (optimisticRaw is Map) {
      var optimisticBlock = Map<String, dynamic>.from(optimisticRaw);

      final nestedBlocks = optimisticBlock['render_blocks'];

      if (nestedBlocks is List && nestedBlocks.isNotEmpty) {
        final first = nestedBlocks.first;

        if (first is Map) {
          optimisticBlock = Map<String, dynamic>.from(first);
        }
      }

      return optimisticBlock;
    }

    return <String, dynamic>{};
  }

  String _stripJsonCodeFence(String raw) {
    var text = raw.trim();

    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```(?:json|JSON)?\s*'), '');
      text = text.replaceFirst(RegExp(r'\s*```$'), '');
    }

    return text.trim();
  }

  String? _extractFirstJsonObject(String text) {
    final source = _stripJsonCodeFence(text);
    final start = source.indexOf('{');

    if (start < 0) return null;

    var depth = 0;
    var inString = false;
    var escape = false;

    for (var i = start; i < source.length; i++) {
      final ch = source[i];

      if (escape) {
        escape = false;
        continue;
      }

      if (ch == '\\') {
        if (inString) escape = true;
        continue;
      }

      if (ch == '"') {
        inString = !inString;
        continue;
      }

      if (inString) continue;

      if (ch == '{') {
        depth++;
      } else if (ch == '}') {
        depth--;

        if (depth == 0) {
          return source.substring(start, i + 1).trim();
        }
      }
    }

    return null;
  }

  _EmmaNormalizedLocalToolRun? _normalizeParsedLocalToolResult({
    required _EmmaParsedLocalToolResult parsed,
    required int assistantMessageId,
  }) {
    final def = _localToolDefinition(parsed.toolName);

    if (def == null) {
      final clientActionId =
          'unsupported_${DateTime.now().microsecondsSinceEpoch}';

      final block = <String, dynamic>{
        'type': 'info',
        'block_id': 'unsupported_tool_$clientActionId',
        'variant': 'error',
        'title': 'Nieobsługiwane narzędzie lokalne',
        'text': parsed.toolName,
        'detail': parsed.toolName,
        'tool_name': parsed.toolName,
        'sync_status': 'failed',
      };

      if (kDebugMode) {
        debugPrint('Emma: unsupported local tool: ${parsed.toolName}');
        debugPrint(
          'Emma: lookup=${_normalizeLocalToolLookupKey(parsed.toolName)}',
        );
        debugPrint(
          'Emma: manifest keys sample='
          '${_emmaLocalToolManifestByKey.keys.take(60).toList()}',
        );
      }

      return _EmmaNormalizedLocalToolRun(
        toolName: parsed.toolName,
        visibleContent: parsed.assistantMessage.isNotEmpty
            ? parsed.assistantMessage
            : 'Nie obsługuję jeszcze tego narzędzia lokalnie.',
        clientActionId: clientActionId,
        localEntityId: null,
        syncStatus: 'failed',
        arguments: parsed.arguments,
        blocks: [block],
        toolResults: [
          {
            'ok': false,
            'tool_name': parsed.toolName,
            'error': 'Unsupported local tool: ${parsed.toolName}',
            'render_blocks': [block],
          }
        ],
      );
    }

    return _normalizeGenericLocalToolResultFromManifest(
      parsed: _EmmaParsedLocalToolResult(
        toolName: def.key,
        arguments: parsed.arguments,
        assistantMessage: parsed.assistantMessage,
        optimisticBlock: parsed.optimisticBlock,
        toolCallId: parsed.toolCallId,
      ),
      def: def,
      assistantMessageId: assistantMessageId,
    );
  }

  _EmmaNormalizedLocalToolRun _normalizeGenericLocalToolResultFromManifest({
    required _EmmaParsedLocalToolResult parsed,
    required _EmmaLocalToolDefinition def,
    required int assistantMessageId,
  }) {
    final nowMicros = DateTime.now().microsecondsSinceEpoch;

    final safeToolPart = _safeToolIdPart(def.key);
    final entityType = _entityTypeForLocalToolDefinition(def);
    final safeEntityPart = _safeToolIdPart(entityType);

    final args = Map<String, dynamic>.from(parsed.arguments);

    final existingClientActionId = _firstNonEmptyString([
      parsed.toolCallId,
      args['client_action_id'],
      args['clientActionId'],
      args['action_id'],
      args['actionId'],
    ]);

    final clientActionId = existingClientActionId ??
        '${safeToolPart}_${DateTime.now().microsecondsSinceEpoch}';

    final existingLocalEntityId = _firstNonEmptyString([
      args['client_local_id'],
      args['clientLocalId'],
      args['local_entity_id'],
      args['localEntityId'],
      args['local_id'],
      args['localId'],
      args['id'],
    ]);

    final localEntityId = _shouldHaveLocalEntityId(def)
        ? (existingLocalEntityId ?? 'local_${safeEntityPart}_$nowMicros')
        : null;

    final initialSyncStatus = _initialSyncStatusForTool(def);

    final materializeArguments = <String, dynamic>{
      ...args,
      'client_action_id': clientActionId,
      if (localEntityId != null) 'client_local_id': localEntityId,
      if (localEntityId != null) 'local_entity_id': localEntityId,
      if (localEntityId != null) 'local_id': localEntityId,
      'sync_origin': 'local_llm_frontend',
    };

    final optimisticBlock = parsed.optimisticBlock.isNotEmpty
        ? _normalizeLocalOptimisticBlockFromModel(
            parsed.optimisticBlock,
            def: def,
            arguments: materializeArguments,
            clientActionId: clientActionId,
            localEntityId: localEntityId,
            syncStatus: initialSyncStatus,
          )
        : _buildOptimisticBlockFromToolManifest(
            def: def,
            arguments: materializeArguments,
            clientActionId: clientActionId,
            localEntityId: localEntityId,
            syncStatus: initialSyncStatus,
          );

    final blocks = optimisticBlock.isNotEmpty
        ? [optimisticBlock]
        : [
            <String, dynamic>{
              'type': 'info',
              'block_id': 'local_${safeToolPart}_$clientActionId',
              'variant': 'success',
              'title': def.title.isNotEmpty ? def.title : def.key,
              'text': parsed.assistantMessage,
              'tool_name': def.key,
              'module_key': def.moduleKey,
              'client_action_id': clientActionId,
              'local_entity_id': localEntityId,
              'sync_status': initialSyncStatus,
              'sync_origin': 'local_llm_frontend',
            }
          ];

    final visibleContent = parsed.assistantMessage.isNotEmpty
        ? parsed.assistantMessage
        : _defaultAssistantMessageForLocalTool(def);

    final toolResult = <String, dynamic>{
      'ok': true,
      'tool_name': def.key,
      'module_key': def.moduleKey,
      'local': true,
      'optimistic': true,
      'local_entity_id': localEntityId,
      'client_action_id': clientActionId,
      'arguments': materializeArguments,
      'render_blocks': blocks,
      'llm_result': {
        'ok': true,
        'local': true,
        'optimistic': true,
        'tool_name': def.key,
        'module_key': def.moduleKey,
        'local_entity_id': localEntityId,
        'client_action_id': clientActionId,
        'note': 'Tool prepared locally and is waiting for backend sync.',
      },
    };

    return _EmmaNormalizedLocalToolRun(
      toolName: def.key,
      visibleContent: visibleContent,
      clientActionId: clientActionId,
      localEntityId: localEntityId,
      syncStatus: initialSyncStatus,
      arguments: materializeArguments,
      blocks: blocks,
      toolResults: [toolResult],
    );
  }

  String? _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text != 'null') return text;
    }

    return null;
  }

  bool _shouldHaveLocalEntityId(_EmmaLocalToolDefinition def) {
    if (def.destructive) return false;

    if (def.syncable) return true;
    if (def.offlineQueueable) return true;
    if (def.executionMode == 'localFirst') return true;
    if (def.executionMode == 'localOnly') return true;

    return false;
  }

  String _initialSyncStatusForTool(_EmmaLocalToolDefinition def) {
    if (def.executionMode == 'uiOnly') return 'synced';
    if (def.syncable || def.offlineQueueable) return 'syncing';
    return 'synced';
  }

  String _safeToolIdPart(String value) {
    final safe = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    return safe.isNotEmpty ? safe : 'tool';
  }

  String _defaultAssistantMessageForLocalTool(_EmmaLocalToolDefinition def) {
    final title = def.title.isNotEmpty ? def.title : def.key.replaceAll('_', ' ');

    if (def.moduleKey == 'tms' && def.key.contains('create')) {
      return 'Dodałam zadanie.';
    }

    if (def.moduleKey == 'calendar' && def.key.contains('create')) {
      return 'Dodałam wydarzenie do kalendarza.';
    }

    if (def.moduleKey == 'notes' && def.key.contains('create')) {
      return 'Dodałam notatkę.';
    }

    if (def.moduleKey == 'email') {
      return 'Przygotowałam wiadomość e-mail.';
    }

    return '$title.';
  }

  Map<String, dynamic> _normalizeLocalOptimisticBlockFromModel(
    Map<String, dynamic> raw, {
    required _EmmaLocalToolDefinition def,
    required Map<String, dynamic> arguments,
    required String clientActionId,
    required String? localEntityId,
    required String syncStatus,
  }) {
    final block = Map<String, dynamic>.from(raw);

    if (block.isEmpty) {
      return _buildOptimisticBlockFromToolManifest(
        def: def,
        arguments: arguments,
        clientActionId: clientActionId,
        localEntityId: localEntityId,
        syncStatus: syncStatus,
      );
    }

    final blockType = (block['type'] ?? _blockTypeFromLocalToolDefinition(def))
        .toString()
        .trim();

    block['type'] = blockType.isNotEmpty ? blockType : 'info';
    block['title'] ??= def.title;
    block['tool_name'] ??= def.key;
    block['module_key'] ??= def.moduleKey;
    block['client_action_id'] ??= clientActionId;
    block['local_entity_id'] ??= localEntityId;
    block['sync_status'] ??= syncStatus;
    block['sync_origin'] ??= 'local_llm_frontend';

    block['block_id'] ??= _stableLocalBlockIdForTool(
      toolName: def.key,
      clientActionId: clientActionId,
      localEntityId: localEntityId,
      blockType: blockType,
    );

    return _mergeArgumentsIntoManifestBlock(
      block: block,
      schema: def.blockSchema,
      arguments: arguments,
      def: def,
      clientActionId: clientActionId,
      localEntityId: localEntityId,
      syncStatus: syncStatus,
    );
  }

  Map<String, dynamic> _buildOptimisticBlockFromToolManifest({
    required _EmmaLocalToolDefinition def,
    required Map<String, dynamic> arguments,
    required String clientActionId,
    required String? localEntityId,
    required String syncStatus,
  }) {
    final schema = Map<String, dynamic>.from(def.blockSchema);

    final blockType = _blockTypeFromLocalToolDefinition(def);

    final block = <String, dynamic>{
      'type': blockType.isNotEmpty ? blockType : 'info',
      'block_id': _stableLocalBlockIdForTool(
        toolName: def.key,
        clientActionId: clientActionId,
        localEntityId: localEntityId,
        blockType: blockType,
      ),
      'title': (schema['title'] ?? def.title).toString(),
      'tool_name': def.key,
      'module_key': def.moduleKey,
      'client_action_id': clientActionId,
      'local_entity_id': localEntityId,
      'sync_status': syncStatus,
      'sync_origin': 'local_llm_frontend',
    };

    if (block['type'] == 'info') {
      block['variant'] = 'success';
      block['text'] = def.title;
    }

    return _mergeArgumentsIntoManifestBlock(
      block: block,
      schema: schema,
      arguments: arguments,
      def: def,
      clientActionId: clientActionId,
      localEntityId: localEntityId,
      syncStatus: syncStatus,
    );
  }

  Map<String, dynamic> _mergeArgumentsIntoManifestBlock({
    required Map<String, dynamic> block,
    required Map<String, dynamic> schema,
    required Map<String, dynamic> arguments,
    required _EmmaLocalToolDefinition def,
    required String clientActionId,
    required String? localEntityId,
    required String syncStatus,
  }) {
    final out = Map<String, dynamic>.from(block);

    schema.forEach((key, schemaValue) {
      if (key == 'type') return;

      if (out.containsKey(key) && out[key] != null) {
        if (out[key] is Map && schemaValue is Map) {
          out[key] = _mergeNestedManifestBlockPayload(
            existing: Map<String, dynamic>.from(out[key] as Map),
            schema: Map<String, dynamic>.from(schemaValue),
            arguments: arguments,
            def: def,
            clientActionId: clientActionId,
            localEntityId: localEntityId,
            syncStatus: syncStatus,
          );
        }

        return;
      }

      out[key] = _materializeManifestSchemaValue(
        key: key,
        schemaValue: schemaValue,
        arguments: arguments,
        def: def,
        clientActionId: clientActionId,
        localEntityId: localEntityId,
        syncStatus: syncStatus,
      );
    });

    // Wiele widgetów oczekuje płaskich pól top-level.
    // Dlatego arguments dokładamy na top-level, ale nie nadpisujemy block_schema.
    for (final entry in arguments.entries) {
      out.putIfAbsent(entry.key, () => entry.value);
    }

    out['tool_name'] ??= def.key;
    out['module_key'] ??= def.moduleKey;
    out['client_action_id'] ??= clientActionId;
    out['local_entity_id'] ??= localEntityId;
    out['sync_status'] ??= syncStatus;
    out['sync_origin'] ??= 'local_llm_frontend';

    return out;
  }

  Map<String, dynamic> _mergeNestedManifestBlockPayload({
    required Map<String, dynamic> existing,
    required Map<String, dynamic> schema,
    required Map<String, dynamic> arguments,
    required _EmmaLocalToolDefinition def,
    required String clientActionId,
    required String? localEntityId,
    required String syncStatus,
  }) {
    final out = Map<String, dynamic>.from(existing);

    schema.forEach((key, schemaValue) {
      if (out.containsKey(key) && out[key] != null) {
        if (out[key] is Map && schemaValue is Map) {
          out[key] = _mergeNestedManifestBlockPayload(
            existing: Map<String, dynamic>.from(out[key] as Map),
            schema: Map<String, dynamic>.from(schemaValue),
            arguments: arguments,
            def: def,
            clientActionId: clientActionId,
            localEntityId: localEntityId,
            syncStatus: syncStatus,
          );
        }

        return;
      }

      out[key] = _materializeManifestSchemaValue(
        key: key,
        schemaValue: schemaValue,
        arguments: arguments,
        def: def,
        clientActionId: clientActionId,
        localEntityId: localEntityId,
        syncStatus: syncStatus,
      );
    });

    return out;
  }

  dynamic _materializeManifestSchemaValue({
    required String key,
    required dynamic schemaValue,
    required Map<String, dynamic> arguments,
    required _EmmaLocalToolDefinition def,
    required String clientActionId,
    required String? localEntityId,
    required String syncStatus,
  }) {
    if (schemaValue is Map) {
      final nested = <String, dynamic>{};

      schemaValue.forEach((nestedKey, nestedSchemaValue) {
        nested[nestedKey.toString()] = _materializeManifestSchemaValue(
          key: nestedKey.toString(),
          schemaValue: nestedSchemaValue,
          arguments: arguments,
          def: def,
          clientActionId: clientActionId,
          localEntityId: localEntityId,
          syncStatus: syncStatus,
        );
      });

      return nested;
    }

    if (schemaValue is List) {
      return schemaValue.map((item) {
        return _materializeManifestSchemaValue(
          key: key,
          schemaValue: item,
          arguments: arguments,
          def: def,
          clientActionId: clientActionId,
          localEntityId: localEntityId,
          syncStatus: syncStatus,
        );
      }).toList(growable: false);
    }

    if (schemaValue is String) {
      final resolved = _resolveManifestSchemaTemplate(
        schemaValue,
        arguments: arguments,
        def: def,
        clientActionId: clientActionId,
        localEntityId: localEntityId,
        syncStatus: syncStatus,
      );

      if (!identical(resolved, _emmaManifestValueUnresolved)) {
        return resolved;
      }

      if (_looksLikeManifestTypeDescriptor(schemaValue)) {
        return _defaultValueForManifestBlockField(
          key: key,
          schemaValue: schemaValue,
          arguments: arguments,
          def: def,
          clientActionId: clientActionId,
          localEntityId: localEntityId,
          syncStatus: syncStatus,
        );
      }

      return schemaValue;
    }

    if (schemaValue == null || schemaValue is num || schemaValue is bool) {
      return schemaValue;
    }

    return _defaultValueForManifestBlockField(
      key: key,
      schemaValue: schemaValue,
      arguments: arguments,
      def: def,
      clientActionId: clientActionId,
      localEntityId: localEntityId,
      syncStatus: syncStatus,
    );
  }

  dynamic _resolveManifestSchemaTemplate(
    String raw, {
    required Map<String, dynamic> arguments,
    required _EmmaLocalToolDefinition def,
    required String clientActionId,
    required String? localEntityId,
    required String syncStatus,
  }) {
    final text = raw.trim();

    if (text.isEmpty) return _emmaManifestValueUnresolved;

    final exactBrace = RegExp(r'^\{\{\s*([a-zA-Z0-9_.]+)\s*\}\}$')
        .firstMatch(text);

    if (exactBrace != null) {
      return _lookupManifestTemplatePath(
        exactBrace.group(1) ?? '',
        arguments: arguments,
        def: def,
        clientActionId: clientActionId,
        localEntityId: localEntityId,
        syncStatus: syncStatus,
      );
    }

    final exactDollar = RegExp(r'^\$([a-zA-Z0-9_.]+)$').firstMatch(text);

    if (exactDollar != null) {
      return _lookupManifestTemplatePath(
        exactDollar.group(1) ?? '',
        arguments: arguments,
        def: def,
        clientActionId: clientActionId,
        localEntityId: localEntityId,
        syncStatus: syncStatus,
      );
    }

    final exactDollarBraced =
        RegExp(r'^\$\{([a-zA-Z0-9_.]+)\}$').firstMatch(text);

    if (exactDollarBraced != null) {
      return _lookupManifestTemplatePath(
        exactDollarBraced.group(1) ?? '',
        arguments: arguments,
        def: def,
        clientActionId: clientActionId,
        localEntityId: localEntityId,
        syncStatus: syncStatus,
      );
    }

    if (!text.contains('{{')) {
      return _emmaManifestValueUnresolved;
    }

    return text.replaceAllMapped(
      RegExp(r'\{\{\s*([a-zA-Z0-9_.]+)\s*\}\}'),
      (match) {
        final value = _lookupManifestTemplatePath(
          match.group(1) ?? '',
          arguments: arguments,
          def: def,
          clientActionId: clientActionId,
          localEntityId: localEntityId,
          syncStatus: syncStatus,
        );

        if (identical(value, _emmaManifestValueUnresolved) || value == null) {
          return '';
        }

        return value.toString();
      },
    );
  }

  dynamic _lookupManifestTemplatePath(
    String rawPath, {
    required Map<String, dynamic> arguments,
    required _EmmaLocalToolDefinition def,
    required String clientActionId,
    required String? localEntityId,
    required String syncStatus,
  }) {
    var path = rawPath.trim();

    if (path.isEmpty) return _emmaManifestValueUnresolved;

    if (path.startsWith('arguments.')) {
      path = path.substring('arguments.'.length);
    } else if (path.startsWith('args.')) {
      path = path.substring('args.'.length);
    }

    switch (path) {
      case 'client_action_id':
      case 'clientActionId':
        return clientActionId;

      case 'local_entity_id':
      case 'localEntityId':
      case 'client_local_id':
      case 'clientLocalId':
      case 'local_id':
      case 'localId':
        return localEntityId;

      case 'sync_status':
      case 'syncStatus':
        return syncStatus;

      case 'sync_origin':
      case 'syncOrigin':
        return 'local_llm_frontend';

      case 'tool_name':
      case 'toolName':
        return def.key;

      case 'module_key':
      case 'moduleKey':
        return def.moduleKey;
    }

    dynamic current = arguments;

    for (final part in path.split('.')) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return _emmaManifestValueUnresolved;
      }
    }

    return current;
  }

  bool _looksLikeManifestTypeDescriptor(String value) {
    final text = value.trim().toLowerCase();

    const descriptors = <String>{
      'string',
      'str',
      'text',
      'integer',
      'int',
      'number',
      'float',
      'double',
      'boolean',
      'bool',
      'array',
      'list',
      'object',
      'map',
      'dict',
      'null',
      'nullable',
      'any',
      'iso_8601',
      'iso8601',
      'datetime',
      'date',
      'time',
    };

    return descriptors.contains(text);
  }

  dynamic _defaultValueForManifestBlockField({
    required String key,
    required dynamic schemaValue,
    required Map<String, dynamic> arguments,
    required _EmmaLocalToolDefinition def,
    required String clientActionId,
    required String? localEntityId,
    required String syncStatus,
  }) {
    if (arguments.containsKey(key)) return arguments[key];

    switch (key) {
      case 'id':
      case 'event_id':
      case 'task_id':
      case 'note_id':
      case 'document_id':
      case 'memo_id':
        return localEntityId;

      case 'local_id':
      case 'local_event_id':
      case 'local_task_id':
      case 'local_note_id':
      case 'local_document_id':
      case 'client_local_id':
      case 'local_entity_id':
        return localEntityId;

      case 'backend_id':
      case 'backend_event_id':
      case 'backend_task_id':
      case 'backend_note_id':
      case 'backend_document_id':
        return null;

      case 'client_action_id':
        return clientActionId;

      case 'sync_status':
        return syncStatus;

      case 'sync_origin':
        return 'local_llm_frontend';

      case 'tool_name':
        return def.key;

      case 'module_key':
        return def.moduleKey;

      case 'title':
        return arguments['title'] ??
            arguments['name'] ??
            arguments['subject'] ??
            def.title;

      case 'name':
        return arguments['name'] ??
            arguments['title'] ??
            arguments['subject'] ??
            def.title;

      case 'subject':
        return arguments['subject'] ??
            arguments['title'] ??
            arguments['name'] ??
            '';

      case 'description':
      case 'location':
      case 'text':
      case 'content':
      case 'body':
        return arguments[key] ?? '';

      case 'deadline':
      case 'start_time':
      case 'end_time':
      case 'date':
      case 'time':
      case 'created_at':
      case 'updated_at':
        return arguments[key];

      case 'items':
      case 'actions':
      case 'tags':
      case 'to':
      case 'cc':
      case 'bcc':
      case 'messages':
      case 'emails':
      case 'tasks':
      case 'events':
        return arguments[key] is List ? arguments[key] : <dynamic>[];

      case 'summary':
        return {
          'count': 1,
          'source': 'local',
        };
    }

    final schemaText = schemaValue?.toString().toLowerCase() ?? '';

    if (schemaText.contains('integer') ||
        schemaText == 'int' ||
        schemaText.contains('number') ||
        schemaText.contains('float') ||
        schemaText.contains('double')) {
      return null;
    }

    if (schemaText.contains('boolean') || schemaText == 'bool') {
      return false;
    }

    if (schemaText.contains('array') || schemaText.contains('list')) {
      return <dynamic>[];
    }

    if (schemaText.contains('object') ||
        schemaText.contains('map') ||
        schemaText.contains('dict')) {
      return <String, dynamic>{};
    }

    if (schemaText.contains('null') || schemaText.contains('nullable')) {
      return null;
    }

    return arguments[key] ?? '';
  }

  String _stableLocalBlockIdForTool({
    required String toolName,
    required String clientActionId,
    required String? localEntityId,
    required String blockType,
  }) {
    final type = _safeToolIdPart(blockType.isNotEmpty ? blockType : 'block');
    final tool = _safeToolIdPart(toolName);
    final id = (localEntityId ?? clientActionId).trim();

    return '${type}_${tool}_${_safeToolIdPart(id)}';
  }

  Future<_EmmaNormalizedLocalToolRun?> _handleLocalToolResultFromContent({
    required Map<String, dynamic> job,
    required int sessionId,
    required int assistantMessageId,
    required String content,
  }) async {
    final parsed = _parseLocalToolResult(content);
    if (parsed == null) return null;

    final normalized = _normalizeParsedLocalToolResult(
      parsed: parsed,
      assistantMessageId: assistantMessageId,
    );

    if (normalized == null) return null;

    for (final block in normalized.blocks) {
      _handleAssistantBlockReady({
        'message_id': assistantMessageId,
        'assistant_message_id': assistantMessageId,
        'session_id': sessionId,
        'block_id': block['block_id'],
        'block': block,
      });
    }

    unawaited(
      _materializeLocalToolRun(
        job: job,
        sessionId: sessionId,
        assistantMessageId: assistantMessageId,
        run: normalized,
      ),
    );

    return normalized;
  }

  Future<void> _materializeLocalToolRun({
    required Map<String, dynamic> job,
    required int sessionId,
    required int assistantMessageId,
    required _EmmaNormalizedLocalToolRun run,
  }) async {
    final hasInternet = await _hasInternetRightNowFast();

    if (!hasInternet) {
      await _storePendingLocalToolRun(
        sessionId: sessionId,
        assistantMessageId: assistantMessageId,
        run: run,
      );

      return;
    }

    await _executeLocalToolRunOnBackend(
      job: job,
      sessionId: sessionId,
      assistantMessageId: assistantMessageId,
      run: run,
    );
  }

  Future<void> _storePendingLocalToolRun({
    required int sessionId,
    required int assistantMessageId,
    required _EmmaNormalizedLocalToolRun run,
  }) async {
    final now = DateTime.now();

    final pendingBlocks = _blocksWithSyncStatus(
      run.blocks,
      status: 'pending_create',
    );

    final action = EmmaPendingToolAction(
      id: run.clientActionId,
      toolName: run.toolName,
      moduleKey: _moduleFromLocalToolName(run.toolName),
      sessionLocalId: sessionId,
      assistantMessageLocalId: assistantMessageId,
      clientActionId: run.clientActionId,
      localEntityId: run.localEntityId,
      entityType: _entityTypeFromLocalToolName(run.toolName),
      arguments: run.arguments,
      optimisticBlocks: pendingBlocks,
      status: 'pending',
      attemptCount: 0,
      lastError: null,
      backendResult: null,
      createdAt: now,
      updatedAt: now,
      nextRetryAt: null,
    );

    try {
      await EmmaLocalDb.instance.upsertPendingToolAction(action);
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: failed to store pending tool action: $e\n$stack');
      }
    }

    for (final block in pendingBlocks) {
      _handleAssistantBlockReady({
        'message_id': assistantMessageId,
        'assistant_message_id': assistantMessageId,
        'session_id': sessionId,
        'block_id': block['block_id'],
        'block': block,
      });
    }

    _mergeAssistantMeta(
      messageId: assistantMessageId,
      meta: {
        'blocks': pendingBlocks,
        'local_llm_tools': {
          'enabled': true,
          'detected': true,
          'tool_name': run.toolName,
          'client_action_id': run.clientActionId,
          'local_entity_id': run.localEntityId,
          'sync_status': 'pending_create',
          'pending_sync': true,
          'blocks': pendingBlocks,
        },
      },
    );

    if (kDebugMode) {
      debugPrint(
        'Emma: local tool pending sync stored: ${run.toolName} ${run.arguments}',
      );
    }
  }

  Future<void> _executeLocalToolRunOnBackend({
    required Map<String, dynamic> job,
    required int sessionId,
    required int assistantMessageId,
    required _EmmaNormalizedLocalToolRun run,
  }) async {
    final meta = _extractMap(job['meta'] ?? job['metadata']);

    final endpoint = (job['tool_execute_url'] ??
            meta['tool_execute_url'] ??
            URLsEmma.emmaToolExecuteOnly)
        .toString();

    final now = DateTime.now();

    try {
      await EmmaLocalDb.instance.upsertPendingToolAction(
        EmmaPendingToolAction(
          id: run.clientActionId,
          toolName: run.toolName,
          moduleKey: _moduleFromLocalToolName(run.toolName),
          sessionLocalId: sessionId,
          assistantMessageLocalId: assistantMessageId,
          clientActionId: run.clientActionId,
          localEntityId: run.localEntityId,
          entityType: _entityTypeFromLocalToolName(run.toolName),
          arguments: run.arguments,
          optimisticBlocks: run.blocks,
          status: 'syncing',
          attemptCount: 0,
          lastError: null,
          backendResult: null,
          createdAt: now,
          updatedAt: now,
          nextRetryAt: null,
        ),
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: failed to store syncing tool action: $e\n$stack');
      }
    }

    try {
      final response = await ApiServices.post(
        endpoint,
        hasToken: true,
        ref: ref,
        data: {
          'session_id': sessionId > 0 ? sessionId : null,
          'assistant_message_id':
              assistantMessageId > 0 ? assistantMessageId : null,
          'tool_name': run.toolName,
          'arguments': run.arguments,
          'source': 'local_llm_frontend',
          'client_action_id': run.clientActionId,
          'local_entity_id': run.localEntityId,
        },
      );

      final dynamic responseData = response is Response ? response.data : response;

      final data = responseData is Map
          ? Map<String, dynamic>.from(responseData)
          : <String, dynamic>{
              'ok': false,
              'error': 'Invalid backend response.',
            };

      if (data['ok'] == false) {
        await _markLocalToolRunSyncFailed(
          sessionId: sessionId,
          assistantMessageId: assistantMessageId,
          run: run,
          error: data['error']?.toString() ?? 'Backend returned ok=false.',
        );

        return;
      }

      try {
        await EmmaLocalDb.instance.markPendingToolActionSynced(
          id: run.clientActionId,
          backendResult: data,
        );
      } catch (e, stack) {
        if (kDebugMode) {
          debugPrint('Emma: failed to mark tool action synced: $e\n$stack');
        }
      }

      final officialBlocks = _extractOfficialRenderBlocks(data);

      for (final block in officialBlocks) {
        block['block_id'] ??= _stableLocalBlockIdForTool(
          toolName: run.toolName,
          clientActionId: run.clientActionId,
          localEntityId: run.localEntityId,
          blockType: (block['type'] ?? '').toString(),
        );

        _handleAssistantBlockReady({
          'message_id': assistantMessageId,
          'assistant_message_id': assistantMessageId,
          'session_id': sessionId,
          'block_id': block['block_id'],
          'block': block,
        });
      }

      _mergeAssistantMeta(
        messageId: assistantMessageId,
        meta: {
          if (officialBlocks.isNotEmpty) 'blocks': officialBlocks,
          'local_llm_tools': {
            'enabled': true,
            'detected': true,
            'backend_synced': true,
            'pending_sync': false,
            'tool_name': run.toolName,
            'client_action_id': run.clientActionId,
            'local_entity_id': run.localEntityId,
            'sync_status': 'synced',
            if (officialBlocks.isNotEmpty) 'blocks': officialBlocks,
          },
        },
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: backend materialization failed: $e\n$stack');
      }

      try {
        await EmmaLocalDb.instance.markPendingToolActionFailed(
          id: run.clientActionId,
          error: e.toString(),
          attemptCount: 1,
          retryable: true,
        );
      } catch (_) {}

      final failedBlocks = _blocksWithSyncStatus(
        run.blocks,
        status: 'failed_retryable',
      );

      for (final block in failedBlocks) {
        _handleAssistantBlockReady({
          'message_id': assistantMessageId,
          'assistant_message_id': assistantMessageId,
          'session_id': sessionId,
          'block_id': block['block_id'],
          'block': block,
        });
      }

      _mergeAssistantMeta(
        messageId: assistantMessageId,
        meta: {
          'blocks': failedBlocks,
          'local_llm_tools': {
            'enabled': true,
            'detected': true,
            'backend_sync_failed': true,
            'pending_sync': true,
            'tool_name': run.toolName,
            'client_action_id': run.clientActionId,
            'local_entity_id': run.localEntityId,
            'sync_status': 'failed_retryable',
            'error': e.toString(),
            'blocks': failedBlocks,
          },
        },
      );
    }
  }

  Future<void> _markLocalToolRunSyncFailed({
    required int sessionId,
    required int assistantMessageId,
    required _EmmaNormalizedLocalToolRun run,
    required String error,
  }) async {
    try {
      await EmmaLocalDb.instance.markPendingToolActionFailed(
        id: run.clientActionId,
        error: error,
        attemptCount: 1,
        retryable: true,
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: failed to mark local tool run failed: $e\n$stack');
      }
    }

    final failedBlocks = _blocksWithSyncStatus(
      run.blocks,
      status: 'failed_retryable',
    );

    for (final block in failedBlocks) {
      _handleAssistantBlockReady({
        'message_id': assistantMessageId,
        'assistant_message_id': assistantMessageId,
        'session_id': sessionId,
        'block_id': block['block_id'],
        'block': block,
      });
    }

    _mergeAssistantMeta(
      messageId: assistantMessageId,
      meta: {
        'blocks': failedBlocks,
        'local_llm_tools': {
          'enabled': true,
          'detected': true,
          'backend_sync_failed': true,
          'pending_sync': true,
          'tool_name': run.toolName,
          'client_action_id': run.clientActionId,
          'local_entity_id': run.localEntityId,
          'sync_status': 'failed_retryable',
          'error': error,
          'blocks': failedBlocks,
        },
      },
    );
  }

  Future<void> _syncPendingLocalToolActions({
    int limit = 25,
  }) async {
    if (!_canUseLocalDb) return;

    final hasInternet = await _hasInternetRightNowFast();
    if (!hasInternet) return;

    List<EmmaPendingToolAction> actions;

    try {
      actions = await EmmaLocalDb.instance.getPendingToolActionsReady(
        limit: limit,
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: load pending tool actions failed: $e\n$stack');
      }

      return;
    }

    if (actions.isEmpty) return;

    for (final action in actions) {
      if (!_canEmit) return;
      await _syncSinglePendingToolAction(action);
    }

    try {
      await EmmaLocalDb.instance.deleteSyncedPendingToolActions();
    } catch (_) {}
  }

  Future<void> _syncSinglePendingToolAction(
    EmmaPendingToolAction action,
  ) async {
    try {
      await EmmaLocalDb.instance.markPendingToolActionSyncing(action.id);
    } catch (_) {}

    final endpoint = URLsEmma.emmaToolExecuteOnly;

    try {
      final response = await ApiServices.post(
        endpoint,
        hasToken: true,
        ref: ref,
        data: {
          'session_id': action.sessionLocalId > 0 ? action.sessionLocalId : null,
          'assistant_message_id': action.assistantMessageLocalId > 0
              ? action.assistantMessageLocalId
              : null,
          'tool_name': action.toolName,
          'arguments': action.arguments,
          'source': 'local_pending_sync',
          'client_action_id': action.clientActionId,
          'local_entity_id': action.localEntityId,
        },
      );

      final dynamic responseData = response is Response ? response.data : response;

      final data = responseData is Map
          ? Map<String, dynamic>.from(responseData)
          : <String, dynamic>{
              'ok': false,
              'error': 'Invalid backend response.',
            };

      if (data['ok'] == false) {
        final error = (data['error'] ?? 'Backend returned ok=false.').toString();

        await EmmaLocalDb.instance.markPendingToolActionFailed(
          id: action.id,
          error: error,
          attemptCount: action.attemptCount + 1,
          retryable: true,
        );

        _markPendingToolActionFailedInMessage(
          action: action,
          error: error,
        );

        return;
      }

      await EmmaLocalDb.instance.markPendingToolActionSynced(
        id: action.id,
        backendResult: data,
      );

      final officialBlocks = _extractOfficialRenderBlocks(data);

      for (final block in officialBlocks) {
        block['block_id'] ??= _stableLocalBlockIdForTool(
          toolName: action.toolName,
          clientActionId: action.clientActionId,
          localEntityId: action.localEntityId,
          blockType: (block['type'] ?? '').toString(),
        );

        _handleAssistantBlockReady({
          'message_id': action.assistantMessageLocalId,
          'assistant_message_id': action.assistantMessageLocalId,
          'session_id': action.sessionLocalId,
          'block_id': block['block_id'],
          'block': block,
        });
      }

      _mergeAssistantMeta(
        messageId: action.assistantMessageLocalId,
        meta: {
          if (officialBlocks.isNotEmpty) 'blocks': officialBlocks,
          'local_llm_tools': {
            'enabled': true,
            'detected': true,
            'backend_synced': true,
            'pending_sync': false,
            'tool_name': action.toolName,
            'client_action_id': action.clientActionId,
            'local_entity_id': action.localEntityId,
            'sync_status': 'synced',
            if (officialBlocks.isNotEmpty) 'blocks': officialBlocks,
          },
        },
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: pending tool action sync failed: $e\n$stack');
      }

      await EmmaLocalDb.instance.markPendingToolActionFailed(
        id: action.id,
        error: e.toString(),
        attemptCount: action.attemptCount + 1,
        retryable: true,
      );

      _markPendingToolActionFailedInMessage(
        action: action,
        error: e.toString(),
      );
    }
  }

  void _markPendingToolActionFailedInMessage({
    required EmmaPendingToolAction action,
    required String error,
  }) {
    final failedBlocks = _blocksWithSyncStatus(
      action.optimisticBlocks,
      status: 'failed_retryable',
    );

    for (final block in failedBlocks) {
      _handleAssistantBlockReady({
        'message_id': action.assistantMessageLocalId,
        'assistant_message_id': action.assistantMessageLocalId,
        'session_id': action.sessionLocalId,
        'block_id': block['block_id'],
        'block': block,
      });
    }

    _mergeAssistantMeta(
      messageId: action.assistantMessageLocalId,
      meta: {
        if (failedBlocks.isNotEmpty) 'blocks': failedBlocks,
        'local_llm_tools': {
          'enabled': true,
          'detected': true,
          'backend_sync_failed': true,
          'pending_sync': true,
          'tool_name': action.toolName,
          'client_action_id': action.clientActionId,
          'local_entity_id': action.localEntityId,
          'sync_status': 'failed_retryable',
          'error': error,
          if (failedBlocks.isNotEmpty) 'blocks': failedBlocks,
        },
      },
    );
  }

  List<Map<String, dynamic>> _extractOfficialRenderBlocks(
    Map<String, dynamic> data,
  ) {
    final out = <Map<String, dynamic>>[];

    void addBlocks(dynamic value) {
      if (value is! List) return;

      for (final raw in value.whereType<Map>()) {
        out.add(Map<String, dynamic>.from(raw));
      }
    }

    addBlocks(data['render_blocks']);
    addBlocks(data['blocks']);

    final resultRaw = data['result'];

    if (resultRaw is Map) {
      final result = Map<String, dynamic>.from(resultRaw);

      addBlocks(result['render_blocks']);
      addBlocks(result['blocks']);

      final llmResultRaw = result['llm_result'];

      if (llmResultRaw is Map) {
        final llmResult = Map<String, dynamic>.from(llmResultRaw);

        addBlocks(llmResult['render_blocks']);
        addBlocks(llmResult['blocks']);
      }
    }

    final llmResultRaw = data['llm_result'];

    if (llmResultRaw is Map) {
      final llmResult = Map<String, dynamic>.from(llmResultRaw);

      addBlocks(llmResult['render_blocks']);
      addBlocks(llmResult['blocks']);
    }

    return out;
  }

  String _moduleFromLocalToolName(String toolName) {
    final def = _localToolDefinition(toolName);

    if (def != null && def.moduleKey.trim().isNotEmpty) {
      return def.moduleKey.trim();
    }

    if (toolName.startsWith('calendar_')) return 'calendar';

    if (toolName.startsWith('tms_') || toolName.startsWith('task_')) {
      return 'tms';
    }

    if (toolName.startsWith('email_')) return 'email';
    if (toolName.startsWith('notes_')) return 'notes';
    if (toolName.startsWith('memos_')) return 'memos';
    if (toolName.startsWith('finance_')) return 'finance';
    if (toolName.startsWith('docs_')) return 'docs';
    if (toolName.startsWith('advertisements_')) return 'advertisements';
    if (toolName.startsWith('networking_')) return 'networking';
    if (toolName.startsWith('realestate_')) return 'realestate';
    if (toolName.startsWith('dynamic_')) return 'dynamic';
    if (toolName.startsWith('ui_')) return 'ui';

    return '';
  }

  String? _entityTypeFromLocalToolName(String toolName) {
    final def = _localToolDefinition(toolName);

    if (def != null) {
      return _entityTypeForLocalToolDefinition(def);
    }

    if (toolName.startsWith('calendar_')) return 'calendar_event';

    if (toolName.startsWith('tms_') || toolName.startsWith('task_')) {
      return 'task';
    }

    if (toolName.startsWith('email_')) return 'email_draft';
    if (toolName.startsWith('notes_')) return 'note';
    if (toolName.startsWith('memos_')) return 'memo';
    if (toolName.startsWith('finance_create_expense')) return 'expense';
    if (toolName.startsWith('finance_create_revenue')) return 'revenue';
    if (toolName.startsWith('docs_')) return 'document';
    if (toolName.startsWith('advertisements_')) return 'advertisement';
    if (toolName.startsWith('networking_')) return 'networking_item';
    if (toolName.startsWith('dynamic_')) return 'dynamic_entity';
    if (toolName.startsWith('ui_')) return 'ui_action';

    return null;
  }

  List<Map<String, dynamic>> _blocksWithSyncStatus(
    List<Map<String, dynamic>> blocks, {
    required String status,
  }) {
    return blocks
        .map((raw) => _mapWithSyncStatus(raw, status: status))
        .toList(growable: false);
  }

  Map<String, dynamic> _mapWithSyncStatus(
    Map<String, dynamic> raw, {
    required String status,
  }) {
    final out = Map<String, dynamic>.from(raw);

    out['sync_status'] = status;

    for (final entry in out.entries.toList()) {
      final value = entry.value;

      if (value is Map) {
        final nested = Map<String, dynamic>.from(value);

        if (_looksLikeSyncablePayload(nested)) {
          out[entry.key] = _mapWithSyncStatus(nested, status: status);
        }

        continue;
      }

      if (value is List) {
        out[entry.key] = value.map((item) {
          if (item is Map) {
            final nested = Map<String, dynamic>.from(item);

            if (_looksLikeSyncablePayload(nested)) {
              return _mapWithSyncStatus(nested, status: status);
            }

            return nested;
          }

          return item;
        }).toList(growable: false);
      }
    }

    return out;
  }

  bool _looksLikeSyncablePayload(Map<String, dynamic> value) {
    return value.containsKey('sync_status') ||
        value.containsKey('client_action_id') ||
        value.containsKey('local_entity_id') ||
        value.containsKey('local_event_id') ||
        value.containsKey('local_task_id') ||
        value.containsKey('local_note_id') ||
        value.containsKey('event_id') ||
        value.containsKey('task_id') ||
        value.containsKey('note_id');
  }
}