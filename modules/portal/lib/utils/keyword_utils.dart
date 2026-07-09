import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';

void logFinalApiPayload({
  required String endpoint,
  required Map<String, dynamic> queryParameters,
}) {
  if (!kDebugMode) return;

  log('📌 [API] endpoint: $endpoint');
  log('📌 [API] queryParameters:\n${const JsonEncoder.withIndent('  ').convert(queryParameters)}');
}


class KeywordUtils {
  static List<String> normalizeToList(String? input) {
    if (input == null) return const [];

    final parts = input
        .split(RegExp(r'[,;\n|]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final seen = <String>{};
    final out = <String>[];
    for (final p in parts) {
      final k = p.toLowerCase();
      if (seen.add(k)) out.add(p);
    }
    return out;
  }
}

