import 'package:crm/contact_panel/sections/ad_view_widgets/detail_row_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:portal/screens/edit_offer/components/edit_fileds.dart';
import 'package:core/theme/apptheme.dart';

class MetaSection extends StatelessWidget {
  const MetaSection({
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
        _row(
          context,
          'views_label'.tr,
          state.viewCountController,
          number: true,
        ),
        _row(
          context,
          'user_id_label'.tr,
          state.userController,
        ),
        _row(
          context,
          'client_id_label'.tr,
          state.clientController,
        ),
      ],
    );
  }

  Widget _row(
      BuildContext context,
      String label,
      TextEditingController controller, {
        bool number = false,
      }) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    if (!isMobile) {
      return DetailRow(
        label: label,
        theme: theme,
        editingChild: SizedBox(
          width: number ? 160 : 200,
          child: number
              ? BuildNumberTextField(
            controller: controller,
            labelText: label,
            unit: '',
            isEditAdView: true,
          )
              : BuildTextField(
            controller: controller,
            labelText: label,
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
                ? number
                ? BuildNumberTextField(
              controller: controller,
              labelText: label,
              unit: '',
              isEditAdView: true,
            )
                : BuildTextField(
              controller: controller,
              labelText: label,
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