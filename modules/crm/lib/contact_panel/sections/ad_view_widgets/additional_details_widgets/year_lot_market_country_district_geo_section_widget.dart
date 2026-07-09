import 'package:crm/contact_panel/sections/ad_view_widgets/detail_row_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:portal/screens/edit_offer/components/edit_fileds.dart';
import 'package:core/theme/apptheme.dart';

class YearLotMarketCountryDistrictGeoSection extends StatelessWidget {
  const YearLotMarketCountryDistrictGeoSection({
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
    final countryItems = ['poland_country'.tr, 'country_2'.tr, 'country_3'.tr];

    return Column(
      children: [
        _row(context, 'build_year_label'.tr, state.buildYearController,
            number: true, fieldLabel: 'year_label'.tr),
        _row(context, 'lot_size_label'.tr, state.lotSizeController,
            number: true, fieldLabel: 'm²'.tr, unit: 'm²'),
        _row(context, 'market_label'.tr, state.marketTypeController),
        _dropdownRow(
          context,
          'country_label'.tr,
          state.countryController,
          countryItems,
        ),
        _row(context, 'district_label'.tr, state.districtController),
        _row(context, 'latitude_label'.tr, state.latitudeController,
            fieldLabel: 'latitude_hint'.tr),
        _row(context, 'longitude_label'.tr, state.longitudeController,
            fieldLabel: 'longitude_hint'.tr),
        _row(context, 'zipcode_label'.tr, state.zipcodeController,
            number: true, fieldLabel: 'code_label'.tr),
        _row(context, 'phone_label'.tr, state.phoneNumberController,
            number: true),
        _row(context, 'phone_prefix_label'.tr,
            state.phoneNumberPrefixController,
            fieldLabel: 'prefix_hint'.tr),
      ],
    );
  }

  Widget _row(
      BuildContext context,
      String label,
      TextEditingController controller, {
        bool number = false,
        String? fieldLabel,
        String unit = '',
      }) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    if (!isMobile) {
      return DetailRow(
        label: label,
        theme: theme,
        editingChild: SizedBox(
          width: number ? 160 : 220,
          child: number
              ? BuildNumberTextField(
            controller: controller,
            labelText: fieldLabel ?? label,
            unit: unit,
            isEditAdView: true,
          )
              : BuildTextField(
            controller: controller,
            labelText: fieldLabel ?? label,
            maxLines: 1,
            isEditAdView: true,
          ),
        ),
        viewText: unit.isNotEmpty && controller.text.trim().isNotEmpty
            ? '${controller.text} $unit'
            : controller.text,
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
              labelText: fieldLabel ?? label,
              unit: unit,
              isEditAdView: true,
            )
                : BuildTextField(
              controller: controller,
              labelText: fieldLabel ?? label,
              maxLines: 1,
              isEditAdView: true,
            )
                : Text(
              controller.text.trim().isEmpty
                  ? '-'
                  : unit.isNotEmpty
                  ? '${controller.text} $unit'
                  : controller.text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: theme.textColor),
            ),
          ),
        ],
      ),
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
          width: 200,
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