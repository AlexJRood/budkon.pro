// ============================================
// ClientPanelPcFiltersWidget.dart (FULL - fixed)
// - rooms + bathrooms are MULTI select now
// - "Any" clears selection for that filterKey
// - Wrap is inside Expanded -> fixes RenderBox was not laid out in sheets/rows
// - adds runSpacing for nicer wrapping
// - safer casting from filterButtonProvider state
// ============================================

import 'package:crm/contact_panel/tabs/saved_search_client/components/controlers.dart';
import 'package:crm/contact_panel/tabs/saved_search_client/components/from_filter_components.dart';
import 'package:crm/contact_panel/tabs/saved_search_client/components/custom_drop_down.dart';
import 'package:crm/contact_panel/tabs/saved_search_client/components/filtered_slider.dart';
import 'package:crm/data/clients/ad_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

class ClientPanelPcFiltersWidget extends ConsumerStatefulWidget {
  const ClientPanelPcFiltersWidget({super.key});

  @override
  ConsumerState<ClientPanelPcFiltersWidget> createState() => _ClientPanelPcFiltersWidgetState();
}

class _ClientPanelPcFiltersWidgetState extends ConsumerState<ClientPanelPcFiltersWidget> {
  late final FocusNode _yearFromFocus;
  late final FocusNode _yearToFocus;
  late final FocusNode _areaFromFocus;
  late final FocusNode _areaToFocus;
  late final FocusNode _priceFromFocus;
  late final FocusNode _priceToFocus;

  @override
  void initState() {
    super.initState();

    _yearFromFocus = FocusNode();
    _yearToFocus = FocusNode();
    _areaFromFocus = FocusNode();
    _areaToFocus = FocusNode();
    _priceFromFocus = FocusNode();
    _priceToFocus = FocusNode();
  }
  @override
  void dispose() {
    _yearFromFocus.dispose();
    _yearToFocus.dispose();
    _areaFromFocus.dispose();
    _areaToFocus.dispose();
    _priceFromFocus.dispose();
    _priceToFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dropdownValues = ref.watch(clientPanelDropdownProvider);
    final theme = ref.watch(themeColorsProvider);
    final filterControllers = ref.read(filtersControllersProvider);

    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filters'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'year_of_build_label'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: ClientPanelBuildNumberField(
                controller: filterControllers.minBuildYearController,
                labelText: 'Year from'.tr,
                filterKey: 'min_build_year',
                focusNode: _yearFromFocus,
                nextFocusNode: _yearToFocus,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ClientPanelBuildNumberField(
                controller: filterControllers.maxBuildYearController,
                labelText: 'Year to'.tr,
                filterKey: 'max_build_year',
                focusNode: _yearToFocus,
                nextFocusNode: _areaFromFocus,
              ),
            ),
          ],
        ),
        Text(
          'Floor area'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: ClientPanelBuildNumberField(
                controller: filterControllers.minSquareFootageController,
                labelText: 'area_from'.tr,
                filterKey: 'min_square_footage',
                focusNode: _areaFromFocus,
                nextFocusNode: _areaToFocus,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ClientPanelBuildNumberField(
                controller: filterControllers.maxSquareFootageController,
                labelText: 'area_to'.tr,
                filterKey: 'max_square_footage',
                focusNode: _areaToFocus,
                nextFocusNode: _priceFromFocus,
              ),
            ),
          ],
        ),
        Text(
          'Price'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: ClientPanelBuildDropdownButtonFormField(
                filterKey: 'currency',
                items: const ['PLN', 'EUR', 'USD'],
                labelText: 'Currency'.tr,
                currentValue: 'PLN',
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ClientPanelBuildNumberField(
                controller: filterControllers.minPriceController,
                labelText: 'price_from'.tr,
                filterKey: 'min_price',
                focusNode: _priceFromFocus,
                nextFocusNode: _priceToFocus,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ClientPanelBuildNumberField(
                controller: filterControllers.maxPriceController,
                labelText: 'price_to'.tr,
                filterKey: 'max_price',
                focusNode: _priceToFocus,
                nextFocusNode: null,
              ),
            ),
          ],
        ),
        Text(
          'Floors'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const ClientPanelFilteredSlider(filterKey: 'floors'),

        // ---------- ROOMS (MULTI) ----------
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            SizedBox(
              width: 110,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Rooms'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            ),
            const SizedBox(width: 5),
                 Expanded(
                   child: SingleChildScrollView(
                     scrollDirection: Axis.horizontal,
                     child: Row(
                       spacing: 8,
                       children: [
                         ClientPanelMultiFilteredButton(
                           text: 'Any',
                           filterValue: 'any',
                           filterKey: 'rooms',
                         ),
                         ClientPanelMultiFilteredButton(
                           text: '1',
                           filterValue: '1',
                           filterKey: 'rooms',
                         ),
                         ClientPanelMultiFilteredButton(
                           text: '2',
                           filterValue: '2',
                           filterKey: 'rooms',
                         ),
                         ClientPanelMultiFilteredButton(
                           text: '3',
                           filterValue: '3',
                           filterKey: 'rooms',
                         ),
                         ClientPanelMultiFilteredButton(
                           text: '4',
                           filterValue: '4',
                           filterKey: 'rooms',
                         ),
                         ClientPanelMultiFilteredButton(
                           text: '5',
                           filterValue: '5',
                           filterKey: 'rooms',
                         ),
                         ClientPanelMultiFilteredButton(
                           text: '6+',
                           filterValue: '6+',
                           filterKey: 'rooms',
                         ),
                       ],
                     ),
                   ),
                 )
                ],
              ),


        // ---------- BATHROOMS (MULTI) ----------
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            SizedBox(
              width: 110,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Bathrooms'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            ),
            const SizedBox(width: 5),
               Expanded(
                 child: SingleChildScrollView(
                   scrollDirection: Axis.horizontal,
                   child: Row(
                     spacing: 8,
                     children: [
                       ClientPanelMultiFilteredButton(
                         text: 'Any',
                         filterValue: 'any',
                         filterKey: 'bathrooms',
                       ),
                       ClientPanelMultiFilteredButton(
                         text: '1',
                         filterValue: '1',
                         filterKey: 'bathrooms',
                       ),
                       ClientPanelMultiFilteredButton(
                         text: '2',
                         filterValue: '2',
                         filterKey: 'bathrooms',
                       ),
                       ClientPanelMultiFilteredButton(
                         text: '3',
                         filterValue: '3',
                         filterKey: 'bathrooms',
                       ),
                       ClientPanelMultiFilteredButton(
                         text: '4',
                         filterValue: '4',
                         filterKey: 'bathrooms',
                       ),
                       ClientPanelMultiFilteredButton(
                         text: '5',
                         filterValue: '5',
                         filterKey: 'bathrooms',
                       ),
                       ClientPanelMultiFilteredButton(
                         text: '6+',
                         filterValue: '6+',
                         filterKey: 'bathrooms',
                       ),
                     ],
                   ),
                 ),
               )
                ],
              ),
      ],
    );
  }
}

