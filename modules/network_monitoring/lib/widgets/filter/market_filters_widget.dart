import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:network_monitoring/widgets/filter/fileds.dart';

class MarketFiltersWidget extends ConsumerWidget {
  final String? currentCountry;
  final double dynamicBoxHeightGroup;
  final double dynamicBoxHeightGroupSmall;
  final bool isTablet;
  final dynamic ref;

  const MarketFiltersWidget({
    super.key,
    required this.currentCountry,
    required this.dynamicBoxHeightGroup,
    required this.dynamicBoxHeightGroupSmall,
    this.isTablet = false,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: isTablet ? 8 : dynamicBoxHeightGroupSmall,
      children: [
        Text(
          'Market type'.tr,
          style: (isTablet ? AppTextStyles.interSemiBold : AppTextStyles.interSemiBold16)
              .copyWith(color: theme.textColor),
        ),
        isTablet
            ? Column(
                spacing: 8,
                children: [
                  NetworkMonitoringFilterButton(
                    text: 'Primary market'.tr,
                    filterValue: 'primary',
                    filterKey: 'market_type',
                    isTablet: isTablet,
                  ),
                  NetworkMonitoringFilterButton(
                    text: 'Secondary market'.tr,
                    filterValue: 'secondary',
                    filterKey: 'market_type',
                    isTablet: isTablet,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: NetworkMonitoringFilterButton(
                      text: 'Primary market'.tr,
                      filterValue: 'primary',
                      filterKey: 'market_type',
                      isTablet: isTablet,
                    ),
                  ),
                  SizedBox(width: isTablet ? 8 : dynamicBoxHeightGroup),
                  Expanded(
                    child: NetworkMonitoringFilterButton(
                      text: 'Secondary market'.tr,
                      filterValue: 'secondary',
                      filterKey: 'market_type',
                      isTablet: isTablet,
                    ),
                  ),
                ],
              ),
        // SizedBox(height: dynamicBoxHeightGroup),
        // SizedBox(
        //   child: BuildDropdownButtonFormField(
        //     currentValue: currentCountry,
        //     items:  [
        //       'Blok'.tr,
        //       'Apartamentowiec'.tr,
        //       'Kamienica'.tr,
        //       'Wieżowiec'.tr,
        //       'Loft',
        //       'Szeregowiec'.tr,
        //       'Plomba'.tr
        //     ],
        //     labelText: 'Rodzaj zabudowy'.tr,
        //     filterKey: 'building_type',
        //   ),
        // ),
        // SizedBox(height: dynamicBoxHeightGroup),
        // SizedBox(
        //   child: BuildDropdownButtonFormField(
        //     currentValue: currentCountry,
        //     items:  [
        //       'Gazowe'.tr,
        //       'Elektryczne'.tr,
        //       'Miejskie'.tr,
        //       'Pompa ciepła'.tr,
        //       'Olejowe'.tr,
        //       'Nie podono informacji'.tr,
        //       'Wszystkie'.tr
        //     ],
        //     labelText: 'Rodzaj ogrzewania'.tr,
        //     filterKey: 'heating_type',
        //   ),
        // ),
        // SizedBox(height: dynamicBoxHeightGroup),
        // SizedBox(
        //   child: BuildDropdownButtonFormField(
        //     currentValue: currentCountry,
        //     items:  [
        //       'Dowolna'.tr,
        //       'Z ostatnich 24h'.tr,
        //       'Z ostatnich 3 dni'.tr,
        //       'Z ostatnich 7 dni'.tr,
        //       'Z ostatnich 14 dni'.tr,
        //       'Z ostatnich 30 dni'.tr
        //     ],
        //     labelText: 'Aktualność oferty'.tr,
        //     filterKey: 'aktualnosc_oferty',
        //   ),
        // ),
        // SizedBox(height: dynamicBoxHeightGroup),
        // SizedBox(
        //   child: BuildDropdownButtonFormField(
        //     currentValue: currentCountry,
        //     items:  [
        //       'Dowolna'.tr,
        //       'Cegła'.tr,
        //       'Wielka płyta'.tr,
        //       'Drewno'.tr,
        //       'Pustak'.tr,
        //       'Keramzyt'.tr,
        //       'Beton'.tr,
        //       'Silikat'.tr,
        //       'Beton komórkowy'.tr,
        //       'Żelbet'.tr
        //     ],
        //     labelText: 'Materiał budynku'.tr,
        //     filterKey: 'building_material',
        //   ),
        // ),
        // SizedBox(height: dynamicBoxHeightGroup),
        // SizedBox(
        //   child: BuildDropdownButtonFormField(
        //     currentValue: currentCountry,
        //     items:  [
        //       'Agent nieruchomości'.tr,
        //       'Deweloper'.tr,
        //       'Osoba prywatna'.tr,
        //       'Dowolna'.tr
        //     ],
        //     labelText: 'Ogłoszeniodawca'.tr,
        //     filterKey: 'advertiser_type',
        //   ),
        // ),
      ],
    );
  }

  // Pamiętaj, aby zdefiniować metody `buildDropdownButtonFormField` i `NetworkMonitoringFilterButton` lub zaimportować je, jeśli są w oddzielnym pliku.
}
