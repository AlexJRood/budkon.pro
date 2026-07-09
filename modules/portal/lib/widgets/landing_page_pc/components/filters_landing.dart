import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:portal/screens/filters/filters_page.dart';
import 'package:portal/screens/landing_page/providers/landing_page_provider.dart';
import 'package:portal/screens/pop_pages/pages/view_pop_changer_page.dart';
import 'package:portal/widgets/landing_page_pc/components/category_buttons.dart';
import 'package:portal/widgets/landing_page_pc/components/filter_buttons.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/platform/filters/filters_const.dart';
import 'package:portal/screens/filter_landing_page/components/filters_components.dart';

enum PopupType { location, property, price, meter }

final activePopupProvider = StateProvider<PopupType?>((ref) => null);

class FilterLandingpageContent extends ConsumerWidget {
  final double paddingDynamic;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final Map<PopupType, GlobalKey> popupKeys;
  final Map<PopupType, LayerLink> popupLinks;
  final void Function(PopupType type) togglePopup;
  final bool isTablet;
  final String heroTag;

  const FilterLandingpageContent({
    super.key,
    required this.paddingDynamic,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.popupKeys,
    required this.popupLinks,
    required this.togglePopup,
    required this.heroTag,
    this.isTablet = false,
  });

  bool _isBuyCategory(BuildContext context) =>
      selectedCategory.trim().toLowerCase() == 'Buy'.tr.toLowerCase();

  bool _isRentCategory(BuildContext context) =>
      selectedCategory.trim().toLowerCase() == 'Rent'.tr.toLowerCase();

  bool _isDevelopersCategory(BuildContext context) =>
      selectedCategory.trim().toLowerCase() == 'Developers'.tr.toLowerCase();

  String? _offerTypeFromCategory(BuildContext context) {
    if (_isRentCategory(context)) return 'rent';
    if (_isBuyCategory(context) || _isDevelopersCategory(context)) return 'sell';
    return null;
  }

  Map<String, dynamic> _buildUiStateFromCache(WidgetRef ref) {
    final cacheNotifier = ref.read(filterCacheProvider.notifier);
    final cacheFilters = Map<String, dynamic>.from(cacheNotifier.filters);
    final uiState = Map<String, dynamic>.from(cacheFilters);

    final estateRaw = uiState[FilterPopConst.estateType];
    final estateValues = FilterPopConst.parseCsv(estateRaw);

    if (estateValues.isNotEmpty) {
      uiState[FilterPopConst.estateType] = estateValues;
    } else {
      uiState.remove(FilterPopConst.estateType);
    }

    for (final key in FilterPopConst.additionalBoolKeys) {
      if (uiState.containsKey(key)) {
        uiState[key] = FilterPopConst.toBool(uiState[key]);
      }
    }

    return uiState;
  }

  void _syncLandingFiltersToUiState(BuildContext context, WidgetRef ref) {
    final cache = ref.read(filterCacheProvider.notifier);
    final ui = ref.read(filterButtonProvider.notifier);

    final offerType = _offerTypeFromCategory(context);
    if (offerType != null) {
      cache.addFilter(FilterPopConst.offerType, offerType);
    }

    if (_isDevelopersCategory(context)) {
      cache.addFilter(FilterPopConst.marketType, 'primary');
    }

    final selectedProperty = ref.read(selectedPropertyProvider);
    if (selectedProperty.isNotEmpty) {
      cache.addFilter(FilterPopConst.estateType, selectedProperty);
    }

    final uiState = _buildUiStateFromCache(ref);

    if (offerType != null) {
      uiState[FilterPopConst.offerType] = offerType;
    }

    if (_isDevelopersCategory(context)) {
      uiState[FilterPopConst.marketType] = 'primary';
    }

    if (selectedProperty.isNotEmpty) {
      uiState[FilterPopConst.estateType] = <String>[selectedProperty];
    } else {
      uiState.remove(FilterPopConst.estateType);
    }

    ui.loadSavedFilters(uiState);
  }

