import 'dart:async';
import 'package:company_cat/company_cat_urls.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/live/live.dart';

int? _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

Map<String, dynamic>? _decode(dynamic data) {
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is List<int>) {
    return Map<String, dynamic>.from(jsonDecode(utf8.decode(data)));
  }
  if (data is String) return Map<String, dynamic>.from(jsonDecode(data));
  return null;
}

@immutable
class CatState {
  final String name;
  final int happiness;
  final int energy;
  final int totalPets;
  final int? hostId;

  /// Czy kot siedzi teraz na MOIM ekranie (host == ja).
  final bool onMyScreen;

  /// Chwilowa reakcja (emoji) na event produktu — np. 🔔 gdy przyszła
  /// notyfikacja. Znika po ~2.6s. Transient, nie z serwera.
  final String? reaction;

  /// Kot świętuje wygraną (ukończony task) — impreza przez ~3.2s.
  final bool celebrating;

  /// Ktoś przesłał ci głaska przez kota (imię) — bąbelek przez ~3.6s.
  final String? patFrom;

  /// Założona ozdoba (emoji, '' = brak).
  final String accessory;

  /// Cisza nocna — kot śpi.
  final bool quiet;

  /// Czy jestem ulubieńcem kota (top opiekun) — z /state/.
  final bool youAreFavorite;

  const CatState({
    this.name = 'Kotek',
    this.happiness = 60,
    this.energy = 80,
    this.totalPets = 0,
    this.hostId,
    this.onMyScreen = false,
    this.reaction,
    this.celebrating = false,
    this.patFrom,
    this.accessory = '',
    this.quiet = false,
    this.youAreFavorite = false,
  });

  /// Emoji wg nastroju (system pozytywny — najwyżej śpiący, nigdy smutny).
  String get moodEmoji {
    if (energy < 30) return '😴';
    if (happiness >= 85) return '😻';
    if (happiness >= 65) return '😸';
    return '🐱';
  }

  CatState copyWith({
    String? name,
    int? happiness,
    int? energy,
    int? totalPets,
    int? hostId,
    bool? onMyScreen,
    String? reaction,
    bool clearReaction = false,
    bool? celebrating,
    String? patFrom,
    bool clearPat = false,
    String? accessory,
    bool? quiet,
    bool? youAreFavorite,
  }) {
    return CatState(
      name: name ?? this.name,
      happiness: happiness ?? this.happiness,
      energy: energy ?? this.energy,
      totalPets: totalPets ?? this.totalPets,
      hostId: hostId ?? this.hostId,
      onMyScreen: onMyScreen ?? this.onMyScreen,
      reaction: clearReaction ? null : (reaction ?? this.reaction),
      celebrating: celebrating ?? this.celebrating,
      patFrom: clearPat ? null : (patFrom ?? this.patFrom),
      accessory: accessory ?? this.accessory,
      quiet: quiet ?? this.quiet,
      youAreFavorite: youAreFavorite ?? this.youAreFavorite,
    );
  }

  factory CatState.fromJson(Map<String, dynamic> j, {bool? onMyScreen}) {
    return CatState(
      name: j['name']?.toString() ?? 'Kotek',
      happiness: _asInt(j['happiness']) ?? 60,
      energy: _asInt(j['energy']) ?? 80,
      totalPets: _asInt(j['total_pets']) ?? 0,
      hostId: _asInt(j['host_id']),
      onMyScreen: onMyScreen ?? (j['is_on_my_screen'] == true),
      accessory: j['accessory']?.toString() ?? '',
      quiet: j['quiet'] == true,
      youAreFavorite: j['you_are_favorite'] == true,
    );
  }
}

class CompanyCatNotifier extends StateNotifier<CatState> {
  CompanyCatNotifier(this._ref) : super(const CatState()) {
    final client = _ref.read(liveClientProvider);
    _offs = [
      client.registry.on('cat:hop', (s) => _applyStats(s, onMyScreen: true)),
      client.registry.on('cat:left', (s) => _applyStats(s, onMyScreen: false)),
      client.registry.on('cat:update', _applyStats), // staty, obecność bez zmian
      // reakcje na eventy produktu — kot zerka gdy coś się dzieje (tylko u mnie)
      client.registry.on('notification:unread', (_) => _react('🔔')),
      client.registry.on('tms:tasks', (_) => _react('📋')),
      client.registry.on('chat:unread', (_) => _react('💬')),
      client.registry.on('cat:celebrate', (_) => _celebrate()),
      client.registry.on('cat:pat', (_) {
        if (state.onMyScreen) fetchPats();
      }),
    ];
    _connSub = _ref.listen<AsyncValue<LiveConnectionState>>(
      liveConnectionProvider,
      (_, next) {
        if (next.valueOrNull == LiveConnectionState.connected) refresh();
      },
      fireImmediately: true,
    );
  }

  final Ref _ref;
  List<LiveUnsubscribe> _offs = const [];
  ProviderSubscription<AsyncValue<LiveConnectionState>>? _connSub;
  Timer? _reactionTimer;
  Timer? _celebrateTimer;
  Timer? _patTimer;

