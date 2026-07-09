import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

import 'package:reports/reports/create_report_page/providers/providers_report.dart';
import 'package:reports/reports/create_report_page/widgets/components/filter_chips_custom.dart';
import 'package:core/common/shared_widgets/global_dropdown.dart';
import 'package:core/ui/forms/form_fields.dart';

class AdditionalFeaturesMapWidget extends ConsumerWidget {
  const AdditionalFeaturesMapWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(propertyValuationFormProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Additional Features".tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
            Spacer(),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          runSpacing: 10,
          spacing: 10,
          children: [
            CustomFilterChip(
              label: 'Balcony'.tr,
              isSelected: formState.additionalFeatures.contains('Balcony'),
              onTap: () {
                ref
                    .read(propertyValuationFormProvider.notifier)
                    .toggleAdditionalFeature('Balcony');
              },
            ),
            CustomFilterChip(
              label: 'Elevator'.tr,
              isSelected: formState.additionalFeatures.contains('Elevator'),
              onTap: () {
                ref
                    .read(propertyValuationFormProvider.notifier)
                    .toggleAdditionalFeature('Elevator');
              },
            ),
            CustomFilterChip(
              label: 'Sauna'.tr,
              isSelected: formState.additionalFeatures.contains('Sauna'),
              onTap: () {
                ref
                    .read(propertyValuationFormProvider.notifier)
                    .toggleAdditionalFeature('Sauna');
              },
            ),
            CustomFilterChip(
              label: 'Parking'.tr,
              isSelected: formState.additionalFeatures.contains('Parking'),
              onTap: () {
                ref
                    .read(propertyValuationFormProvider.notifier)
                    .toggleAdditionalFeature('Parking');
              },
            ),
            CustomFilterChip(
              label: 'Gym'.tr,
              isSelected: formState.additionalFeatures.contains('Gym'),
              onTap: () {
                ref
                    .read(propertyValuationFormProvider.notifier)
                    .toggleAdditionalFeature('Gym');
              },
            ),
            CustomFilterChip(
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
            CustomFilterChip(
              label: 'Garden'.tr,
              isSelected: formState.additionalFeatures.contains('Garden'),
              onTap: () {
                ref
                    .read(propertyValuationFormProvider.notifier)
                    .toggleAdditionalFeature('Garden');
              },
            ),
            CustomFilterChip(
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

        // New Extended Property Information Section
        Text(
          "Extended Property Information".tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).iconTheme.color,
          ),
        ),
        const SizedBox(height: 16),

        // Neighborhood field
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Neighborhood".tr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GradientTextField(
                    controller: formState.neighborhoodController,
                    hintText: 'enter_neighborhood_name'.tr,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'distance_to_public_transport_minutes'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GradientTextField(
                    controller: formState.distanceToPublicTransportController,
                    keyboardType: TextInputType.number,
                    hintText: 'enter_distance_to_public_transport'.tr,
                  ),
                ],
              ),
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
              'has_highway_access'.tr,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Productivity Boost and Exclusive fields
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Boost_productivity'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GradientDropdownReport(
                    isPc: true,
                    value: formState.boostProductivity ?? '',
                    hintText:'select_productivity_boost'.tr,
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
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Exclusive Features".tr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GradientTextField(
                    controller: formState.exclusiveController,
                    hintText: 'describe_exclusive_features'.tr,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Boost Productivity Facility field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'boost_productivity_facility'.tr,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
            const SizedBox(height: 8),
            GradientTextField(
              controller: formState.boostProductivityFacilityController,
              maxLines: 2,
              hintText: 'describe_facilities_that_boost_productivity'.tr,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Price per sqm field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'price_per_m2'.tr,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
            // const SizedBox(height: 8),
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
