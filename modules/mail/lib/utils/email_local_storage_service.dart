import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/mail_models.dart';

class LocalMailboxScopeSnapshot {
  final String scopeKey;
  final List<int> ids;
  final int totalInScope;
  final bool hasOlder;
  final String? lastCheckAt;
  final String? oldestCachedAt;
  final int maxLocal;

  const LocalMailboxScopeSnapshot({
    required this.scopeKey,
    required this.ids,
    required this.totalInScope,
    required this.hasOlder,
    required this.lastCheckAt,
    required this.oldestCachedAt,
    required this.maxLocal,
  });

  Map<String, dynamic> toJson() => {
        "scope_key": scopeKey,
        "ids": ids,
        "total_in_scope": totalInScope,
        "has_older": hasOlder,
        "last_check_at": lastCheckAt,
        "oldest_cached_at": oldestCachedAt,
        "max_local": maxLocal,
      };

  factory LocalMailboxScopeSnapshot.fromJson(Map<String, dynamic> json) {
    final rawIds = json["ids"];
    final ids = rawIds is List
        ? rawIds
            .map((e) => int.tryParse(e.toString()))
            .whereType<int>()
            .toList()
        : <int>[];

    return LocalMailboxScopeSnapshot(
      scopeKey: (json["scope_key"] ?? "").toString(),
      ids: ids,
      totalInScope: int.tryParse("${json["total_in_scope"]}") ?? 0,
      hasOlder: json["has_older"] == true,
      lastCheckAt: json["last_check_at"]?.toString(),
      oldestCachedAt: json["oldest_cached_at"]?.toString(),
      maxLocal: int.tryParse("${json["max_local"]}") ?? 3000,
    );
  }

  LocalMailboxScopeSnapshot copyWith({
    String? scopeKey,
    List<int>? ids,
    int? totalInScope,
    bool? hasOlder,
    String? lastCheckAt,
    String? oldestCachedAt,
    int? maxLocal,
  }) {
    return LocalMailboxScopeSnapshot(
      scopeKey: scopeKey ?? this.scopeKey,
      ids: ids ?? this.ids,
      totalInScope: totalInScope ?? this.totalInScope,
      hasOlder: hasOlder ?? this.hasOlder,
      lastCheckAt: lastCheckAt ?? this.lastCheckAt,
      oldestCachedAt: oldestCachedAt ?? this.oldestCachedAt,
      maxLocal: maxLocal ?? this.maxLocal,
    );
  }
}

class EmailLocalStorageService {
  static const _emailStorePrefix = "mail_email_store_v1__";
  static const _scopePrefix = "mail_scope_v1__";
  static const _scopeIndexPrefix = "mail_scope_index_v1__";
  static const _bodyPrefix = "mail_body_v1__";
  static const _bodyIndexPrefix = "mail_body_index_v1__";

  String _emailStoreKey(String namespace) => "$_emailStorePrefix$namespace";
  String _scopeKey(String namespace, String scopeKey) =>
      "$_scopePrefix$namespace::$scopeKey";
  String _scopeIndexKey(String namespace) => "$_scopeIndexPrefix$namespace";
  String _bodyKey(String namespace, int emailId) => "$_bodyPrefix$namespace::$emailId";
  String _bodyIndexKey(String namespace) => "$_bodyIndexPrefix$namespace";

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  Future<Map<String, dynamic>> _readEmailStore(String namespace) async {
    final prefs = await _prefs();
    final raw = prefs.getString(_emailStoreKey(namespace));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return {};
  }


  Future<void> updateEmailReadState(
    String namespace,
    int emailId,
    bool isRead,
  ) async {
    final store = await _readEmailStore(namespace);
    final raw = store[emailId.toString()];

    if (raw is Map) {
      final updated = Map<String, dynamic>.from(raw);
      updated['is_read'] = isRead;
      store[emailId.toString()] = updated;
      await _writeEmailStore(namespace, store);
    }
  }


  Future<void> _writeEmailStore(String namespace, Map<String, dynamic> data) async {
    final prefs = await _prefs();
    await prefs.setString(_emailStoreKey(namespace), jsonEncode(data));
  }

  Future<Set<String>> _readScopeIndex(String namespace) async {
    final prefs = await _prefs();
    final raw = prefs.getStringList(_scopeIndexKey(namespace)) ?? const [];
    return raw.toSet();
  }

  Future<void> _writeScopeIndex(String namespace, Set<String> values) async {
    final prefs = await _prefs();
    await prefs.setStringList(_scopeIndexKey(namespace), values.toList());
  }

