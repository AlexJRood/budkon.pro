import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:portal/screens/filter_landing_page/components/filters_components.dart';
import 'package:portal/screens/pop_pages/pages/view_pop_changer_page.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:core/platform/navigation_service.dart';

class FiltersLandingPageMobile extends ConsumerStatefulWidget {
  const FiltersLandingPageMobile({super.key});

  @override
  FiltersLandingPageState createState() => FiltersLandingPageState();
}

class FiltersLandingPageState extends ConsumerState<FiltersLandingPageMobile> {
  String selectedOfferType = '';

  late TextEditingController searchController;
  late TextEditingController searchRadiusController;
  late TextEditingController excludeController;
  late TextEditingController minPriceController;
  late TextEditingController maxPriceController;
  late TextEditingController minSquareFootageController;
  late TextEditingController maxSquareFootageController;
  late TextEditingController estateTypeController;
  late TextEditingController offerTypeController;
  late TextEditingController countryController;
  late TextEditingController streetController;
  late TextEditingController cityController;
  late TextEditingController stateController;
  late TextEditingController zipcodeController;

  @override
  void initState() {
    super.initState();
    final filterNotifier = ref.read(filterProvider.notifier);

    searchController = TextEditingController(text: filterNotifier.searchQuery);
    searchRadiusController = TextEditingController(
      text: filterNotifier.searchQuery,
    ); //do poprawy
    excludeController = TextEditingController(
      text: filterNotifier.excludeQuery,
    );
    minPriceController = TextEditingController(
      text: filterNotifier.filters['min_price']?.toString(),
    );
    maxPriceController = TextEditingController(
      text: filterNotifier.filters['max_price']?.toString(),
    );
    minSquareFootageController = TextEditingController(
      text: filterNotifier.filters['min_square_footage']?.toString(),
    );
    maxSquareFootageController = TextEditingController(
      text: filterNotifier.filters['max_square_footage']?.toString(),
    );
    estateTypeController = TextEditingController(
      text: filterNotifier.filters['estate_type'],
    );
    streetController = TextEditingController(
      text: filterNotifier.filters['street'],
    );
    cityController = TextEditingController(
      text: filterNotifier.filters['city'],
    );
    stateController = TextEditingController(
      text: filterNotifier.filters['state'],
    );
    zipcodeController = TextEditingController(
      text: filterNotifier.filters['zipcode'],
    );
    offerTypeController = TextEditingController(
      text: filterNotifier.filters['offer_type'],
    );
    countryController = TextEditingController(
      text: filterNotifier.filters['country'],
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    searchRadiusController.dispose();
    excludeController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    minSquareFootageController.dispose();
    maxSquareFootageController.dispose();
    estateTypeController.dispose();
    streetController.dispose();
    cityController.dispose();
    stateController.dispose();
    zipcodeController.dispose();
    offerTypeController.dispose();
    countryController.dispose();
    super.dispose();
  }

  void setSelectedOfferType(String value) {
    setState(() {
      selectedOfferType = value;
      offerTypeController.text = value; // Aktualizacja kontrolera tekstu
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double dynamicBoxHeight = 15;
    double dynamicBoxHeightGroup = 12;
    double dynamicBoxHeightGroupSmall = 10;
    double dynamiSpacerBoxWidth = 10;
    double filterBarWidth = (screenWidth * 0.95);
    double filterBarHeigth = math.max(screenHeight * 0.4, 275);
    final inputDecorationTheme = Theme.of(context).inputDecorationTheme;
    final themecolors = ref.watch(themeColorsProvider);
    final filterPageColor = themecolors.filterPageColor;
    final currentthememode = ref.watch(themeProvider);

    final cursorcolor = Theme.of(context).primaryColor;
    final buttoncolor = Theme.of(context).primaryColor;
    final buttonTextColor =
        currentthememode == ThemeMode.system
            ? AppColors.textColorLight
            : themecolors.buttonTextColor;

    final textFieldColor =
        currentthememode == ThemeMode.system ? Colors.black : Colors.white;
    return Column(
      children: [
        SizedBox(
          width: filterBarWidth,
          child: Row(
            children: [
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 10,
                    sigmaY: 10,
                  ), // Adjust the blur intensity
                  child: Container(
                    padding: const EdgeInsets.only(
                      bottom: 10,
                      top: 15,
                      left: 25,
                      right: 25,
                    ),
                    decoration: BoxDecoration(
                      color: filterPageColor,
                      //  gradient: BackgroundGradients.oppacityGradient50,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        topRight: Radius.circular(20.0),
                      ),
                    ),
                    child: Row(
                      children: [
                        FilterButton(
                          text: 'offer_type_sell'.tr,
                          filterValue: 'sell',
                          filterKey: 'offer_type',
                        ),
                        const SizedBox(width: 15),
                        FilterButton(
                          text: 'offer_type_rent'.tr,
                          filterValue: 'rent',
                          filterKey: 'offer_type',
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
        Center(
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10,
                sigmaY: 10,
              ), // Adjust the blur intensity
              child: Container(
                width: filterBarWidth,
                // height: filterBarHeigth,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: filterPageColor,
                  // gradient: BackgroundGradients.oppacityGradient50,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20.0),
                    bottomRight: Radius.circular(20.0),
                    bottomLeft: Radius.circular(20.0),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          // Rozszerzony TextField z białym tłem i zaokrąglonymi rogami
                          child: Material(
                            borderRadius: BorderRadius.circular(30.0), // Zaokrąglenie rogów
                            elevation: 2, // Lekkie uniesienie dla efektu cienia
                            child: SizedBox(
                              height:
                                  35.0, // Ograniczenie wysokości do 35 pikseli
                              child: TextField(
                                controller: searchController,
                                style: AppTextStyles.interMedium14dark.copyWith(
                                  color: textFieldColor,
                                ),
                                cursorColor:
                                    currentthememode == ThemeMode.system
                                        ? Colors.black
                                        : cursorcolor,
                                decoration: InputDecoration(
                                  labelText: 'search_keywords'.tr,
                                  prefixIcon: AppIcons.search(
                                    color: inputDecorationTheme.prefixIconColor,
                                  ),
                                  filled: inputDecorationTheme.filled,
                                  fillColor: inputDecorationTheme.fillColor,
                                  border: inputDecorationTheme.border,
                                  focusedBorder:
                                      inputDecorationTheme.focusedBorder,
                                  labelStyle: inputDecorationTheme.labelStyle!
                                      .copyWith(fontSize: 14),
                                  floatingLabelStyle:
                                      inputDecorationTheme.floatingLabelStyle,
                                ),
                                onChanged:
                                    (value) => ref
                                        .read(filterCacheProvider.notifier)
                                        .setSearchQuery(value),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: dynamicBoxHeightGroupSmall),
                        Expanded(
                          child: SizedBox(
                            child: BuildDropdownButtonFormField(
                              currentValue: null,
                              items: [
                                'flat'.tr,
                                'studio_apartment'.tr,
                                'apartmen'.tr,
                                'single_family_house'.tr,
                                'semi_detached_house'.tr,
                                'row_house'.tr,
                                'investments'.tr,
                                'plots'.tr,
                                'commercial_premises'.tr,
                                'halls_and_warehouses'.tr,
                                'Rooms'.tr,
                                'garages'.tr,
                              ],
                              labelText: 'property_type'.tr,
                              filterKey: 'estate_type',
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        SizedBox(height: dynamicBoxHeightGroupSmall),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: BuildTextField(
                                controller: countryController,
                                labelText: 'Country'.tr,
                                filterKey: 'country',
                              ),
                            ),
                            SizedBox(width: dynamiSpacerBoxWidth),
                            Expanded(
                              child: BuildTextField(
                                controller: cityController,
                                labelText: 'city'.tr,
                                filterKey: 'city',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: dynamicBoxHeightGroupSmall),
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                child: BuildNumberField(
                                  controller: minSquareFootageController,
                                  labelText: 'Area from'.tr,
                                  filterKey: 'min_square_footage',
                                ),
                              ),
                              SizedBox(width: dynamiSpacerBoxWidth),
                              Expanded(
                                child: BuildNumberField(
                                  controller: maxSquareFootageController,
                                  labelText: 'Area to'.tr,
                                  filterKey:
                                      'max_square_footage', // Klucz używany do aktualizacji wartości w filterProvider
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: dynamicBoxHeightGroup),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                child: BuildNumberField(
                                  controller: minPriceController,
                                  labelText: 'Price from'.tr,
                                  filterKey:
                                      'min_price', // Klucz używany do aktualizacji wartości w filterProvider
                                ),
                              ),
                              SizedBox(
                                width: dynamiSpacerBoxWidth,
                              ), // Odstęp pomiędzy polami
                              Expanded(
                                child: BuildNumberField(
                                  controller: maxPriceController,
                                  labelText: 'Price to'.tr,
                                  filterKey:
                                      'max_price', // Klucz używany do aktualizacji wartości w filterProvider
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: dynamicBoxHeight),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            ref.read(filterProvider.notifier).applyFilters(ref);
                            String selectedFeedView = ref.read(
                              selectedFeedViewProvider,
                            ); // Odczytaj wybrany widok
                            ref
                                .read(navigationService)
                                .pushNamedReplacementScreen(selectedFeedView);
                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttoncolor,
                            foregroundColor:
                                Colors.white, // Kolor tekstu przycisku
                            padding: const EdgeInsets.only(
                              left: 30,
                              right: 30,
                              top: 10,
                              bottom: 10,
                            ),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                          child: Text(
                            'apply_filters'.tr,
                            style: TextStyle(color: buttonTextColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
