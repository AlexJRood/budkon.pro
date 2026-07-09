part of '../emma_notifier.dart';

const String _emmaToolManifestCacheKey = 'emma_tool_manifest_response_v2';

final Map<String, _EmmaLocalToolDefinition> _emmaLocalToolManifestByKey = {};
DateTime? _emmaLocalToolManifestLoadedAt;
Future<void>? _emmaLocalToolManifestLoadFuture;

class _EmmaLocalToolDefinition {
  final String key;
  final String moduleKey;
  final String requiredAppModule;
  final String title;
  final String description;
  final String permissionCode;
  final String consentSettingKey;
  final String executionMode;
  final String localExecutorKey;
  final String backendActionKey;
  final bool requiresOnline;
  final bool offlineQueueable;
  final bool requiresConfirmation;
  final bool destructive;
  final bool syncable;
  final String frontendMode;
  final Map<String, dynamic> toolSchema;
  final Map<String, dynamic> parametersSchema;
  final Map<String, dynamic> outputSchema;
  final Map<String, dynamic> blockSchema;
  final List<String> keywords;
  final List<String> aliases;
  final List<dynamic> examples;
  final Map<String, dynamic> uiHints;
  final Map<String, dynamic> rawSource;
  final bool enabled;
  final String manifestVersion;
  final String hash;

  const _EmmaLocalToolDefinition({
    required this.key,
    required this.moduleKey,
    required this.requiredAppModule,
    required this.title,
    required this.description,
    required this.permissionCode,
    required this.consentSettingKey,
    required this.executionMode,
    required this.localExecutorKey,
    required this.backendActionKey,
    required this.requiresOnline,
    required this.offlineQueueable,
    required this.requiresConfirmation,
    required this.destructive,
    required this.syncable,
    required this.frontendMode,
    required this.toolSchema,
    required this.parametersSchema,
    required this.outputSchema,
    required this.blockSchema,
    required this.keywords,
    required this.aliases,
    required this.examples,
    required this.uiHints,
    required this.rawSource,
    required this.enabled,
    required this.manifestVersion,
    required this.hash,
  });

