import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ValueSnapshot {
  final double value;
  final String currency;
  final DateTime recordedAt;

  const ValueSnapshot({
    required this.value,
    required this.currency,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
        'value': value,
        'currency': currency,
        'recordedAt': recordedAt.toIso8601String(),
      };

  factory ValueSnapshot.fromJson(Map<String, dynamic> j) => ValueSnapshot(
        value: (j['value'] as num).toDouble(),
        currency: j['currency'] as String? ?? 'PLN',
        recordedAt: DateTime.parse(j['recordedAt'] as String),
      );
}

class ReportValueHistoryNotifier
    extends AsyncNotifier<Map<int, List<ValueSnapshot>>> {
  static const _prefix = 'report_value_history_';
  static const _maxEntries = 20;

  @override
  Future<Map<int, List<ValueSnapshot>>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    final map = <int, List<ValueSnapshot>>{};
    for (final k in keys) {
      final id = int.tryParse(k.substring(_prefix.length));
      if (id == null) continue;
      final raw = prefs.getString(k);
      if (raw == null) continue;
      try {
        final list = (jsonDecode(raw) as List)
            .cast<Map<String, dynamic>>()
            .map(ValueSnapshot.fromJson)
            .toList();
        map[id] = list;
      } catch (_) {}
    }
    return map;
  }

  Future<void> recordSnapshot(
      int reportId, double value, String currency) async {
    final current = state.valueOrNull ?? {};
    final history = List<ValueSnapshot>.from(current[reportId] ?? []);

    // Only record if value differs from last entry or it's the first today
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';
    final alreadyTodayWithSameValue = history.any((s) {
      final d = s.recordedAt;
      final k = '${d.year}-${d.month}-${d.day}';
      return k == todayKey && (s.value - value).abs() < 1;
    });
    if (alreadyTodayWithSameValue) return;

    history.add(
        ValueSnapshot(value: value, currency: currency, recordedAt: now));
    if (history.length > _maxEntries) {
      history.removeRange(0, history.length - _maxEntries);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        '$_prefix$reportId', jsonEncode(history.map((s) => s.toJson()).toList()));

    state = AsyncData({...current, reportId: history});
  }
}

final reportValueHistoryProvider =
    AsyncNotifierProvider<ReportValueHistoryNotifier, Map<int, List<ValueSnapshot>>>(
  ReportValueHistoryNotifier.new,
);
