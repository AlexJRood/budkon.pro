import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MapLayerStateStats {
  final bool exists;
  final int approxBytes;

  const MapLayerStateStats({
    required this.exists,
    required this.approxBytes,
  });
}

class MapLayerStateStorage {
  static const String _prefix = 'map_layer_state__';

  static String _key(String namespace) => '$_prefix$namespace';

  static Future<void> write({
    required String namespace,
    required Map<String, dynamic> data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(namespace), jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> read({
    required String namespace,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(namespace));
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear({
    required String namespace,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(namespace));
  }

  static Future<MapLayerStateStats> stats({
    required String namespace,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(namespace));

    return MapLayerStateStats(
      exists: raw != null && raw.isNotEmpty,
      approxBytes: raw == null ? 0 : utf8.encode(raw).length,
    );
  }
}