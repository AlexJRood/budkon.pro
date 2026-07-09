import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:reports/reports/create_report_page/providers/providers_report.dart';
import 'package:reports/reports/create_report_page/widgets/components/filter_chips_custom.dart';
import 'package:core/common/shared_widgets/global_dropdown.dart';
import 'package:core/ui/forms/form_fields.dart';
import 'package:core/theme/backgroundgradient.dart';

class AdditionalFeaturesMobile extends ConsumerWidget {
  const AdditionalFeaturesMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(propertyValuationFormProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Additional Features".tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CustomColors.secondaryWidgetTextColor(context, ref),
            ),
          ),
        ),

        const SizedBox(height: 8),
        screenWidth < 500
            ? Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomFilterChipMobile(
                        label: 'Balcony'.tr,
                        isSelected: formState.additionalFeatures.contains(
                          'Balcony',
                        ),
                        onTap: () {
                          ref
                              .read(propertyValuationFormProvider.notifier)
                              .toggleAdditionalFeature('Balcony');
                        },
                      ),
                    ),
                    Expanded(
                      child: CustomFilterChipMobile(
                        label: 'Elevator'.tr,
                        isSelected: formState.additionalFeatures.contains(
                          'Elevator',
                        ),
                        onTap: () {
                          ref
                              .read(propertyValuationFormProvider.notifier)
                              .toggleAdditionalFeature('Elevator');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CustomFilterChipMobile(
                        label: 'Sauna'.tr,
                        isSelected: formState.additionalFeatures.contains(
                          'Sauna',
                        ),
                        onTap: () {
                          ref
                              .read(propertyValuationFormProvider.notifier)
                              .toggleAdditionalFeature('Sauna');
                        },
                      ),
                    ),
                    Expanded(
                      child: CustomFilterChipMobile(
                        label: 'Parking'.tr,
                        isSelected: formState.additionalFeatures.contains(
                          'Parking',
                        ),
                        onTap: () {
                          ref
                              .read(propertyValuationFormProvider.notifier)
                              .toggleAdditionalFeature('Parking');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CustomFilterChipMobile(
                        label: 'Gym'.tr,
                        isSelected: formState.additionalFeatures.contains(
                          'Gym',
                        ),
                        onTap: () {
                          ref
                              .read(propertyValuationFormProvider.notifier)
                              .toggleAdditionalFeature('Gym');
                        },
                      ),
                    ),
                    Expanded(
                      child: CustomFilterChipMobile(
                        label: 'Air conditioning'.tr,
                        isSelected: formState.additionalFeatures.contains(
                          'Air conditioning',
                        ),
                        onTap: () {
                          ref
                              .read(propertyValuationFormProvider.notifier)
                              .toggleAdditionalFeature('Air conditioning');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CustomFilterChipMobile(
                        label: 'Garden'.tr,
                        isSelected: formState.additionalFeatures.contains(
                          'Garden',
                        ),
                        onTap: () {
                          ref
                              .read(propertyValuationFormProvider.notifier)
                              .toggleAdditionalFeature('Garden');
                        },
                      ),
                    ),
                    Expanded(
                      child: CustomFilterChipMobile(
                        label: 'Basement'.tr,
                        isSelected: formState.additionalFeatures.contains(
                          'Basement',
                        ),
                        onTap: () {
                          ref
                              .read(propertyValuationFormProvider.notifier)
                              .toggleAdditionalFeature('Basement');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            )
            : Wrap(
              runSpacing: 10,
              spacing: 10,
              children: [
                CustomFilterChipMobile(
                  label: 'Balcony'.tr,
                  isSelected: formState.additionalFeatures.contains('Balcony'),
                  onTap: () {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .toggleAdditionalFeature('Balcony');
                  },
                ),
                CustomFilterChipMobile(
                  label: 'Elevator'.tr,
                  isSelected: formState.additionalFeatures.contains('Elevator'),
                  onTap: () {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .toggleAdditionalFeature('Elevator');
                  },
                ),
                CustomFilterChipMobile(
                  label: 'Sauna'.tr,
                  isSelected: formState.additionalFeatures.contains('Sauna'),
                  onTap: () {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .toggleAdditionalFeature('Sauna');
                  },
                ),
                CustomFilterChipMobile(
                  label: 'Parking'.tr,
                  isSelected: formState.additionalFeatures.contains('Parking'),
                  onTap: () {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .toggleAdditionalFeature('Parking');
                  },
                ),
                CustomFilterChipMobile(
                  label: 'Gym'.tr,
                  isSelected: formState.additionalFeatures.contains('Gym'),
                  onTap: () {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .toggleAdditionalFeature('Gym');
                  },
                ),
                CustomFilterChipMobile(
                  label: 'Air conditioning'.tr,
                  isSelected: formState.additionalFeatures.contains(
                    'Air conditioning',
                  ),
                  onTap: () {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .toggleAdditionalFeature('Air conditioning');
                  },
                ),
                CustomFilterChipMobile(
                  label: 'Garden'.tr,
                  isSelected: formState.additionalFeatures.contains('Garden'),
                  onTap: () {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .toggleAdditionalFeature('Garden');
                  },
                ),
                CustomFilterChipMobile(
                  label: 'Basement'.tr,
                  isSelected: formState.additionalFeatures.contains('Basement'),
                  onTap: () {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .toggleAdditionalFeature('Basement');
                  },
                ),
              ],
            ),
        const SizedBox(height: 20),

        // Extended Property Information Section
        Text(
          "Extended Property Information".tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: CustomColors.secondaryWidgetTextColor(context, ref),
          ),
        ),
        const SizedBox(height: 16),

        // Neighborhood field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Neighborhood",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CustomColors.secondaryWidgetTextColor(context, ref),
              ),
            ),
            const SizedBox(height: 8),
            GradientTextField(
              hintText: "Enter neighborhood name",
              controller: formState.neighborhoodController,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Distance to Public Transport field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Distance to Public Transport (minutes)",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CustomColors.secondaryWidgetTextColor(context, ref),
              ),
            ),
            const SizedBox(height: 8),
            GradientTextField(
              controller: formState.distanceToPublicTransportController,
              keyboardType: TextInputType.number,
              hintText: "Enter distance to public transport",
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Highway Access Checkbox
        Row(
          children: [
            Checkbox(
              value: formState.hasHighwayAccess,
              onChanged: (value) {
                ref
                    .read(propertyValuationFormProvider.notifier)
                    .updateField('hasHighwayAccess', value ?? false);
              },
              activeColor: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              "Has Highway Access",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CustomColors.secondaryWidgetTextColor(context, ref),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Boost Productivity dropdown
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Boost Productivity",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CustomColors.secondaryWidgetTextColor(context, ref),
              ),
            ),
            const SizedBox(height: 8),
            GradientDropdownReport(
              isPc: false,
              value: formState.boostProductivity ?? '',
              hintText: "Select productivity boost",
              items: const ["Yes", "No", "Partially"],
              selectedItem:
                  (formState.boostProductivity?.isNotEmpty ?? false)
                      ? formState.boostProductivity
                      : null,
              onChanged: (value) {
                ref
                    .read(propertyValuationFormProvider.notifier)
                    .updateField('boostProductivity', value ?? '');
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Exclusive Features field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Exclusive Features",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CustomColors.secondaryWidgetTextColor(context, ref),
              ),
            ),
            const SizedBox(height: 8),
            GradientTextField(
              controller: formState.exclusiveController,
              hintText: "Enter exclusive features",
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Boost Productivity Facility field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Boost Productivity Facility",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CustomColors.secondaryWidgetTextColor(context, ref),
              ),
            ),
            const SizedBox(height: 8),
            GradientTextField(
              controller: formState.boostProductivityFacilityController,
              maxLines: 2,
              hintText: "Enter boost productivity facility",
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Price per sqm field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Price per m²",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CustomColors.secondaryWidgetTextColor(context, ref),
              ),
            ),
            const SizedBox(height: 8),
            // GradientTextField(
            //   controller: formState.pricePerSqmController,
            //   keyboardType: TextInputType.number,
            //   hintText: "Enter price per square meter",
            // ),
          ],
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