  void _applyAndNavigate(BuildContext context, WidgetRef ref) {
    _syncLandingFiltersToUiState(context, ref);

    ref.read(filterProvider.notifier).applyFiltersFromCache(
          ref.read(filterCacheProvider.notifier),
          ref,
        );

    ref.read(filterProvider.notifier).applyFilters(ref).whenComplete(() {
      final data = ref.watch(filterCacheProvider);
      if (kDebugMode) {
        debugPrint(data.toString());
      }
    });

    final selectedFeedView = ref.read(selectedFeedViewProvider);
    ref.read(navigationService).pushNamedReplacementScreen(selectedFeedView);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final selectedPropertyRaw = ref.watch(selectedPropertyProvider);
    final selectedPropertyLabel =
        FilterPopConst.estateTypeTextFromValue(selectedPropertyRaw);

    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;
        final bool isDoubleDecer = containerWidth < 900 || isTablet;
        final bool isLower700 = containerWidth < 700;

        return SizedBox(
          height: isDoubleDecer ? 200 : 140,
          width: containerWidth,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                color: theme.adPopBackground.withAlpha(60),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 10,
                  children: [
                    CategorySelector(
                      selectedCategory: selectedCategory,
                      onCategorySelected: onCategorySelected,
                      tabs: [
                        'Buy'.tr,
                        'Rent'.tr,
                        'Developers'.tr,
                      ],
                      isTablet: isTablet,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Column(
                        spacing: 10,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: isDoubleDecer ? 20 : 10,
                            children: [
                              Flexible(
                                child: _buildSelectionButton(
                                  title: 'Location'.tr,
                                  value: ref.watch(selectedLocationProvider).isEmpty
                                      ? 'All locations'.tr
                                      : ref.watch(selectedLocationProvider),
                                  onPressed: () =>
                                      togglePopup(PopupType.location),
                                  buttonKey: popupKeys[PopupType.location]!,
                                  layerLink: popupLinks[PopupType.location]!,
                                ),
                              ),
                              Flexible(
                                child: _buildSelectionButton(
                                  title: 'Property type'.tr,
                                  value: selectedPropertyRaw.isEmpty
                                      ? 'All property types'.tr
                                      : (selectedPropertyLabel ??
                                          selectedPropertyRaw),
                                  onPressed: () =>
                                      togglePopup(PopupType.property),
                                  buttonKey: popupKeys[PopupType.property]!,
                                  layerLink: popupLinks[PopupType.property]!,
                                ),
                              ),
                              if (!isDoubleDecer) ...[
                                Flexible(
                                  child: _buildSelectionButton(
                                    title: 'Price range'.tr,
                                    value: ref
                                            .watch(selectedPriceRangeProvider)
                                            .isEmpty
                                        ? 'Choose price range'.tr
                                        : ref.watch(selectedPriceRangeProvider),
                                    onPressed: () =>
                                        togglePopup(PopupType.price),
                                    buttonKey: popupKeys[PopupType.price]!,
                                    layerLink: popupLinks[PopupType.price]!,
                                  ),
                                ),
                                Flexible(
                                  child: _buildSelectionButton(
                                    title: 'Meter range'.tr,
                                    value: ref
                                            .watch(selectedMeterRangeProvider)
                                            .isEmpty
                                        ? 'Choose meter range'.tr
                                        : ref.watch(selectedMeterRangeProvider),
                                    onPressed: () =>
                                        togglePopup(PopupType.meter),
                                    buttonKey: popupKeys[PopupType.meter]!,
                                    layerLink: popupLinks[PopupType.meter]!,
                                  ),
                                ),
                              ],
                              Hero(
                              tag: 'landing-filters-tag',
                              child: Container(
                                height: 60,
                                width: isDoubleDecer
                                    ? isLower700
                                        ? 140
                                        : 200
                                    : 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: theme.textColor),
                                ),
                                child: ElevatedButton(
                                  style: elevatedButtonStyleRounded10,
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        opaque: false,
                                        pageBuilder: (_, __, ___) =>
                                            FiltersPage(
                                           tag: 'landing-filters-tag',
                                          isNeedToNavigate: true,
                                        ),
                                        transitionsBuilder:
                                            (_, anim, __, child) {
                                          return FadeTransition(
                                            opacity: anim,
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      AppIcons.filterAlt(
                                          color: theme.textColor),
                                      if (isDoubleDecer) ...[
                                        const SizedBox(width: 15),
                                        Text(
                                          'Filters'.tr,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: theme.textColor,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                              if (!isDoubleDecer) ...[
                                Container(
                                  height: 60,
                                  width: 140,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: theme.adPopBackground,
                                    ),
                                  ),
                                  child: ElevatedButton(
                                    style: buttonStyleRounded10ThemeRed,
                                    onPressed: () => _applyAndNavigate(context, ref),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          AppIcons.search(
                                            color: AppColors.white,
                                          ),
                                          const SizedBox(width: 15),
                                          Text(
                                            'Search'.tr,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: isDoubleDecer ? 20 : 10,
                            children: [
                              if (isDoubleDecer) ...[
                                Flexible(
                                  child: _buildSelectionButton(
                                    title: 'Price range'.tr,
                                    value: ref
                                            .watch(selectedPriceRangeProvider)
                                            .isEmpty
                                        ? 'Choose price range'.tr
                                        : ref.watch(selectedPriceRangeProvider),
                                    onPressed: () =>
                                        togglePopup(PopupType.price),
                                    buttonKey: popupKeys[PopupType.price]!,
                                    layerLink: popupLinks[PopupType.price]!,
                                  ),
                                ),
                                Flexible(
                                  child: _buildSelectionButton(
                                    title: 'Meter range'.tr,
                                    value: ref
                                            .watch(selectedMeterRangeProvider)
                                            .isEmpty
                                        ? 'Choose meter range'.tr
                                        : ref.watch(selectedMeterRangeProvider),
                                    onPressed: () =>
                                        togglePopup(PopupType.meter),
                                    buttonKey: popupKeys[PopupType.meter]!,
                                    layerLink: popupLinks[PopupType.meter]!,
                                  ),
                                ),
                                Container(
                                  height: 60,
                                  width: isLower700 ? 140 : 200,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: theme.adPopBackground,
                                    ),
                                  ),
                                  child: ElevatedButton(
                                    style: buttonStyleRounded10ThemeRed,
                                    onPressed: () => _applyAndNavigate(context, ref),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          AppIcons.search(
                                            color: AppColors.white,
                                          ),
                                          const SizedBox(width: 15),
                                          Text(
                                            'Search'.tr,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectionButton({
    required String title,
    required String value,
    required VoidCallback onPressed,
    required GlobalKey buttonKey,
    required LayerLink layerLink,
  }) {
    return CompositedTransformTarget(
      link: layerLink,
      child: SelectionButton(
        isMobile: false,
        title: title,
        value: value,
        onPressed: onPressed,
        buttonKey: buttonKey,
      ),
    );
  }
}