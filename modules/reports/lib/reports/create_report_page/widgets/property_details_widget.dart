import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/common/shared_widgets/location_components.dart';
import 'package:reports/reports/create_report_page/widgets/components/filter_chips_custom.dart';
import 'package:reports/reports/create_report_page/providers/providers_report.dart';
import 'package:core/ui/forms/form_fields.dart';
import 'package:core/theme/apptheme.dart';

class PropertyDetailsWidget extends ConsumerWidget {
  const PropertyDetailsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(propertyValuationFormProvider);
    final theme = ref.watch(themeColorsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'property_type'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).iconTheme.color,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          runSpacing: 10,
          spacing: 10,
          children: [
            CustomFilterChip(
              label: 'All types'.tr,
              isSelected: formState.propertyType == 'All types',
              onTap: () {
                ref
                    .read(propertyValuationFormProvider.notifier)
                    .updateField('propertyType', 'All types');
              },
            ),
            CustomFilterChip(
              label: 'House'.tr,
              isSelected: formState.propertyType == 'House',
              onTap: () {
                ref
                    .read(propertyValuationFormProvider.notifier)
                    .updateField('propertyType', 'House');
              },
            ),
            CustomFilterChip(
              label: 'Townhouse'.tr,
              isSelected: formState.propertyType == 'Townhouse',
              onTap: () {
                ref
                    .read(propertyValuationFormProvider.notifier)
                    .updateField('propertyType', 'Townhouse');
              },
            ),
            CustomFilterChip(
              label: 'Villa'.tr,
              isSelected: formState.propertyType == 'Villa',
              onTap: () {
                ref
                    .read(propertyValuationFormProvider.notifier)
                    .updateField('propertyType', 'Villa');
              },
            ),
            CustomFilterChip(
              label: 'Commercial'.tr,
              isSelected: formState.propertyType == 'Commercial',
              onTap: () {
                ref
                    .read(propertyValuationFormProvider.notifier)
                    .updateField('propertyType', 'Commercial');
              },
            ),
            CustomFilterChip(
              label: 'Flat'.tr,
              isSelected: formState.propertyType == 'Flat',
              onTap: () {
                ref
                    .read(propertyValuationFormProvider.notifier)
                    .updateField('propertyType', 'Flat');
              },
            ),
            CustomFilterChip(
              label: 'Duplex Homes'.tr,
              isSelected: formState.propertyType == 'Duplex Homes',
              onTap: () {
                ref
                    .read(propertyValuationFormProvider.notifier)
                    .updateField('propertyType', 'Duplex Homes');
              },
            ),
            CustomFilterChip(
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
        SizedBox(height: 16),
        Text(
          "Key Property Features".tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).iconTheme.color,
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GradientDropdownAddOffer(
                selectedItem: formState.typeOfBuilding,
                isPc: true,
                hintText: 'Type of building'.tr,
                value: formState.typeOfBuilding!,
                items: [
                  'Studio'.tr,
                  'Flat'.tr,
                  'House'.tr,
                  'Twin house'.tr,
                  'Row house'.tr,
                  'Invest'.tr,
                  'Commercial'.tr,
                  'Room'.tr,
                  'Apartment',
                ],
                onChanged: (value) {
                  ref
                      .read(propertyValuationFormProvider.notifier)
                      .updateField('building_type', value);
                },
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: GradientDropdownAddOffer(
                selectedItem: formState.buildingMaterial,
                isPc: true,
                hintText: 'Building Material'.tr,
                value: formState.buildingMaterial!,
                items: [
                  'Brick'.tr,
                  'Concrete'.tr,
                  'Reinforced Concrete'.tr,
                  'Prefabricated Panel'.tr,
                  'Wood / Timber'.tr,
                  'Steel Structure'.tr,
                  'Stone'.tr,
                  'Aerated Concrete (Ytong/Bloczek)'.tr,
                  'Mixed Construction'.tr,
                  'Log House'.tr,
                ],

                onChanged: (value) {
                  ref
                      .read(propertyValuationFormProvider.notifier)
                      .updateField('building_material', value);
                },
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: GradientDropdownAddOffer(
                selectedItem: formState.heatingType,
                isPc: true,
                hintText: 'Heating type'.tr,
                value: formState.heatingType!,
                items: [
                  'Gas Heating'.tr,
                  'Electric Heating'.tr,
                  'District Heating'.tr,
                  'Heat Pump (Air/Water)'.tr,
                  'Heat Pump (Ground Source)'.tr,
                  'Oil Heating'.tr,
                  'Solid Fuel (Coal/Wood/Pellets)'.tr,
                  'Underfloor Heating'.tr,
                  'Solar Thermal Heating'.tr,
                  'Hybrid Heating System'.tr,
                ],

                onChanged: (value) {
                  ref
                      .read(propertyValuationFormProvider.notifier)
                      .updateField('heating_type', value);
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
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
            SizedBox(width: 10),
            Expanded(
              child: GradientTextField(
                controller: formState.floorAreaController,
                hintText: 'Floor area, m²'.tr,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: GradientTextField(
                controller: formState.floorLevelController,
                hintText: 'Floor/Level'.tr,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),

        SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bedroom'.tr,
                    style: TextStyle(color: Theme.of(context).iconTheme.color),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children:
                        ['Any', '1', '2', '3', '4+'].map((label) {
                          final isSelected =
                              formState.bedrooms == 2147483647 &&
                                  label == 'Any' ||
                              formState.bedrooms == 4 && label == '4+' ||
                              formState.bedrooms.toString() == label;
                          return CustomFilterChip(
                            label: label,
                            isSelected: isSelected,
                            onTap: () {
                              final selectedValue =
                                  label == 'Any'
                                      ? 2147483647
                                      : label == '4+'
                                      ? 4
                                      : int.tryParse(label) ?? 0;
                              ref
                                  .read(propertyValuationFormProvider.notifier)
                                  .updateField('bedrooms', selectedValue);
                            },
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20), // space between the two columns
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bathrooms'.tr,
                    style: TextStyle(color: Theme.of(context).iconTheme.color),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children:
                        ['Any', '1', '2', '3', '4+'].map((label) {
                          final isSelected =
                              formState.bathrooms == 2147483647 &&
                                  label == 'Any' ||
                              formState.bathrooms == 4 && label == '4+' ||
                              formState.bathrooms.toString() == label;
                          return CustomFilterChip(
                            label: label,
                            isSelected: isSelected,
                            onTap: () {
                              final selectedValue =
                                  label == 'Any'
                                      ? 2147483647
                                      : label == '4+'
                                      ? 4
                                      : int.tryParse(label) ?? 0;
                              ref
                                  .read(propertyValuationFormProvider.notifier)
                                  .updateField('bathrooms', selectedValue);
                            },
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 16),
      ],
    );
  }
}
