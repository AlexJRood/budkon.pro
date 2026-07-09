// ============================================
// PcFiltersWidget.dart (FULL - fixed)
// - rooms + bathrooms are MULTI select now (List<String>)
// - "Any" clears selection (removes filterKey from cache)
// - keeps cache value as CSV: "1,2,3"
// ============================================

import 'package:crm_agent/add_client_form/components/buy/buy_from_filter_components.dart';
import 'package:crm_agent/add_client_form/controllers/buy_controlers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crm_agent/add_client_form/components/buy/buy_filltered_button.dart';
import 'package:crm_agent/add_client_form/components/buy/buy_filtered_slider.dart';
import 'package:crm_agent/add_client_form/components/buy/buy_custom_drop_down.dart';

import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

class PcFiltersWidget extends ConsumerStatefulWidget {
  const PcFiltersWidget({super.key});

  @override
  ConsumerState<PcFiltersWidget> createState() => _PcFiltersWidgetState();
}

class _PcFiltersWidgetState extends ConsumerState<PcFiltersWidget> {
  late final FocusNode _buildYearFromFocusNode;
  late final FocusNode _buildYearToFocusNode;
  late final FocusNode _areaFromFocusNode;
  late final FocusNode _areaToFocusNode;
  late final FocusNode _priceFromFocusNode;
  late final FocusNode _priceToFocusNode;

  @override
  void initState() {
    super.initState();

    _buildYearFromFocusNode = FocusNode();
    _buildYearToFocusNode = FocusNode();
    _areaFromFocusNode = FocusNode();
    _areaToFocusNode = FocusNode();
    _priceFromFocusNode = FocusNode();
    _priceToFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _buildYearFromFocusNode.dispose();
    _buildYearToFocusNode.dispose();
    _areaFromFocusNode.dispose();
    _areaToFocusNode.dispose();
    _priceFromFocusNode.dispose();
    _priceToFocusNode.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final dropdownValues = ref.watch(crmAddDropdownProvider);
    final buyControllers = ref.watch(buySearchControllersProvider);
    final theme = ref.watch(themeColorsProvider);

    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [



        Text(
          'Year of build'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),

        Row(
          children:[

          Expanded(
                    child: CrmAddBuildNumberField(
                      controller: buyControllers.minBuildYear,
                      labelText: 'Year of build from'.tr,
                      filterKey: 'max_build_year',
                      focusNode: _buildYearFromFocusNode,
                      nextFocusNode: _buildYearToFocusNode,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: CrmAddBuildNumberField(
                      controller: buyControllers.maxBuildYear,
                      labelText: 'Year of build to'.tr,
                      filterKey: 'max_build_year',
                      focusNode: _buildYearToFocusNode,
                      nextFocusNode: _areaFromFocusNode,
                      textInputAction: TextInputAction.next,
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
              child: CrmAddBuildNumberField(
                controller: buyControllers.minSquareFootageController,
                labelText: 'area_from'.tr,
                filterKey: 'min_square_footage',
                focusNode: _areaFromFocusNode,
                nextFocusNode: _areaToFocusNode,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: CrmAddBuildNumberField(
                controller: buyControllers.maxSquareFootageController,
                labelText: 'area_to'.tr,
                filterKey: 'max_square_footage',
                focusNode: _areaToFocusNode,
                nextFocusNode: _priceFromFocusNode,
                textInputAction: TextInputAction.next,
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
              child: CrmAddBuildDropdownButtonFormField(
                filterKey: 'currency',
                items: const ['PLN', 'EUR', 'USD'],
                labelText: 'Currency'.tr,
                currentValue: 'PLN',
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: CrmAddBuildNumberField(
                controller: buyControllers.minPriceController,
                labelText: 'price_from'.tr,
                filterKey: 'min_price',
                focusNode: _priceFromFocusNode,
                nextFocusNode: _priceToFocusNode,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: CrmAddBuildNumberField(
                controller: buyControllers.maxPriceController,
                labelText: 'price_to'.tr,
                filterKey: 'max_price',
                focusNode: _priceToFocusNode,
                textInputAction: TextInputAction.done,
                isLast: true,
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
        const CrmAddFilteredSlider(filterKey: 'floors'),

        // ---------- ROOMS (MULTI) ----------
        Row(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Rooms'.tr, style: TextStyle(color: theme.textColor)),
            Wrap(
              spacing: 2,
              children: const [
                CrmAddMultiFilteredButton(text: 'Any', filterValue: 'any', filterKey: 'rooms'),
                CrmAddMultiFilteredButton(text: '1', filterValue: '1', filterKey: 'rooms'),
                CrmAddMultiFilteredButton(text: '2', filterValue: '2', filterKey: 'rooms'),
                CrmAddMultiFilteredButton(text: '3', filterValue: '3', filterKey: 'rooms'),
                CrmAddMultiFilteredButton(text: '4', filterValue: '4', filterKey: 'rooms'),
                CrmAddMultiFilteredButton(text: '5', filterValue: '5', filterKey: 'rooms'),
                CrmAddMultiFilteredButton(text: '6+', filterValue: '6+', filterKey: 'rooms'),
              ],
            ),
          ],
        ),

        // ---------- BATHROOMS (MULTI) ----------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Bathrooms'.tr, style: TextStyle(color: theme.textColor)),
            Wrap(
              direction: Axis.horizontal,
              spacing: 2,
              children: const [
                CrmAddMultiFilteredButton(text: 'Any', filterValue: 'any', filterKey: 'bathrooms'),
                CrmAddMultiFilteredButton(text: '1', filterValue: '1', filterKey: 'bathrooms'),
                CrmAddMultiFilteredButton(text: '2', filterValue: '2', filterKey: 'bathrooms'),
                CrmAddMultiFilteredButton(text: '3', filterValue: '3', filterKey: 'bathrooms'),
                CrmAddMultiFilteredButton(text: '4', filterValue: '4', filterKey: 'bathrooms'),
                CrmAddMultiFilteredButton(text: '5', filterValue: '5', filterKey: 'bathrooms'),
                CrmAddMultiFilteredButton(text: '6+', filterValue: '6+', filterKey: 'bathrooms'),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
