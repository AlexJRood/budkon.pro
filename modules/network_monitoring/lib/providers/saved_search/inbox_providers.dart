import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inbox_api.dart';
import 'inbox_models.dart';

enum SavedSearchInboxBrowseMode {
  list,
  allNew,
  singleSearch,
}


enum SavedSearchAllNewMode {
  merged,
  sequential,
}

final savedSearchAllNewModeProvider =
    StateProvider<SavedSearchAllNewMode>(
  (ref) => SavedSearchAllNewMode.merged,
);



final savedSearchInboxOnlyNewProvider = StateProvider<bool>((ref) => true);
final savedSearchInboxIncludeInactiveProvider =
    StateProvider<bool>((ref) => false);
final savedSearchInboxIncludeArchivedProvider =
    StateProvider<bool>((ref) => false);
final savedSearchInboxExcludeFavoritesProvider =
    StateProvider<bool>((ref) => false);
final savedSearchInboxExcludeHideProvider =
    StateProvider<bool>((ref) => false);
final savedSearchInboxExcludeDisplayedProvider =
    StateProvider<bool>((ref) => false);

final savedSearchInboxMarkSeenAcrossSearchesProvider =
    StateProvider<bool>((ref) => false);

final savedSearchInboxPageProvider = StateProvider<int>((ref) => 1);
final savedSearchInboxPageSizeProvider = StateProvider<int>((ref) => 20);

final savedSearchInboxBrowseModeProvider =
    StateProvider<SavedSearchInboxBrowseMode>(
  (ref) => SavedSearchInboxBrowseMode.list,
);

final savedSearchInboxPanelOpenProvider = StateProvider<bool>((ref) => false);

final selectedSavedSearchIdProvider = StateProvider<int?>((ref) => null);

final savedSearchesListQueryProvider = StateProvider<String>((ref) => '');
final savedSearchesListHasNewProvider = StateProvider<bool>((ref) => false);
final savedSearchesListHasResultsProvider = StateProvider<bool>((ref) => false);
final savedSearchesListEnableNotificationsProvider =
    StateProvider<bool>((ref) => false);
final savedSearchesListEnableEmailNotificationsProvider =
    StateProvider<bool>((ref) => false);

final savedSearchesListScopeProvider = StateProvider<String>((ref) => '');
final savedSearchesListOrderingProvider =
    StateProvider<String>((ref) => 'new_desc');

final savedSearchesListPageProvider = StateProvider<int>((ref) => 1);
final savedSearchesListPageSizeProvider = StateProvider<int>((ref) => 50);

final savedSearchesWithCountersProvider =
    FutureProvider.autoDispose<SavedSearchesWithCountersPageModel>(
  (ref) async {
    final api = ref.watch(savedSearchInboxApiProvider);

    final query = ref.watch(savedSearchesListQueryProvider);
    final hasNew = ref.watch(savedSearchesListHasNewProvider);
    final hasResults = ref.watch(savedSearchesListHasResultsProvider);
    final enableNotifications =
        ref.watch(savedSearchesListEnableNotificationsProvider);
    final enableEmailNotifications =
        ref.watch(savedSearchesListEnableEmailNotificationsProvider);
    final scope = ref.watch(savedSearchesListScopeProvider);
    final ordering = ref.watch(savedSearchesListOrderingProvider);
    final page = ref.watch(savedSearchesListPageProvider);
    final pageSize = ref.watch(savedSearchesListPageSizeProvider);

    return api.fetchSavedSearchesWithCounters(
      q: query.trim().isEmpty ? null : query.trim(),
      hasNew: hasNew ? true : null,
      hasResults: hasResults ? true : null,
      enableNotifications: enableNotifications ? true : null,
      enableEmailNotification: enableEmailNotifications ? true : null,
      scope: scope.trim().isEmpty ? null : scope.trim(),
      ordering: ordering,
      page: page,
      pageSize: pageSize,
    );
  },
);

final selectedSavedSearchProvider =
    FutureProvider.autoDispose<SavedSearchWithCountersModel?>((ref) async {
  final selectedId = ref.watch(selectedSavedSearchIdProvider);
  final currentPage = await ref.watch(savedSearchesWithCountersProvider.future);

  if (selectedId == null) {
    return currentPage.results.isNotEmpty ? currentPage.results.first : null;
  }

  for (final item in currentPage.results) {
    if (item.id == selectedId) {
      return item;
    }
  }

  final exactPage = await ref.read(savedSearchInboxApiProvider).fetchSavedSearchesWithCounters(
        ids: [selectedId],
        page: 1,
        pageSize: 1,
      );

  if (exactPage.results.isNotEmpty) {
    return exactPage.results.first;
  }

  return currentPage.results.isNotEmpty ? currentPage.results.first : null;
});



