import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';
import 'package:core/platform/status_dropdown.dart'; // StatusOption

String _safePreview(Object? raw, {int max = 280}) {
  // Zbuduj string, ale NIE tnij ponad długość
  String s;
  try {
    s = jsonEncode(raw);
  } catch (_) {
    s = raw?.toString() ?? '';
  }
  if (s.isEmpty) return s;
  final end = math.min(max, s.length);
  return s.substring(0, end);
}

final favStatusTypesProvider = FutureProvider<List<StatusOption>>((ref) async {
  final url = URLs.favoriteStatusTypes;
  final resp = await ApiServices.get(ref: ref, url, hasToken: true);

  final sc = resp?.statusCode;
  final dt = resp?.data;
  // Lekki log – bez substringów
  // ignore: avoid_print
  debugPrint('FAV_STATUS GET $url -> status=$sc, dataType=${dt.runtimeType}');

  if (resp == null) throw Exception('${'no_response_from_url'.tr} $url');
  if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode} z $url');

  dynamic raw = dt;

  // Dekodowanie bytes/string
  if (raw is List<int>) {
    try {
      raw = json.decode(utf8.decode(raw));
    } catch (_) {/* zostaw raw */}
  } else if (raw is String) {
    final str = raw.trim();
    if (str.startsWith('<!DOCTYPE') || str.startsWith('<html')) {
      throw Exception(
        'html_instead_of_json_error'.tr,
      );
    }
    try {
      raw = json.decode(str);
    } catch (_) {
      // zostaw str jako raw (np. backend zwrócił już „goły” tekst)
      raw = str;
    }
  }

  // Wyciąganie listy
  List<dynamic> list;
  if (raw is List) {
    list = raw;
  } else if (raw is Map) {
    if (raw['results'] is List) {
      list = List<dynamic>.from(raw['results']);
    } else if (raw['data'] is List) {
      list = List<dynamic>.from(raw['data']);
    } else {
      // mapa -> mapy; próbujemy złożyć listę
      final tmp = <Map<String, dynamic>>[];
      raw.forEach((k, v) {
        if (v is Map) {
          final id = (k is int) ? k : int.tryParse(k.toString());
          tmp.add({'id': id, ...Map<String, dynamic>.from(v)});
        }
      });
      list = tmp;
    }
  } else {
    throw Exception('${'unexpected_response_type'.tr} ${raw.runtimeType}');
  }

  // Mapowanie
  final out = <StatusOption>[];
  for (final e in list) {
    if (e is! Map) continue;
    final m = Map<String, dynamic>.from(e);
    final idRaw = m['id'];
    final int? id = (idRaw is int) ? idRaw : int.tryParse(idRaw?.toString() ?? '');
    if (id == null) continue;
    final label = (m['label'] ?? m['name'] ?? '$id').toString();
    final int? index = (m['index'] is int)
        ? m['index'] as int
        : int.tryParse(m['index']?.toString() ?? '');
    out.add(StatusOption(id: id, label: label, index: index));
  }

  // Sort wg. index; brak -> na koniec
  int _idx(StatusOption o) => o.index ?? 0x3fffffff;
  out.sort((a, b) => _idx(a).compareTo(_idx(b)));

  // Debug – BEZBŁĘDNY preview
  // ignore: avoid_print
  debugPrint('favStatusTypesProvider -> ${out.length} opcje');
  if (out.isEmpty) {
    // ignore: avoid_print
    debugPrint('EMPTY OPTIONS. RAW PREVIEW: ${_safePreview(raw)}');
  }

  return out;
});

Future<void> createFavStatusType(WidgetRef ref, String label) async {
  final resp = await ApiServices.post(
    URLs.favoriteStatusTypes, // POST /networking/favorites/status-types/
    hasToken: true,
    data: {'label': label},
  );
  if (resp == null || (resp.statusCode ?? 0) >= 300) {
    throw Exception('failed_to_add_status'.tr);
  }
  ref.invalidate(favStatusTypesProvider);
}

Future<void> deleteFavStatusType(WidgetRef ref, int id) async {
  final resp = await ApiServices.delete(
    URLs.favoriteStatusTypesDelete(id),
    hasToken: true,
  );
  if (resp == null || (resp.statusCode ?? 0) >= 300) {
    throw Exception('failed_to_delete_status'.tr);
  }
  ref.invalidate(favStatusTypesProvider);
}
