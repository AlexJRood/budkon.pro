import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/odbiory_model.dart';
import '../services/odbiory_api.dart';

// ---- Lista protokołów dla budowy ----

final protokolyProvider = FutureProvider.family<List<ProtokołOdbioruModel>, int>(
  (ref, budowaId) => ref.watch(odbioryApiProvider).fetchProtokoly(budowaId: budowaId),
);

// ---- Szczegóły protokołu ----

class ProtokolNotifier extends AutoDisposeAsyncNotifier<ProtokołOdbioruModel?> {
  late int protokolId;

  @override
  Future<ProtokołOdbioruModel?> build() async => null;

  Future<void> load(int id) async {
    protokolId = id;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(odbioryApiProvider).fetchProtokolOne(id),
    );
  }

  Future<void> updatePunkt(int punktId, WynikPunktu wynik, {String? uwaga}) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final api = ref.read(odbioryApiProvider);
    final updated = await api.updatePunkt(punktId, {
      'wynik': wynik.apiValue,
      if (uwaga != null) 'uwaga': uwaga,
    });

    state = AsyncData(ProtokołOdbioruModel(
      id: current.id,
      budowaId: current.budowaId,
      etapId: current.etapId,
      tytul: current.tytul,
      typ: current.typ,
      status: current.status,
      data: current.data,
      kierownikImie: current.kierownikImie,
      inwestorImie: current.inwestorImie,
      uwagi: current.uwagi,
      usterki: current.usterki,
      usterkiOtwarte: current.usterkiOtwarte,
      podpisanyPrzezKierownika: current.podpisanyPrzezKierownika,
      podpisanyPrzezInwestora: current.podpisanyPrzezInwestora,
      punkty: current.punkty.map((p) => p.id == punktId ? updated : p).toList(),
    ));
  }

  Future<void> podpisz({required bool kierownik}) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = await ref.read(odbioryApiProvider).podpisz(
      current.id,
      kierownik: kierownik,
    );
    state = AsyncData(updated);
  }

  Future<void> updateStatus(StatusProtokolu status) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = await ref.read(odbioryApiProvider).updateProtokol(
      current.id,
      {'status': status.apiValue},
    );
    state = AsyncData(updated);
  }
}

final protokolProvider =
    AsyncNotifierProvider.autoDispose<ProtokolNotifier, ProtokołOdbioruModel?>(
  ProtokolNotifier.new,
);

// ---- Usterki ----

class UsterkiNotifier extends AutoDisposeAsyncNotifier<List<UsterkaModel>> {
  @override
  Future<List<UsterkaModel>> build() async => [];

  Future<void> load({int? budowaId, int? protokolId}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(odbioryApiProvider).fetchUsterki(
            budowaId: budowaId,
            protokolId: protokolId,
          ),
    );
  }

  Future<void> addUsterka(UsterkaModel u) async {
    final created = await ref.read(odbioryApiProvider).createUsterka(u);
    state = AsyncData([created, ...state.valueOrNull ?? []]);
  }

  Future<void> updateStatus(int id, StatusUsterki status) async {
    final updated = await ref.read(odbioryApiProvider).updateUsterkaStatus(id, status);
    state = AsyncData(
      (state.valueOrNull ?? []).map((u) => u.id == id ? updated : u).toList(),
    );
  }
}

final usterkiProvider =
    AsyncNotifierProvider.autoDispose<UsterkiNotifier, List<UsterkaModel>>(
  UsterkiNotifier.new,
);
