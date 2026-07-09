import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/common/shared_widgets/location_components.dart';
import 'package:reports/reports/create_report_page/widgets/components/filter_chips_custom.dart';
import 'package:reports/reports/create_report_page/providers/providers_report.dart';
import 'package:core/ui/forms/form_fields.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';

class PropertyDetailsMobile extends ConsumerWidget {
  const PropertyDetailsMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(propertyValuationFormProvider);
    final theme = ref.watch(themeColorsProvider);
    final width = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'property_type'.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CustomColors.secondaryWidgetTextColor(context, ref),
            ),
          ),
        ),
        SizedBox(height: 15),
        if (width > 500) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              runSpacing: 10,
              spacing: 10,
              children: [
                CustomFilterChipMobile(
                  label: 'All types'.tr,
                  isSelected: formState.propertyType == 'All types',
                  onTap: () {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .updateField('propertyType', 'All types');
                  },
                ),
                CustomFilterChipMobile(
                  label: 'House'.tr,
                  isSelected: formState.propertyType == 'House',
                  onTap: () {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .updateField('propertyType', 'House');
                  },
                ),
                CustomFilterChipMobile(
                  label: 'Townhouse'.tr,
                  isSelected: formState.propertyType == 'Townhouse',
                  onTap: () {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .updateField('propertyType', 'Townhouse');
                  },
                ),
                CustomFilterChipMobile(
                  label: 'Villa'.tr,
                  isSelected: formState.propertyType == 'Villa',
                  onTap: () {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .updateField('propertyType', 'Villa');
                  },
                ),
                CustomFilterChipMobile(
                  label: 'Commercial'.tr,
                  isSelected: formState.propertyType == 'Commercial',
                  onTap: () {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .updateField('propertyType', 'Commercial');
                  },
                ),
                CustomFilterChipMobile(
                  label: 'Flat'.tr,
                  isSelected: formState.propertyType == 'Flat',
                  onTap: () {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .updateField('propertyType', 'Flat');
                  },
                ),
                CustomFilterChipMobile(
                  label: 'Duplex Homes'.tr,
                  isSelected: formState.propertyType == 'Duplex Homes',
                  onTap: () {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .updateField('propertyType', 'Duplex Homes');
                  },
                ),
                CustomFilterChipMobile(
                  label: 'Land Plot'.tr,
                  isSelected: formState.propertyType == 'Land Plot',
                  onTap: () {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .updateField('propertyType', 'Land Plot');
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
        ],
        if (width < 500) ...[
          Row(
            children: [
              Expanded(
                child: CustomFilterChipMobile(
                  label: 'All types'.tr,
                  isSelected: formState.propertyType == 'All types',
                  onTap: () {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .updateField('propertyType', 'All types');
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: CustomFilterChipMobile(
                  label: 'House'.tr,
                  isSelected: formState.propertyType == 'House',
                  onTap: () {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .updateField('propertyType', 'House');
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CustomFilterChipMobile(
                  label: 'Townhouse'.tr,
                  isSelected: formState.propertyType == 'Townhouse',
                  onTap: () {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .updateField('propertyType', 'Townhouse');
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: CustomFilterChipMobile(
                  label: 'Villa'.tr,
                  isSelected: formState.propertyType == 'Villa',
                  onTap: () {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .updateField('propertyType', 'Villa');
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: CustomFilterChipMobile(
                  label: 'Commercial'.tr,
                  isSelected: formState.propertyType == 'Commercial',
                  onTap: () {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .updateField('propertyType', 'Commercial');
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: CustomFilterChipMobile(
                  label: 'Flat'.tr,
                  isSelected: formState.propertyType == 'Flat',
                  onTap: () {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .updateField('propertyType', 'Flat');
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CustomFilterChipMobile(
                  label: 'Duplex Homes'.tr,
                  isSelected: formState.propertyType == 'Duplex Homes',
                  onTap: () {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .updateField('propertyType', 'Duplex Homes');
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: CustomFilterChipMobile(
                  label: 'Land Plot'.tr,
                  isSelected: formState.propertyType == 'Land Plot',
                  onTap: () {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .updateField('propertyType', 'Land Plot');
                  },
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: 15),
        DottedLine(dashColor: theme.themeTextColor),
        SizedBox(height: 15),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Key Property Features".tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CustomColors.secondaryWidgetTextColor(context, ref),
            ),
          ),
        ),
        SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GradientDropdownAddOffer(
                selectedItem: formState.typeOfBuilding,
                isPc: false,
                hintText: 'Type of building'.tr,
                value: formState.typeOfBuilding!,
                items: ['Option 1'.tr, 'Option 2'.tr, 'Option 3'.tr],
                onChanged: (value) {
                  ref
                      .read(propertyValuationFormProvider.notifier)
                      .updateField('building_type', value);
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GradientDropdownAddOffer(
                selectedItem: formState.buildingMaterial,
                isPc: true,
                hintText: 'Building Material'.tr,
                value: formState.buildingMaterial!,
                items: ['Option 1'.tr, 'Option 2'.tr, 'Option 3'.tr],
                onChanged: (value) {
                  ref
                      .read(propertyValuationFormProvider.notifier)
                      .updateField('building_material', value);
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GradientDropdownAddOffer(
                selectedItem: formState.heatingType,
                isPc: true,
                hintText: 'Heating type'.tr,
                value: formState.heatingType!,
                items: ['Option 1'.tr, 'Option 2'.tr, 'Option 3'.tr],
                onChanged: (value) {
                  ref
                      .read(propertyValuationFormProvider.notifier)
                      .updateField('heating_type', value);
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GradientTextField(
                controller: formState.yearBuiltController,
                hintText: 'Year Built'.tr,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GradientTextField(
                controller: formState.floorAreaController,
                hintText: 'Floor area, m²'.tr,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GradientTextField(
                controller: formState.floorLevelController,
                hintText: 'Floor/Level'.tr,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
