import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:network_monitoring/components/nm_tag_input_widget.dart';
import 'package:network_monitoring/enum/tag_input_cache_extension.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';
import 'package:network_monitoring/providers/tag_input_provider.dart';
import 'package:network_monitoring/widgets/filter/fileds.dart';
import 'package:map/map_state.dart';
import 'package:core/platform/filters/filters_const.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/common/autocompletion/autocomplete.dart';
import 'package:core/common/autocompletion/provider/autocompletion_provider.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:network_monitoring/filters/new_widgets/grid_view_additional_info.dart';
import 'package:network_monitoring/filters/new_widgets/grid_view_state_type.dart';
import 'package:network_monitoring/filters/new_widgets/mobile_filters_area_widget.dart';
import 'dart:math' as math;
import 'package:network_monitoring/filters/new_widgets/custom_drop_down.dart';
import 'package:network_monitoring/filters/new_widgets/filltered_button.dart';
import 'package:network_monitoring/filters/new_widgets/key_property_button.dart';
import 'package:network_monitoring/widgets/filter/dialog.dart';

import 'package:get/get_utils/get_utils.dart';

class NewFilterPopMobile extends ConsumerWidget {
  final bool needNavigate;
  final ScrollController? scrollController;

  const NewFilterPopMobile({
    super.key,
    this.needNavigate = false,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fields = ref.watch(dropdownProvider);
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final theme = ref.read(themeColorsProvider);
    const lineSpacer =
        '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ';
    return Stack(
      children: [
        Center(
          child: Container(
            width: screenWidth,
            height: math.max(screenHeight * 0.91, 400),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 180,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                spacing: 12,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 10.0,
                    ),
                    child: Column(
                      spacing: 12,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: theme.textColor,
                                size: 20,
                              ),
                              tooltip: 'Back'.tr,
                            ),
                            ElevatedButton(
                              style: elevatedButtonStyleRounded10,
                              onPressed: () {
                                showDialog<void>(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (BuildContext context) {
                                    return SaveSearchDialog();
                                  },
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Save Search'.tr,
                                    style: const TextStyle(
                                      color: Color.fromRGBO(255, 255, 255, 1),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  AppIcons.heart(
                                    color: const Color.fromRGBO(255, 255, 255, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                             AutoCompleteWidget(
                              provider: 'network_monitoring',
                              onLocationChanged: (ref, sel) {
                                ref.read(networkMonitoringFilterCacheProvider.notifier).setLocationSelectionNM(sel);
                              },
                            ),

                        Row(
                          spacing: 10,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: FilteredButton(
                                text: 'offer_type_sell'.tr,
                                filterValue: 'sell',
                                filterKey: 'offer_type',
                                minHeight: 48,
                              ),
                            ),
                            Expanded(
                              child: FilteredButton(
                                text: 'offer_type_rent'.tr,
                                filterValue: 'rent',
                                filterKey: 'offer_type',
                                minHeight: 48,
                              ),
                            ),
                          ],
                        ),
                        const Text(lineSpacer, style: TextStyle(), maxLines: 1),
                        Column(
                          spacing: 10,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'property_type'.tr,
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            GridViewEstateTypes(
                              estateTypes: FilterPopConst.estateTypes,
                            ),
                            Column(
                              spacing: 16,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Key Property Features'.tr,
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: KeyPropertyButton(
                                        text: 'Primary market'.tr,
                                        filterValue: 'primary',
                                        filterKey: 'market_type',
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: KeyPropertyButton(
                                        text: 'Secondary market'.tr,
                                        filterValue: 'secondary',
                                        filterKey: 'market_type',
                                      ),
                                    ),
                                  ],
                                ),

                                CustomDropdownMap(
                                  label:
                                      fields['building_type']!
                                          .label, // <- label from state
                                  options: FilterPopConst.typeOfBuildingOptions,
                                  value:
                                      fields['building_type']!
                                          .value, // <- filterKey from state
                                  onChanged: (newValue) {
                                    ref
                                        .read(dropdownProvider.notifier)
                                        .updateValue(
                                          'building_type',
                                          newValue ?? '',
                                          ref,
                                        );
                                  },
                                  width: 405,
                                  height: 46,
                                ),

                                const SizedBox(height: 16),

                                CustomDropdownMap(
                                  label: fields['building_material']!.label,
                                  options:
                                      FilterPopConst.buildingMaterialOptions,
                                  value: fields['building_material']!.value,
                                  onChanged: (newValue) {
                                    ref
                                        .read(dropdownProvider.notifier)
                                        .updateValue(
                                          'building_material',
                                          newValue ?? '',
                                          ref,
                                        );
                                  },
                                  width: 405,
                                  height: 46,
                                ),

                                const SizedBox(height: 16),

                                CustomDropdownMap(
                                  label: fields['heating_type']!.label,
                                  options: FilterPopConst.heatingTypeOptions,
                                  value: fields['heating_type']!.value,
                                  onChanged: (newValue) {
                                    ref
                                        .read(dropdownProvider.notifier)
                                        .updateValue(
                                          'heating_type',
                                          newValue ?? '',
                                          ref,
                                        );
                                  },
                                  width: 405,
                                  height: 46,
                                ),

                                const SizedBox(height: 16),

                                CustomDropdownMap(
                                  label: fields['advertiser_type']!.label,
                                  options: FilterPopConst.advertiserOptions,
                                  value: fields['advertiser_type']!.value,
                                  onChanged: (newValue) {
                                    ref
                                        .read(dropdownProvider.notifier)
                                        .updateValue(
                                          'advertiser_type',
                                          newValue ?? '',
                                          ref,
                                        );
                                  },
                                  width: 405,
                                  height: 46,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Text(
                          lineSpacer,
                          style: TextStyle(
                            color: Color.fromRGBO(90, 90, 90, 1),
                          ),
                          maxLines: 1,
                        ),
                        const MobileFiltersAreaWidget(lineSpacer: lineSpacer),
                        const Text(
                          lineSpacer,
                          style: TextStyle(
                            color: Color.fromRGBO(90, 90, 90, 1),
                          ),
                          maxLines: 1,
                        ),
                        Column(
                          spacing: 10,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'Market type'.tr,
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            GridViewAdditionalInfo(
                              additionalInfo: FilterPopConst.additionalInfo,
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            NMTagInputWidget(
                              label: 'Search'.tr,
                              hintText: 'keywords'.tr,
                              prefixIcon: Icons.search,
                              providerId: 'nm_search',
                              useSearchController: true,
                              onItemsChanged: (items) {
                                ref.syncNMTagInputToCache(
                                  providerId: 'nm_search',
                                  cacheKey: 'search',
                                  cache: ref.read(
                                    networkMonitoringFilterCacheProvider.notifier,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            NMTagInputWidget(
                              label: 'Exclude'.tr,
                              hintText: 'words to skip'.tr,
                              prefixIcon: Icons.block,
                              providerId: 'nm_exclude',
                              useSearchController: false,
                              onItemsChanged: (items) {
                                ref.syncNMTagInputToCache(
                                  providerId: 'nm_exclude',
                                  cacheKey: 'exclude',
                                  cache: ref.read(
                                    networkMonitoringFilterCacheProvider.notifier,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 4.0),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  Container(
                    height: 68,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           ElevatedButton(
                          style: elevatedButtonStyleRounded10withoutPadding,
                          onPressed:()=>_clearFiltersPreservingSearchExclude(ref),
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 140),
                            height: 40,
                            decoration: BoxDecoration(
                              color: theme.dashboardContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Center(
                              child: Material(
                                color: Colors.transparent,
                                child: Text(
                                  'Clear'.tr,
                                  style: AppTextStyles.interMedium12dark.copyWith(
                                    color: theme.textColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                              const SizedBox(width: 20),
                              ElevatedButton(
                          style: elevatedButtonStyleRounded10withoutPadding,
                          onPressed: () {
                            ref
                                .read(networkMonitoringFilterProvider.notifier)
                                .applyFiltersFromCacheNM(
                                  ref.read(
                                    networkMonitoringFilterCacheProvider.notifier,
                                  ),
                                  ref,
                                );
                            Navigator.of(context).pop();
                               if (needNavigate) {
                              ref
                                  .read(navigationService)
                                  .pushNamedScreen(Routes.networkMonitoring);
                            }
                          
                          },
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 140),
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.themeColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Center(
                                child: Text(
                                  'Search'.tr,
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  void _clearFiltersPreservingSearchExclude(WidgetRef ref) {
    final cache = ref.read(networkMonitoringFilterCacheProvider.notifier);
    final currentSearchItems =
        List<String>.from(ref.read(nmTagInputProvider('nm_search')).items);
    final currentExcludeItems =
        List<String>.from(ref.read(nmTagInputProvider('nm_exclude')).items);

    final preservedSearch = currentSearchItems.join(',');
    final preservedExclude = currentExcludeItems.join(',');

    // Clear all standard filters/UI, but do NOT clear tag inputs.
    cache.clearFiltersNM();
    ref.read(networkMonitoringFilterButtonProvider.notifier).clearUiFiltersNM(ref);
    ref.read(myTextFieldViewModelProvider('network_monitoring').notifier).clear();

    // Restore search / exclude back into cache.
    if (preservedSearch.trim().isNotEmpty) {
      cache.setSearchQueryNM(preservedSearch);
    }

    if (preservedExclude.trim().isNotEmpty) {
      cache.setExcludeQueryNM(preservedExclude);
    }

    // Keep current viewport, clear only map selection.
    clearMapSelectionKeepViewport(ref, refreshPinsAfter: false);

    // Apply once after everything is ready.
    ref
        .read(networkMonitoringFilterProvider.notifier)
        .applyFiltersFromCacheNM(cache, ref);

    refreshMapPins(ref);
  }

}
