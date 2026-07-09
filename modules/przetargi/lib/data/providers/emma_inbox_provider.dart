import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/przetargi_api.dart';

class EmmaWiadomosc {
  final int id;
  final int przetargId;
  final String przetargTytul;
  final double? przetargWartosc;
  final int? przetargAiScore;
  final String przetargLokalizacja;
  final String tekst;
  final int? kosztorysId;
  final bool przeczytana;

  const EmmaWiadomosc({
    required this.id,
    required this.przetargId,
    required this.przetargTytul,
    this.przetargWartosc,
    this.przetargAiScore,
    required this.przetargLokalizacja,
    required this.tekst,
    this.kosztorysId,
    required this.przeczytana,
  });

  factory EmmaWiadomosc.fromJson(Map<String, dynamic> j) => EmmaWiadomosc(
        id: j['id'] as int,
        przetargId: j['przetarg_id'] as int,
        przetargTytul: j['przetarg_tytul'] as String? ?? '',
        przetargWartosc: j['przetarg_wartosc'] != null
            ? double.tryParse(j['przetarg_wartosc'].toString())
            : null,
        przetargAiScore: j['przetarg_ai_score'] as int?,
        przetargLokalizacja: j['przetarg_lokalizacja'] as String? ?? '',
        tekst: j['tekst'] as String? ?? '',
        kosztorysId: j['kosztorys_id'] as int?,
        przeczytana: j['przeczytana'] as bool? ?? false,
      );

  String get wartoscLabel {
    if (przetargWartosc == null) return '';
    final v = przetargWartosc!;
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)} mln PLN';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)} tys. PLN';
    return '${v.toStringAsFixed(0)} PLN';
  }
}

class EmmaInboxNotifier
    extends StateNotifier<AsyncValue<List<EmmaWiadomosc>>> {
  EmmaInboxNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      final raw = await PrzetargiApi().emmaInbox();
      state = AsyncValue.data(raw.map(EmmaWiadomosc.fromJson).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> akceptuj(int id) async {
    await PrzetargiApi().emmaAkceptuj(id);
    state = AsyncValue.data(
      (state.valueOrNull ?? []).where((m) => m.id != id).toList(),
    );
  }

  Future<void> odrzuc(int id) async {
    await PrzetargiApi().emmaOdrzuc(id);
    state = AsyncValue.data(
      (state.valueOrNull ?? []).where((m) => m.id != id).toList(),
    );
  }
}

final emmaInboxProvider = StateNotifierProvider.autoDispose<EmmaInboxNotifier,
    AsyncValue<List<EmmaWiadomosc>>>(
  (_) => EmmaInboxNotifier(),
);

/// Liczba nieprzeczytanych powiadomień Emmy (do badge'u)
final emmaInboxCountProvider = Provider.autoDispose<int>((ref) {
  return ref
          .watch(emmaInboxProvider)
          .valueOrNull
          ?.where((m) => !m.przeczytana)
          .length ??
      0;
});
