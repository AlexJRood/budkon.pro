import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/button_style.dart';

import 'package:core/platform/filters/filters_const.dart';
import 'package:core/platform/ad_type_utils.dart';
import 'package:crm_agent/add_client_form/components/sell/sell_estate_filtered_button.dart';
import 'package:crm_agent/add_client_form/components/sell/sell_additional_info_filtered_button.dart';
import 'package:crm_agent/add_client_form/components/sell/sell_add_filltered_button.dart';
import 'package:crm_agent/add_client_form/components/sell/sell_custom_drop_down.dart';
import 'package:crm_agent/add_client_form/components/sell/sell_custom_text_field.dart';
import 'package:crm_agent/add_client_form/components/sell/advertisment_information_image_widget.dart';
import 'package:crm_agent/add_client_form/controllers/sell_controlers.dart';
import 'package:crm_agent/add_client_form/controllers/transaction_controlers.dart';
import 'package:crm_agent/add_client_form/provider/send_form_provider.dart';
import 'package:crm_agent/add_client_form/provider/transaction_provider.dart';
import 'package:crm_agent/add_client_form/provider/sell_estate_data_provider.dart';
import 'package:crm_agent/add_client_form/widgets/transaction.dart';
import 'package:crm_agent/add_client_form/components/event/event_view_widget.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/common/autocompletion/autocomplete.dart';
import 'package:crm_agent/add_client_form/widgets/kw_preview_widget.dart';
import 'package:crm_agent/add_client_form/widgets/kw_input_widget.dart';

class SellWidget extends ConsumerStatefulWidget {
  final GlobalKey<FormState> formKey;
  final bool isMobile;

  const SellWidget({
    super.key,
    required this.formKey,
    this.isMobile = false,
  });

  @override
  ConsumerState<SellWidget> createState() => _SellWidgetState();
}

class _SellWidgetState extends ConsumerState<SellWidget> {
  late final TextEditingController _stateController;
  late final TextEditingController _cityController;
  late final TextEditingController _districtController;
  late final TextEditingController _countyController;
  late final TextEditingController _communeController;
  late final FocusNode _titleFocusNode;
  late final FocusNode _descriptionFocusNode;
  late final FocusNode _streetFocusNode;
  late final FocusNode _zipcodeFocusNode;

  String _stringFromDraft(Map<dynamic, dynamic> draft, String key) {
    final value = draft[key];
    if (value == null) return '';
    return value.toString();
  }

