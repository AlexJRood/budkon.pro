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

// ── preferencje usera (DND, mute) ──────────────────────────────────────────

@immutable
class CatPrefs {
  final bool dnd;
  final bool muteReactions;
  final double? posX;
  final double? posY;
  const CatPrefs({
    this.dnd = false,
    this.muteReactions = false,
    this.posX,
    this.posY,
  });

  CatPrefs copyWith({
    bool? dnd,
    bool? muteReactions,
    double? posX,
    double? posY,
  }) =>
      CatPrefs(
        dnd: dnd ?? this.dnd,
        muteReactions: muteReactions ?? this.muteReactions,
        posX: posX ?? this.posX,
        posY: posY ?? this.posY,
      );

  factory CatPrefs.fromJson(Map<String, dynamic> j) {
    double? asD(dynamic v) =>
        v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);
    return CatPrefs(
      dnd: j['dnd'] == true,
      muteReactions: j['mute_reactions'] == true,
      posX: asD(j['pos_x']),
      posY: asD(j['pos_y']),
    );
  }
}

class CatPrefsNotifier extends StateNotifier<CatPrefs> {
  CatPrefsNotifier() : super(const CatPrefs()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final resp =
          await ApiServices.get(CompanyCatUrls.companyCatPrefs, hasToken: true, ref: null);
      if (resp == null || resp.statusCode != 200) return;
      final map = _decode(resp.data);
      if (map != null && mounted) state = CatPrefs.fromJson(map);
    } catch (_) {}
  }

  Future<void> setDnd(bool v) async {
    state = state.copyWith(dnd: v);
    await _patch({'dnd': v});
  }

  Future<void> setMuteReactions(bool v) async {
    state = state.copyWith(muteReactions: v);
    await _patch({'mute_reactions': v});
  }

  /// Podczas przeciągania — tylko lokalnie (bez requestu).
  void setLocalPosition(double x, double y) {
    state = state.copyWith(posX: x, posY: y);
  }

  /// Po puszczeniu — zapisz pozycję.
  Future<void> savePosition() async {
    await _patch({'pos_x': state.posX, 'pos_y': state.posY});
  }

  Future<void> _patch(Map<String, dynamic> data) async {
    try {
      await ApiServices.patch(CompanyCatUrls.companyCatPrefs, hasToken: true, data: data);
    } catch (_) {}
  }
}

final catPrefsProvider =
    StateNotifierProvider<CatPrefsNotifier, CatPrefs>((ref) => CatPrefsNotifier());

// ── ustawienia firmowe (enabled, roam_minutes) ─────────────────────────────

@immutable
class CatSettings {
  final bool enabled;
  final int roamMinutes;
  final bool quietEnabled;
  const CatSettings({
    this.enabled = true,
    this.roamMinutes = 5,
    this.quietEnabled = true,
  });

  CatSettings copyWith({bool? enabled, int? roamMinutes, bool? quietEnabled}) =>
      CatSettings(
        enabled: enabled ?? this.enabled,
        roamMinutes: roamMinutes ?? this.roamMinutes,
        quietEnabled: quietEnabled ?? this.quietEnabled,
      );

  factory CatSettings.fromJson(Map<String, dynamic> j) => CatSettings(
        enabled: j['enabled'] != false,
        roamMinutes: j['roam_minutes'] is num
            ? (j['roam_minutes'] as num).toInt()
            : 5,
        quietEnabled: j['quiet_enabled'] != false,
      );
}

class CatSettingsNotifier extends StateNotifier<CatSettings> {
  CatSettingsNotifier() : super(const CatSettings()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await ApiServices.get(
        CompanyCatUrls.companyCatSettings,
        hasToken: true,
        ref: null,
      );
      if (resp == null || resp.statusCode != 200) return;
      final map = _decode(resp.data);
      if (map != null && mounted) state = CatSettings.fromJson(map);
    } catch (_) {}
  }

  Future<void> setEnabled(bool v) async {
    state = state.copyWith(enabled: v);
    await _patch({'enabled': v});
  }

  Future<void> setRoamMinutes(int v) async {
    state = state.copyWith(roamMinutes: v);
    await _patch({'roam_minutes': v});
  }

  Future<void> setQuietEnabled(bool v) async {
    state = state.copyWith(quietEnabled: v);
    await _patch({'quiet_enabled': v});
  }

  Future<void> _patch(Map<String, dynamic> data) async {
    try {
      await ApiServices.patch(CompanyCatUrls.companyCatSettings, hasToken: true, data: data);
    } catch (_) {}
  }
}

final catSettingsProvider =
    StateNotifierProvider<CatSettingsNotifier, CatSettings>(
  (ref) => CatSettingsNotifier(),
);
