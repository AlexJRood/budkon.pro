import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/portal_model.dart';
import '../services/portal_api.dart';

final portalListProvider = StateNotifierProvider.autoDispose
    .family<PortalListNotifier, AsyncValue<List<PortalKlientaModel>>, int>(
  (ref, budowaId) => PortalListNotifier(ref.watch(portalApiProvider), budowaId),
);

class PortalListNotifier
    extends StateNotifier<AsyncValue<List<PortalKlientaModel>>> {
  PortalListNotifier(this._api, this._budowaId)
      : super(const AsyncValue.loading()) {
    fetch();
  }

  final PortalApi _api;
  final int _budowaId;

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _api.fetchList(budowaId: _budowaId));
  }

  void addLocal(PortalKlientaModel p) {
    state.whenData((list) => state = AsyncValue.data([p, ...list]));
  }

  void updateLocal(PortalKlientaModel updated) {
    state.whenData((list) => state = AsyncValue.data(
          list.map((p) => p.id == updated.id ? updated : p).toList(),
        ));
  }

  void removeLocal(int id) {
    state.whenData(
      (list) => state = AsyncValue.data(list.where((p) => p.id != id).toList()),
    );
  }
}