  /// Krótka reakcja (emoji) nad kotem na event produktu. Tylko gdy kot u mnie.
  void _react(String emoji) {
    if (!state.onMyScreen) return;
    state = state.copyWith(reaction: emoji);
    _reactionTimer?.cancel();
    _reactionTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) state = state.copyWith(clearReaction: true);
    });
  }

  /// Impreza — kot świętuje wygraną (ukończony task). Tylko gdy u mnie.
  void _celebrate() {
    if (!state.onMyScreen) return;
    state = state.copyWith(celebrating: true);
    _celebrateTimer?.cancel();
    _celebrateTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) state = state.copyWith(celebrating: false);
    });
  }

  /// Pobierz oczekujące głaski od kolegów i pokaż (kot dostarcza).
  Future<void> fetchPats() async {
    try {
      final resp =
          await ApiServices.get(CompanyCatUrls.companyCatPats, hasToken: true, ref: null);
      if (resp == null || resp.statusCode != 200) return;
      final map = _decode(resp.data);
      final list = map?['pats'];
      if (list is! List || list.isEmpty || !mounted) return;
      final last = list.last;
      _showPat(last is Map ? last['from_name']?.toString() : null);
    } catch (_) {}
  }

  void _showPat(String? name) {
    if (name == null || name.isEmpty) return;
    state = state.copyWith(patFrom: name);
    _patTimer?.cancel();
    _patTimer = Timer(const Duration(milliseconds: 3600), () {
      if (mounted) state = state.copyWith(clearPat: true);
    });
  }

  /// Wyślij głaska koledze.
  Future<void> sendPat(int toUserId) async {
    try {
      await ApiServices.post(
        CompanyCatUrls.companyCatSendPat,
        hasToken: true,
        data: {'to_user_id': toUserId},
      );
    } catch (_) {}
  }

  /// Załóż ozdobę (optimistic; backend rozgłasza cat:update do wszystkich).
  Future<void> equip(String accessory) async {
    state = state.copyWith(accessory: accessory);
    try {
      await ApiServices.post(
        CompanyCatUrls.companyCatEquip,
        hasToken: true,
        data: {'accessory': accessory},
      );
    } catch (_) {}
  }

  void _applyStats(LiveSignal sig, {bool? onMyScreen}) {
    final p = sig.payload;
    if (p == null) {
      if (onMyScreen != null) state = state.copyWith(onMyScreen: onMyScreen);
      return;
    }
    state = state.copyWith(
      name: p['name']?.toString() ?? state.name,
      happiness: _asInt(p['happiness']) ?? state.happiness,
      energy: _asInt(p['energy']) ?? state.energy,
      totalPets: _asInt(p['total_pets']) ?? state.totalPets,
      hostId: _asInt(p['host_id']) ?? state.hostId,
      onMyScreen: onMyScreen ?? state.onMyScreen,
      accessory: p['accessory']?.toString() ?? state.accessory,
      quiet: p.containsKey('quiet') ? p['quiet'] == true : state.quiet,
    );
  }

  Future<void> refresh() async {
    try {
      final resp = await ApiServices.get(
        CompanyCatUrls.companyCatState,
        hasToken: true,
        ref: null,
      );
      if (resp == null || resp.statusCode != 200) return;
      final map = _decode(resp.data);
      if (map == null || !mounted) return;
      state = CatState.fromJson(map, onMyScreen: map['is_on_my_screen'] == true);
    } catch (_) {
      // best-effort
    }
  }

  Future<void> pet() async {
    // optimistic — natychmiastowa reakcja na tap
    state = state.copyWith(
      happiness: (state.happiness + 3).clamp(0, 100),
      totalPets: state.totalPets + 1,
    );
    await _post(CompanyCatUrls.companyCatPet);
  }

  Future<void> feed() => _post(CompanyCatUrls.companyCatFeed);
  Future<void> treat() => _post(CompanyCatUrls.companyCatTreat);
  Future<void> nudge() => _post(CompanyCatUrls.companyCatNudge);
  Future<void> rename(String name) => _post(CompanyCatUrls.companyCatRename, {'name': name});

  Future<void> _post(String url, [Map<String, dynamic>? data]) async {
    try {
      final resp = await ApiServices.post(url, hasToken: true, data: data);
      if (resp == null || resp.statusCode != 200) return;
      final map = _decode(resp.data);
      if (map == null || !mounted) return;
      state = CatState.fromJson(map, onMyScreen: map['is_on_my_screen'] == true);
    } catch (_) {
      // best-effort
    }
  }

  @override
  void dispose() {
    _reactionTimer?.cancel();
    _celebrateTimer?.cancel();
    _patTimer?.cancel();
    for (final off in _offs) {
      off();
    }
    _connSub?.close();
    super.dispose();
  }
}

final companyCatProvider =
    StateNotifierProvider<CompanyCatNotifier, CatState>(
  (ref) => CompanyCatNotifier(ref),
);

/// Ekrany „high-stakes" (edytor, formularz, call) ustawiają true, by schować
/// kota — „towarzysz, nie rozpraszacz".
final catSuppressedProvider = StateProvider<bool>((ref) => false);

/// True gdy silnik ruchu aktywnie animuje pozycję kota (walk/enter/leave).
/// Odczytywany przez [CatVisual] do przełączenia stanu Walk w Rive.
final catIsMovingProvider = StateProvider<bool>((ref) => false);
