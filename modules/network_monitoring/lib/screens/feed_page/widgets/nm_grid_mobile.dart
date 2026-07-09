import 'dart:math' as math;

import 'package:core/ui/device_type_util.dart';
import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_payload_type.dart';
import 'package:core/dndservice/widgets/dnd_sender.dart';
import 'package:core/dndservice/widgets/drag_feedback_builders.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:network_monitoring/components/cards/selected_card.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';
import 'package:network_monitoring/pie_menu/network_monitoring.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';

class NMGridViewMobile extends ConsumerStatefulWidget {
  const NMGridViewMobile({super.key});

  @override
  ConsumerState<NMGridViewMobile> createState() => NMGridViewMobileState();
}

class NMGridViewMobileState extends ConsumerState<NMGridViewMobile> {
  static const int _pageSize = 10;

  final PagingController<int, MonitoringAdsModel> _pagingController =
      PagingController(firstPageKey: 1);

  ProviderSubscription<dynamic>? _filterSub;

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener(_fetchPage);

    _filterSub = ref.listenManual(
      networkMonitoringFilterProvider,
      (prev, next) {
        if (!mounted) return;
        _pagingController.refresh();
      },
      fireImmediately: false,
    );
  }

  Future<void> _fetchPage(int pageKey) async {
    if (!mounted) return;

    try {
      final advertisements = await ref
          .read(networkMonitoringFilterProvider.notifier)
          .fetchAdvertisementsNM(pageKey, _pageSize);

      if (!mounted) return;

      final isLastPage = advertisements.length < _pageSize;

      if (isLastPage) {
        _pagingController.appendLastPage(advertisements);
      } else {
        _pagingController.appendPage(advertisements, pageKey + 1);
      }
    } catch (error) {
      if (!mounted) return;
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardType = ref.watch(selectedCardProviderNM);
    final isListMode =
        DeviceTypeUtil.isMobile(context) && cardType == CardTypeNM.list;

    final screenWidth = MediaQuery.of(context).size.width;

    int grid = screenWidth >= 1440
        ? math.max(1, (screenWidth / 500).ceil())
        : screenWidth >= 1080
            ? 3
            : screenWidth >= 600
                ? 2
                : 1;

    grid = math.max(1, grid);

    const double maxWidth = 1080;
    const double minWidth = 350;
    const double maxDynamicPadding = 15;
    const double minDynamicPadding = 5;

    final dynamicPadding = ((screenWidth - minWidth) /
                (maxWidth - minWidth) *
                (maxDynamicPadding - minDynamicPadding) +
            minDynamicPadding)
        .clamp(minDynamicPadding, maxDynamicPadding);

    final adFiledSize = screenWidth - (dynamicPadding * 2);

    return EmmaUiAnchorTarget(
      // @emma-backend: NetworkMonitoringEmmaAnchors.feedMobileRoot
      anchorKey: 'network_monitoring.feed.mobile.root',
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: TopAppBarSize.resolve(context)),
          ),
          if (isListMode)
            PagedSliverList<int, MonitoringAdsModel>(
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate<MonitoringAdsModel>(
                itemBuilder: (context, advertisement, index) {
                  final tag = 'networkAd${advertisement.id}';
                  final cardRatio = cardType.aspectRatio;
                  final theme = ref.watch(themeColorsProvider);
                  final themeMode = ref.watch(themeProvider);

                  return EmmaUiAnchorTarget(
                    // Runtime item anchor.
                    anchorKey:
                        'network_monitoring.feed.mobile.list_card.${advertisement.id}',
                    child: DndSender(
                      useLongPress: true,
                      payload: DndPayload(
                        action: 'add_to_favorites',
                        type: DndPayloadType.nm_ad,
                        id: advertisement.id.toString(),
                        data: {
                          'advertisement': advertisement.id,
                          'advertisement_id': advertisement.id,
                          'title': advertisement.title,
                          'source': 'network_monitoring',
                        },
                      ),
                      feedbackBuilder: (context) =>
                          DragFeedbackBuilders.nmAdFeedback(
                        context,
                        advertisement.title ?? 'property_ad'.tr,
                      ),
                      child: SelectedCardWidgetNM(
                        isMobile: true,
                        aspectRatio: cardRatio,
                        ad: advertisement,
                        tag: tag,
                        mainImageUrl: advertisement.mainImageUrl,
                        isPro: advertisement.isPro,
                        isDefaultDarkSystem:
                            ref.watch(isDefaultDarkSystemProvider),
                        color: Theme.of(context).primaryColor,
                        textColor: theme.themeTextColor,
                        textFieldColor: themeMode == ThemeMode.system
                            ? Colors.black
                            : Colors.white,
                        buildShimmerPlaceholder: ShimmerPlaceholderWidget(
                          adFiledSize: adFiledSize,
                          crossAxisCount: 1,
                        ),
                        buildPieMenuActions: buildPieMenuActionsNM(
                          ref,
                          advertisement,
                          context,
                          null,
                          null,
                        ),
                      ),
                    ),
                  );
                },
                firstPageProgressIndicatorBuilder: (_) =>
                    ShimmerPlaceholderWidget(
                  adFiledSize: adFiledSize,
                  crossAxisCount: 1,
                ),
                newPageProgressIndicatorBuilder: (_) =>
                    ShimmerPlaceholderWidget(
                  adFiledSize: adFiledSize,
                  crossAxisCount: 1,
                ),
                noItemsFoundIndicatorBuilder: (_) => EmmaUiAnchorTarget(
                  // @emma-backend: NetworkMonitoringEmmaAnchors.feedMobileNoResults
                  anchorKey: 'network_monitoring.feed.mobile.no_results',
                  child: Center(child: AppLottie.noResults(size: 450)),
                ),
              ),
            )
          else
            PagedSliverGrid<int, MonitoringAdsModel>(
              pagingController: _pagingController,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: grid,
                childAspectRatio: cardType.aspectRatio,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
              ),
              builderDelegate: PagedChildBuilderDelegate<MonitoringAdsModel>(
                itemBuilder: (context, advertisement, index) {
                  return BuildAdvertisementsList(
                    adFiledSize: adFiledSize,
                    buildShimmerPlaceholder: ShimmerPlaceholderWidget(
                      adFiledSize: adFiledSize,
                      crossAxisCount: 1,
                    ),
                    networkMonitoringFilterProvider: [advertisement],
                  );
                },
                firstPageProgressIndicatorBuilder: (_) =>
                    ShimmerPlaceholderWidget(
                  adFiledSize: adFiledSize,
                  crossAxisCount: grid,
                ),
                newPageProgressIndicatorBuilder: (_) =>
                    ShimmerPlaceholderWidget(
                  adFiledSize: adFiledSize,
                  crossAxisCount: grid,
                ),
                noItemsFoundIndicatorBuilder: (_) => EmmaUiAnchorTarget(
                  // @emma-backend: NetworkMonitoringEmmaAnchors.feedMobileNoResults
                  anchorKey: 'network_monitoring.feed.mobile.no_results',
                  child: Center(child: AppLottie.noResults(size: 450)),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: isListMode ? 16 : TopAppBarSize.withTopAppBar(context),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _filterSub?.close();
    _pagingController.dispose();
    super.dispose();
  }
}

class BuildAdvertisementsList extends ConsumerWidget {
  final List<MonitoringAdsModel> networkMonitoringFilterProvider;
  final Widget buildShimmerPlaceholder;
  final double adFiledSize;

  const BuildAdvertisementsList({
    super.key,
    required this.networkMonitoringFilterProvider,
    required this.buildShimmerPlaceholder,
    required this.adFiledSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final currentThemeMode = ref.watch(themeProvider);

    final textFieldColor =
        currentThemeMode == ThemeMode.system ? Colors.black : Colors.white;
    final textColor = themeColors.themeTextColor;
    final color = Theme.of(context).primaryColor;
    final isDefaultDarkSystem = ref.watch(isDefaultDarkSystemProvider);
    final cardRatio = ref.watch(selectedCardProviderNM).aspectRatio;

    return Column(
      children: List.generate(networkMonitoringFilterProvider.length, (index) {
        final ad = networkMonitoringFilterProvider[index];
        final tag = 'networkAd${ad.id}';

        return EmmaUiAnchorTarget(
          // Runtime item anchor.
          anchorKey: 'network_monitoring.feed.mobile.grid_card.${ad.id}',
          child: DndSender(
            useLongPress: true,
            payload: DndPayload(
              action: 'add_to_favorites',
              type: DndPayloadType.nm_ad,
              id: ad.id.toString(),
              data: {
                'advertisement': ad.id,
                'advertisement_id': ad.id,
                'title': ad.title,
                'source': 'network_monitoring',
              },
            ),
            feedbackBuilder: (context) => DragFeedbackBuilders.nmAdFeedback(
              context,
              ad.title ?? 'property_ad'.tr,
            ),
            child: SelectedCardWidgetNM(
              isMobile: true,
              aspectRatio: cardRatio,
              ad: ad,
              tag: tag,
              mainImageUrl: ad.mainImageUrl,
              isPro: ad.isPro,
              isDefaultDarkSystem: isDefaultDarkSystem,
              color: color,
              textColor: textColor,
              textFieldColor: textFieldColor,
              buildShimmerPlaceholder: buildShimmerPlaceholder,
              buildPieMenuActions: buildPieMenuActionsNM(
                ref,
                ad,
                context,
                null,
                null,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class ShimmerPlaceholderWidget extends StatelessWidget {
  final double adFiledSize;
  final int crossAxisCount;

  const ShimmerPlaceholderWidget({
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