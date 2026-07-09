// import 'dart:convert';

// import 'package:shared_preferences/shared_preferences.dart';

// import 'offline_city_pack_model.dart';

// class OfflineCityPackRegistry {
//   static const _key = 'offline_city_pack_registry_v1';

//   static Future<List<OfflineCityPack>> readAll() async {
//     final prefs = await SharedPreferences.getInstance();
//     final raw = prefs.getString(_key);
//     if (raw == null || raw.isEmpty) return const [];

//     try {
//       final decoded = jsonDecode(raw);
//       if (decoded is! List) return const [];

//       return decoded
//           .whereType<Map>()
//           .map((e) => OfflineCityPack.fromJson(Map<String, dynamic>.from(e)))
//           .toList();
//     } catch (_) {
//       return const [];
//     }
//   }

//   static Future<void> writeAll(List<OfflineCityPack> packs) async {
//     final prefs = await SharedPreferences.getInstance();
//     final raw = jsonEncode(packs.map((e) => e.toJson()).toList());
//     await prefs.setString(_key, raw);
//   }
// }