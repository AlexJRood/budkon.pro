import 'package:crm/contact_panel/sections/ad_view_widgets/detail_row_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:portal/screens/edit_offer/components/edit_fileds.dart';
import 'package:core/theme/apptheme.dart';

class UtilityInfrastructureSection extends StatelessWidget {
  const UtilityInfrastructureSection({
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
        _row(context, 'windows_label'.tr, state.windowsController),
        _row(context, 'attic_type_label'.tr, state.atticTypeController),
        _row(context, 'security_label'.tr, state.securityController),
        _row(context, 'premises_location_label'.tr, state.premisesLocationController),
        _row(context, 'purpose_label'.tr, state.purposeController),
        _row(context, 'roof_label'.tr, state.roofController),
        _row(context, 'recreational_house_label'.tr, state.recreationalHouseController),
        _row(context, 'roof_covering_label'.tr, state.roofCoveringController),
        _row(context, 'lightning_label'.tr, state.lightningController),
        _row(context, 'construction_label'.tr, state.constructionController),
        _row(context, 'height_label'.tr, state.heightController, number: true),
        _row(context, 'office_rooms_label'.tr, state.officeRoomsController, number: true, fieldLabel: 'count_label'.tr),
        _row(context, 'social_facilities_label'.tr, state.socialFacilitiesController),
        _row(context, 'parking_description_label'.tr, state.parkingController, fieldLabel: 'parking_label'.tr),
        _row(context, 'ramp_label'.tr, state.rampController),
        _row(context, 'floor_material_label'.tr, state.floorMaterialController),
        _row(context, 'fencing_label'.tr, state.fencingController),
        _row(context, 'access_road_label'.tr, state.accessRoadController),
        _row(context, 'plot_type_label'.tr, state.plotTypeController),
        _row(context, 'dimensions_label'.tr, state.dimensionsController),
      ],
    );
  }

  Widget _row(
      BuildContext context,
      String label,
      TextEditingController controller, {
        bool number = false,
        String? fieldLabel,
      }) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    if (!isMobile) {
      return DetailRow(
        label: label,
        theme: theme,
        editingChild: SizedBox(
          width: number ? 160 : 240,
          child: number
              ? BuildNumberTextField(
            controller: controller,
            labelText: fieldLabel ?? label,
            unit: '',
            isEditAdView: true,
          )
              : BuildTextField(
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
                ? (number
                ? BuildNumberTextField(
              controller: controller,
              labelText: fieldLabel ?? label,
              unit: '',
              isEditAdView: true,
            )
                : BuildTextField(
              controller: controller,
              labelText: fieldLabel ?? label,
              maxLines: 1,
              isEditAdView: true,
            ))
                : Text(
              controller.text.isEmpty ? '-' : controller.text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: theme.textColor),
            ),
          ),
        ],
      ),
    );
  }
}