final savedSearchInboxProvider =
    FutureProvider.autoDispose<SavedSearchInboxPageModel>((ref) async {
  final api = ref.watch(savedSearchInboxApiProvider);
  final browseMode = ref.watch(savedSearchInboxBrowseModeProvider);
  final allNewMode = ref.watch(savedSearchAllNewModeProvider);
  final selected = await ref.watch(selectedSavedSearchProvider.future);

  final onlyNew = ref.watch(savedSearchInboxOnlyNewProvider);
  final includeInactive = ref.watch(savedSearchInboxIncludeInactiveProvider);
  final includeArchived = ref.watch(savedSearchInboxIncludeArchivedProvider);
  final excludeFavorites = ref.watch(savedSearchInboxExcludeFavoritesProvider);
  final excludeHide = ref.watch(savedSearchInboxExcludeHideProvider);
  final excludeDisplayed = ref.watch(savedSearchInboxExcludeDisplayedProvider);
  final page = ref.watch(savedSearchInboxPageProvider);
  final pageSize = ref.watch(savedSearchInboxPageSizeProvider);

  List<int>? savedSearchIds;

  if (browseMode == SavedSearchInboxBrowseMode.singleSearch) {
    if (selected == null) {
      return SavedSearchInboxPageModel.empty();
    }
    savedSearchIds = [selected.id];
  } else if (browseMode == SavedSearchInboxBrowseMode.allNew) {
    if (allNewMode == SavedSearchAllNewMode.sequential) {
      if (selected == null) {
        return SavedSearchInboxPageModel.empty();
      }
      savedSearchIds = [selected.id];
    } else {
      savedSearchIds = null;
    }
  } else {
    return SavedSearchInboxPageModel.empty();
  }

  return api.fetchInbox(
    savedSearchIds: savedSearchIds,
    onlyNew: onlyNew,
    includeInactive: includeInactive,
    includeArchived: includeArchived,
    excludeFavorites: excludeFavorites,
    excludeHide: excludeHide,
    excludeDisplayed: excludeDisplayed,
    page: page,
    pageSize: pageSize,
  );
});

final savedSearchInboxActionsProvider =
    Provider<SavedSearchInboxActions>((ref) => SavedSearchInboxActions(ref));

class SavedSearchInboxActions {
  SavedSearchInboxActions(this.ref);

  final Ref ref;


List<int>? _resolveSavedSearchIdsForItems(
  List<SavedSearchInboxItemModel> items,
) {
  final browseMode = ref.read(savedSearchInboxBrowseModeProvider);
  final allNewMode = ref.read(savedSearchAllNewModeProvider);
  final markAcrossSearches =
      ref.read(savedSearchInboxMarkSeenAcrossSearchesProvider);

  if (browseMode == SavedSearchInboxBrowseMode.allNew) {
    if (allNewMode == SavedSearchAllNewMode.merged) {
      return null;
    }

    if (markAcrossSearches) {
      return null;
    }

    final selectedAsync = ref.read(selectedSavedSearchProvider);
    final selected = selectedAsync.valueOrNull;
    if (selected != null && selected.id > 0) {
      return [selected.id];
    }

    return null;
  }

  if (markAcrossSearches) {
    return null;
  }

  final selectedAsync = ref.read(selectedSavedSearchProvider);
  final selected = selectedAsync.valueOrNull;
  if (selected != null && selected.id > 0) {
    return [selected.id];
  }

  return null;
}

  void openSavedSearchesList() {
    ref.read(savedSearchInboxBrowseModeProvider.notifier).state =
        SavedSearchInboxBrowseMode.list;
    ref.read(savedSearchInboxPanelOpenProvider.notifier).state = false;
    ref.read(savedSearchInboxPageProvider.notifier).state = 1;
  }

  void selectSavedSearch(
    int id, {
    bool openPanel = true,
  }) {
    ref.read(selectedSavedSearchIdProvider.notifier).state = id;
    ref.read(savedSearchInboxPageProvider.notifier).state = 1;

    if (openPanel) {
      ref.read(savedSearchInboxPanelOpenProvider.notifier).state = true;
    }

    ref.invalidate(selectedSavedSearchProvider);
    ref.invalidate(savedSearchInboxProvider);
  }

  void closePanel() {
    ref.read(savedSearchInboxPanelOpenProvider.notifier).state = false;
  }

