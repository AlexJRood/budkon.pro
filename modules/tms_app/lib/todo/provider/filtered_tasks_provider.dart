import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:tms_app/todo/local/tms_sync_service.dart';
import 'package:tms_app/todo/view/model/member_lite_model.dart';
import 'package:core/user/user/user_provider.dart';

import 'task_filters_provider.dart';
import '../models/tasks_model.dart';
import 'package:tms_app/todo/local/tms_local_store.dart';

final filteredTasksProvider =
    StateNotifierProvider<FilteredTasksNotifier, AsyncValue<List<Tasks>>>((ref) {
  return FilteredTasksNotifier(ref);
});

class FilteredTasksNotifier extends StateNotifier<AsyncValue<List<Tasks>>> {
  FilteredTasksNotifier(this.ref) : super(const AsyncValue.data([]));

  final Ref ref;

  Timer? _debounce;
  String? _lastKey;

  void fetchForProjectDebounced(
    int projectId, {
    Duration delay = const Duration(milliseconds: 120),
  }) {
    _debounce?.cancel();
    _debounce = Timer(delay, () => fetchForProject(projectId));
  }

  Future<void> fetchForProject(int projectId) async {
    final previous = state.value ?? const <Tasks>[];
    state = AsyncValue<List<Tasks>>.loading().copyWithPrevious(
      AsyncValue.data(previous),
    );

    final filters = ref.read(appliedTaskFiltersProvider).toQueryParams(ref);
    final search = (filters['name'] ?? '').toString();

    final sync = ref.read(tmsSyncServiceProvider);
    await sync.init();

    final key = ref.read(tmsLocalStoreProvider).makeSearchKey(
          projectId: projectId,
          filters: filters,
          search: search,
        );

    _lastKey = key;

    try {
      final local = sync.searchLocal(
        projectId: projectId,
        filters: filters,
        search: search,
      );

      state = AsyncValue.data(local);

      final fresh = await sync.refreshSearch(
        projectId: projectId,
        filters: filters,
        search: search,
      );

      if (_lastKey == key) {
        state = AsyncValue.data(fresh);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final membersSourceProvider = Provider<AsyncValue<List<MemberLite>>>((ref) {
  final userAsync = ref.watch(userProvider);

  return userAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (user) {
      final members = user?.companyMembers ?? const [];
      final list = members
          .map((m) {
            final id = int.tryParse(m.id.toString());
            if (id == null || id <= 0) return null;

            final first = m.firstName.toString().trim();
            final last = m.lastName.toString().trim();
            final fullName = ('$first $last').trim();

            return MemberLite(
              id: id,
              name: fullName.isEmpty ? 'Unnamed'.tr : fullName,
              email: (m.email.toString().trim().isEmpty)
                  ? null
                  : m.email.toString().trim(),
              avatar: (m.avatar == null || m.avatar.toString().trim().isEmpty)
                  ? null
                  : m.avatar.toString().trim(),
            );
          })
          .whereType<MemberLite>()
          .toList();

      return AsyncValue.data(list);
    },
  );
});

final membersSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredMembersProvider = Provider<AsyncValue<List<MemberLite>>>((ref) {
  final q = ref.watch(membersSearchQueryProvider).trim().toLowerCase();
  final source = ref.watch(membersSourceProvider);

  return source.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (list) {
      if (q.isEmpty) return AsyncValue.data(list);

      final filtered = list.where((m) {
        final n = m.name.toLowerCase();
        final e = (m.email ?? '').toLowerCase();
        return n.contains(q) || e.contains(q) || m.id.toString().contains(q);
      }).toList();

      return AsyncValue.data(filtered);
    },
  );
});

final showAssignedClientsSheetProvider = StateProvider<bool>((ref) => false);
final assignedClientsSearchQueryProvider = StateProvider<String>((ref) => '');
final showMembersSheetProvider = StateProvider<bool>((ref) => false);