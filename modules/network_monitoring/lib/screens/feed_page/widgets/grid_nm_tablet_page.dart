import 'dart:async';
import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_payload_type.dart';
import 'package:core/dndservice/widgets/dnd_sender.dart';
import 'package:core/dndservice/widgets/drag_feedback_builders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:network_monitoring/components/cards/selected_card.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';
import 'package:network_monitoring/pie_menu/network_monitoring.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';
import 'package:portal/feed/components/view/slected_view_provider.dart';
import 'package:portal/screens/filters/widgets/sort_feed.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';

/// Tablet-optimised grid page (800 – 1 200 px).
///
/// Key differences from [GridNMPcPage]:
/// • Horizontal padding is 16 px instead of 65 px so cards have room to breathe.
/// • Cross-axis count is capped at 2 to keep cards readable on narrow viewports.
/// • Top header bar is more compact (reduced top offset 60 → 48).
class GridNMTabletPage extends ConsumerStatefulWidget {
  const GridNMTabletPage({super.key});

  @override
  GridNMTabletPageState createState() => GridNMTabletPageState();
}

class GridNMTabletPageState extends ConsumerState<GridNMTabletPage> {
  static const int _pageSize = 20;

  final PagingController<int, MonitoringAdsModel> _pagingController =
      PagingController(firstPageKey: 1);

  Timer? _refreshDebounce;
  ProviderSubscription<dynamic>? _filtersSub;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchPage);

    _filtersSub = ref.listenManual(networkMonitoringFilterProvider, (
      prev,
      next,
    ) {
      _refreshDebounce?.cancel();
      _refreshDebounce = Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _pagingController.refresh();
      });
    }, fireImmediately: false);
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final advertisements = await ref
          .read(networkMonitoringFilterProvider.notifier)
          .fetchAdvertisementsNM(pageKey, _pageSize);

      if (advertisements.isEmpty) {
        _pagingController.appendLastPage(const <MonitoringAdsModel>[]);
        return;
      }

      final isLastPage = advertisements.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(advertisements);
      } else {
        _pagingController.appendPage(advertisements, pageKey + 1);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    _filtersSub?.close();
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardProvider = ref.watch(selectedCardProviderNM);

    // Cap at 2 columns maximum so cards stay readable on 800 px viewports.
    final grid = cardProvider.gridCount(context).clamp(1, 2);

    final theme = ref.read(themeColorsProvider);

    // Tighter padding for tablet — 16 px horizontal instead of 65 px.
    const double horizontalPadding = 16.0;
    final double adFiledSize = screenWidth - (horizontalPadding * 2) - 80;

    final count = ref.watch(networkMonitoringTotalCountProvider);

    // Slightly more conservative scaling to prevent overflow at 800px
    final double headerHeight = (((screenWidth - 800) / 400) * 8 + 30).clamp(
      30.0,
      38.0,
    );
    final double sortWidth = (((screenWidth - 800) / 400) * 50 + 110).clamp(
      110.0,
      170.0,
    );
    final double countWidth = (((screenWidth - 800) / 400) * 40 + 110).clamp(
      110.0,
      160.0,
    );
    final double resultFontSize = (((screenWidth - 800) / 400) * 3 + 11).clamp(
      11.0,
      14.0,
    );

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: CustomScrollView(
          cacheExtent: 200,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 80, bottom: 12),
                child: Row(
                  children: [
                    // Sort dropdown
                    Container(
                      decoration: BoxDecoration(
                        color: theme.dashboardContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      height: headerHeight,
                      width: sortWidth,
                      child: DropdownSortSelector(
                        isNetworkMonitoring: true,
                        isTablet: true,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Count badge
                    SizedBox(
                      height: headerHeight,
                      width: countWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.dashboardContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '$count ${'ads found'.tr}',
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: resultFontSize,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Card-type toggle
                    SizedBox(
                      height: headerHeight,
                      child: CardTypeSelector(isNetworkMonitoring: true),
                    ),
                  ],
                ),
              ),
            ),
            PagedSliverGrid<int, MonitoringAdsModel>(
              pagingController: _pagingController,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: grid,
                childAspectRatio: cardProvider.aspectRatio,
                crossAxisSpacing: cardProvider.basePadding,
                mainAxisSpacing: cardProvider.basePadding,
              ),
              builderDelegate: PagedChildBuilderDelegate<MonitoringAdsModel>(
                itemBuilder: (context, ad, index) {
                  return RepaintBoundary(
                    child: _AdGridItemTabletNM(
                      key: ValueKey(ad.id),
                      ad: ad,
                      adFiledSize: adFiledSize,
                    ),
                  );
                },
                firstPageProgressIndicatorBuilder:
                    (_) => ShimmerPlaceholderTabletNM(
                      adFiledSize: adFiledSize,
                      crossAxisCount: grid,
                    ),
                newPageProgressIndicatorBuilder:
                    (_) => ShimmerPlaceholderTabletNM(
                      adFiledSize: adFiledSize,
                      crossAxisCount: 1,
                    ),
                noItemsFoundIndicatorBuilder:
                    (_) => Center(child: AppLottie.noResults(size: 350)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

class _AdGridItemTabletNM extends ConsumerWidget {
  const _AdGridItemTabletNM({
    super.key,
    required this.ad,
    required this.adFiledSize,
  });

  final MonitoringAdsModel ad;
  final double adFiledSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themecolors = ref.watch(themeColorsProvider);
    final currentThemeMode = ref.watch(themeProvider);
    final textFieldColor =
        currentThemeMode == ThemeMode.system ? Colors.black : Colors.white;
    final textColor = themecolors.themeTextColor;
    final color = Theme.of(context).primaryColor;
    final isDefaultDarkSystem = ref.watch(isDefaultDarkSystemProvider);

    final tag = 'networkAdTablet_${ad.id}';

    return DndSender(
      payload: DndPayload(
        action: 'add_to_favorites',
        type: DndPayloadType.nm_ad,
        id: ad.id.toString(),
      ),
      feedbackBuilder:
          (context) => DragFeedbackBuilders.nmAdFeedback(
            context,
            ad.title ?? 'Property Ad',
          ),
      child: SelectedCardWidgetNM(
        isMobile: false,
        isTablet: true,
        aspectRatio: ref.watch(selectedCardProviderNM).aspectRatio,
        ad: ad,
        tag: tag,
        mainImageUrl: ad.mainImageUrl,
        isPro: ad.isPro,
        isDefaultDarkSystem: isDefaultDarkSystem,
        color: color,
        textColor: textColor,
        textFieldColor: textFieldColor,
        buildShimmerPlaceholder: ShimmerPlaceholderTabletNM(
          adFiledSize: adFiledSize,
          crossAxisCount: 1,
        ),
        buildPieMenuActions: buildPieMenuActionsNM(
          ref,
          ad,
          context,
          null,
          null,
        ),
      ),
    );
  }
}

class ShimmerPlaceholderTabletNM extends StatelessWidget {
  final double adFiledSize;
  final int crossAxisCount;

  const ShimmerPlaceholderTabletNM({
    super.key,
    required this.adFiledSize,
    required this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: adFiledSize,
      width: adFiledSize,
      child: ShimmerAdvertisementGrid(crossAxisCount: crossAxisCount),
    );
  }
}
