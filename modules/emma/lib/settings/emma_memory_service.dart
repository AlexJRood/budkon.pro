import 'dart:convert';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';

/// Pojedynczy trwały fakt o userze.
class MemoryFact {
  final int id;
  final String key;
  final String value;
  final String category;
  final double confidence;

  const MemoryFact({
    required this.id,
    required this.key,
    required this.value,
    required this.category,
    required this.confidence,
  });

  factory MemoryFact.fromJson(Map<String, dynamic> j) => MemoryFact(
        id: (j['id'] as num?)?.toInt() ?? 0,
        key: j['key'] as String? ?? '',
        value: j['value'] as String? ?? '',
        category: j['category'] as String? ?? 'inne',
        confidence: (j['confidence'] as num?)?.toDouble() ?? 1.0,
      );
}

/// Ulotny bieżący kontekst (z wygaśnięciem).
class MemoryContextItem {
  final int id;
  final String key;
  final String value;
  final String? expiresAt;

  const MemoryContextItem({
    required this.id,
    required this.key,
    required this.value,
    this.expiresAt,
  });

  factory MemoryContextItem.fromJson(Map<String, dynamic> j) => MemoryContextItem(
        id: (j['id'] as num?)?.toInt() ?? 0,
        key: j['key'] as String? ?? '',
        value: j['value'] as String? ?? '',
        expiresAt: j['expires_at'] as String?,
      );
}

/// Komplet pamięci Emmy o userze.
class EmmaMemory {
  final List<MemoryFact> facts;
  final List<MemoryContextItem> context;
  final Map<String, String> preferences;
  final int total;

  const EmmaMemory({
    required this.facts,
    required this.context,
    required this.preferences,
    required this.total,
  });

  bool get isEmpty => facts.isEmpty && context.isEmpty && preferences.isEmpty;

  factory EmmaMemory.fromJson(Map<String, dynamic> j) => EmmaMemory(
        facts: (j['facts'] as List<dynamic>? ?? [])
            .map((e) => MemoryFact.fromJson(e as Map<String, dynamic>))
            .toList(),
        context: (j['context'] as List<dynamic>? ?? [])
            .map((e) => MemoryContextItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        preferences: (j['preferences'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, '$v')),
        total: (j['total'] as num?)?.toInt() ?? 0,
      );
}

class EmmaMemoryService {
  static const _base = '${URLs.baseUrl}/emma/memory';

  static Future<EmmaMemory?> fetch(dynamic ref) async {
    final res = await ApiServices.get('$_base/', hasToken: true, ref: ref);
    if (res == null || res.statusCode != 200) return null;
    return EmmaMemory.fromJson(json.decode(utf8.decode(res.data)));
  }

  /// Usuń jeden element pamięci. kind: fact | context | preference.
  static Future<bool> forget({
    required dynamic ref,
    required String kind,
    String? key,
    int? id,
  }) async {
    final res = await ApiServices.post(
      '$_base/forget/',
      data: {
        'kind': kind,
        if (id != null) 'id': id,
        if (key != null) 'key': key,
      },
      hasToken: true,
      ref: ref,
    );
    return res != null && res.statusCode == 200;
  }
}