  factory _EmmaLocalToolDefinition.fromJson(Map<String, dynamic> json) {
    return _EmmaLocalToolDefinition(
      key: (json['key'] ?? '').toString(),
      moduleKey: (json['module_key'] ?? '').toString(),
      requiredAppModule: (json['required_app_module'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      permissionCode: (json['permission_code'] ?? '').toString(),
      consentSettingKey: (json['consent_setting_key'] ?? '').toString(),
      executionMode: (json['execution_mode'] ?? 'backendOnly').toString(),
      localExecutorKey: (json['local_executor_key'] ?? '').toString(),
      backendActionKey: (json['backend_action_key'] ?? json['key'] ?? '').toString(),
      requiresOnline: json['requires_online'] == true,
      offlineQueueable: json['offline_queueable'] == true,
      requiresConfirmation: json['requires_confirmation'] == true,
      destructive: json['destructive'] == true,
      syncable: json['syncable'] == true,
      frontendMode: (json['frontend_mode'] ?? 'chat').toString(),
      toolSchema: _safeToolManifestMap(json['tool_schema']),
      parametersSchema: _safeToolManifestMap(json['parameters_schema']),
      outputSchema: _safeToolManifestMap(json['output_schema']),
      blockSchema: _safeToolManifestMap(json['block_schema']),
      keywords: _safeToolManifestStringList(json['keywords']),
      aliases: _safeToolManifestStringList(json['aliases']),
      examples: json['examples'] is List ? List<dynamic>.from(json['examples']) : const [],
      uiHints: _safeToolManifestMap(json['ui_hints']),
      rawSource: _safeToolManifestMap(json['raw_source']),
      enabled: json['enabled'] != false,
      manifestVersion: (json['manifest_version'] ?? '').toString(),
      hash: (json['hash'] ?? json['source_hash'] ?? '').toString(),
    );
  }

  Map<String, dynamic> get localMeta {
    final meta = rawSource['local_meta'];
    return _safeToolManifestMap(meta);
  }

  String get blockType {
    final fromSchema = (blockSchema['type'] ?? '').toString().trim();
    if (fromSchema.isNotEmpty) return fromSchema;

    final fromMeta = (localMeta['block_type'] ?? '').toString().trim();
    if (fromMeta.isNotEmpty) return fromMeta;

    return entityType;
  }

  String get entityType {
    final fromMeta = (localMeta['local_entity_type'] ?? '').toString().trim();
    if (fromMeta.isNotEmpty) return fromMeta;

    final type = blockType.trim();
    if (type.isNotEmpty &&
        !type.endsWith('_list') &&
        !type.endsWith('_delete_result') &&
        type != 'info' &&
        type != 'loading') {
      return type;
    }

    if (key.startsWith('calendar_')) return 'calendar_event';
    if (key.startsWith('tms_')) return 'tms_task';
    if (key.startsWith('email_')) return 'email_draft';
    if (key.startsWith('notes_')) return 'note';
    if (key.startsWith('memos_')) return 'memo';
    if (key.startsWith('docs_')) return 'document';
    if (key.startsWith('finance_')) return 'finance_item';
    if (key.startsWith('ui_')) return 'ui_action';
    if (key.startsWith('automation_')) return 'automation_workflow';

    return moduleKey.isNotEmpty ? moduleKey : 'item';
  }

  bool get isAdvertisementsLike {
    return moduleKey == 'advertisements' ||
        moduleKey == 'networking' ||
        key.startsWith('advertisements_') ||
        key.startsWith('networking_');
  }

  bool canBeShownToLocalLlm({
    required bool offline,
  }) {
    if (!enabled) return false;
    if (toolSchema.isEmpty) return false;

    // Ogłoszenia zostawiamy backend-only, bo lokalnie nie ma sensownego datasetu.
    if (isAdvertisementsLike) return false;

    if (!offline) return true;

    if (executionMode == 'uiOnly') return true;
    if (executionMode == 'localOnly') return true;
    if (executionMode == 'localFirst') return true;
    if (offlineQueueable) return true;

    if (requiresOnline) return false;

    return executionMode == 'backendFirst';
  }

  Map<String, dynamic> toLocalLlmToolSchema() {
    final schema = Map<String, dynamic>.from(toolSchema);

    final fnRaw = schema['function'];
    final fn = fnRaw is Map ? Map<String, dynamic>.from(fnRaw) : <String, dynamic>{};

    if (fn.isEmpty) {
      schema['type'] = 'function';
      schema['function'] = {
        'name': key,
        'description': description,
        'parameters': parametersSchema,
      };
    } else {
      fn['name'] ??= key;
      fn['description'] ??= description;
      fn['parameters'] ??= parametersSchema;
      schema['function'] = fn;
    }

    schema['key'] = key;
    schema['module_key'] = moduleKey;
    schema['title'] = title;
    schema['frontend_mode'] = frontendMode;
    schema['execution_mode'] = executionMode;
    schema['requires_online'] = requiresOnline;
    schema['offline_queueable'] = offlineQueueable;
    schema['requires_confirmation'] = requiresConfirmation;
    schema['destructive'] = destructive;
    schema['syncable'] = syncable;
    schema['local_executor_key'] = localExecutorKey;
    schema['backend_action_key'] = backendActionKey;
    schema['block_schema'] = blockSchema;
    schema['output_schema'] = outputSchema;
    schema['keywords'] = keywords;
    schema['aliases'] = aliases;
    schema['examples'] = examples;
    schema['ui_hints'] = uiHints;
    schema['local_entity_type'] = entityType;
    schema['block_type'] = blockType;

    return schema;
  }
}

Map<String, dynamic> _safeToolManifestMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<String> _safeToolManifestStringList(dynamic value) {
  if (value is! List) return const [];

  final out = <String>[];

  for (final raw in value) {
    final text = raw.toString().trim();
    if (text.isNotEmpty && !out.contains(text)) {
      out.add(text);
    }
  }

  return out;
}

String _normalizeToolSearchText(String value) {
  return value
      .toLowerCase()
      .replaceAll('ą', 'a')
      .replaceAll('ć', 'c')
      .replaceAll('ę', 'e')
      .replaceAll('ł', 'l')
      .replaceAll('ń', 'n')
      .replaceAll('ó', 'o')
      .replaceAll('ś', 's')
      .replaceAll('ż', 'z')
      .replaceAll('ź', 'z')
      .trim();
}

extension EmmaNotifierToolManifestRuntime on ChatAiMessagesNotifier {
  _EmmaLocalToolDefinition? _localToolDefinition(String toolName) {
    return _emmaLocalToolManifestByKey[toolName.trim()];
  }

  Future<void> _ensureLocalToolManifestLoaded({
    bool forceRefresh = false,
  }) async {
    final running = _emmaLocalToolManifestLoadFuture;
    if (running != null) {
      await running;
      return;
    }

    final future = _ensureLocalToolManifestLoadedInternal(
      forceRefresh: forceRefresh,
    );

    _emmaLocalToolManifestLoadFuture = future;

    try {
      await future;
    } finally {
      _emmaLocalToolManifestLoadFuture = null;
    }
  }

  Future<void> _ensureLocalToolManifestLoadedInternal({
    required bool forceRefresh,
  }) async {
    if (_emmaLocalToolManifestByKey.isEmpty) {
      await _loadLocalToolManifestFromCache();
    }

    final lastLoaded = _emmaLocalToolManifestLoadedAt;
    final freshEnough = lastLoaded != null &&
        DateTime.now().difference(lastLoaded) < const Duration(minutes: 5);

    if (!forceRefresh && _emmaLocalToolManifestByKey.isNotEmpty && freshEnough) {
      return;
    }

    final hasInternet = await _hasInternetRightNowFast();
    if (!hasInternet) return;

    try {
      final response = await ApiServices.get(
        URLsEmma.emmaToolManifest,
        hasToken: true,
        ref: ref,
      );

      final dynamic responseData = response is Response ? response.data : response;

      final data = responseData is Map
          ? Map<String, dynamic>.from(responseData)
          : <String, dynamic>{};

      if (data['ok'] != true) return;

      _applyLocalToolManifestPayload(data);
      _emmaLocalToolManifestLoadedAt = DateTime.now();

      if (_canUseLocalDb) {
        await EmmaLocalDb.instance.setMeta(
          _emmaToolManifestCacheKey,
          jsonEncode(data),
        );
      }

      if (kDebugMode) {
        debugPrint(
          'Emma: tool manifest loaded: ${_emmaLocalToolManifestByKey.length} tools',
        );
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: tool manifest fetch failed: $e\n$stack');
      }
    }
  }

  Future<void> _loadLocalToolManifestFromCache() async {
    if (!_canUseLocalDb) return;

    try {
      final raw = await EmmaLocalDb.instance.getMeta(_emmaToolManifestCacheKey);
      if (raw == null || raw.trim().isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;

      _applyLocalToolManifestPayload(Map<String, dynamic>.from(decoded));
      _emmaLocalToolManifestLoadedAt = DateTime.now();

      if (kDebugMode) {
        debugPrint(
          'Emma: tool manifest loaded from cache: ${_emmaLocalToolManifestByKey.length} tools',
        );
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: tool manifest cache load failed: $e\n$stack');
      }
    }
  }

  void _applyLocalToolManifestPayload(Map<String, dynamic> data) {
    final toolsRaw = data['tools'];

    if (toolsRaw is! List) return;

    final next = <String, _EmmaLocalToolDefinition>{};

    for (final raw in toolsRaw) {
      if (raw is! Map) continue;

      final def = _EmmaLocalToolDefinition.fromJson(
        Map<String, dynamic>.from(raw),
      );

      if (def.key.trim().isEmpty) continue;
      if (!def.enabled) continue;

      next[def.key] = def;
    }

    _emmaLocalToolManifestByKey
      ..clear()
      ..addAll(next);
  }

  List<Map<String, dynamic>> _getLocalToolSchemasForEngineFromManifest({
    required Map<String, dynamic> job,
    required List<Map<String, dynamic>> messages,
    int limit = 14,
  }) {
    if (_emmaLocalToolManifestByKey.isEmpty) return const [];

    final offline = _isOfflineLocalJob(job);

    final meta = _extractMap(job['meta'] ?? job['metadata']);
    final selectedModules = _extractStringSet(meta['selected_modules']);
    final candidateModules = _extractStringSet(meta['candidate_modules']);

    final text = _normalizeToolSearchText(
      messages
          .map((m) => m['content']?.toString() ?? '')
          .where((v) => v.trim().isNotEmpty)
          .join('\n'),
    );

    if (text.trim().length < 2) return const [];

    final scored = <({int score, _EmmaLocalToolDefinition tool})>[];

    for (final def in _emmaLocalToolManifestByKey.values) {
      if (!def.canBeShownToLocalLlm(offline: offline)) continue;

      final score = _scoreLocalToolForPrompt(
        def,
        text,
        selectedModules: selectedModules,
        candidateModules: candidateModules,
      );

      if (score <= 0) continue;

      scored.add((score: score, tool: def));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));

    return scored
        .take(limit)
        .map((item) => item.tool.toLocalLlmToolSchema())
        .where((schema) => schema.isNotEmpty)
        .toList(growable: false);
  }

  int _scoreLocalToolForPrompt(
    _EmmaLocalToolDefinition def,
    String normalizedText, {
    required Set<String> selectedModules,
    required Set<String> candidateModules,
  }) {
    var score = 0;

    final key = _normalizeToolSearchText(def.key);
    final module = _normalizeToolSearchText(def.moduleKey);
    final title = _normalizeToolSearchText(def.title);
    final description = _normalizeToolSearchText(def.description);

    if (normalizedText.contains(key)) score += 100;
    if (module.isNotEmpty && normalizedText.contains(module)) score += 12;
    if (title.isNotEmpty && normalizedText.contains(title)) score += 8;

    if (selectedModules.contains(def.moduleKey)) score += 45;
    if (candidateModules.contains(def.moduleKey)) score += 20;

    for (final keyword in def.keywords) {
      final k = _normalizeToolSearchText(keyword);
      if (k.length < 3) continue;

      if (normalizedText.contains(k)) {
        score += 30;
      }
    }

    for (final alias in def.aliases) {
      final a = _normalizeToolSearchText(alias);
      if (a.length < 3) continue;

      if (normalizedText.contains(a)) {
        score += 18;
      }
    }

    if (description.isNotEmpty) {
      final importantWords = description
          .split(RegExp(r'\s+'))
          .where((w) => w.length >= 6)
          .take(8);

      for (final word in importantWords) {
        if (normalizedText.contains(word)) score += 2;
      }
    }

    if (def.moduleKey == 'calendar') {
      if (_containsAny(normalizedText, const [
        'kalendarz',
        'wydarzenie',
        'event',
        'spotkanie',
        'meeting',
        'termin',
        'jutro',
        'dzisiaj',
        'dzis',
        'pojutrze',
        'godzina',
        'godzine',
      ])) {
        score += 25;
      }
    }

    if (def.moduleKey == 'notes') {
      if (_containsAny(normalizedText, const [
        'notatka',
        'notatke',
        'zanotuj',
        'zapisz to',
        'zapamietaj',
        'remember',
        'note',
      ])) {
        score += 25;
      }
    }

    if (def.moduleKey == 'email') {
      if (_containsAny(normalizedText, const [
        'mail',
        'email',
        'e-mail',
        'wiadomosc',
        'wiadomosci',
        'inbox',
        'skrzynka',
        'wyslij',
        'odpisz',
      ])) {
        score += 25;
      }
    }

    if (def.moduleKey == 'tms') {
      if (_containsAny(normalizedText, const [
        'task',
        'zadanie',
        'todo',
        'to-do',
        'projekt',
        'kolumna',
        'zrobic',
        'wyrzucic',
        'poprawic',
        'dodaj task',
        'dodaj zadanie',
      ])) {
        score += 35;
      }
    }

    if (def.moduleKey == 'finance') {
      if (_containsAny(normalizedText, const [
        'wydatek',
        'koszt',
        'przychod',
        'revenue',
        'expense',
        'faktura',
        'finanse',
      ])) {
        score += 25;
      }
    }

    if (def.moduleKey == 'ui') {
      if (_containsAny(normalizedText, const [
        'otworz',
        'kliknij',
        'podswietl',
        'pokaz gdzie',
        'gdzie kliknac',
        'open',
        'highlight',
        'click',
      ])) {
        score += 25;
      }
    }

    if (def.moduleKey == 'automation') {
      if (_containsAny(normalizedText, const [
        'automatyzacja',
        'automatyzacj',
        'automatyzuj',
        'zautomatyzuj',
        'workflow',
        'automatyzacje',
        'gdy',
        'kiedy',
        'jezeli',
        'jesli',
        'triggerem',
        'trigger',
        'wyzwalacz',
        'wtedy wyslij',
        'wtedy dodaj',
        'wtedy utworz',
        'po kazdym',
        'po kazdej',
        'cyklicznie',
        'codziennie',
        'co tydzien',
        'webhook',
      ])) {
        score += 50;
      }
    }

    if (def.destructive) {
      if (!_containsAny(normalizedText, const [
        'usun',
        'skasuj',
        'delete',
        'remove',
        'wywal',
      ])) {
        score -= 60;
      }
    }

    return score;
  }

  bool _containsAny(String text, List<String> values) {
    for (final value in values) {
      if (text.contains(_normalizeToolSearchText(value))) return true;
    }

    return false;
  }

  Set<String> _extractStringSet(dynamic value) {
    if (value is! List) return const <String>{};

    return value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toSet();
  }
}