  void openPanel() {
    ref.read(savedSearchInboxPanelOpenProvider.notifier).state = true;
  }


void openAllNewInbox({
  SavedSearchAllNewMode mode = SavedSearchAllNewMode.merged,
}) {
  ref.read(savedSearchAllNewModeProvider.notifier).state = mode;
  ref.read(savedSearchInboxBrowseModeProvider.notifier).state =
      SavedSearchInboxBrowseMode.allNew;
  ref.read(savedSearchInboxPageProvider.notifier).state = 1;
  ref.read(savedSearchInboxPanelOpenProvider.notifier).state = true;

  if (mode == SavedSearchAllNewMode.sequential) {
    final page = ref.read(savedSearchesWithCountersProvider).valueOrNull;
    final searches = page?.results ?? const <SavedSearchWithCountersModel>[];

    SavedSearchWithCountersModel? firstWithNew;
    for (final item in searches) {
      if (item.newUniqueCount > 0) {
        firstWithNew = item;
        break;
      }
    }

    final fallback = searches.isNotEmpty ? searches.first : null;
    final target = firstWithNew ?? fallback;
    if (target != null) {
      ref.read(selectedSavedSearchIdProvider.notifier).state = target.id;
    }
  }

  ref.invalidate(selectedSavedSearchProvider);
  ref.invalidate(savedSearchInboxProvider);
}

void setAllNewMode(SavedSearchAllNewMode mode) {
  ref.read(savedSearchAllNewModeProvider.notifier).state = mode;
  ref.read(savedSearchInboxPageProvider.notifier).state = 1;

  if (mode == SavedSearchAllNewMode.sequential) {
    final page = ref.read(savedSearchesWithCountersProvider).valueOrNull;
    final searches = page?.results ?? const <SavedSearchWithCountersModel>[];

    final currentSelectedId = ref.read(selectedSavedSearchIdProvider);
    final exists = searches.any((e) => e.id == currentSelectedId);

    if (!exists) {
      SavedSearchWithCountersModel? firstWithNew;
      for (final item in searches) {
        if (item.newUniqueCount > 0) {
          firstWithNew = item;
          break;
        }
      }
      final fallback = searches.isNotEmpty ? searches.first : null;
      final target = firstWithNew ?? fallback;
      if (target != null) {
        ref.read(selectedSavedSearchIdProvider.notifier).state = target.id;
      }
    }
  }

  ref.invalidate(selectedSavedSearchProvider);
  ref.invalidate(savedSearchInboxProvider);
}



  void openSingleSearchInbox(int id) {
    ref.read(selectedSavedSearchIdProvider.notifier).state = id;
    ref.read(savedSearchInboxBrowseModeProvider.notifier).state =
        SavedSearchInboxBrowseMode.singleSearch;
    ref.read(savedSearchInboxPageProvider.notifier).state = 1;
    ref.read(savedSearchInboxPanelOpenProvider.notifier).state = true;
    ref.invalidate(selectedSavedSearchProvider);
    ref.invalidate(savedSearchInboxProvider);
  }

  Future<void> markSeenItem(SavedSearchInboxItemModel item) async {
    await markSeenItems([item]);
  }

  Future<void> markSeenItems(List<SavedSearchInboxItemModel> items) async {
    if (items.isEmpty) return;

    final savedSearchIds = _resolveSavedSearchIdsForItems(items);

    await ref.read(savedSearchInboxApiProvider).markInboxSeen(
          representativeAdIds: items.map((e) => e.representativeAdId).toList(),
          savedSearchIds: savedSearchIds,
        );

    ref.invalidate(savedSearchesWithCountersProvider);
    ref.invalidate(selectedSavedSearchProvider);
  }

  void refreshAll() {
    ref.invalidate(savedSearchesWithCountersProvider);
    ref.invalidate(selectedSavedSearchProvider);
    ref.invalidate(savedSearchInboxProvider);
  }

  void resetSavedSearchesFilters() {
    ref.read(savedSearchesListQueryProvider.notifier).state = '';
    ref.read(savedSearchesListHasNewProvider.notifier).state = false;
    ref.read(savedSearchesListHasResultsProvider.notifier).state = false;
    ref.read(savedSearchesListEnableNotificationsProvider.notifier).state =
        false;
    ref.read(savedSearchesListEnableEmailNotificationsProvider.notifier).state =
        false;
    ref.read(savedSearchesListScopeProvider.notifier).state = '';
    ref.read(savedSearchesListOrderingProvider.notifier).state = 'new_desc';
    ref.read(savedSearchesListPageProvider.notifier).state = 1;
    ref.read(savedSearchesListPageSizeProvider.notifier).state = 50;
    ref.invalidate(savedSearchesWithCountersProvider);
  }
}

class SavedSearchInboxDeepLink {
  final int? savedSearchId;
  final int? targetAdId;
  final bool fromNotification;

  const SavedSearchInboxDeepLink({
    this.savedSearchId,
    this.targetAdId,
    this.fromNotification = false,
  });

  SavedSearchInboxDeepLink copyWith({
    int? savedSearchId,
    int? targetAdId,
    bool? fromNotification,
  }) {
    return SavedSearchInboxDeepLink(
      savedSearchId: savedSearchId ?? this.savedSearchId,
      targetAdId: targetAdId ?? this.targetAdId,
      fromNotification: fromNotification ?? this.fromNotification,
    );
  }
}

final savedSearchInboxDeepLinkProvider =
    StateProvider<SavedSearchInboxDeepLink?>((ref) => null);

final savedSearchInboxHighlightedAdIdProvider =
    StateProvider<int?>((ref) => null);