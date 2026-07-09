import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:portal/screens/feed/widgets/map/filters_pv_mobile_page.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_cntrl.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:core/platform/navigation_history_provider.dart';
import 'package:core/common/autocompletion/autocomplete.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

import 'components/estate_type_widget.dart';
import 'components/filter_buttons_widget.dart';
import 'components/filters_widget.dart';
import 'components/market_filters_widget.dart';
import 'components/offer_type_widget.dart';

class TabletQuickFiltersWidget extends ConsumerStatefulWidget {
  const TabletQuickFiltersWidget({super.key});

  @override
  _TabletQuickFiltersWidgetState createState() =>
      _TabletQuickFiltersWidgetState();
}

class _TabletQuickFiltersWidgetState
    extends ConsumerState<TabletQuickFiltersWidget> {
  late final LandingFilterControllers controllers;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final filterNotifier = ref.read(filterCacheProvider.notifier);

    final cache = ref.read(filterCacheProvider.notifier);
    controllers = LandingFilterControllers.fromCache(cache);

    _scrollController = ScrollController();

    ref.listenManual(filterCacheProvider, (previous, next) {
      if (next.isEmpty) {
        _syncControllersWithCache();
      }
    });
  }

  void _syncControllersWithCache() {
    final cache = ref.read(filterCacheProvider.notifier);
    controllers.minPriceController.text =
        cache.filters['min_price']?.toString() ?? '';
    controllers.maxPriceController.text =
        cache.filters['max_price']?.toString() ?? '';
    controllers.minSquareFootageController.text =
        cache.filters['min_square_footage']?.toString() ?? '';
    controllers.maxSquareFootageController.text =
        cache.filters['max_square_footage']?.toString() ?? '';
    controllers.minPricePerMeterController.text =
        cache.filters['min_price_per_meter']?.toString() ?? '';
    controllers.maxPricePerMeterController.text =
        cache.filters['max_price_per_meter']?.toString() ?? '';
    controllers.minRoomsController.text =
        cache.filters['min_rooms']?.toString() ?? '';
    controllers.maxRoomsController.text =
        cache.filters['max_rooms']?.toString() ?? '';
  }

  @override
  void dispose() {
    controllers.minPriceController.dispose();
    controllers.maxPriceController.dispose();
    controllers.minPricePerMeterController.dispose();
    controllers.maxPricePerMeterController.dispose();
    controllers.minRoomsController.dispose();
    controllers.maxRoomsController.dispose();
    controllers.minSquareFootageController.dispose();
    controllers.maxSquareFootageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? currentCountry = ref.watch(
      filterButtonProvider.select((state) => state['country']),
    );

    return Column(
      children: [
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              children: [
                const SizedBox(height: 60),

                // 1. Offer Type
                const OfferTypeWidget(dynamicBoxHeightGroupSmall: 8),

                const SizedBox(height: 20),

                // Search Heading
                Material(
                  color: Colors.transparent,
                  child: Text(
                    'Search'.tr,
                    style: AppTextStyles.interSemiBold14.copyWith(
                      fontSize: 16.sp,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 2. Search
                AutoCompleteWidget(
            onCleared: (ref) => ref.read(filterProvider.notifier).applyFiltersFromCache(ref.read(filterCacheProvider.notifier), ref),
                  provider: 'portal',
                  onLocationChanged: (ref, sel) {
                    final cache = ref.read(filterCacheProvider.notifier);
                    if (sel.isEmpty) {
                      cache.removeFilter('location_type');
                      cache.removeFilter('location_id');
                      return;
                    }
                    cache.addFilter('location_type', sel.type);
                    cache.addFilter('location_id', sel.id);
                  },
                ),

                const SizedBox(height: 25),

                // 3. Property Type
                const EstateTypeWidget(
                  dynamicSpace: 10,
                  dynamicBoxHeightGroupSmall: 10,
                ),

                const SizedBox(height: 25),

                // 4. Area & Price Filters
                FiltersWidget(
                  controllers: controllers,
                  dynamicBoxHeightGroupSmall: 8,
                  dynamiSpacerBoxWidth: 8,
                  dynamicBoxHeightGroup: 8,
                  dynamicBoxHeight: 8,
                  dynamicSpace: 8,
                  ref: ref,
                ),

                const SizedBox(height: 25),

                // 5. Market Type
                MarketFiltersWidget(
                  currentCountry: currentCountry,
                  dynamicBoxHeightGroup: 8,
                  dynamicBoxHeightGroupSmall: 8,
                  ref: ref,
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),

        // Action Buttons
        const Divider(height: 1),
        FilterButtonsWidget(
          isTablet: true,
          navigationHistoryProvider: navigationHistoryProvider,
        ),
      ],
    );
  }
}
