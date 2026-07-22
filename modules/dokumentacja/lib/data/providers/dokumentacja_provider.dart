import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dokumentacja_model.dart';
import '../services/dokumentacja_api.dart';

class DokumentacjaNotifier extends AutoDisposeAsyncNotifier<List<DokumentModel>> {
  late int _budowaId;

  @override
  Future<List<DokumentModel>> build() async => [];

  void init(int budowaId) {
    _budowaId = budowaId;
    _load();
  }

  Future<void> _load() async {
    state = const AsyncLoading();
    state = AsyncData(
        await ref.read(dokumentacjaApiProvider).fetchDokumenty(_budowaId));
  }

  Future<void> addDokument(DokumentModel d) async {
    await ref.read(dokumentacjaApiProvider).createDokument(d);
    await _load();
  }

  Future<void> deleteDokument(int id) async {
    await ref.read(dokumentacjaApiProvider).deleteDokument(id);
    await _load();
  }
}

final dokumentacjaProvider =
    AsyncNotifierProvider.autoDispose<DokumentacjaNotifier, List<DokumentModel>>(
  DokumentacjaNotifier.new,
);
