import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/components/cards/real_state_and_home_for_sale_card.dart';
import 'package:core/common/loading_widgets.dart';
import 'dart:math' as math;
import 'package:core/theme/design.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';
import 'package:get/get_utils/get_utils.dart';

class SavedSearchGridView extends ConsumerStatefulWidget {
  final bool isMobile;
  const SavedSearchGridView({super.key, this.isMobile = false});

  @override
  SavedSearchGridViewState createState() => SavedSearchGridViewState();
}

class SavedSearchGridViewState extends ConsumerState<SavedSearchGridView> {
  static const int _pageSize = 20;
  final PagingController<int, MonitoringAdsModel> _pagingController =
      PagingController(firstPageKey: 1);

  // manual Riverpod subscription
  ProviderSubscription<dynamic>? _filterSub;

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener(_fetchPage);

    // przeniesiony nasłuch z build() do initState()
    _filterSub = ref.listenManual(
      networkMonitoringFilterProvider,
      (prev, next) {
        if (!mounted) return;
        _pagingController.refresh();
      },
    );
  }

  Future<void> _fetchPage(int pageKey) async {
    if (!mounted) return;
    try {
      final listingProvider = await ref
          .read(networkMonitoringFilterProvider.notifier)
          .fetchAdvertisementsNM(pageKey, _pageSize);

      if (!mounted) return;

      final isLastPage = listingProvider.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(listingProvider);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(listingProvider, nextPageKey);
      }
    } catch (error) {
      if (!mounted) return;
      _pagingController.error = error;
    }
  }

  @override
  void dispose() {
    _filterSub?.close(); // zamknij subskrypcję
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ❌ NIE słuchamy już tutaj: ref.listen(...)

    final double screenWidth = MediaQuery.of(context).size.width;

    int grid;
    if (screenWidth >= 1440) {
      grid = math.max(1, (screenWidth / 800).ceil());
    } else if (screenWidth >= 1080) {
      grid = 3;
    } else if (screenWidth >= 600) {
      grid = 2;
    } else {
      grid = 1;
    }

    const double maxWidth = 1920;
    const double minWidth = 1080;
    const double maxDynamicPadding = 40;
    const double minDynamicPadding = 15;

    double dynamicPadding = (screenWidth - minWidth) /
            (maxWidth - minWidth) *
            (maxDynamicPadding - minDynamicPadding) +
        minDynamicPadding;
    dynamicPadding = dynamicPadding.clamp(minDynamicPadding, maxDynamicPadding);

    const double minBaseTextSize = 5;
    const double maxBaseTextSize = 15;
    double baseTextSize = (screenWidth - minWidth) /
            (maxWidth - minWidth) *
            (maxBaseTextSize - minBaseTextSize) +
        minBaseTextSize;
    baseTextSize = baseTextSize.clamp(minBaseTextSize, maxBaseTextSize);

    final double adFiledSize = (screenWidth - (dynamicPadding * 2) - 80);

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: PagedGridView<int, MonitoringAdsModel>(
                  pagingController: _pagingController,
                  padding: EdgeInsets.symmetric(
                    horizontal: dynamicPadding,
                    vertical: 65,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: grid,
                    childAspectRatio: 1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  builderDelegate:
                      PagedChildBuilderDelegate<MonitoringAdsModel>(
                    itemBuilder: (context, advertisement, index) {
                      return BuildAdvertisementsList(
                        adFiledSize: adFiledSize,
                        buildShimmerPlaceholder: ShimmerPlaceholderWidget(
                          adFiledSize: adFiledSize,
                          crossAxisCount: 1,
                        ),
                        networkMonitoringFilterProvider: [advertisement],
                        isMobile: widget.isMobile,
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
                      crossAxisCount: 1,
                    ),
                    noItemsFoundIndicatorBuilder: (_) => Center(
                      child: Text(
                        'no_search_results'.tr,
                        style: AppTextStyles.interLight16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BuildAdvertisementsList extends ConsumerWidget {
  final List<MonitoringAdsModel> networkMonitoringFilterProvider;
  final Widget buildShimmerPlaceholder;
  final double adFiledSize;
  final bool isMobile;

  const BuildAdvertisementsList({
    super.key,
    required this.networkMonitoringFilterProvider,
    required this.buildShimmerPlaceholder,
    required this.adFiledSize,
    this.isMobile = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: List.generate(networkMonitoringFilterProvider.length, (index) {
        final ad = networkMonitoringFilterProvider[index];
        final tag = 'nm_search_mobile${ad.id}-${UniqueKey().toString()}';

        return RealStateAndHomeForSaleCard(
          ad: ad,
          keyTag: tag,
          isMobile: isMobile,
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
      child: ShimmerAdvertisementGrid(
        crossAxisCount: crossAxisCount,
      ),
    );
  }
}
