import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:core/common/install_popup.dart';

class SortPopMobilePage extends ConsumerStatefulWidget {
  const SortPopMobilePage({super.key});

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
    excludeController = TextEditingController(
      text: filterNotifier.excludeQuery,
    );
    minPriceController = TextEditingController(
      text: filterNotifier.filters['min_price']?.toString(),
    );
    maxPriceController = TextEditingController(
      text: filterNotifier.filters['max_price']?.toString(),
    );
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

    // Oblicz proporcję szerokości
    // double widthRatio = screenWidth / 1920.0;

    // Oblicz szerokość dla dynamicznego SizedBox
    //  double dynamicSizedBoxWidth = screenWidth * 0.5;
    //  double dynamicSizedBoxHeight = screenHeight * 0.5;

    return PopupListener(
      child: SafeArea(
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
              GestureDetector(onTap: () => Navigator.of(context).pop()),
              // Zawartość modalu
              Hero(
                tag:
                    'SortMobile-${UniqueKey().toString()}', // need to be change both sides of hero need the same tag
                child: Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: screenWidth * 0.05,
                      horizontal: screenHeight * 0.1,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25.0),
                      child: Container(
                        width: screenWidth * 0.5 >= 350 ? 350 : 350,
                        height: screenHeight * 0.75 >= 450 ? 450 : 450,
                        padding: const EdgeInsets.all(20),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                FilterSortButton(
                                  text: 'sort_price_asc'.tr,
                                  filterKey: 'sort',
                                  filterValue: 'price_asc',
                                  icon:
                                      Icons
                                          .arrow_upward, // Ikona wskazująca rosnąco
                                ),
                                FilterSortButton(
                                  text: 'sort_price_desc'.tr,
                                  filterKey: 'sort',
                                  filterValue: 'price_desc',
                                  icon:
                                      Icons
                                          .arrow_downward, // Ikona wskazująca malejąco
                                ),
                                FilterSortButton(
                                  text: 'sort_newest'.tr,
                                  filterKey: 'sort',
                                  filterValue: 'date_desc',
                                  icon:
                                      Icons
                                          .new_releases, // Ikona dla najnowszych
                                ),
                                FilterSortButton(
                                  text: 'sort_oldest'.tr,
                                  filterKey: 'sort',
                                  filterValue: 'date_asc',
                                  icon: Icons.history, // Ikona dla najstarszych
                                ),
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

final sortButtonProvider =
    StateNotifierProvider<SortButtonNotifier, Map<String, dynamic>>((ref) {
      return SortButtonNotifier();
    });

class SortButtonNotifier extends StateNotifier<Map<String, dynamic>> {
  SortButtonNotifier() : super({});
  void updateFilter(String key, dynamic value) {
    state = {...state, key: value};
  }

  void updateRangeFilter(String key, RangeValues values) {
    state = {...state, key: values};
  }

  void clearUiFilters() {
    state = {};
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
      sortButtonProvider.select((state) => state[filterKey] == filterValue),
    );

    return SizedBox(
      width: double.infinity, // Wypełnienie całej dostępnej szerokości
      child: ElevatedButton.icon(
        icon: Icon(
          icon,
          color: isSelected ? Colors.blue : Colors.white,
        ), // Zmiana koloru ikony na podstawie selekcji
        label: Text(
          text,
          style: TextStyle(color: isSelected ? Colors.blue : Colors.white),
        ), // Zmiana koloru tekstu
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
              .applyFiltersFromCache(
                ref.read(filterCacheProvider.notifier),
                ref,
              );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, // Brak tła
          elevation: 0, // Brak cienia
          padding: const EdgeInsets.symmetric(
            vertical: 20,
          ), // Zwiększenie paddingu dla lepszej widoczności i dotykowości
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ), // Usunięcie zaokrągleń
          side:
              isSelected
                  ? const BorderSide(color: Colors.blue, width: 2)
                  : BorderSide.none, // Podświetlenie obramowaniem gdy wybrane
        ),
      ),
    );
  }
}
