import 'package:crm/contact_panel/sections/ad_view_widgets/additional_details_widgets/bool_feature_row_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';

class PublicationFlagsSection extends StatelessWidget {
  const PublicationFlagsSection({
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
    return Column(
      children: [
        BoolFeatureRow(
          label: 'premium_2_label'.tr,
          isEditing: isEditing,
          theme: theme,
          controller: state.isPremium2,
        ),
        BoolFeatureRow(
          label: 'renewable_label'.tr,
          isEditing: isEditing,
          theme: theme,
          controller: state.isRenewable,
        ),
        BoolFeatureRow(
          label: 'active_label'.tr,
          isEditing: isEditing,
          theme: theme,
          controller: state.isActive,
        ),
        BoolFeatureRow(
          label: 'crm_update_block_label'.tr,
          isEditing: isEditing,
          theme: theme,
          controller: state.crmBlockUpdates,
        ),
      ],
    );
  }
}
