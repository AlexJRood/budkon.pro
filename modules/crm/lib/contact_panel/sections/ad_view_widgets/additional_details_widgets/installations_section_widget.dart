import 'package:crm/contact_panel/sections/ad_view_widgets/additional_details_widgets/bool_feature_row_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';

class InstallationsSection extends StatelessWidget {
  const InstallationsSection({
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
    return Wrap(
      spacing: 6.0,
      runSpacing: 6.0,
      children: [
        BoolFeatureRow(
          label: 'electricity_label'.tr,
          isEditing: isEditing,
          theme: theme,
          controller: state.electricity,
        ),
        BoolFeatureRow(
          label:'energy_certificate_label'.tr,
          isEditing: isEditing,
          theme: theme,
          controller: state.energyCertificate,
        ),
        BoolFeatureRow(
          label: 'water_label'.tr,
          isEditing: isEditing,
          theme: theme,
          controller: state.water,
        ),
        BoolFeatureRow(
          label: 'gas_label'.tr,
          isEditing: isEditing,
          theme: theme,
          controller: state.gas,
        ),
        BoolFeatureRow(
          label: 'landline_phone_label'.tr,
          isEditing: isEditing,
          theme: theme,
          controller: state.phone,
        ),
        BoolFeatureRow(
          label: 'internet_label'.tr,
          isEditing: isEditing,
          theme: theme,
          controller: state.internet,
        ),
        BoolFeatureRow(
          label: 'sewerage_label'.tr,
          isEditing: isEditing,
          theme: theme,
          controller: state.sewerage,
        ),
        BoolFeatureRow(
          label: 'equipment_label'.tr,
          isEditing: isEditing,
          theme: theme,
          controller: state.equipment,
        ),
      ],
    );
  }
}
