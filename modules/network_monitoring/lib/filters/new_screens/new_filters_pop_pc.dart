import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:network_monitoring/components/nm_tag_input_widget.dart';
import 'package:network_monitoring/enum/tag_input_cache_extension.dart';
import 'package:network_monitoring/filters/new_widgets/additional_info_filtered_button.dart';
import 'package:network_monitoring/filters/new_widgets/custom_drop_down.dart';
import 'package:network_monitoring/filters/new_widgets/estate_filtered_button.dart';
import 'package:network_monitoring/filters/new_widgets/filltered_button.dart';
import 'package:network_monitoring/filters/new_widgets/key_property_button.dart';
import 'package:network_monitoring/filters/new_widgets/pc_filters_widget.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';
import 'package:network_monitoring/providers/tag_input_provider.dart';
import 'package:network_monitoring/widgets/filter/controllers.dart';
import 'package:network_monitoring/widgets/filter/dialog.dart';
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

class NewFiltersPopPc extends ConsumerStatefulWidget {
  final bool needNavigate;

  const NewFiltersPopPc({
    super.key,
    this.needNavigate = false,
  });

  @override
  ConsumerState<NewFiltersPopPc> createState() => _NewFiltersPopPcState();
}

class _NewFiltersPopPcState extends ConsumerState<NewFiltersPopPc> {
  void _clearFiltersPreservingSearchExclude() {
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

  @override
  Widget build(BuildContext context) {
    final fields = ref.watch(dropdownProvider);
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final theme = ref.watch(themeColorsProvider);

    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        Center(
          child: Container(
            width: math.max(screenWidth * 0.7, 450),
            height: math.max(screenHeight * 0.91, 400),
            decoration: BoxDecoration(
              color: theme.adPopBackground.withAlpha(80),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 10,
              ),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(height: 20),
                        AutoCompleteWidget(
                          provider: 'network_monitoring',
                          onLocationChanged: (ref, sel) {
                            ref
                                .read(networkMonitoringFilterCacheProvider.notifier)
                                .setLocationSelectionNM(sel, ref: ref);
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            FilteredButton(
                              text: 'offer_type_sell'.tr,
                              filterValue: 'sell',
                              filterKey: 'offer_type',
                              minHeight: 50,
                              minWidth: 120,
                            ),
                            const SizedBox(width: 12),
                            FilteredButton(
                              text: 'offer_type_rent'.tr,
                              filterValue: 'rent',
                              filterKey: 'offer_type',
                              minHeight: 50,
                              minWidth: 120,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'property_type'.tr,
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              alignment: WrapAlignment.start,
                              spacing: 12,
                              runSpacing: 12,
                              children: FilterPopConst.estateTypes.map((estateType) {
                                return ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 120,
                                    maxWidth: 180,
                                  ),
                                  child: SizedBox(
                                    height: 40,
                                    child: NetworkMonitoringEstateTypeFilterButton(
                                      color: theme.themeColor,
                                      text: estateType['text']!,
                                      filterValue: estateType['filterValue']!,
                                      filterKey: 'estate_type',
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Key Property Features'.tr,
                                    style: TextStyle(
                                      color: theme.textColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: KeyPropertyButton(
                                          text: 'Primary market'.tr,
                                          filterValue: 'primary',
                                          filterKey: 'market_type',
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: KeyPropertyButton(
                                          text: 'Secondary market'.tr,
                                          filterValue: 'secondary',
                                          filterKey: 'market_type',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  CustomDropdownMap(
                                    label: 'Building type'.tr,
                                    options: FilterPopConst.typeOfBuildingOptions,
                                    value: fields['building_type']!.value,
                                    onChanged: (newValue) {
                                      ref.read(dropdownProvider.notifier).updateValue(
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
                                    label: 'Building material'.tr,
                                    options: FilterPopConst.buildingMaterialOptions,
                                    value: fields['building_material']!.value,
                                    onChanged: (newValue) {
                                      ref.read(dropdownProvider.notifier).updateValue(
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
                                    label: 'Heating type'.tr,
                                    options: FilterPopConst.heatingTypeOptions,
                                    value: fields['heating_type']!.value,
                                    onChanged: (newValue) {
                                      ref.read(dropdownProvider.notifier).updateValue(
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
                                    label: 'Advertiser type'.tr,
                                    options: FilterPopConst.advertiserOptions,
                                    value: fields['advertiser_type']!.value,
                                    onChanged: (newValue) {
                                      ref.read(dropdownProvider.notifier).updateValue(
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
                            ),
                            const SizedBox(
                              height: 322,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12.0),
                                child: VerticalDivider(
                                  color: Color.fromRGBO(90, 90, 90, 1),
                                  width: 13,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: PcFiltersWidget(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'Additional Features'.tr,
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              alignment: WrapAlignment.start,
                              spacing: 12,
                              runSpacing: 12,
                              children:
                                  FilterPopConst.additionalInfo.map((additionalInfo) {
                                return ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 120,
                                    maxWidth: 180,
                                  ),
                                  child: AdditionalInfoFilteredButton(
                                    text: additionalInfo['text']!,
                                    filterKey: additionalInfo['filterKey']!,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
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
                        const SizedBox(height: 72),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          style: elevatedButtonStyleRounded10withoutPadding,
                          onPressed: _clearFiltersPreservingSearchExclude,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 380),
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
                        const SizedBox(width: 12),
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

                            if (widget.needNavigate) {
                              ref
                                  .read(navigationService)
                                  .pushNamedScreen(Routes.networkMonitoring);
                            }
                          },
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 520),
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
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}