// ============================================
// NEW: Multi-select filtered button (drop-in replacement for ClientPanelFilteredButton)
// - stores List<String> in filterButtonProvider
// - stores CSV in filterCacheProvider
// - "any" clears selection
// ============================================

class ClientPanelMultiFilteredButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;

  const ClientPanelMultiFilteredButton({
    super.key,
    required this.text,
    required this.filterKey,
    required this.filterValue,
  });

  int _weight(String v) {
    final vv = v.trim();
    final base = vv.replaceAll('+', '');
    final n = int.tryParse(base);
    if (n == null) return 9999;
    return vv.contains('+') ? (n * 1000) : n;
  }

  List<String> _safeStringList(dynamic v) {
    if (v == null) return <String>[];
    if (v is List<String>) return v;
    if (v is List) return v.map((e) => e.toString()).toList();
    // fallback: if someone accidentally stored CSV here
    final s = v.toString().trim();
    if (s.isEmpty) return <String>[];
    return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final List<String> selected = _safeStringList(
      ref.watch(
        filterButtonProvider.select((state) => state[filterKey]),
      ),
    );

    final bool isAny = filterValue.toLowerCase() == 'any';
    final bool isSelected = isAny ? selected.isEmpty : selected.contains(filterValue);

    return InkWell(
      onTap: () {
        final cache = ref.read(filterCacheProvider.notifier);
        final notifier = ref.read(filterButtonProvider.notifier);

        if (isAny) {
          // clear selection
          notifier.updateFilter(filterKey, <String>[]);
          cache.removeFilter(filterKey);
          return;
        }

        final next = [...selected];
        if (next.contains(filterValue)) {
          next.remove(filterValue);
        } else {
          next.add(filterValue);
        }

        next.sort((a, b) => _weight(a).compareTo(_weight(b)));

        notifier.updateFilter(filterKey, next);

        if (next.isEmpty) {
          cache.removeFilter(filterKey);
        } else {
          cache.addFilter(filterKey, next.join(','));
        }
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.themeColor : theme.dashboardContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: Center(
          child: Text(
            text.tr,
            style: TextStyle(
              color: isSelected ? theme.themeColorText : theme.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
