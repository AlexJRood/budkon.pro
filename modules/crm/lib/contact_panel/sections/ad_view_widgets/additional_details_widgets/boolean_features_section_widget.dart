import 'package:crm/contact_panel/sections/ad_view_widgets/additional_details_widgets/bool_feature_row_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class BooleanFeaturesSection extends StatelessWidget {
  const BooleanFeaturesSection({
    super.key,
    required this.isEditing,
    required this.state,
    required this.theme,
  });

  final bool isEditing;
  final dynamic state;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    final features = [
      (
        label: 'balcony_label'.tr,
        controller: state.balconyController as ValueNotifier<bool>,
      ),
      (
        label: 'terrace_label'.tr,
        controller: state.terraceController as ValueNotifier<bool>,
      ),
      (
        label: 'sauna_label'.tr,
        controller: state.saunaController as ValueNotifier<bool>,
      ),
      (
        label: 'jacuzzi_label'.tr,
        controller: state.jacuzziController as ValueNotifier<bool>,
      ),
      (
        label: 'basement_label'.tr,
        controller: state.basementController as ValueNotifier<bool>,
      ),
      (
        label: 'elevator_label'.tr,
        controller: state.elevatorController as ValueNotifier<bool>,
      ),
      (
        label: 'garden_label'.tr,
        controller: state.gardenController as ValueNotifier<bool>,
      ),
      (
        label:'air_conditioning_label'.tr,
        controller: state.airConditioningController as ValueNotifier<bool>,
      ),
      (
        label: 'garage_label'.tr,
        controller: state.garageController as ValueNotifier<bool>,
      ),
      (
        label:'parking_space_label'.tr,
        controller: state.parkingSpaceController as ValueNotifier<bool>,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'additional_features_title'.tr,
          style: AppTextStyles.interBold.copyWith(
            fontSize: 16,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in features)
              BoolFeatureRow(
                label: item.label,
                isEditing: isEditing,
                theme: theme,
                controller: item.controller,
              ),
          ],
        ),
      ],
    );
  }
}