import 'package:crm/contact_panel/sections/ad_view_widgets/detail_row_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:portal/screens/edit_offer/components/edit_fileds.dart';
import 'package:core/theme/apptheme.dart';

class FinancialRegistrySection extends StatelessWidget {
  const FinancialRegistrySection({
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
        _row(context, 'rent_label'.tr, state.rentController),
        _row(
          context,
          'land_registry_label'.tr,
          state.landAndMortgageRegisterController,
          fieldLabel: 'land_and_mortgage_hint'.tr,
        ),
        _row(context, 'estate_condition_label'.tr, state.estateConditionController),
        _row(context, 'remote_services_label'.tr, state.remoteServiceController),
        _row(context, 'crm_signature_label'.tr, state.crmSignatureController),
      ],
    );
  }

  Widget _row(
      BuildContext context,
      String label,
      TextEditingController controller, {
        String? fieldLabel,
      }) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    if (!isMobile) {
      return DetailRow(
        label: label,
        theme: theme,
        editingChild: SizedBox(
          width: 240,
          child: BuildTextField(
            controller: controller,
            labelText: fieldLabel ?? label,
            maxLines: 1,
            isEditAdView: true,
          ),
        ),
        viewText: controller.text,
        isEditing: isEditing,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 145,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: isEditing
                ? BuildTextField(
              controller: controller,
              labelText: fieldLabel ?? label,
              maxLines: 1,
              isEditAdView: true,
            )
                : Text(
              controller.text.trim().isEmpty ? '-' : controller.text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: theme.textColor),
            ),
          ),
        ],
      ),
    );
  }
}