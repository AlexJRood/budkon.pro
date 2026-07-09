// emma/mentions/mention_provider.dart

import 'dart:convert';
import 'package:emma/model/mention_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core/platform/api_services.dart';
import 'package:emma/provider/urls.dart'; 

final mentionSearchProvider = FutureProvider.family
    <List<MentionItem>, ({String query, String trigger})>((ref, params) async {
  final q = params.query.trim();
  final trigger = params.trigger; // '@', '#' lub '/'

  // Slash-commands: katalog narzędzi Emmy → menu „/".
  if (trigger == '/') {
    try {
      final response = await ApiServices.get(
        '${URLsEmma.baseUrl}tools/catalog/?q=${Uri.encodeQueryComponent(q)}',
        hasToken: true,
        ref: ref,
      );
      if (response == null || response.statusCode != 200) return [];
      final decoded = jsonDecode(utf8.decode(response.data));
      final list = (decoded is Map<String, dynamic>)
          ? (decoded['tools'] as List<dynamic>? ?? [])
          : (decoded as List<dynamic>);
      var i = 0;
      return list.whereType<Map>().map((e) {
        final m = Map<String, dynamic>.from(e);
        final name = (m['name'] ?? '').toString();
        return MentionItem(
          kind: MentionKind.tool,
          id: i++,
          displayName: name,
          subtitle: (m['short'] ?? m['module'] ?? '').toString(),
          tag: name,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Tool catalog error: $e');
      return [];
    }
  }

  if (q.isEmpty && trigger == '@') {
    // np. ostatnie kontakty / userzy
  }

  String types;
  if (trigger == '#') {
    types = 'transaction';
  } else {
    types = 'contact,user';
  }


  try {
    final response = await ApiServices.get(
      URLsEmma.emmaMentionsSearch(q, types),
      hasToken: true,
      ref: ref,
    );

    if (response == null || response.statusCode != 200) {
      if (kDebugMode) {
        debugPrint('Mention search failed: ${response?.statusCode}');
      }
      return [];
    }

    final decoded = jsonDecode(utf8.decode(response.data));
    // you can support both {results: []} and plain []
    final list = decoded is Map<String, dynamic>
        ? (decoded['results'] as List<dynamic>)
        : (decoded as List<dynamic>);

    return list
        .whereType<Map>()
        .map((e) => MentionItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  } catch (e) {
    if (kDebugMode) debugPrint('Mention search error: $e');
    return [];
  }
});