  @override
  void initState() {
    super.initState();

    _stateController = TextEditingController();
    _cityController = TextEditingController();
    _districtController = TextEditingController();
    _countyController = TextEditingController();
    _communeController = TextEditingController();
    _titleFocusNode = FocusNode();
    _descriptionFocusNode = FocusNode();
    _streetFocusNode = FocusNode();
    _zipcodeFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final draft = ref.read(sellOfferFilterCacheProvider);
      _syncLocationControllersFromDraft(draft);
    });
  }

  @override
  void dispose() {
    _stateController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _countyController.dispose();
    _communeController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _streetFocusNode.dispose();
    _zipcodeFocusNode.dispose();
    super.dispose();
  }

  void _syncLocationControllersFromDraft(Map<dynamic, dynamic> draft) {
    _stateController.text = _stringFromDraft(draft, 'state');
    _cityController.text = _stringFromDraft(draft, 'city');
    _districtController.text = _stringFromDraft(draft, 'district');
    _countyController.text = _stringFromDraft(draft, 'county');
    _communeController.text = _stringFromDraft(draft, 'commune');
  }

  void _clearLocationControllers() {
    _stateController.clear();
    _cityController.clear();
    _districtController.clear();
    _countyController.clear();
    _communeController.clear();
  }

  void _clearLocationDraft(dynamic sellOfferDraftData) {
    sellOfferDraftData.addData('location_query', '');
    sellOfferDraftData.addData('location_selection', null);

    sellOfferDraftData.addData('city', '');
    sellOfferDraftData.addData('state', '');
    sellOfferDraftData.addData('district', '');

    sellOfferDraftData.addData('geo_id', '');
    sellOfferDraftData.addData('geo_type', '');
    sellOfferDraftData.addData('geo_level', null);

    sellOfferDraftData.addData('location_name', '');
    sellOfferDraftData.addData('location_display', '');
    sellOfferDraftData.addData('location_path', <String>[]);

    sellOfferDraftData.addData('county', '');
    sellOfferDraftData.addData('commune', '');
    sellOfferDraftData.addData('locality_sym', '');
    sellOfferDraftData.addData('country', '');

    _clearLocationControllers();
  }

  void _applyLocationSelection(
    LocationSelection selection,
    dynamic sellOfferDraftData,
  ) {
    if (selection.isEmpty) {
      _clearLocationDraft(sellOfferDraftData);
      return;
    }

    sellOfferDraftData.addData('location_selection', selection.toJson());
    sellOfferDraftData.addData('location_name', selection.name);
    sellOfferDraftData.addData('location_display', selection.display);
    sellOfferDraftData.addData('location_path', selection.path);

    sellOfferDraftData.addData('city', selection.city);
    sellOfferDraftData.addData('state', selection.state);
    sellOfferDraftData.addData('district', selection.district);

    sellOfferDraftData.addData('county', selection.county);
    sellOfferDraftData.addData('commune', selection.commune);
    sellOfferDraftData.addData('locality_sym', selection.localitySym);

    sellOfferDraftData.addData('geo_id', selection.id);
    sellOfferDraftData.addData('geo_type', selection.type);
    sellOfferDraftData.addData('geo_level', selection.level);

    sellOfferDraftData.addData('country', 'Poland');

    _stateController.text = selection.state;
    _cityController.text = selection.city;
    _districtController.text = selection.district;
    _countyController.text = selection.county;
    _communeController.text = selection.commune;
  }

  Widget _buildLocationReadOnlyField({
    required String label,
    required TextEditingController controller,
    required WidgetRef ref,
  }) {
    final theme = ref.watch(themeColorsProvider);
    final isEmpty = controller.text.trim().isEmpty;

    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.dashboardContainer.withAlpha(160),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dashboardBoarder.withAlpha(isEmpty ? 50 : 100),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textColor.withAlpha(isEmpty ? 100 : 150),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.auto_awesome_rounded,
                size: 10,
                color: theme.textColor.withAlpha(60),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: isEmpty
                  ? Text(
                      'auto',
                      style: TextStyle(
                        color: theme.textColor.withAlpha(45),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : Text(
                      controller.text.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addClientFormNotifier = ref.read(addClientFormProvider.notifier);
    final sellControllers = ref.watch(sellControllersProvider);
    final sellOfferDraftData = ref.read(sellOfferFilterCacheProvider.notifier);
    final sellOfferDraftState = ref.watch(sellOfferFilterCacheProvider);

    final tranactionIsSellerController = ref.watch(
      transactionControllersProvider,
    );
    tranactionIsSellerController.isSellerController.value = true;

    final theme = ref.watch(themeColorsProvider);
    final estateType = (sellOfferDraftState['estate_type'] ?? '').toString();

    final locationDisplay =
        _stringFromDraft(sellOfferDraftState, 'location_display');
    final initialLocationText = locationDisplay.isNotEmpty
        ? locationDisplay
        : _stringFromDraft(sellOfferDraftState, 'location_query');

    return Form(
      key: widget.formKey,
      child: Column(
        spacing: 20,
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.adPopBackground,
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            child: Column(
              children: [
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.themeColor,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(6),
                      topLeft: Radius.circular(6),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Advertisment Information'.tr,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const Icon(Icons.expand_more, color: AppColors.white),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    spacing: 12,
                    children: [
                      Column(
                        spacing: 12,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Photos'.tr,
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          AdvertisementInformationImageWidget(),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Column(
                        spacing: 12,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Offer type'.tr,
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            spacing: 12,
                            children: [
                              Expanded(
                                child: CrmAddFilteredButton(
                                  text: 'offer_type_sell'.tr,
                                  filterValue: 'sell',
                                  filterKey: 'offer_type',
                                  alignment: Alignment.centerLeft,
                                  minHeight: 46,
                                ),
                              ),
                              Expanded(
                                child: CrmAddFilteredButton(
                                  text: 'offer_type_rent'.tr,
                                  filterValue: 'rent',
                                  filterKey: 'offer_type',
                                  alignment: Alignment.centerLeft,
                                  minHeight: 46,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Column(
                        spacing: 12,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'General Information'.tr,
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SellCustomTextField(
                            id: 10,
                            valueKey: 'title',
                            hintText: 'Add title'.tr,
                            maxLines: 5,
                            controller: sellControllers.titleController,
                            focusNode: _titleFocusNode,
                            nextFocusNode: _descriptionFocusNode,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "title_cant_be_empty".tr;
                              }
                              return null;
                            },
                            onChanged: (value) {
                              addClientFormNotifier.updateTextField(
                                sellControllers.titleController,
                                value,
                              );
                              sellOfferDraftData.addData('title', value);
                            },
                          ),
                          SellCustomTextField(
                            id: 11,
                            valueKey: 'description',
                            hintText: 'Description'.tr,
                            maxLines: 50,
                            minLines: 5,
                            controller: sellControllers.descriptionController,
                            focusNode: _descriptionFocusNode,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).unfocus();
                            },
                            onChanged: (value) {
                              addClientFormNotifier.updateTextField(
                                sellControllers.descriptionController,
                                value,
                              );
                              sellOfferDraftData.addData('description', value);
                            },
                          ),
                          const SizedBox(height: 30),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'property_type'.tr,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                alignment: WrapAlignment.start,
                                spacing: 12,
                                runSpacing: 12,
                                children:
                                    FilterPopConst.estateTypes.map((estateType) {
                                  return ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minWidth: 120,
                                      maxWidth: 180,
                                    ),
                                    child: CrmAddEstateTypeFilteredButton(
                                      text: estateType['text']!.tr,
                                      filterValue: estateType['filterValue']!,
                                      filterKey: 'estate_type',
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          /// LOCATION
                          Column(
                            spacing: 12,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Location'.tr,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              AutoCompleteWidget(
                                provider: 'sell-estate-location',
                                initialText: initialLocationText,
                                hintText: 'Search city / district'.tr,
                                onQueryChanged: (ref, query) {
                                  sellOfferDraftData.addData(
                                    'location_query',
                                    query,
                                  );

                                  if (query.trim().isEmpty) {
                                    _clearLocationDraft(sellOfferDraftData);
                                    if (mounted) setState(() {});
                                  }
                                },
                                onLocationChanged: (ref, selection) {
                                  _applyLocationSelection(
                                    selection,
                                    sellOfferDraftData,
                                  );
                                  if (mounted) setState(() {});
                                },
                              ),

                              if (locationDisplay.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline_rounded, size: 13, color: theme.textColor.withAlpha(90)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Wybierz lokalizację z listy — pola poniżej wypełnią się automatycznie'.tr,
                                        style: TextStyle(fontSize: 12, color: theme.textColor.withAlpha(90)),
                                      ),
                                    ],
                                  ),
                                ),

                              if (locationDisplay.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: theme.themeColor.withAlpha(30),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: theme.themeColor.withAlpha(80)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on_rounded, size: 16, color: theme.themeColor),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          locationDisplay,
                                          style: TextStyle(color: theme.textColor, fontSize: 14, fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          _clearLocationDraft(sellOfferDraftData);
                                          if (mounted) setState(() {});
                                        },
                                        child: Icon(Icons.close_rounded, size: 18, color: theme.textColor.withAlpha(140)),
                                      ),
                                    ],
                                  ),
                                ),

                              if (_stateController.text.isNotEmpty || _cityController.text.isNotEmpty) ...[
                              Row(
                                spacing: 12,
                                children: [
                                  Expanded(
                                    child: _buildLocationReadOnlyField(
                                      label: 'State'.tr,
                                      controller: _stateController,
                                      ref: ref,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildLocationReadOnlyField(
                                      label: 'City'.tr,
                                      controller: _cityController,
                                      ref: ref,
                                    ),
                                  ),
                                ],
                              ),

                              Row(
                                spacing: 12,
                                children: [
                                  Expanded(
                                    child: _buildLocationReadOnlyField(
                                      label: 'heating_type_district'.tr,
                                      controller: _districtController,
                                      ref: ref,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildLocationReadOnlyField(
                                      label: 'county'.tr,
                                      controller: _countyController,
                                      ref: ref,
                                    ),
                                  ),
                                ],
                              ),

                              if (_communeController.text.trim().isNotEmpty)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildLocationReadOnlyField(
                                        label: 'Commune'.tr,
                                        controller: _communeController,
                                        ref: ref,
                                      ),
                                    ),
                                  ],
                                ),
                              ], // end location detail grid

                              Row(
                                spacing: 12,
                                children: [
                                  Expanded(
                                    child: SellCustomTextField(
                                      id: 15,
                                      valueKey: 'street',
                                      hintText: 'Street Address'.tr,
                                      controller:
                                          sellControllers.streetController,
                                      focusNode: _streetFocusNode,
                                      nextFocusNode: _zipcodeFocusNode,
                                      textInputAction: TextInputAction.next,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Address can't be empty".tr;
                                        }
                                        return null;
                                      },
                                      onChanged: (value) {
                                        addClientFormNotifier.updateTextField(
                                          sellControllers.streetController,
                                          value,
                                        );
                                        sellOfferDraftData.addData(
                                          'street',
                                          value,
                                        );
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: SellCustomTextField(
                                      id: 16,
                                      valueKey: 'postal_code',
                                      hintText: 'Zipcode'.tr,
                                      maxLength: 10,
                                      controller:
                                          sellControllers.zipcodeController,
                                      focusNode: _zipcodeFocusNode,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) {
                                        FocusScope.of(context).unfocus();
                                      },
                                      onChanged: (value) {
                                        addClientFormNotifier.updateTextField(
                                          sellControllers.zipcodeController,
                                          value,
                                        );
                                        sellOfferDraftData.addData(
                                          'zipcode',
                                          value,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),
                          KwInputWidget(
                            kwController: sellControllers.landAndMortgageRegisterController,
                            onChanged: (value) {
                              sellOfferDraftData.addData('land_and_mortgage_register', value);
                              ref.read(agentTransactionCacheProvider.notifier)
                                  .addTransactionData('land_and_mortgage_register', value);
                            },
                          ),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: sellControllers.landAndMortgageRegisterController,
                            builder: (_, v, __) {
                              if (true) return const SizedBox.shrink(); // TODO: re-enable when EKW proxy configured
                              if (v.text.trim().isEmpty) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: KwPreviewButton(
                                  kwController: sellControllers.landAndMortgageRegisterController,
                                  onAutofill: (fields) {
                                    void _set(String key, TextEditingController ctrl) {
                                      final val = fields[key];
                                      if (val == null) return;
                                      final str = val.toString();
                                      ctrl.text = str;
                                      sellOfferDraftData.addData(key, str);
                                    }
                                    _set('street', sellControllers.streetController);
                                    _set('city', sellControllers.cityController);
                                    _set('zipcode', sellControllers.zipcodeController);
                                    _set('state', sellControllers.stateController);
                                    final area = fields['square_footage'];
                                    if (area != null) {
                                      final areaStr = area.toString();
                                      sellControllers.squareFootageController.text = areaStr;
                                      sellOfferDraftData.addData('square_footage', areaStr);
                                    }
                                    final estateType = fields['estate_type'];
                                    if (estateType != null) {
                                      sellControllers.estateTypeController.text = estateType.toString();
                                      sellOfferDraftData.addData('estate_type', estateType.toString());
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                          if (!AdTypeUtils.isPlot(estateType)) ...[
                          const SizedBox(height: 30),
                          Column(
                            spacing: 12,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Key Property Features'.tr,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Row(
                                spacing: 12,
                                children: [
                                  Expanded(
                                    child: AddClientFormCustomDropDown(
                                      options:
                                          FilterPopConst.typeOfBuildingOptions,
                                      valueKey: 'building_type',
                                      hintText: 'Type of building'.tr,
                                      id: 14,
                                    ),
                                  ),
                                  Expanded(
                                    child: AddClientFormCustomDropDown(
                                      options: FilterPopConst
                                          .buildingMaterialOptions,
                                      valueKey: 'building_material',
                                      hintText: 'Building Material'.tr,
                                      id: 15,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                spacing: 12,
                                children: [
                                  Expanded(
                                    child: AddClientFormCustomDropDown(
                                      options:
                                          FilterPopConst.heatingTypeOptions,
                                      valueKey: 'heating_type',
                                      hintText: 'Heating type'.tr,
                                      id: 16,
                                    ),
                                  ),
                                  Expanded(
                                    child: SellCustomTextField(
                                      controller: sellControllers.buildYearController,
                                      maxLength: 4,
                                      valueKey: 'build_year',
                                      hintText: 'Build Year'.tr,
                                      id: 17,
                                      onChanged: (value) {
                                        addClientFormNotifier.updateTextField(
                                          sellControllers.buildYearController,
                                          value,
                                        );
                                        sellOfferDraftData.addData(
                                          'build_year',
                                          value,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          ], // end !isPlot
                          if (AdTypeUtils.showRoomsAndBathrooms(estateType) && widget.isMobile)
                            Column(
                              spacing: 12,
                              children: [
                                Column(
                                  spacing: 12,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Rooms'.tr,
                                      style: TextStyle(color: theme.textColor),
                                    ),
                                    Row(
                                      spacing: 8,
                                      children: [
                                        CrmAddFilteredButton(
                                          text: 'Any'.tr,
                                          filterValue: 'any',
                                          filterKey: 'rooms',
                                        ),
                                        CrmAddFilteredButton(
                                          text: '1',
                                          filterValue: '1',
                                          filterKey: 'rooms',
                                        ),
                                        CrmAddFilteredButton(
                                          text: '2',
                                          filterValue: '2',
                                          filterKey: 'rooms',
                                        ),
                                        CrmAddFilteredButton(
                                          text: '3',
                                          filterValue: '3',
                                          filterKey: 'rooms',
                                        ),
                                        CrmAddFilteredButton(
                                          text: '4',
                                          filterValue: '4',
                                          filterKey: 'rooms',
                                        ),
                                        CrmAddFilteredButton(
                                          text: '5',
                                          filterValue: '5',
                                          filterKey: 'rooms',
                                        ),
                                        CrmAddFilteredButton(
                                          text: '6+',
                                          filterValue: '6+',
                                          filterKey: 'rooms',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Column(
                                  spacing: 12,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bathrooms'.tr,
                                      style: TextStyle(color: theme.textColor),
                                    ),
                                    Row(
                                      spacing: 8,
                                      children: [
                                        CrmAddFilteredButton(
                                          text: 'Any'.tr,
                                          filterValue: 'any',
                                          filterKey: 'bathrooms',
                                        ),
                                        CrmAddFilteredButton(
                                          text: '1',
                                          filterValue: '1',
                                          filterKey: 'bathrooms',
                                        ),
                                        CrmAddFilteredButton(
                                          text: '2',
                                          filterValue: '2',
                                          filterKey: 'bathrooms',
                                        ),
                                        CrmAddFilteredButton(
                                          text: '3',
                                          filterValue: '3',
                                          filterKey: 'bathrooms',
                                        ),
                                        CrmAddFilteredButton(
                                          text: '4',
                                          filterValue: '4',
                                          filterKey: 'bathrooms',
                                        ),
                                        CrmAddFilteredButton(
                                          text: '5',
                                          filterValue: '5',
                                          filterKey: 'bathrooms',
                                        ),
                                        CrmAddFilteredButton(
                                          text: '6+',
                                          filterValue: '6+',
                                          filterKey: 'bathrooms',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          if (AdTypeUtils.showRoomsAndBathrooms(estateType) && !widget.isMobile)
                            Row(
                              spacing: 12,
                              children: [
                                Expanded(
                                  child: Column(
                                    spacing: 12,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Rooms'.tr,
                                        style: TextStyle(
                                          color: theme.textColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Row(
                                        spacing: 8,
                                        children: [
                                          CrmAddFilteredButton(
                                            text: 'Any'.tr,
                                            filterValue: 'any',
                                            filterKey: 'rooms',
                                          ),
                                          CrmAddFilteredButton(
                                            text: '1',
                                            filterValue: '1',
                                            filterKey: 'rooms',
                                          ),
                                          CrmAddFilteredButton(
                                            text: '2',
                                            filterValue: '2',
                                            filterKey: 'rooms',
                                          ),
                                          CrmAddFilteredButton(
                                            text: '3',
                                            filterValue: '3',
                                            filterKey: 'rooms',
                                          ),
                                          CrmAddFilteredButton(
                                            text: '4',
                                            filterValue: '4',
                                            filterKey: 'rooms',
                                          ),
                                          CrmAddFilteredButton(
                                            text: '5',
                                            filterValue: '5',
                                            filterKey: 'rooms',
                                          ),
                                          CrmAddFilteredButton(
                                            text: '6+',
                                            filterValue: '6+',
                                            filterKey: 'rooms',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    spacing: 12,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Bathrooms'.tr,
                                        style: TextStyle(
                                          color: theme.textColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Row(
                                        spacing: 8,
                                        children: [
                                          CrmAddFilteredButton(
                                            text: 'Any'.tr,
                                            filterValue: 'any',
                                            filterKey: 'bathrooms',
                                          ),
                                          CrmAddFilteredButton(
                                            text: '1',
                                            filterValue: '1',
                                            filterKey: 'bathrooms',
                                          ),
                                          CrmAddFilteredButton(
                                            text: '2',
                                            filterValue: '2',
                                            filterKey: 'bathrooms',
                                          ),
                                          CrmAddFilteredButton(
                                            text: '3',
                                            filterValue: '3',
                                            filterKey: 'bathrooms',
                                          ),
                                          CrmAddFilteredButton(
                                            text: '4',
                                            filterValue: '4',
                                            filterKey: 'bathrooms',
                                          ),
                                          CrmAddFilteredButton(
                                            text: '5',
                                            filterValue: '5',
                                            filterKey: 'bathrooms',
                                          ),
                                          CrmAddFilteredButton(
                                            text: '6+',
                                            filterValue: '6+',
                                            filterKey: 'bathrooms',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 30),
                          Column(
                            spacing: 12,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pricing Information'.tr,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Row(
                                spacing: 12,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    child: AddClientFormCustomDropDown(
                                      options: FilterPopConst.currencyOptions,
                                      valueKey: 'currency',
                                      hintText: 'Currency'.tr,
                                      id: 20,
                                      validator: (value) {
                                        if (value == null ||
                                            value.toString().isEmpty) {
                                          return 'currency_is_required'.tr;
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  
                                  Expanded(
                                    child: SellCustomTextField(
                                      id: 25,
                                      valueKey: 'price',
                                      hintText: 'Price'.tr,
                                      useThousandsSeparator: true,
                                      maxLength: 20, // np. max 999999999
                                      emitRawValue: true, // onChanged dostanie np. 55000000
                                      controller:
                                          sellControllers.priceController,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Price can't be empty".tr;
                                        }
                                        return null;
                                      },
                                      onChanged: (value) {
                                        addClientFormNotifier.updateTextField(
                                          sellControllers.priceController,
                                          value,
                                        );
                                        sellOfferDraftData.addData(
                                          'price',
                                          value,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (AdTypeUtils.showResidentialAmenities(estateType)) ...[
                          const SizedBox(height: 30),
                          Column(
                            spacing: 12,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'Additional Features'.tr,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Wrap(
                                alignment: WrapAlignment.start,
                                spacing: 12,
                                runSpacing: 12,
                                children:
                                    FilterPopConst.additionalInfo.map((
                                  additionalInfo,
                                ) {
                                  return ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minWidth: 120,
                                      maxWidth: 180,
                                    ),
                                    child:
                                        CrmAddAdditionalInfoFilteredButton(
                                      text: additionalInfo['text']!,
                                      filterKey:
                                          additionalInfo['filterKey']!,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          ], // end showResidentialAmenities
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: 55,
                                width: 150,
                                child: ElevatedButton(
                                  style: elevatedButtonStyleRounded10,
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      barrierDismissible: true,
                                      builder: (ctx) {
                                        final t = ref.watch(
                                          themeColorsProvider,
                                        );
                                        return AlertDialog(
                                          backgroundColor:
                                              t.dashboardContainer,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          title: Text(
                                            'Confirm'.tr,
                                            style: TextStyle(
                                              color: t.textColor,
                                            ),
                                          ),
                                          content: Text(
                                            'are_you_sure_you_want_to_clear_data_from_this_form'.tr,
                                            style: TextStyle(
                                              color: t.textColor,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(false),
                                              child: Text(
                                                'Cancel'.tr,
                                                style: TextStyle(
                                                  color: t.textColor,
                                                ),
                                              ),
                                            ),
                                            FilledButton.tonal(
                                              style: ButtonStyle(
                                                backgroundColor:
                                                    WidgetStatePropertyAll(
                                                  Colors.red.shade700,
                                                ),
                                                foregroundColor:
                                                    const WidgetStatePropertyAll(
                                                  Colors.white,
                                                ),
                                              ),
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(true),
                                              child: Text('Clear'.tr),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (confirmed == true) {
                                      ref
                                          .read(
                                            sellOfferFilterCacheProvider
                                                .notifier,
                                          )
                                          .clearData(ref);
                                      _clearLocationControllers();
                                      if (mounted) setState(() {});
                                    }
                                  },
                                  child: Center(
                                    child: Row(
                                      spacing: 10,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        AppIcons.close(
                                          color: theme.textColor,
                                        ),
                                        Text(
                                          "Clear".tr,
                                          style: TextStyle(
                                            color: theme.textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          TransactionCardWidget(isMobile: widget.isMobile),
          ViewWidget(isMobile: widget.isMobile),
        ],
      ),
    );
  }
}

