import 'package:crm/contact_panel/sections/ad_view_widgets/detail_row_widget.dart';
import 'package:crm/contact_panel/sections/ad_view_widgets/parking_row_widget.dart';
import 'package:crm/data/add_field/edit_sell_offer_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:portal/screens/edit_offer/components/edit_fileds.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class DescriptionAndDetails extends StatelessWidget {
  const DescriptionAndDetails({
    super.key,
    required this.isEditing,
    required this.state,
    required this.theme,
    this.isMobile = false,
  });

  final bool isEditing;
  final bool isMobile;
  final EditOfferState state;
  final ThemeColors theme;

  String _floorViewText() {
    final floor = state.floorController.text.trim();
    final totalFloors = state.totalFloorsController.text.trim();

    if (floor.isEmpty && totalFloors.isEmpty) return '-';
    if (floor.isNotEmpty && totalFloors.isNotEmpty) {
      return '$floor/$totalFloors';
    }
    return floor.isNotEmpty ? floor : totalFloors;
  }

  @override
  Widget build(BuildContext context) {
    final useMobileLayout = isMobile || MediaQuery.of(context).size.width < 700;
    if (useMobileLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _descriptionBlock(),
          const SizedBox(height: 28),
          _detailsBlockMobile(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: _descriptionBlock()),
        const Expanded(flex: 1, child: SizedBox()),
        Expanded(flex: 3, child: _detailsBlockDesktop()),
      ],
    );
  }

  Widget _descriptionBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'description_title'.tr,
          style: AppTextStyles.interBold.copyWith(
            fontSize: 20,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 10),
        isEditing
            ? BuildTextFieldDes(
          controller: state.descriptionController,
          labelText: 'listing_description_label'.tr,
          isEditAdView: true,
        )
            : Text(
          state.descriptionController.text,
          style: AppTextStyles.interRegular14.copyWith(
            color: theme.textColor,
          ),
        ),
      ],
    );
  }

  Widget _detailsBlockMobile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'listing_details_title'.tr,
          style: AppTextStyles.interBold.copyWith(
            fontSize: 20,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 16),

        _mobileField(
          label: 'Floor area'.tr,
          child: BuildNumberTextField(
            controller: state.squareFootageController,
            labelText: 'm²'.tr,
            unit: 'm²',
            isEditAdView: true,
          ),
          viewText: state.squareFootageController.text.trim().isEmpty
              ? '-'
              : '${state.squareFootageController.text} m²',
        ),

        _mobileField(
          label: 'bathroom_number'.tr,
          child: BuildDropdownButtonFormField(
            controller: state.bathroomsController,
            items: const ['1', '2', '3', '4', '5', '6', '7+'],
            labelText: 'bathrooms_label'.tr,
            isEditAdView: true,
          ),
          viewText: state.bathroomsController.text.trim().isEmpty
              ? '-'
              : state.bathroomsController.text,
        ),

        _mobileField(
          label: 'room_number'.tr,
          child: BuildDropdownButtonFormField(
            controller: state.roomsController,
            items: const ['1', '2', '3', '4', '5', '6', '7+'],
            labelText: 'rooms_label'.tr,
            isEditAdView: true,
          ),
          viewText: state.roomsController.text.trim().isEmpty
              ? '-'
              : state.roomsController.text,
        ),

        _mobileField(
          label: 'Floor'.tr,
          child: Row(
            children: [
              Expanded(
                child: BuildNumberTextField(
                  controller: state.floorController,
                  labelText: 'Floor'.tr,
                  unit: '',
                  isEditAdView: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '/',
                  style: AppTextStyles.interRegular.copyWith(
                    fontSize: 14,
                    color: theme.textColor,
                  ),
                ),
              ),
              Expanded(
                child: BuildNumberTextField(
                  controller: state.totalFloorsController,
                  labelText: 'floors_label'.tr,
                  unit: '',
                  isEditAdView: true,
                ),
              ),
            ],
          ),
          viewText: _floorViewText(),
        ),

        _mobileField(
          label: 'ownership_form'.tr,
          child: BuildNumberTextField(
            controller: state.propertyFormController,
            labelText: 'ownership_form'.tr,
            unit: '',
            isEditAdView: true,
          ),
          viewText: state.propertyFormController.text.trim().isEmpty
              ? '-'
              : state.propertyFormController.text,
        ),

        ParkingRow(
          isEditing: isEditing,
          theme: theme,
          parkingController: state.parkingSpaceController,
        ),
      ],
    );
  }

  Widget _mobileField({
    required String label,
    required Widget child,
    required String viewText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.interRegular.copyWith(
              fontSize: 14,
              color: theme.textColor.withAlpha(210),
            ),
          ),
          const SizedBox(height: 8),
          isEditing
              ? SizedBox(width: double.infinity, child: child)
              : Text(
            viewText,
            style: AppTextStyles.interRegular14.copyWith(
              color: theme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsBlockDesktop() {
    const fieldWidth = 140.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'listing_details_title'.tr,
          style: AppTextStyles.interBold.copyWith(
            fontSize: 20,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 20),

        DetailRow(
          label: 'Floor area'.tr,
          theme: theme,
          editingChild: SizedBox(
            width: fieldWidth,
            child: BuildNumberTextField(
              controller: state.squareFootageController,
              labelText: 'm²'.tr,
              unit: 'm²',
              isEditAdView: true,
            ),
          ),
          viewText: state.squareFootageController.text.trim().isEmpty
              ? '-'
              : '${state.squareFootageController.text} m²',
          isEditing: isEditing,
        ),

        DetailRow(
          label: 'bathroom_number'.tr,
          theme: theme,
          editingChild: SizedBox(
            width: fieldWidth,
            child: BuildDropdownButtonFormField(
              controller: state.bathroomsController,
              items: const ['1', '2', '3', '4', '5', '6', '7+'],
              labelText: 'bathrooms_label'.tr,
              isEditAdView: true,
            ),
          ),
          viewText: state.bathroomsController.text.trim().isEmpty
              ? '-'
              : state.bathroomsController.text,
          isEditing: isEditing,
        ),

        DetailRow(
          label: 'room_number'.tr,
          theme: theme,
          editingChild: SizedBox(
            width: fieldWidth,
            child: BuildDropdownButtonFormField(
              controller: state.roomsController,
              items: const ['1', '2', '3', '4', '5', '6', '7+'],
              labelText: 'rooms_label'.tr,
              isEditAdView: true,
            ),
          ),
          viewText: state.roomsController.text.trim().isEmpty
              ? '-'
              : state.roomsController.text,
          isEditing: isEditing,
        ),

        DetailRow.composite(
          label: 'Floor'.tr,
          theme: theme,
          isEditing: isEditing,
          editingBuilder: () => Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 70,
                child: BuildNumberTextField(
                  controller: state.floorController,
                  labelText: 'Floor'.tr,
                  unit: '',
                  isEditAdView: true,
                ),
              ),
              Text(
                '/',
                style: AppTextStyles.interRegular.copyWith(
                  fontSize: 14,
                  color: theme.textColor,
                ),
              ),
              SizedBox(
                width: 70,
                child: BuildNumberTextField(
                  controller: state.totalFloorsController,
                  labelText: 'floors_label'.tr,
                  unit: '',
                  isEditAdView: true,
                ),
              ),
            ],
          ),
          viewText: _floorViewText(),
        ),

        DetailRow(
          label: 'ownership_form'.tr,
          theme: theme,
          editingChild: SizedBox(
            width: fieldWidth,
            child: BuildNumberTextField(
              controller: state.propertyFormController,
              labelText: 'ownership_form'.tr,
              unit: '',
              isEditAdView: true,
            ),
          ),
          viewText: state.propertyFormController.text.trim().isEmpty
              ? '-'
              : state.propertyFormController.text,
          isEditing: isEditing,
        ),

        ParkingRow(
          isEditing: isEditing,
          theme: theme,
          parkingController: state.parkingSpaceController,
        ),
      ],
    );
  }
}