import 'dart:convert';
import 'package:calendar/models/event_model.dart';
import 'package:crm/crm_urls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';
import 'package:crm/contact_panel/viewer/viewer_models.dart';
import 'dart:math' as math;
import 'package:core/platform/status_dropdown.dart'; 


// ───────────────── helpers ─────────────────
String _safePreview(Object? raw, {int max = 280}) {
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

/// Uniwersalny parser: bytes/string/map/list → Dart json.
dynamic _parseBody(dynamic data) {
  if (data == null) return null;

  // Dio potrafi zwrócić bytes (List<int>)
  if (data is List) {
    // bytes?
    if (data.isNotEmpty && data.first is int) {
      final raw = utf8.decode(data.cast<int>());
      try {
        return json.decode(raw);
      } catch (_) {
        return raw; // tekst
      }
    }
    return data; // już jest List<dynamic>
  }

  if (data is String) {
    try {
      return json.decode(data);
    } catch (_) {
      return data;
    }
  }

  if (data is Map) return data;

  return data;
}

/// Zwraca czystą listę elementów niezależnie czy backend zwrócił [] czy {"results":[...]}
List<dynamic> _extractList(dynamic body) {
  if (body == null) return const [];
  if (body is List) return body;
  if (body is Map && body['results'] is List) return body['results'] as List;
  return const [];
}

// ── PROVIDERS ────────────────────────────────────────────────────

// ───────────────── Provider listy statusów oglądających ─────────────────
final viewerStatusTypesProvider = FutureProvider<List<StatusOption>>((ref) async {
  final url = URLs.transactionViewersStatusTypes;
  final resp = await ApiServices.get(ref: ref, url, hasToken: true);

  final sc = resp?.statusCode;
  final dt = resp?.data;
  // ignore: avoid_print
  debugPrint('VIEWER_STATUS GET $url -> status=$sc, dataType=${dt.runtimeType}');
  if (resp == null) throw Exception('${'no_response_from'.tr} $url');
  if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode} z $url');

  dynamic raw = dt;

  // dekoduj w razie czego
  if (raw is List<int>) {
    try { raw = json.decode(utf8.decode(raw)); } catch (_) {}
  } else if (raw is String) {
    final str = raw.trim();
    if (str.startsWith('<!DOCTYPE') || str.startsWith('<html')) {
      throw Exception('html_instead_of_json_error'.tr);
    }
    try { raw = json.decode(str); } catch (_) { raw = str; }
  }

  // wyciągnij listę
  List<dynamic> list;
  if (raw is List) {
    list = raw;
  } else if (raw is Map) {
    if (raw['results'] is List) {
      list = List<dynamic>.from(raw['results']);
    } else if (raw['data'] is List) {
      list = List<dynamic>.from(raw['data']);
    } else {
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

  // mapuj -> StatusOption
  final out = <StatusOption>[];
  for (final e in list) {
    if (e is! Map) continue;
    final m = Map<String, dynamic>.from(e);
    final idRaw = m['id'];
    final int? id = (idRaw is int) ? idRaw : int.tryParse(idRaw?.toString() ?? '');
    if (id == null) continue;
    final label = (m['label'] ?? m['name'] ?? '$id').toString();
    final int? index = (m['index'] is int) ? m['index'] as int : int.tryParse(m['index']?.toString() ?? '');
    out.add(StatusOption(id: id, label: label, index: index));
  }

  int _idx(StatusOption o) => o.index ?? 0x3fffffff;
  out.sort((a, b) => _idx(a).compareTo(_idx(b)));

  // ignore: avoid_print
  debugPrint('viewerStatusTypesProvider -> ${out.length} opcje');
  if (out.isEmpty) {
    // ignore: avoid_print
    debugPrint('EMPTY OPTIONS. RAW PREVIEW: ${_safePreview(raw)}');
  }
  return out;
});

final viewersForTransactionProvider = FutureProvider.family<List<ViewerItem>, int>((ref, txId) async {
  final resp = await ApiServices.get(
    CrmUrls.transactionViewersList(txId),
    hasToken: true,
    ref: ref,
  );

  final body = _parseBody(resp?.data);
  final list = _extractList(body);

  final result = <ViewerItem>[];
  for (final e in list) {
    if (e is Map) {
      // upewnij się, że mamy transactionId w JSON (serializer mógł go nie zwrócić)
      final m = Map<String, dynamic>.from(e);
      m['transaction'] ??= txId;
      result.add(ViewerItem.fromJson(m));
    } else {
      if (kDebugMode) debugPrint('viewersForTx: pominięty element $e (nie Map)');
    }
  }
  return result;
});

// ── AKCJE ────────────────────────────────────────────────────────

Future<void> addViewerToTx({required int txId, required int contactId}) async {
  await ApiServices.post(
    CrmUrls.transactionViewersList(txId),
    hasToken: true,
    data: {'contact_id': contactId},
  );
}

Future<void> removeViewerFromTx({required int txId, required int viewerId}) async {
  await ApiServices.delete(
    CrmUrls.transactionViewersDetail(txId, viewerId),
    hasToken: true,
  );
}

Future<void> setViewerStatusForTx({required int txId, required int viewerId, required int? statusId}) async {
  await ApiServices.patch(
    CrmUrls.transactionViewersSetStatus(txId, viewerId),
    hasToken: true,
    data: {'status_id': statusId},
  );
}

Future<void> setViewerNote({required int txId, required int viewerId, required String note}) async {
  await ApiServices.patch(
    CrmUrls.transactionViewersSetNote(txId, viewerId),
    hasToken: true,
    data: {'note': note},
  );
}

Future<void> setViewerLastContact({required int txId, required int viewerId, required String iso}) async {
  await ApiServices.patch(
    CrmUrls.transactionViewersSetLastContact(txId, viewerId),
    hasToken: true,
    data: {'last_contact_at': iso},
  );
}


Future<void> setHideViewerContact({required int txId, required int viewerId, required bool isHide}) async {
  await ApiServices.patch(
    CrmUrls.transactionViewersSetHideViewer(txId, viewerId),
    hasToken: true,
    data: {'is_hide': isHide},
  );
}


// GET /events/
Future<List<EventModel>> fetchViewerEvents({
  required int txId,
  required int viewerId,
  required WidgetRef ref,
}) async {
  final r = await ApiServices.get(
    CrmUrls.transactionViewerEvents(txId, viewerId),
    hasToken: true,
    ref: ref,
  );
  final body = _parseBody(r?.data);
  final list = _extractList(body);
  return list
      .whereType<Map>()
      .map((e) => EventModel.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

// POST /events/
Future<EventModel> createViewerEvent({
  required int txId,
  required int viewerId,
  required Map<String, dynamic> payload,
  WidgetRef? ref,
}) async {
  final r = await ApiServices.post(
    CrmUrls.transactionViewerEvents(txId, viewerId),
    hasToken: true,
    data: payload,
    ref: ref,
  );
  final body = _parseBody(r?.data);
  if (body is Map) {
    return EventModel.fromJson(Map<String, dynamic>.from(body));
  }
  throw Exception('${'bad_response_creating_event'.tr} ${r?.statusCode} $body');
}

Future<EventModel> linkExistingViewerEvent({
  required int txId,
  required int viewerId,
  required int eventId,
}) async {
  final r = await ApiServices.post(
    CrmUrls.transactionViewerEventsLink(txId, viewerId), // /events/link
    hasToken: true,
    data: {'event_id': eventId},
  );
  return EventModel.fromJson(Map<String, dynamic>.from(r?.data ?? {}));
}
