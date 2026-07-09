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

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

@immutable
class LeaderboardEntry {
  final int userId;
  final String name;
  final int count;
  const LeaderboardEntry({
    required this.userId,
    required this.name,
    required this.count,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        userId: _asInt(j['user_id']),
        name: (j['name'] ?? '').toString(),
        count: _asInt(j['count']),
      );
}

@immutable
class Achievement {
  final String key;
  final String label;
  final bool unlocked;
  const Achievement({
    required this.key,
    required this.label,
    required this.unlocked,
  });

  factory Achievement.fromJson(Map<String, dynamic> j) => Achievement(
        key: (j['key'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
        unlocked: j['unlocked'] == true,
      );
}

@immutable
class CatProfile {
  final String name;
  final int happiness;
  final int energy;
  final int totalPets;
  final int distinctPetters;
  final LeaderboardEntry? bestFriend;
  final List<LeaderboardEntry> leaderboard;
  final List<Achievement> achievements;

  const CatProfile({
    required this.name,
    required this.happiness,
    required this.energy,
    required this.totalPets,
    required this.distinctPetters,
    this.bestFriend,
    this.leaderboard = const [],
    this.achievements = const [],
  });

  factory CatProfile.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(dynamic raw, T Function(Map<String, dynamic>) f) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => f(Map<String, dynamic>.from(e)))
          .toList();
    }

    final bf = j['best_friend'];
    return CatProfile(
      name: (j['name'] ?? 'Kotek').toString(),
      happiness: _asInt(j['happiness']),
      energy: _asInt(j['energy']),
      totalPets: _asInt(j['total_pets']),
      distinctPetters: _asInt(j['distinct_petters']),
      bestFriend: bf is Map
          ? LeaderboardEntry.fromJson(Map<String, dynamic>.from(bf))
          : null,
      leaderboard: list(j['leaderboard'], LeaderboardEntry.fromJson),
      achievements: list(j['achievements'], Achievement.fromJson),
    );
  }
}

/// Profil kota — pobierany gdy otwierasz panel (autoDispose = świeży za każdym).
final catProfileProvider = FutureProvider.autoDispose<CatProfile?>((ref) async {
  final resp = await ApiServices.get(
    CompanyCatUrls.companyCatProfile,
    hasToken: true,
    ref: null,
  );
  if (resp == null || resp.statusCode != 200) return null;
  final map = _decode(resp.data);
  if (map == null || map.isEmpty) return null;
  return CatProfile.fromJson(map);
});
