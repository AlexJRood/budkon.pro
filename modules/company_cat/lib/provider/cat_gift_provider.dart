import 'dart:convert';
import 'package:company_cat/company_cat_urls.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

Map<String, dynamic>? _decode(dynamic data) {
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is List<int>) {
    return Map<String, dynamic>.from(jsonDecode(utf8.decode(data)));
  }
  if (data is String) return Map<String, dynamic>.from(jsonDecode(data));
  return null;
}

/// Coś, co kot „przyniósł" — istotny element z produktu (task / notyfikacja).
@immutable
class CatGift {
  final String type; // 'task' | 'notification'
  final String title;
  final String subtitle;
  final int? id;

  const CatGift({
    required this.type,
    required this.title,
    this.subtitle = '',
    this.id,
  });

  String get icon => type == 'task' ? '📋' : '🔔';

  factory CatGift.fromJson(Map<String, dynamic> j) => CatGift(
        type: (j['type'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        subtitle: (j['subtitle'] ?? '').toString(),
        id: j['id'] is int ? j['id'] as int : int.tryParse('${j['id']}'),
      );
}

class CatGiftNotifier extends StateNotifier<CatGift?> {
  CatGiftNotifier() : super(null);

  Future<void> fetch() async {
    try {
      final resp = await ApiServices.get(
        CompanyCatUrls.companyCatGift,
        hasToken: true,
        ref: null,
      );
      if (resp == null || resp.statusCode != 200) return;
      final map = _decode(resp.data);
      if (map == null || map['type'] == null || '${map['type']}'.isEmpty) {
        if (mounted) state = null;
        return;
      }
      if (mounted) state = CatGift.fromJson(map);
    } catch (_) {
      // best-effort
    }
  }

  void clear() {
    if (mounted) state = null;
  }
}

/// Kot przynosi prezent gdy wskoczy na twój ekran (mount go pobiera).
final catGiftProvider =
    StateNotifierProvider<CatGiftNotifier, CatGift?>((ref) => CatGiftNotifier());
