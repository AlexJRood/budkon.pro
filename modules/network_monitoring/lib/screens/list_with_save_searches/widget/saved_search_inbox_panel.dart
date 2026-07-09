import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/export.dart';
import 'package:network_monitoring/components/cards/provider.dart';
import 'package:network_monitoring/components/cards/selected_card.dart';
import 'package:network_monitoring/components/open_nm_ad.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';
import 'package:network_monitoring/pie_menu/network_monitoring.dart';
import 'package:network_monitoring/providers/saved_search/inbox_api.dart';
import 'package:network_monitoring/providers/saved_search/inbox_models.dart';
import 'package:network_monitoring/providers/saved_search/inbox_providers.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';
import 'package:network_monitoring/widgets/filter/fileds.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';
import 'package:visibility_detector/visibility_detector.dart';

String? _extractMainImage(dynamic images) {
  if (images == null) return null;

  if (images is List && images.isNotEmpty) {
    final first = images.first;
    if (first != null && first.toString().trim().isNotEmpty) {
      return first.toString();
    }
  }

  if (images is Map) {
    for (final key in const ['main', '0', 'first', 'thumbnail']) {
      final value = images[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    for (final entry in images.entries) {
      final value = entry.value;
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
  }

  return null;
}

MonitoringAdsModel? _toMonitoringAd(Map<String, dynamic>? raw) {
  if (raw == null) return null;
  try {
    return MonitoringAdsModel.fromJson(raw);
  } catch (_) {
    return null;
  }
}

class SavedSearchInboxPanel extends ConsumerStatefulWidget {
  const SavedSearchInboxPanel({super.key});

  @override
  ConsumerState<SavedSearchInboxPanel> createState() =>
      _SavedSearchInboxPanelState();
}

class _SavedSearchInboxPanelState extends ConsumerState<SavedSearchInboxPanel> {
  final ScrollController _scrollController = ScrollController();

  final Map<int, SavedSearchInboxItemModel> _pendingSeen = {};
  final Set<int> _queuedSeen = {};

  Timer? _seenDebounce;
  Timer? _bannerTimer;

  String? _bannerText;

  List<SavedSearchWithCountersModel> _currentSearches = const [];
  SavedSearchAllNewMode _currentAllNewMode = SavedSearchAllNewMode.merged;
  String? _autoAdvanceHandledSignature;

  List<SavedSearchInboxItemModel> _items = [];
  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _nextPage = 1;
  String? _loadError;
  String? _activeSignature;

  SavedSearchWithCountersModel? _currentSelected;
  SavedSearchInboxBrowseMode _currentBrowseMode =
      SavedSearchInboxBrowseMode.list;

  bool _currentOnlyNew = true;
  bool _currentIncludeInactive = false;
  bool _currentIncludeArchived = false;
  bool _currentExcludeFavorites = false;
  bool _currentExcludeHide = false;
  bool _currentExcludeDisplayed = false;

  bool _isResolvingTargetAd = false;
  String? _openedTargetSignature;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _seenDebounce?.cancel();
    _bannerTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;

    if (_hasMore &&
        !_isLoadingMore &&
        !_isInitialLoading &&
        pos.pixels >= pos.maxScrollExtent - 700) {
      _loadMore();
    }

    if (!_hasMore &&
        !_isLoadingMore &&
        !_isInitialLoading &&
        pos.maxScrollExtent > 0 &&
        pos.pixels >= pos.maxScrollExtent - 40) {
      _maybeAutoAdvanceAfterEndReached();
    }
  }

  SavedSearchWithCountersModel? _findNextSearchWithNewAds({
    required List<SavedSearchWithCountersModel> searches,
    required SavedSearchWithCountersModel current,
  }) {
    final currentIndex = searches.indexWhere((e) => e.id == current.id);
    if (currentIndex == -1) return null;

    for (int i = currentIndex + 1; i < searches.length; i++) {
      if (searches[i].newUniqueCount > 0) {
        return searches[i];
      }
    }

    for (int i = 0; i < currentIndex; i++) {
      if (searches[i].newUniqueCount > 0) {
        return searches[i];
      }
    }

    return null;
  }

  void _maybeAutoAdvanceAfterEndReached() {
    if (_currentBrowseMode != SavedSearchInboxBrowseMode.allNew) return;
    if (_currentAllNewMode != SavedSearchAllNewMode.sequential) return;
    if (_currentSelected == null) return;
    if (_activeSignature == null) return;
    if (_autoAdvanceHandledSignature == _activeSignature) return;

    _autoAdvanceHandledSignature = _activeSignature;

    final next = _findNextSearchWithNewAds(
      searches: _currentSearches,
      current: _currentSelected!,
    );

    if (next == null || next.id == _currentSelected!.id) return;

    ref.read(savedSearchInboxActionsProvider).openSingleSearchInbox(next.id);
    ref.read(savedSearchInboxBrowseModeProvider.notifier).state =
        SavedSearchInboxBrowseMode.allNew;
    ref.read(savedSearchAllNewModeProvider.notifier).state =
        SavedSearchAllNewMode.sequential;

    _showBanner(
        '${'Now showing new ads from'.tr}: ${next.title ?? 'Saved search'.tr}'
    );
  }

  void _showBanner(String text) {
    _bannerTimer?.cancel();

    setState(() {
      _bannerText = text;
    });

    _bannerTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _bannerText = null;
      });
    });
  }

  void _resetTransientState() {
    _pendingSeen.clear();
    _queuedSeen.clear();
    _seenDebounce?.cancel();
    _openedTargetSignature = null;
  }

  void _queueSeen(SavedSearchInboxItemModel item) {
    if (item.newMatchesCount <= 0) return;
    if (_queuedSeen.contains(item.representativeAdId)) return;

    _queuedSeen.add(item.representativeAdId);
    _pendingSeen[item.representativeAdId] = item;

    _seenDebounce?.cancel();
    _seenDebounce = Timer(const Duration(milliseconds: 700), _flushSeen);
  }

  Future<void> _flushSeen() async {
    if (_pendingSeen.isEmpty) return;

    final items = _pendingSeen.values.toList(growable: false);
    _pendingSeen.clear();

    try {
      await ref.read(savedSearchInboxActionsProvider).markSeenItems(items);
    } catch (_) {
      for (final item in items) {
        _queuedSeen.remove(item.representativeAdId);
      }
    }
  }

  void _applySavedSearch(
    WidgetRef ref,
    SavedSearchWithCountersModel search,
  ) {
    ref
        .read(networkMonitoringFilterCacheProvider.notifier)
        .setFiltersFromJson(search.toJson());

    ref.read(networkMonitoringFilterProvider.notifier).applyFiltersFromCacheNM(
          ref.read(networkMonitoringFilterCacheProvider.notifier),
        );

    ref
        .read(networkMonitoringFilterButtonProvider.notifier)
        .loadSavedFilters(ref.read(networkMonitoringFilterCacheProvider));

    ref.read(navigationService).pushNamedScreen(Routes.networkMonitoring);
  }

  String _buildSignature({
    required SavedSearchInboxBrowseMode browseMode,
    required SavedSearchAllNewMode allNewMode,
    required int? selectedId,
    required bool onlyNew,
    required bool includeInactive,
    required bool includeArchived,
    required bool excludeFavorites,
    required bool excludeHide,
    required bool excludeDisplayed,
  }) {
    return [
      browseMode.name,
      allNewMode.name,
      selectedId,
      onlyNew,
      includeInactive,
      includeArchived,
      excludeFavorites,
      excludeHide,
      excludeDisplayed,
    ].join('|');
  }

  String _targetSignature({
    required SavedSearchInboxBrowseMode browseMode,
    required SavedSearchAllNewMode allNewMode,
    required int? savedSearchId,
    required int targetAdId,
    required bool fromNotification,
  }) {
    return '${browseMode.name}|${allNewMode.name}|$savedSearchId|$targetAdId|$fromNotification';
  }

  List<int>? _resolveRequestSavedSearchIds({
    required SavedSearchInboxBrowseMode browseMode,
    required SavedSearchAllNewMode allNewMode,
    required int? selectedId,
  }) {
    if (browseMode == SavedSearchInboxBrowseMode.singleSearch &&
        selectedId != null) {
      return [selectedId];
    }

    if (browseMode == SavedSearchInboxBrowseMode.allNew &&
        allNewMode == SavedSearchAllNewMode.sequential &&
        selectedId != null) {
      return [selectedId];
    }

    if (browseMode == SavedSearchInboxBrowseMode.allNew &&
        allNewMode == SavedSearchAllNewMode.merged) {
      return null;
    }

    return null;
  }

  Future<void> _loadFirstPage(
    String signature, {
    required SavedSearchInboxBrowseMode browseMode,
    required SavedSearchAllNewMode allNewMode,
    required int? selectedId,
  }) async {
    _resetTransientState();

    setState(() {
      _activeSignature = signature;
      _isInitialLoading = true;
      _isLoadingMore = false;
      _items = [];
      _hasMore = false;
      _nextPage = 1;
      _loadError = null;
      _autoAdvanceHandledSignature = null;
    });

    try {
      final page = await ref.read(savedSearchInboxApiProvider).fetchInbox(
            savedSearchIds: _resolveRequestSavedSearchIds(
              browseMode: browseMode,
              allNewMode: allNewMode,
              selectedId: selectedId,
            ),
            onlyNew: _currentOnlyNew,
            includeInactive: _currentIncludeInactive,
            includeArchived: _currentIncludeArchived,
            excludeFavorites: _currentExcludeFavorites,
            excludeHide: _currentExcludeHide,
            excludeDisplayed: _currentExcludeDisplayed,
            page: 1,
            pageSize: ref.read(savedSearchInboxPageSizeProvider),
          );

      if (!mounted || _activeSignature != signature) return;

      setState(() {
        _items = page.results;
        _hasMore = page.next != null && page.next!.isNotEmpty;
        _nextPage = 2;
        _isInitialLoading = false;
        _loadError = null;
      });

      await _resolveDeepLinkTargetIfNeeded(
        browseMode: browseMode,
        allNewMode: allNewMode,
        selectedId: selectedId,
      );

      if (_items.isEmpty) {
        _maybeAutoAdvanceAfterEndReached();
      }
    } catch (e) {
      if (!mounted || _activeSignature != signature) return;
      setState(() {
        _isInitialLoading = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    await _loadMoreInternal(triggerResolveTarget: true);
  }

  Future<void> _loadMoreInternal({
    bool triggerResolveTarget = true,
  }) async {
    if (_isLoadingMore || !_hasMore) return;

    final signature = _activeSignature;
    if (signature == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final page = await ref.read(savedSearchInboxApiProvider).fetchInbox(
            savedSearchIds: _resolveRequestSavedSearchIds(
              browseMode: _currentBrowseMode,
              allNewMode: _currentAllNewMode,
              selectedId: _currentSelected?.id,
            ),
            onlyNew: _currentOnlyNew,
            includeInactive: _currentIncludeInactive,
            includeArchived: _currentIncludeArchived,
            excludeFavorites: _currentExcludeFavorites,
            excludeHide: _currentExcludeHide,
            excludeDisplayed: _currentExcludeDisplayed,
            page: _nextPage,
            pageSize: ref.read(savedSearchInboxPageSizeProvider),
          );

      if (!mounted || _activeSignature != signature) return;

      final existingIds = _items.map((e) => e.representativeAdId).toSet();
      final newItems = page.results
          .where((e) => !existingIds.contains(e.representativeAdId))
          .toList();

      setState(() {
        _items = [..._items, ...newItems];
        _hasMore = page.next != null && page.next!.isNotEmpty;
        _nextPage += 1;
        _isLoadingMore = false;
      });

      if (triggerResolveTarget) {
        await _resolveDeepLinkTargetIfNeeded(
          browseMode: _currentBrowseMode,
          allNewMode: _currentAllNewMode,
          selectedId: _currentSelected?.id,
        );
      }
    } catch (e) {
      if (!mounted || _activeSignature != signature) return;
      setState(() {
        _isLoadingMore = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _resolveDeepLinkTargetIfNeeded({
    required SavedSearchInboxBrowseMode browseMode,
    required SavedSearchAllNewMode allNewMode,
    required int? selectedId,
  }) async {
    final deepLink = ref.read(savedSearchInboxDeepLinkProvider);

    if (deepLink == null || deepLink.targetAdId == null) return;

    if (browseMode == SavedSearchInboxBrowseMode.singleSearch &&
        deepLink.savedSearchId != null &&
        selectedId != deepLink.savedSearchId) {
      return;
    }

    final signature = _targetSignature(
      browseMode: browseMode,
      allNewMode: allNewMode,
      savedSearchId: selectedId,
      targetAdId: deepLink.targetAdId!,
      fromNotification: deepLink.fromNotification,
    );

    if (_openedTargetSignature == signature) return;
    if (_isResolvingTargetAd) return;

    SavedSearchInboxItemModel? findTarget() {
      for (final item in _items) {
        if (item.representativeAdId == deepLink.targetAdId) {
          return item;
        }
      }
      return null;
    }

    final existingItem = findTarget();
    if (existingItem != null) {
      _openTargetAdOverlay(existingItem, signature);
      return;
    }

    if (!_hasMore) return;

    _isResolvingTargetAd = true;
    try {
      while (mounted && _hasMore) {
        await _loadMoreInternal(triggerResolveTarget: false);

        final foundItem = findTarget();
        if (foundItem != null) {
          _openTargetAdOverlay(foundItem, signature);
          break;
        }
      }
    } finally {
      _isResolvingTargetAd = false;
    }
  }

  void _openTargetAdOverlay(
    SavedSearchInboxItemModel item,
    String signature,
  ) {
    if (_openedTargetSignature == signature) return;
    _openedTargetSignature = signature;

    final ad = _toMonitoringAd(item.ad);
    if (ad == null) return;

    final tag = 'saved-search-notification-${item.representativeAdId}';

    ref.read(savedSearchInboxDeepLinkProvider.notifier).state = null;

    final sourceTitle = (_currentBrowseMode == SavedSearchInboxBrowseMode.singleSearch ||
            (_currentBrowseMode == SavedSearchInboxBrowseMode.allNew &&
                _currentAllNewMode == SavedSearchAllNewMode.sequential))
        ? (_currentSelected?.title ?? 'Saved search'.tr)
        : (item.matchedSavedSearches.isNotEmpty
            ? item.matchedSavedSearches.first.title
            : 'Saved search'.tr);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      _showBanner(
        '${'Now showing ads from'.tr}: $sourceTitle',
      );

      await openAdUrl(
        context,
        ref,
        ad,
        item.defaultTransactionId,
        item.defaultClientId,
        tag,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final searchesPageAsync = ref.watch(savedSearchesWithCountersProvider);
    final selectedAsync = ref.watch(selectedSavedSearchProvider);
    final selectedCardType = ref.watch(selectedCardProviderNM);

    final browseMode = ref.watch(savedSearchInboxBrowseModeProvider);
    final allNewMode = ref.watch(savedSearchAllNewModeProvider);
    final onlyNew = ref.watch(savedSearchInboxOnlyNewProvider);
    final includeInactive = ref.watch(savedSearchInboxIncludeInactiveProvider);
    final includeArchived = ref.watch(savedSearchInboxIncludeArchivedProvider);
    final excludeFavorites = ref.watch(savedSearchInboxExcludeFavoritesProvider);
    final excludeHide = ref.watch(savedSearchInboxExcludeHideProvider);
    final excludeDisplayed = ref.watch(savedSearchInboxExcludeDisplayedProvider);

    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Stack(
        children: [
          searchesPageAsync.when(
            data: (searchesPage) {
              final totalSearchesCount = searchesPage.count;
              _currentSearches = searchesPage.results;
              _currentAllNewMode = allNewMode;

              return selectedAsync.when(
                data: (selected) {
                  if (browseMode == SavedSearchInboxBrowseMode.singleSearch &&
                      selected == null) {
                    return Center(
                      child: Text(
                        'Select saved search'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                    );
                  }

                  if (browseMode == SavedSearchInboxBrowseMode.allNew &&
                      totalSearchesCount == 0) {
                    return Center(
                      child: Text(
                        'No saved searches'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                    );
                  }

                  _currentSelected = selected;
                  _currentBrowseMode = browseMode;
                  _currentOnlyNew = onlyNew;
                  _currentIncludeInactive = includeInactive;
                  _currentIncludeArchived = includeArchived;
                  _currentExcludeFavorites = excludeFavorites;
                  _currentExcludeHide = excludeHide;
                  _currentExcludeDisplayed = excludeDisplayed;

                  final selectedId = selected?.id;
                  final signature = _buildSignature(
                    browseMode: browseMode,
                    allNewMode: allNewMode,
                    selectedId: selectedId,
                    onlyNew: onlyNew,
                    includeInactive: includeInactive,
                    includeArchived: includeArchived,
                    excludeFavorites: excludeFavorites,
                    excludeHide: excludeHide,
                    excludeDisplayed: excludeDisplayed,
                  );

                  if (_activeSignature != signature) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _loadFirstPage(
                        signature,
                        browseMode: browseMode,
                        allNewMode: allNewMode,
                        selectedId: selectedId,
                      );
                    });
                  }

                  return Column(
                    children: [
                      _InboxHeader(
                        allNewMode: allNewMode,
                        browseMode: browseMode,
                        search: selected,
                        totalSearchesCount: totalSearchesCount,
                        onBackToList: () {
                          ref
                              .read(savedSearchInboxBrowseModeProvider.notifier)
                              .state = SavedSearchInboxBrowseMode.list;
                        },
                        onOpenSearch:
                            browseMode == SavedSearchInboxBrowseMode.singleSearch &&
                                    selected != null
                                ? () => _applySavedSearch(ref, selected)
                                : null,
                        onRefresh: () => _loadFirstPage(
                          signature,
                          browseMode: browseMode,
                          allNewMode: allNewMode,
                          selectedId: selectedId,
                        ),
                        isMobile:isMobile
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: _buildBody(
                          context: context,
                          theme: theme,
                          isMobile: isMobile,
                          selectedCardType: selectedCardType,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => Center(child: AppLottie.loading()),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      '${'Selected search error'.tr}:\n$error',
                      style: TextStyle(color: theme.textColor),
                    ),
                  ),
                ),
              );
            },
            loading: () => Center(child: AppLottie.loading()),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  '${'Saved searches error'.tr}:\n$error',
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _bannerText == null
                    ? const SizedBox.shrink()
                    : Container(
                        key: ValueKey(_bannerText),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: theme.themeColor.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: theme.themeColor.withOpacity(0.20),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: Text(
                          _bannerText!,
                          style: TextStyle(
                            color: theme.themeColorText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required ThemeColors theme,
    required bool isMobile,
    required CardTypeNM selectedCardType,
  }) {
    if (_isInitialLoading && _items.isEmpty) {
      return Center(child: AppLottie.loading());
    }

    if (_loadError != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            '${'Inbox error'.tr}:\n$_loadError',
            style: TextStyle(color: theme.textColor),
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLottie.noResults(size: 260),
              const SizedBox(height: 12),
              Text(
                _currentBrowseMode == SavedSearchInboxBrowseMode.allNew &&
                        _currentAllNewMode == SavedSearchAllNewMode.sequential
                    ? 'No new ads in this search'.tr
                    : _currentBrowseMode == SavedSearchInboxBrowseMode.allNew
                        ? 'No new ads found'.tr
                        : 'No new ads in this saved search'.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final effectiveCardType = isMobile ? CardTypeNM.vanda : selectedCardType;
    final spacing = effectiveCardType.basePadding;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = math
            .max(1, ((constraints.maxWidth - spacing * 2) / (effectiveCardType.baseWidth / 2)).floor())
            .clamp(1, 4);
        final isGrid = crossAxisCount > 1;

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(spacing),
              sliver: isGrid
                  ? SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: effectiveCardType.aspectRatio,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildInboxItem(
                          item: _items[index],
                          theme: theme,
                          isMobile: isMobile,
                          effectiveCardType: effectiveCardType,
                          hideChips: true,
                        ),
                        childCount: _items.length,
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildInboxItem(
                            item: _items[index],
                            theme: theme,
                            isMobile: isMobile,
                            effectiveCardType: effectiveCardType,
                            hideChips: false,
                          ),
                        ),
                        childCount: _items.length,
                      ),
                    ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(child: _buildFooter(theme)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInboxItem({
    required SavedSearchInboxItemModel item,
    required ThemeColors theme,
    required bool isMobile,
    required CardTypeNM effectiveCardType,
    required bool hideChips,
  }) {
    return VisibilityDetector(
      key: Key(
        'saved-search-inbox-${_currentBrowseMode.name}-${_currentAllNewMode.name}-${_currentSelected?.id}-${item.representativeAdId}',
      ),
      onVisibilityChanged: (info) {
        if (info.visibleFraction >= 0.60) {
          _queueSeen(item);
        }
      },
      child: _InboxNmCard(
        item: item,
        theme: theme,
        isMobile: isMobile,
        browseMode: _currentBrowseMode,
        allNewMode: _currentAllNewMode,
        ref: ref,
        cardType: effectiveCardType,
        hideMatchedChips: hideChips,
      ),
    );
  }

  Widget _buildFooter(ThemeColors theme) {
    if (_isLoadingMore) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 10),
          Text('Loading more...'.tr, style: TextStyle(color: theme.textColor)),
        ],
      );
    }
    if (!_hasMore) {
      return Text(
        _currentBrowseMode == SavedSearchInboxBrowseMode.allNew &&
                _currentAllNewMode == SavedSearchAllNewMode.sequential
            ? 'End of current search'.tr
            : _currentBrowseMode == SavedSearchInboxBrowseMode.allNew
                ? 'End of all new ads'.tr
                : 'End of this saved search'.tr,
        style: TextStyle(
          color: theme.textColor.withValues(alpha: 0.65),
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return const SizedBox(height: 40);
  }
}

class _InboxHeader extends ConsumerWidget {
  final SavedSearchInboxBrowseMode browseMode;
  final SavedSearchAllNewMode allNewMode;
  final SavedSearchWithCountersModel? search;
  final int totalSearchesCount;
  final VoidCallback onRefresh;
  final VoidCallback onBackToList;
  final VoidCallback? onOpenSearch;
  final bool isMobile;

  const _InboxHeader({
    required this.browseMode,
    required this.allNewMode,
    required this.search,
    required this.totalSearchesCount,
    required this.onRefresh,
    required this.onBackToList,
    this.onOpenSearch,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final actions = ref.read(savedSearchInboxActionsProvider);
    final onlyNew = ref.watch(savedSearchInboxOnlyNewProvider);
    final includeInactive = ref.watch(savedSearchInboxIncludeInactiveProvider);
    final includeArchived = ref.watch(savedSearchInboxIncludeArchivedProvider);
    final excludeFavorites = ref.watch(savedSearchInboxExcludeFavoritesProvider);
    final excludeHide = ref.watch(savedSearchInboxExcludeHideProvider);
    final excludeDisplayed = ref.watch(savedSearchInboxExcludeDisplayedProvider);
    final markSeenAcrossSearches =
        ref.watch(savedSearchInboxMarkSeenAcrossSearchesProvider);

    final title = browseMode == SavedSearchInboxBrowseMode.allNew
        ? allNewMode == SavedSearchAllNewMode.sequential
            ? '${'Sequential new ads'.tr}: ${search?.title ?? 'Saved search'.tr}'
            : 'All new ads'.tr
        : '${'New ads from'.tr}: ${search?.title ?? 'Saved search'}';

    final showBackButton =
        browseMode == SavedSearchInboxBrowseMode.allNew ||
            browseMode == SavedSearchInboxBrowseMode.singleSearch;

    final showSeenAcrossChip =
        browseMode == SavedSearchInboxBrowseMode.singleSearch ||
            (browseMode == SavedSearchInboxBrowseMode.allNew &&
                allNewMode == SavedSearchAllNewMode.sequential);

    final chips = [
      if (showSeenAcrossChip)
        FilterChip(
          label: Text('Seen in other searches'.tr),
          selected: markSeenAcrossSearches,
          onSelected: (v) {
            ref
                .read(
              savedSearchInboxMarkSeenAcrossSearchesProvider
                  .notifier,
            )
                .state = v;
          },
        ),
      FilterChip(
        label: Text('Only new'.tr),
        selected: onlyNew,
        onSelected: (v) {
          ref.read(savedSearchInboxOnlyNewProvider.notifier).state = v;
        },
      ),
      FilterChip(
        label: Text('Include inactive'.tr),
        selected: includeInactive,
        onSelected: (v) {
          ref
              .read(savedSearchInboxIncludeInactiveProvider.notifier)
              .state = v;
        },
      ),
      FilterChip(
        label: Text('Include archived'.tr),
        selected: includeArchived,
        onSelected: (v) {
          ref
              .read(savedSearchInboxIncludeArchivedProvider.notifier)
              .state = v;
        },
      ),
      FilterChip(
        label: Text('Exclude favorites'.tr),
        selected: excludeFavorites,
        onSelected: (v) {
          ref.read(savedSearchInboxExcludeFavoritesProvider.notifier)
              .state = v;
        },
      ),
      FilterChip(
        label: Text('Exclude hidden'.tr),
        selected: excludeHide,
        onSelected: (v) {
          ref.read(savedSearchInboxExcludeHideProvider.notifier).state =
              v;
        },
      ),
      FilterChip(
        label: Text('Exclude displayed'.tr),
        selected: excludeDisplayed,
        onSelected: (v) {
          ref
              .read(savedSearchInboxExcludeDisplayedProvider.notifier)
              .state = v;
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showBackButton && !isMobile)
                IconButton(
                  onPressed: onBackToList,
                  icon: Icon(Icons.arrow_back, color: theme.textColor),
                  tooltip: 'Back to saved searches'.tr,
                ),
              if (!isMobile)
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              if (!isMobile) const SizedBox(width: 8),
              if (!isMobile) CardTypeSelectorNM(compact: true),
              const Spacer(),
              if (onOpenSearch != null) ...[
                TextButton.icon(
                  onPressed: onOpenSearch,
                  icon: Icon(Icons.travel_explore_outlined, color: theme.textColor),
                  label: Text('Open search'.tr, style: TextStyle(color: theme.textColor)),
                ),
                const SizedBox(width: 8),
              ],
              TextButton.icon(
                onPressed: onRefresh,
                icon: Icon(Icons.refresh, color: theme.textColor),
                label: Text('Refresh'.tr, style: TextStyle(color: theme.textColor)),
              ),
            ],
          ),
          if (browseMode == SavedSearchInboxBrowseMode.allNew) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text('Merged feed'.tr),
                  selected: allNewMode == SavedSearchAllNewMode.merged,
                  onSelected: (_) {
                    actions.setAllNewMode(SavedSearchAllNewMode.merged);
                  },
                ),
                ChoiceChip(
                  label: Text('Sequential searches'.tr),
                  selected: allNewMode == SavedSearchAllNewMode.sequential,
                  onSelected: (_) {
                    actions.setAllNewMode(SavedSearchAllNewMode.sequential);
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          if(isMobile)...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: chips
                .expand((element) => [element, SizedBox(width: 10,)],).toList(),
              ),
            )
          ]else...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: chips,
            ),
          ],

        ],
      ),
    );
  }
}

class _InboxNmCard extends StatelessWidget {
  final SavedSearchInboxItemModel item;
  final ThemeColors theme;
  final bool isMobile;
  final SavedSearchInboxBrowseMode browseMode;
  final SavedSearchAllNewMode allNewMode;
  final WidgetRef ref;
  final CardTypeNM cardType;
  final bool hideMatchedChips;

  const _InboxNmCard({
    super.key,
    required this.item,
    required this.theme,
    required this.isMobile,
    required this.browseMode,
    required this.allNewMode,
    required this.ref,
    required this.cardType,
    this.hideMatchedChips = false,
  });

  @override
  Widget build(BuildContext context) {
    final ad = _toMonitoringAd(item.ad);
    if (ad == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: Text(
          'Cannot render advertisement preview'.tr,
          style: TextStyle(color: theme.textColor),
        ),
      );
    }

    final mainImageUrl = _extractMainImage(item.images) ?? '';

    final bool showMatchedChips =
        !hideMatchedChips &&
        browseMode == SavedSearchInboxBrowseMode.allNew &&
            allNewMode == SavedSearchAllNewMode.merged;

    final effectiveCardType = isMobile ? CardTypeNM.vanda : cardType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showMatchedChips) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...item.matchedSavedSearches.map(
                (e) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: e.isNew
                        ? theme.themeColor.withOpacity(0.16)
                        : theme.textFieldColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    e.title,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        SelectedCardWidgetNM(
          ad: ad,
          tag: 'saved-search-inbox-${item.representativeAdId}',
          mainImageUrl: mainImageUrl,
          isPro: true,
          isDefaultDarkSystem: Theme.of(context).brightness == Brightness.dark,
          color: theme.dashboardContainer,
          textColor: theme.textColor,
          textFieldColor: theme.textFieldColor,
          buildShimmerPlaceholder: Container(
            width: double.infinity,
            height: isMobile ? 220 : 150,
            decoration: BoxDecoration(
              color: theme.textFieldColor,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          buildPieMenuActions: buildPieMenuActionsNM(
            ref,
            ad,
            context,
            item.defaultTransactionId,
            item.defaultClientId,
          ),
          aspectRatio: effectiveCardType.aspectRatio,
          isMobile: isMobile,
          transactionId: item.defaultTransactionId,
          clientId: item.defaultClientId,
          cardTypeNMOverwrite: isMobile ? CardTypeNM.vanda : null,
        ),
      ],
    );
  }
}