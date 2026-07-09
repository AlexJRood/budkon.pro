import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:network_monitoring/emma/anchors/anchors_nm.dart';
import 'package:network_monitoring/providers/saved_search/inbox_models.dart';
import 'package:network_monitoring/providers/saved_search/inbox_providers.dart';
import 'package:network_monitoring/screens/list_with_save_searches/widget/save_search_list_view_widget.dart';
import 'package:network_monitoring/screens/list_with_save_searches/widget/saved_search_inbox_panel.dart';
import 'package:core/theme/apptheme.dart';

class ListWithSaveSearchesPc extends ConsumerWidget {
  const ListWithSaveSearchesPc({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browseMode = ref.watch(savedSearchInboxBrowseModeProvider);
    final allNewMode = ref.watch(savedSearchAllNewModeProvider);

    final bool showHero = browseMode == SavedSearchInboxBrowseMode.list;
    final bool showSidebarWithInbox =
        browseMode == SavedSearchInboxBrowseMode.allNew &&
            allNewMode == SavedSearchAllNewMode.sequential;

    return EmmaUiAnchorTarget(
      // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchPcRoot
      anchorKey: 'network_monitoring.saved_search.pc.root',
      child: Column(
        children: [
          if (showHero) ...[
            EmmaUiAnchorTarget(
              // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchPcHero
              anchorKey: 'network_monitoring.saved_search.pc.hero',
              child: Stack(
                children: [
                  Image.asset(
                    'assets/images/top-content.webp',
                    width: MediaQuery.of(context).size.width,
                    fit: BoxFit.cover,
                    height: 130,
                  ),
                  Positioned(
                    bottom: 10,
                    top: 10,
                    left: 20,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'title_network_monitoring'.tr,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color.fromRGBO(255, 255, 255, 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: browseMode == SavedSearchInboxBrowseMode.list
                  ? Align(
                      key: const ValueKey('saved-search-list-mode'),
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width / 2,
                        child: const EmmaUiAnchorTarget(
                          // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchPcListMode
                          anchorKey:
                              'network_monitoring.saved_search.pc.list_mode',
                          child: _SavedSearchesSidebarPanel(),
                        ),
                      ),
                    )
                  : showSidebarWithInbox
                      ? const EmmaUiAnchorTarget(
                          // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchPcSequentialMode
                          anchorKey:
                              'network_monitoring.saved_search.pc.sequential_mode',
                          child: Row(
                            key: ValueKey('saved-search-sequential-mode'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 430,
                                child: _SavedSearchesSidebarPanel(),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: EmmaUiAnchorTarget(
                                  // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchPcInboxPanel
                                  anchorKey:
                                      'network_monitoring.saved_search.pc.inbox_panel',
                                  child: SavedSearchInboxPanel(),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const EmmaUiAnchorTarget(
                          // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchPcInboxMode
                          anchorKey:
                              'network_monitoring.saved_search.pc.inbox_mode',
                          child: SizedBox(
                            key: ValueKey('saved-search-inbox-mode'),
                            width: double.infinity,
                            child: EmmaUiAnchorTarget(
                              // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchPcInboxPanel
                              anchorKey:
                                  'network_monitoring.saved_search.pc.inbox_panel',
                              child: SavedSearchInboxPanel(),
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedSearchesSidebarPanel extends ConsumerWidget {
  const _SavedSearchesSidebarPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final pageAsync = ref.watch(savedSearchesWithCountersProvider);
    final browseMode = ref.watch(savedSearchInboxBrowseModeProvider);
    final allNewMode = ref.watch(savedSearchAllNewModeProvider);

    final bool isSequentialSidebar =
        browseMode == SavedSearchInboxBrowseMode.allNew &&
            allNewMode == SavedSearchAllNewMode.sequential;

    return EmmaUiAnchorTarget(
      // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchPcSidebarPanel
      anchorKey: 'network_monitoring.saved_search.pc.sidebar_panel',
      child: Container(
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: Column(
          children: [
            _SavedSearchesFiltersHeader(
              isSequentialSidebar: isSequentialSidebar,
            ),
            const Divider(height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    if (isSequentialSidebar)
                      EmmaUiAnchorTarget(
                        // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchPcSequentialNotice
                        anchorKey:
                            'network_monitoring.saved_search.pc.sequential_notice',
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: theme.textFieldColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: theme.dashboardBoarder),
                          ),
                          child: Text(
                            'Sequential mode — current search is highlighted'.tr,
                            style: TextStyle(
                              color: theme.textColor.withOpacity(0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    const Expanded(
                      child: EmmaUiAnchorTarget(
                        // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchPcList
                        anchorKey: 'network_monitoring.saved_search.pc.list',
                        child: SaveSearchListViewWidget(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            pageAsync.when(
              data: (pageData) => _SavedSearchesPaginationFooter(
                pageData: pageData,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedSearchesFiltersHeader extends ConsumerWidget {
  final bool isSequentialSidebar;

  const _SavedSearchesFiltersHeader({
    required this.isSequentialSidebar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final query = ref.watch(savedSearchesListQueryProvider);
    final hasNew = ref.watch(savedSearchesListHasNewProvider);
    final hasResults = ref.watch(savedSearchesListHasResultsProvider);
    final enableNotifications =
        ref.watch(savedSearchesListEnableNotificationsProvider);
    final enableEmailNotifications =
        ref.watch(savedSearchesListEnableEmailNotificationsProvider);
    final scope = ref.watch(savedSearchesListScopeProvider);
    final ordering = ref.watch(savedSearchesListOrderingProvider);

    void resetPage() {
      ref.read(savedSearchesListPageProvider.notifier).state = 1;
    }

    return EmmaUiAnchorTarget(
      // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchPcFiltersHeader
      anchorKey: 'network_monitoring.saved_search.pc.filters_header',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isSequentialSidebar
                        ? 'Searches in sequence'.tr
                        : 'Saved searches'.tr,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                EmmaUiAnchorTarget(
                  // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchPcAllNewButton
                  anchorKey:
                      'network_monitoring.saved_search.pc.all_new_button',
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(savedSearchInboxActionsProvider).openAllNewInbox(
                            mode: SavedSearchAllNewMode.merged,
                          );
                    },
                    icon: const Icon(Icons.auto_awesome_mosaic_outlined),
                    label: Text('All new ads'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.themeColor,
                      foregroundColor: theme.themeColorText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            EmmaUiAnchorTarget(
              // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchPcSearchInput
              anchorKey: 'network_monitoring.saved_search.pc.search_input',
              child: TextFormField(
                initialValue: query,
                onChanged: (value) {
                  ref.read(savedSearchesListQueryProvider.notifier).state =
                      value;
                  resetPage();
                },
                style: TextStyle(color: theme.textColor),
                decoration: InputDecoration(
                  hintText: 'Search saved searches...'.tr,
                  hintStyle: TextStyle(
                    color: theme.textColor.withOpacity(0.55),
                  ),
                  prefixIcon: Icon(Icons.search, color: theme.textColor),
                  filled: true,
                  fillColor: theme.textFieldColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: theme.dashboardBoarder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: theme.dashboardBoarder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: theme.themeColor),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: EmmaUiAnchorTarget(
                    // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchPcSortDropdown
                    anchorKey:
                        'network_monitoring.saved_search.pc.sort_dropdown',
                    child: DropdownButtonFormField<String>(
                      value: ordering,
                      dropdownColor: theme.dashboardContainer,
                      decoration: InputDecoration(
                        label: Text('Sort'.tr,style: TextStyle(color:theme.textColor),),
                        labelStyle: TextStyle(color: theme.textColor),
                        filled: true,
                        fillColor: theme.textFieldColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: theme.dashboardBoarder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: theme.dashboardBoarder),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: theme.dashboardBoarder),
                        ),
                      ),
                      style: TextStyle(color: theme.textColor),
                      items: [
                        DropdownMenuItem(
                          value: 'new_desc',
                          child: Text('Most new'.tr),
                        ),
                        DropdownMenuItem(
                          value: 'updated_desc',
                          child: Text('Recently updated'.tr),
                        ),
                        DropdownMenuItem(
                          value: 'title_asc',
                          child: Text('Title A-Z'.tr),
                        ),
                        DropdownMenuItem(
                          value: 'title_desc',
                          child: Text('Title Z-A'.tr),
                        ),
                        DropdownMenuItem(
                          value: 'created_desc',
                          child: Text('Recently created'.tr),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        ref
                            .read(
                              savedSearchesListOrderingProvider.notifier,
                            )
                            .state = value;
                        resetPage();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: EmmaUiAnchorTarget(
                    // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchPcScopeDropdown
                    anchorKey:
                        'network_monitoring.saved_search.pc.scope_dropdown',
                    child: DropdownButtonFormField<String>(
                      value: scope.isEmpty ? '__all__' : scope,
                      dropdownColor: theme.dashboardContainer,
                      decoration: InputDecoration(
                        label: Text('Scope'.tr,style: TextStyle(color:theme.textColor),),
                        labelStyle: TextStyle(color: theme.textColor),
                        filled: true,
                        fillColor: theme.textFieldColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: theme.dashboardBoarder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: theme.dashboardBoarder),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: theme.dashboardBoarder),
                        ),
                      ),
                      style: TextStyle(color: theme.textColor),
                      items: [
                        DropdownMenuItem(
                          value: '__all__',
                          child: Text('All'.tr),
                        ),
                        DropdownMenuItem(
                          value: 'client',
                          child: Text('Client'.tr),
                        ),
                        DropdownMenuItem(
                          value: 'transaction',
                          child: Text('Transaction'.tr),
                        ),
                        DropdownMenuItem(
                          value: 'unassigned',
                          child: Text('unassigned'.tr),
                        ),
                        DropdownMenuItem(
                          value: 'mixed',
                          child: Text('Assigned'.tr),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        ref.read(savedSearchesListScopeProvider.notifier).state =
                            value == '__all__' ? '' : value;
                        resetPage();
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            EmmaUiAnchorTarget(
              // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchPcFilterChips
              anchorKey: 'network_monitoring.saved_search.pc.filter_chips',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text('Has new'.tr),
                    selected: hasNew,
                    onSelected: (value) {
                      ref.read(savedSearchesListHasNewProvider.notifier).state =
                          value;
                      resetPage();
                    },
                    backgroundColor: theme.adPopBackground,
                    selectedColor: theme.themeColor,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: hasNew
                          ? theme.themeColorText
                          : theme.textColor,
                    ),
                  ),
                  FilterChip(
                    label: Text('Has results'.tr),
                    selected: hasResults,
                    onSelected: (value) {
                      ref
                          .read(
                            savedSearchesListHasResultsProvider.notifier,
                          )
                          .state = value;
                      resetPage();
                    },
                    selectedColor: theme.themeColor,
                    backgroundColor: theme.adPopBackground,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: hasResults
                          ? theme.themeColorText
                          : theme.textColor,
                    ),
                  ),
                  FilterChip(
                    label: Text('Notifications'.tr),
                    selected: enableNotifications,
                    onSelected: (value) {
                      ref
                          .read(
                            savedSearchesListEnableNotificationsProvider
                                .notifier,
                          )
                          .state = value;
                      resetPage();
                    },
                    backgroundColor: theme.adPopBackground,
                    selectedColor: theme.themeColor,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: enableNotifications
                          ? theme.themeColorText
                          : theme.textColor,
                    ),
                  ),
                  FilterChip(
                    label: Text('E-mail notifications'.tr),
                    selected: enableEmailNotifications,
                    onSelected: (value) {
                      ref
                          .read(
                            savedSearchesListEnableEmailNotificationsProvider
                                .notifier,
                          )
                          .state = value;
                      resetPage();
                    },
                    selectedColor: theme.themeColor,
                    showCheckmark: false,
                    backgroundColor: theme.adPopBackground,
                    labelStyle: TextStyle(
                      color: enableEmailNotifications
                          ? theme.themeColorText
                          : theme.textColor,
                    ),
                  ),
                  EmmaUiAnchorTarget(
                    // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchPcResetFiltersButton
                    anchorKey:
                        'network_monitoring.saved_search.pc.reset_filters_button',
                    child: TextButton.icon(
                      onPressed: () {
                        ref
                            .read(savedSearchInboxActionsProvider)
                            .resetSavedSearchesFilters();
                      },
                      icon: Icon(Icons.restart_alt, color: theme.textColor),
                      label: Text(
                        'Reset'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedSearchesPaginationFooter extends ConsumerWidget {
  final SavedSearchesWithCountersPageModel pageData;

  const _SavedSearchesPaginationFooter({
    required this.pageData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final page = ref.watch(savedSearchesListPageProvider);
    final pageSize = ref.watch(savedSearchesListPageSizeProvider);

    final totalCount = pageData.count;
    final totalPages =
        totalCount <= 0 ? 1 : ((totalCount + pageSize - 1) ~/ pageSize);
    final canGoPrev = page > 1;
    final canGoNext = page < totalPages;

    return EmmaUiAnchorTarget(
      // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchPcPaginationFooter
      anchorKey: 'network_monitoring.saved_search.pc.pagination_footer',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${'Results'.tr}: $totalCount',
                style: TextStyle(
                  color: theme.textColor.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            EmmaUiAnchorTarget(
              // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchPcPageSizeDropdown
              anchorKey:
                  'network_monitoring.saved_search.pc.page_size_dropdown',
              child: DropdownButton<int>(
                value: pageSize,
                dropdownColor: theme.dashboardContainer,
                style: TextStyle(color: theme.textColor),
                items: const [50, 100, 200]
                    .map(
                      (size) => DropdownMenuItem<int>(
                        value: size,
                        child: Text('$size per_page'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  ref.read(savedSearchesListPageSizeProvider.notifier).state =
                      value;
                  ref.read(savedSearchesListPageProvider.notifier).state = 1;
                },
              ),
            ),
            const SizedBox(width: 10),
            EmmaUiAnchorTarget(
              // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchPcPreviousPageButton
              anchorKey:
                  'network_monitoring.saved_search.pc.previous_page_button',
              child: IconButton(
                onPressed: canGoPrev
                    ? () {
                        ref.read(savedSearchesListPageProvider.notifier).state =
                            page - 1;
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
            ),
            Text(
              '$page / $totalPages',
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            EmmaUiAnchorTarget(
              // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchPcNextPageButton
              anchorKey: 'network_monitoring.saved_search.pc.next_page_button',
              child: IconButton(
                onPressed: canGoNext
                    ? () {
                        ref.read(savedSearchesListPageProvider.notifier).state =
                            page + 1;
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ),
          ],
        ),
      ),
    );
  }
}