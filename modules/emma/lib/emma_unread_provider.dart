import 'dart:convert';
import 'package:emma/emma_urls.dart';

import 'package:core/platform/api_services.dart';
import 'package:core/platform/live/live.dart';

Future<int> _fetchEmmaUnread() async {
  final resp =
      await ApiServices.get(EmmaUrls.emmaUnreadCount, hasToken: true, ref: null);
  if (resp == null || resp.statusCode != 200) return 0;

  final data = resp.data;
  Map<String, dynamic> map;
  if (data is Map) {
    map = Map<String, dynamic>.from(data);
  } else if (data is List<int>) {
    map = Map<String, dynamic>.from(jsonDecode(utf8.decode(data)));
  } else if (data is String) {
    map = Map<String, dynamic>.from(jsonDecode(data));
  } else {
    return 0;
  }

  final raw = map['unread_count'];
  if (raw is int) return raw;
  return int.tryParse('$raw') ?? 0;
}

/// Live licznik nieprzeczytanych wiadomości Emmy (asystenta) — owner-scoped.
///
/// Sygnał `emma:unread` (bez payloadu) leci do grupy `user:ID` po każdej nowej
/// wiadomości asystenta → LiveCountNotifier dociąga total z endpointu.
final emmaUnreadProvider = liveCountProvider('emma:unread', _fetchEmmaUnread);
