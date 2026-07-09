import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:portal/screens/pop_pages/pages/view_pop_changer_page.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';

import 'package:portal/screens/pop_pages/pages/view_settings_page.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/common/currency_config.dart';

import 'package:get/get_utils/get_utils.dart';

Set<String> _selected = {'/view'};
final selectedFeedViewMobileProvider =
    selectedFeedViewProvider; // Domyślnie ustawione na '/feedview'
final excludeFavoritesMobileProvider = excludeFavoritesProvider;
final excludeHideMobileProvider = excludeHideProvider;
final excludeDisplayedMobileProvider = excludeDisplayedProvider;

class MobilePopAppBarPage extends ConsumerStatefulWidget {
  const MobilePopAppBarPage({super.key});

  @override
  MobilePopAppBarState createState() => MobilePopAppBarState();
}

class MobilePopAppBarState extends ConsumerState<MobilePopAppBarPage> {
  late TextEditingController searchController;
  late TextEditingController excludeController;
  late TextEditingController minPriceController;
  late TextEditingController maxPriceController;
  bool _excludeFavorites = false;
  bool _excludeHide = false;
  bool _excludeDisplayed = false;

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

  void updateSelected(Set<String> newSelection) {
    setState(() {
      _selected = newSelection;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double screenPadding = screenWidth / 430 * 15;
    final isUserLoggedIn = ApiServices.isUserLoggedIn();
    _excludeFavorites = ref.watch(excludeFavoritesProvider);
    _excludeHide = ref.watch(excludeHideProvider);
    _excludeDisplayed = ref.watch(excludeDisplayedProvider);
    final selectedCurrency = ref.watch(currencyProvider);
    final theme = ref.watch(themeColorsProvider);

    // Oblicz proporcję szerokości
    // double widthRatio = screenWidth / 1920.0;

    // Oblicz szerokość dla dynamicznego SizedBox
    //  double dynamicSizedBoxWidth = screenWidth * 0.5;
    //  double dynamicSizedBoxHeight = screenHeight * 0.5;

    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Ta część odpowiada za efekt rozmycia tła
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withAlpha((255 * 0.5).toInt()),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            // Obsługa dotknięcia w dowolnym miejscu aby zamknąć modal
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
            ),
            // Zawartość modalu
            Hero(
              tag: 'MobilePopAppBar-${UniqueKey().toString()}', // need to be change both sides of hero need the same tag 
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding:
                      EdgeInsets.only(right: screenPadding, left: screenPadding),
                  child: Column(
                    children: [
                      const Spacer(),
                       ClipRRect(
                      borderRadius: BorderRadius.circular(25.0),
                        child: Container(
                          width: screenWidth - (screenPadding * 2),
                          height: screenHeight * 0.75,
                          padding: EdgeInsets.all(screenPadding),
                          child:BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                        child:  SingleChildScrollView(
                              child: _selected.contains('/view')
                                  ? const BuildSearchView()
                                  : BuildSettingsView(
                                      selectedCurrency: selectedCurrency,
                                      excludeDisplayed: _excludeDisplayed,
                                      excludeFavorites: _excludeFavorites,
                                      excludeHide: _excludeHide,
                                      isUserLoggedIn: isUserLoggedIn,
                                    ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: screenPadding,
                      ),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(13.0),
                        child: Container(
                          width: screenWidth - screenPadding * 2,
                          height: 62,
                          padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 5),
                          child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: SegmentedButton(
                                    style: ButtonStyle(
                                      foregroundColor:
                                          WidgetStateProperty.resolveWith<Color>(
                                        (states) {
                                          if (states
                                              .contains(WidgetState.selected)) {
                                            return Colors.white;
                                          }
                                          return AppColors.light;
                                        },
                                      ),
                                      padding: WidgetStateProperty.all<EdgeInsets>(
                                        const EdgeInsets.symmetric(
                                            vertical: 0, horizontal: 0),
                                      ),
                                      shape: WidgetStateProperty.all<
                                          RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      backgroundColor:
                                          WidgetStateProperty.resolveWith<Color>(
                                        (states) {
                                          if (states
                                              .contains(WidgetState.selected)) {
                                            return Colors.black.withAlpha((255 * 0.35).toInt());
                                          }
                                          return Colors.transparent;
                                        },
                                      ),
                                      side: WidgetStateProperty.all<BorderSide>(
                                        BorderSide.none,
                                      ),
                                    ),
                                    multiSelectionEnabled: false,
                                    selected: _selected,
                                    onSelectionChanged: updateSelected,
                                    segments: <ButtonSegment<String>>[
                                      ButtonSegment(
                                        label: Text(
                                          'view'.tr,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: _selected.contains('/view')
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        value: '/view',
                                        icon: Icon(
                                          Icons.check,
                                          color: theme.textColor,
                                        ),
                                      ),
                                      ButtonSegment(
                                        label: Text(
                                          'Settings'.tr,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight:
                                                _selected.contains('/settings')
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        value: '/settings',
                                        icon: Icon(
                                          Icons.check,
                                          color: theme.textColor,
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
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BuildSettingsView extends ConsumerWidget {
  const BuildSettingsView({
    super.key,
    required this.selectedCurrency,
    required this.isUserLoggedIn,
    required this.excludeFavorites,
    required this.excludeHide,
    required this.excludeDisplayed,
  });

  final String selectedCurrency;
  final bool isUserLoggedIn;
  final bool excludeFavorites;
  final bool excludeHide;
  final bool excludeDisplayed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Column(
      children: [
        // DropdownButton do wyboru waluty
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
                dropdownColor: theme.popupcontainercolor,
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
    );
  }
}

class BuildSearchView extends ConsumerWidget {
  const BuildSearchView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: Text(
            'select_search_view'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
        ),
        ElevatedButton(
          style: buttonSearchBar,
          onPressed: () {
            ref.read(selectedFeedViewMobileProvider.notifier).state =
                Routes.feedView;
            ref.read(navigationService).pushNamedScreen(Routes.feedView);
          },
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                SizedBox(
                  width: 320,
                  height: 180,
                  child: Image.asset('assets/images/feed_view.webp'),
                ),
                const SizedBox(
                    height:
                        10), // Dodaj trochę przestrzeni między obrazem a tekstem
                Text(
                  'grid_view'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: buttonSearchBar,
          onPressed: () {
            ref.read(selectedFeedViewMobileProvider.notifier).state =
                Routes.fullmap;
            ref.read(navigationService).pushNamedScreen(Routes.fullmap);
          },
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                SizedBox(
                  width: 320,
                  height: 180,
                  child: Image.asset('assets/images/map_view.webp'),
                ),
                const SizedBox(height: 10),
                Text(
                  'Map'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: buttonSearchBar,
          onPressed: () {
            ref.read(selectedFeedViewMobileProvider.notifier).state =
                Routes.fullSize;
            ref.read(navigationService).pushNamedScreen(Routes.fullSize);
          },
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                SizedBox(
                  width: 320,
                  height: 180,
                  child: Image.asset('assets/images/full_size_view.webp'),
                ),
                const SizedBox(height: 10),
                Text(
                  'Full size'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        ElevatedButton(
          style: buttonSearchBar,
          onPressed: () {
            ref.read(selectedFeedViewMobileProvider.notifier).state =
                Routes.listview;
            ref.read(navigationService).pushNamedScreen(Routes.listview);
          },
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                SizedBox(
                  width: 320,
                  height: 180,
                  child: Image.asset('assets/images/full_size_view.webp'),
                ),
                const SizedBox(height: 10),
                Text(
                  'List view'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