  Future<List<int>> _readBodyIndex(String namespace) async {
    final prefs = await _prefs();
    final raw = prefs.getStringList(_bodyIndexKey(namespace)) ?? const [];
    return raw
        .map((e) => int.tryParse(e))
        .whereType<int>()
        .toList();
  }

  Future<void> _writeBodyIndex(String namespace, List<int> values) async {
    final prefs = await _prefs();
    await prefs.setStringList(
      _bodyIndexKey(namespace),
      values.map((e) => e.toString()).toList(),
    );
  }

  Future<LocalMailboxScopeSnapshot?> getScope(
    String namespace,
    String scopeKey,
  ) async {
    final prefs = await _prefs();
    final raw = prefs.getString(_scopeKey(namespace, scopeKey));
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return LocalMailboxScopeSnapshot.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveScope(
    String namespace,
    LocalMailboxScopeSnapshot snapshot,
  ) async {
    final prefs = await _prefs();
    await prefs.setString(
      _scopeKey(namespace, snapshot.scopeKey),
      jsonEncode(snapshot.toJson()),
    );

    final index = await _readScopeIndex(namespace);
    index.add(snapshot.scopeKey);
    await _writeScopeIndex(namespace, index);
  }

  Future<void> upsertEmailSummaries(
    String namespace,
    List<EmailMessage> emails,
  ) async {
    if (emails.isEmpty) return;

    final store = await _readEmailStore(namespace);

    for (final email in emails) {
      store[email.id.toString()] = email.toJson(includeBody: false);
    }

    await _writeEmailStore(namespace, store);
  }

  Future<List<EmailMessage>> getEmailsByIds(
    String namespace,
    List<int> ids,
  ) async {
    if (ids.isEmpty) return const [];

    final store = await _readEmailStore(namespace);
    final prefs = await _prefs();

    final result = <EmailMessage>[];

    for (final id in ids) {
      final raw = store[id.toString()];
      if (raw is Map) {
        final summary = EmailMessage.fromJson(Map<String, dynamic>.from(raw));
        final body = prefs.getString(_bodyKey(namespace, id));
        result.add(body == null ? summary : summary.copyWith(body: body));
      }
    }

    return result;
  }

  Future<EmailMessage?> getEmailById(
    String namespace,
    int emailId,
  ) async {
    final items = await getEmailsByIds(namespace, [emailId]);
    if (items.isEmpty) return null;
    return items.first;
  }

  Future<void> storeEmailDetail(
    String namespace,
    EmailMessage email, {
    int maxStoredBodies = 40,
  }) async {
    final prefs = await _prefs();

    await upsertEmailSummaries(namespace, [email]);
    await prefs.setString(_bodyKey(namespace, email.id), email.body);

    final current = await _readBodyIndex(namespace);
    final withoutCurrent = current.where((e) => e != email.id).toList();
    final next = <int>[email.id, ...withoutCurrent];

    final trimmed = next.take(maxStoredBodies).toList();
    await _writeBodyIndex(namespace, trimmed);

    final removed = next.skip(maxStoredBodies);
    for (final oldId in removed) {
      await prefs.remove(_bodyKey(namespace, oldId));
    }
  }

  Future<void> compactNamespace(String namespace) async {
    final index = await _readScopeIndex(namespace);
    if (index.isEmpty) return;

    final keepIds = <int>{};

    for (final scopeKey in index) {
      final scope = await getScope(namespace, scopeKey);
      if (scope != null) {
        keepIds.addAll(scope.ids);
      }
    }

    final store = await _readEmailStore(namespace);
    final next = <String, dynamic>{};

    for (final entry in store.entries) {
      final id = int.tryParse(entry.key);
      if (id != null && keepIds.contains(id)) {
        next[entry.key] = entry.value;
      }
    }

    await _writeEmailStore(namespace, next);
  }

  Future<void> clearNamespace(String namespace) async {
    final prefs = await _prefs();
    final keys = prefs.getKeys();

    final toRemove = keys.where((key) {
      return key.startsWith(_emailStoreKey(namespace)) ||
          key.startsWith("$_scopePrefix$namespace::") ||
          key.startsWith("$_bodyPrefix$namespace::") ||
          key == _scopeIndexKey(namespace) ||
          key == _bodyIndexKey(namespace);
    }).toList();

    for (final key in toRemove) {
      await prefs.remove(key);
    }
  }
}