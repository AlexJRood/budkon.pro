import 'dart:ui';

import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/export.dart';
import 'package:pie_menu/pie_menu.dart';

import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_payload_type.dart';
import 'package:core/dndservice/widgets/dnd_sender.dart';
import 'package:core/dndservice/widgets/drag_feedback_builders.dart';
import 'package:network_monitoring/pie_menu/saved_search_nm.dart';
import 'package:network_monitoring/providers/saved_search/inbox_models.dart';
import 'package:network_monitoring/providers/saved_search/inbox_providers.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';
import 'package:network_monitoring/screens/list_with_save_searches/widget/saved_search_card.dart';
import 'package:network_monitoring/widgets/filter/fileds.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/common/drad_scroll_widget.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';

class SaveSearchListViewWidget extends ConsumerStatefulWidget {
  final bool isMobile;

  const SaveSearchListViewWidget({
    super.key,
    this.isMobile = false,
  });

  @override
  ConsumerState<SaveSearchListViewWidget> createState() =>
      _SaveSearchListViewWidgetState();
}

class _SaveSearchListViewWidgetState
    extends ConsumerState<SaveSearchListViewWidget> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _applySearch(SavedSearchWithCountersModel search) {
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

void _openResultsPanel(SavedSearchWithCountersModel search) {
  final browseMode = ref.read(savedSearchInboxBrowseModeProvider);
  final allNewMode = ref.read(savedSearchAllNewModeProvider);

  if (browseMode == SavedSearchInboxBrowseMode.allNew &&
      allNewMode == SavedSearchAllNewMode.sequential) {
    ref.read(selectedSavedSearchIdProvider.notifier).state = search.id;
    ref.read(savedSearchInboxPageProvider.notifier).state = 1;
    ref.invalidate(selectedSavedSearchProvider);
    ref.invalidate(savedSearchInboxProvider);
    return;
  }

  ref.read(savedSearchInboxActionsProvider).openSingleSearchInbox(search.id);
}
  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final savedSearchesAsyncValue = ref.watch(savedSearchesWithCountersProvider);
    final selectedId = ref.watch(selectedSavedSearchIdProvider);

    final screenWidth = MediaQuery.of(context).size.width;

    double calculateDynamicSize(double width) {
      if (widget.isMobile) return double.infinity;
      if (width <= 400) return width;
      if (width >= 1440) {
        return width / 2 > 1500 ? 1500 : width / 2;
      }

      final factor = (width - 400) / (1440 - 400);
      final interpolatedSize = width * (1 - (factor * 0.5));
      return interpolatedSize;
    }

    final cardWidth = calculateDynamicSize(screenWidth);

    return savedSearchesAsyncValue.when(
      data: (pageData) {
        final data = pageData.results;

        if (data.isEmpty) {
          return Center(child: AppLottie.noResults(size: 260));
        }

        if (selectedId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || data.isEmpty) return;
            ref.read(selectedSavedSearchIdProvider.notifier).state = data.first.id;
          });
        }

        return SizedBox.expand(
          child: DragScrollView(
            controller: _scrollController,
            scrollDirection: Axis.vertical,
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.only(top: TopAppBarSize.withTopAppBar(context),bottom:BottomBarSize.resolve(context) ),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final search = data[index];
                final isSelected = selectedId == search.id;

                return DndSender(
                  payload: DndPayload(
                    type: DndPayloadType.savedSearch,
                    action: 'assign_saved_search',
                    id: search.id.toString(),
                    data: search.toJson(),
                  ),
                  feedbackBuilder: (context) =>
                      DragFeedbackBuilders.savedSearchFeedback(
                    context,
                    search.title ?? 'Saved Search'.tr,
                  ),
                  useLongPress: true,
                  child: Center(
                    child: Container(
                      color: Colors.transparent,
                      width: cardWidth,
                      child: PieMenu(
                        theme: PieTheme.of(context).copyWith(
                          overlayColor: (() {
                            final bool uiIsDark =
                                theme.textColor.computeLuminance() > 0.5;
                            final base = uiIsDark ? Colors.black : Colors.white;
                            return base.withOpacity(0.70);
                          })(),
                        ),
                        actions: buildPieMenuActionsNMsavedSearch(
                          ref,
                          search,
                          search.id,
                          context,
                          theme,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: SavedSearchNmCard(
                            search: search,
                            selected: isSelected,
                            isMobile: widget.isMobile,
                            onSelect: () => _openResultsPanel(search),
                            onApply: () => _applySearch(search),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      loading: () => Center(child: AppLottie.loading()),
      error: (error, stack) => Center(child: AppLottie.error(size: 260)),
    );
  }
}