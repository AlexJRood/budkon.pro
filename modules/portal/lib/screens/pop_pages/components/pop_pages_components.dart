
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import 'package:portal/screens/pop_pages/pages/mobile_pop_appbar_page.dart';
import 'package:portal/screens/pop_pages/providers/pop_pages_providers.dart';

import 'package:core/platform/route_constant.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';

import 'package:portal/screens/pop_pages/pages/view_settings_page.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/common/currency_config.dart';

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
    return Column(
      children: [
        // DropdownButton do wyboru waluty
        Material(
          color: Colors.transparent,
          child: Row(
            children: [
              Text('Currency'.tr, style: AppTextStyles.interRegular14),
              const Spacer(),
              DropdownButton<String>(
                value: selectedCurrency,
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
                    child: Text(value),
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
                Text('Liked'.tr, style: AppTextStyles.interRegular),
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
                Text('hidden'.tr, style: AppTextStyles.interRegular),
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
                Text('displayed'.tr, style: AppTextStyles.interRegular),
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
        const SizedBox(height: 20),
        ElevatedButton(
          style: buttonSearchBar,
          onPressed: () {
            ref.read(selectedFeedViewMobileProvider.notifier).state =
                Routes.mapView;
            ref.read(navigationService).pushNamedScreen(Routes.mapView);
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
                  'Fill size'.tr,
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
                 'full_map'.tr,
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
class FilterSortButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;
  final IconData icon; // Dodanie ikony jako parametru

  const FilterSortButton({
    super.key,
    required this.text,
    required this.filterKey,
    required this.filterValue,
    required this.icon, // Wymaganie ikony
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSelected = ref.watch(
        sortButtonProvider.select((state) => state[filterKey] == filterValue));

    return SizedBox(
      width: double.infinity, // Wypełnienie całej dostępnej szerokości
      child: ElevatedButton.icon(
        icon: Icon(icon,
            color: isSelected
                ? Colors.blue
                : Colors.white), // Zmiana koloru ikony na podstawie selekcji
        label: Text(text,
            style: TextStyle(
                color: isSelected
                    ? Colors.blue
                    : Colors.white)), // Zmiana koloru tekstu
        onPressed: () {
          ref
              .read(sortButtonProvider.notifier)
              .updateFilter(filterKey, filterValue);
          ref
              .read(filterCacheProvider.notifier)
              .addFilter(filterKey, filterValue);
          ref.read(filterCacheProvider.notifier).setSortOrder(filterValue);
          ref
              .read(filterProvider.notifier)
              .applyFiltersFromCache(ref.read(filterCacheProvider.notifier),ref);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, // Brak tła
          elevation: 0, // Brak cienia
          padding: const EdgeInsets.symmetric(
              vertical:
                  20), // Zwiększenie paddingu dla lepszej widoczności i dotykowości
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0)), // Usunięcie zaokrągleń
          side: isSelected
              ? const BorderSide(color: Colors.blue, width: 2)
              : BorderSide.none, // Podświetlenie obramowaniem gdy wybrane
        ),
      ),
    );
  }
}