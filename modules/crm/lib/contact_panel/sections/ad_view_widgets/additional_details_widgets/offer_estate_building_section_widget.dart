import 'package:crm/contact_panel/sections/ad_view_widgets/detail_row_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:portal/screens/edit_offer/components/edit_fileds.dart';
import 'package:core/theme/apptheme.dart';

class OfferEstateBuildingSection extends StatelessWidget {
  const OfferEstateBuildingSection({
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
    final offerTypeItems = ['want_to_sell_option'.tr, 'want_to_rent_option'.tr];

    final estateTypeItems = [
      'apartment_type_option'.tr,
      'studio_type_option'.tr,
      'penthouse_type_option'.tr,
      'house_type_option'.tr,
      'semi_detached_type_option'.tr,
      'townhouse_type_option'.tr,
      'investments_type_option'.tr,
      'plots_type_option'.tr,
      'commercial_type_option'.tr,
      'warehouse_type_option'.tr,
      'rooms_type_option'.tr,
      'garages_type_option'.tr,
    ];

    final buildingTypeItems = [
      'block_building_option'.tr,
      'apartment_building_option'.tr,
      'townhouse_type_option'.tr,
      'tenement_building_option'.tr,
      'highrise_building_option'.tr,
      'loft_building_option'.tr,
    ];

    final heatingTypeItems = [
      'gas_heating_option'.tr,
      'electric_heating_option'.tr,
      'district_heating_option'.tr,
      'heat_pump_heating_option'.tr,
      'oil_heating_option'.tr,
      'all_heating_option'.tr,
      'not_provided_heating_option'.tr,
    ];

    final buildingMaterialItems = [
      'brick_material_option'.tr,
      'large_panel_material_option'.tr,
      'silicate_material_option'.tr,
      'concrete_material_option'.tr,
      'aerated_concrete_material_option'.tr,
      'hollow_block_material_option'.tr,
      'reinforced_concrete_material_option'.tr,
      'ceramsite_material_option'.tr,
      'wood_material_option'.tr,
      'other_material_option'.tr,
    ];

    return Column(
      children: [
        _dropdownRow(
          context,
          'offer_type_label'.tr,
          state.offerTypeController,
          offerTypeItems,
        ),
        _dropdownRow(
          context,
          'estate_type_label'.tr,
          state.estateTypeController,
          estateTypeItems,
        ),
        _dropdownRow(
          context,
          'building_type_label'.tr,
          state.buildingTypeController,
          buildingTypeItems,
        ),
        _dropdownRow(
          context,
          'building_material_label'.tr,
          state.buildingMaterialController,
          buildingMaterialItems,
        ),
        _dropdownRow(
          context,
          'heating_label'.tr,
          state.heatingTypeController,
          heatingTypeItems,
        ),
      ],
    );
  }

  Widget _dropdownRow(
      BuildContext context,
      String label,
      TextEditingController controller,
      List<String> items,
      ) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    if (!isMobile) {
      return DetailRow(
        label: label,
        theme: theme,
        editingChild: SizedBox(
          width: 240,
          child: BuildDropdownButtonFormField(
            controller: controller,
            items: items,
            labelText: label,
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
                ? BuildDropdownButtonFormField(
              controller: controller,
              items: items,
              labelText: label,
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