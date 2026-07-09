import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:network_monitoring/widgets/filter/offer_type_widget.dart';
import 'package:core/common/autocompletion/autocomplete.dart';
import 'package:network_monitoring/widgets/filter/estate_type_widget.dart';
import 'package:network_monitoring/widgets/filter/filters_widget.dart';
import 'package:network_monitoring/widgets/filter/market_filters_widget.dart';
import 'package:network_monitoring/widgets/filter/filter_buttons_widget.dart';
import 'package:network_monitoring/widgets/filter/controllers.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class TabletFilterMonitoringWidget extends ConsumerWidget {
  const TabletFilterMonitoringWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final controllers = ref.watch(nmControllersProvider);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              spacing: 12,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 50),
                // 1. Offer Type
                OfferTypeWidget(dynamicBoxHeightGroupSmall: 8, isTablet: true),

                // add a heading named search
                Material(
                  color: Colors.transparent,
                  child: Text(
                    'Search'.tr,
                    style: AppTextStyles.interSemiBold.copyWith(
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                ),

                // 2. Search
                AutoCompleteWidget(
                  provider: 'network_monitoring',
                  isTablet: true,
                  onLocationChanged: (ref, location) {
                    // Handle location change if needed
                  },
                ),

                // 3. Property Type
                const EstateTypeWidget(
                  dynamicSpace: 10,
                  dynamicBoxHeightGroupSmall: 10,
                  isTablet: true,
                ),

                // 4. Market Type
                MarketFiltersWidget(
                  currentCountry: null,
                  dynamicBoxHeightGroup: 8,
                  dynamicBoxHeightGroupSmall: 8,
                  isTablet: true,
                  ref: ref,
                ),

                // 5. Area & Price Filters
                FiltersWidget(
                  minSquareFootageController:
                      controllers.minSquareFootageController,
                  maxSquareFootageController:
                      controllers.maxSquareFootageController,
                  minPriceController: controllers.minPriceController,
                  maxPriceController: controllers.maxPriceController,
                  minPricePerMeterController:
                      controllers.minPricePerMeterController,
                  maxPricePerMeterController:
                      controllers.maxPricePerMeterController,
                  minRoomsController: controllers.minRoomsController,
                  maxRoomsController: controllers.maxRoomsController,
                  dynamicBoxHeightGroupSmall: 8,
                  dynamiSpacerBoxWidth: 8,
                  dynamicBoxHeightGroup: 8,
                  dynamicBoxHeight: 8,
                  dynamicSpace: 8,
                  isTablet: true,
                  ref: ref,
                ),
              ],
            ),
          ),
        ),

        // 6. Action Buttons (Footer)
        const Divider(height: 1),
        const FilterButtonsWidget(
          isTablet: true,
          navigationHistoryProvider: null, // Update if needed
        ),
      ],
    );
  }
}
