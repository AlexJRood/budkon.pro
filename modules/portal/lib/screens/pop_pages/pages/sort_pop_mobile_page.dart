import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:portal/feed/components/view/slected_view_provider.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:portal/screens/filters/widgets/components/sort_button.dart';
import 'package:portal/screens/pop_pages/pages/view_settings_page.dart';
import 'package:core/common/currency_config.dart';
import 'package:core/common/install_popup.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';



class SortPopMobilePage extends ConsumerStatefulWidget {
  final ThemeColors theme;
  final bool isUserLoggedIn;
  final ScrollController? scrollController;

  final bool isMobile;

  const SortPopMobilePage({
      super.key,
      required this.isUserLoggedIn,
      required this.theme,
      this.scrollController,
      this.isMobile = false,

      });

  @override
  SortPopMobileState createState() => SortPopMobileState();
}

class SortPopMobileState extends ConsumerState<SortPopMobilePage> {
  late TextEditingController searchController;
  late TextEditingController excludeController;
  late TextEditingController minPriceController;
  late TextEditingController maxPriceController;

  @override
  void initState() {
    super.initState();
    final filterNotifier = ref.read(filterProvider.notifier);
    searchController = TextEditingController(text: filterNotifier.searchQuery);
    excludeController =
        TextEditingController(text: filterNotifier.excludeQuery);
    minPriceController = TextEditingController(
        text: filterNotifier.filters['min_price']?.toString());
    maxPriceController = TextEditingController(
        text: filterNotifier.filters['max_price']?.toString());
  }

  @override
  void dispose() {
    searchController.dispose();
    excludeController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final theme = widget.theme;
     final selectedCurrency = ref.watch(currencyProvider);
    final isUserLoggedIn = widget.isUserLoggedIn;
    final excludeFavorites = ref.watch(excludeFavoritesProvider);
    final excludeHide = ref.watch(excludeHideProvider);
    final excludeDisplayed = ref.watch(excludeDisplayedProvider);

    return PopupListener(
        child: SafeArea(
          top: false,
          bottom: false,
          child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Ta część odpowiada za efekt rozmycia tła
             if(!widget.isMobile)
              BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: theme.adPopBackground.withAlpha(125),
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              // Obsługa dotknięcia w dowolnym miejscu aby zamknąć modal
              GestureDetector(onTap: () => Navigator.of(context).pop(),
              ),
              // Zawartość modalu
              Hero(
                tag: 'SortMobile-${UniqueKey().toString()}', // need to be change both sides of hero need the same tag
                child: Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: widget.isMobile
                      ? EdgeInsetsGeometry.all(0)
                      : EdgeInsets.symmetric(
                        vertical: screenWidth * 0.05,
                        horizontal: screenHeight * 0.1),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25.0),
                      child: Container(
                        width: widget.isMobile ? double.infinity : 350,
                        height: widget.isMobile ? double.infinity : 450,
                         color: theme.adPopBackground.withAlpha(125),
                         child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                          child: SingleChildScrollView(
                            controller: widget.scrollController,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                FilterSortButton(
                                   text: 'price_ascending'.tr,
                                  filterKey: 'sort',
                                  filterValue: 'price_asc',
                                  icon: Icons.arrow_upward,
                                ),
                                 FilterSortButton(
                                  text: 'price_descending'.tr,
                                  filterKey: 'sort',
                                  filterValue: 'price_desc',
                                  icon: Icons.arrow_downward,
                                ),
                                 FilterSortButton(
                                  text: 'Newest'.tr,
                                  filterKey: 'sort',
                                  filterValue: 'date_desc',
                                  icon: Icons.new_releases,
                                ),
                                 FilterSortButton(
                                  text: 'Oldest'.tr,
                                  filterKey: 'sort',
                                  filterValue: 'date_asc',
                                  icon: Icons.history,
                                ),
const SizedBox(height: 10),
                                CardTypeSelector(),
const SizedBox(height: 10),

        const MapFeedToggleSelector(
          currentView: FeedMapViewMode.feed,
          feedRoute: '/feed',
          mapRoute: '/mapview',
        ),

const SizedBox(height: 10),

                                   Material(
          color: Colors.transparent,
          child: Row(
            children: [
              Text('Currency'.tr, style: AppTextStyles.interRegular14.copyWith(
                color: theme.textColor
              )),
              const Spacer(),
              DropdownButton<String>(
                value: selectedCurrency,
                dropdownColor: theme.dashboardContainer,
                onChanged: (String? newValue) {
                  ref.read(currencyProvider.notifier).setCurrency(newValue!);
                  ref
                      .read(filterCacheProvider.notifier)
                      .setSelectedCurrency(newValue);
                  ref.read(filterProvider.notifier).applyFiltersFromCache(
                      ref.read(filterCacheProvider.notifier), ref);
                },
                items: <String>['PLN', 'EUR', 'USD', 'GBP', 'CZK']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value,
                    style: TextStyle(
                      color: theme.textColor
                    ),),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        if (isUserLoggedIn) ...[
          Material(
            color: Colors.transparent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Liked'.tr, style: AppTextStyles.interRegular.copyWith(
                  color: theme.textColor
                )),
                const Spacer(),
                Switch(
                  value: excludeFavorites,
                  onChanged: (value) {
                    // Aktualizowanie stanu providera
                    ref.read(excludeFavoritesProvider.notifier).state = value;
                    // Zastosuj filtry z nowym stanem
                    ref.read(filterCacheProvider.notifier).addFilter(
                        'exclude_favorites', value ? 'true' : 'false');
                    ref.read(filterProvider.notifier).applyFilters(ref);
                  },
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('hidden'.tr, style: AppTextStyles.interRegular.copyWith(
                  color: theme.textColor
                )),
                const Spacer(),
                Switch(
                  value: excludeHide,
                  onChanged: (value) {
                    // Aktualizowanie stanu providera
                    ref.read(excludeHideProvider.notifier).state = value;

                    // Zastosuj filtry z nowym stanem
                    ref
                        .read(filterCacheProvider.notifier)
                        .addFilter('exclude_hide', value ? 'true' : 'false');
                    ref.read(filterProvider.notifier).applyFilters(ref);
                  },
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('displayed'.tr, style: AppTextStyles.interRegular
                .copyWith(
                  color: theme.textColor
                )),
                const Spacer(),
                Switch(
                  value: excludeDisplayed,
                  onChanged: (value) {
                    // Aktualizowanie stanu providera
                    ref.read(excludeDisplayedProvider.notifier).state = value;

                    // Zastosuj filtry z nowym stanem
                    ref.read(filterCacheProvider.notifier).addFilter(
                        'exclude_displayed', value ? 'true' : 'false');
                    ref.read(filterProvider.notifier).applyFilters(ref);
                  },
                ),
              ],
            ),
          ),
        ],
                              ],
                            ),
                          ),
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
    );
  }
}
