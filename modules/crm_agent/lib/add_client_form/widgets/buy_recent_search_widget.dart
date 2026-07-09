import 'dart:ui' as ui;

import 'package:crm_agent/add_client_form/components/buy/buy_additional_info_filtered_button.dart';
import 'package:crm_agent/add_client_form/components/buy/buy_custom_drop_down.dart';
import 'package:crm_agent/add_client_form/components/buy/buy_estate_filtered_button.dart';
import 'package:crm_agent/add_client_form/components/buy/buy_filltered_button.dart';
import 'package:crm_agent/add_client_form/components/buy/buy_filters_widget.dart';
import 'package:crm_agent/add_client_form/components/buy/buy_key_property_button.dart';
import 'package:crm_agent/add_client_form/components/usercontact/user_contact_custom_text_field.dart';
import 'package:core/platform/filters/filters_const.dart';
import 'package:crm_agent/add_client_form/controllers/buy_controlers.dart';
import 'package:crm_agent/add_client_form/provider/buy_filter_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/common/autocompletion/autocomplete.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';

import '../components/buy/buy_from_filter_components.dart';

class BuyRecentSearchWidget extends ConsumerStatefulWidget {
  final bool isMobile;
  final bool needBackground;
  final Map<String, dynamic>? search;
  final int? transactionId;
  final int? clientId;
  final bool hasSave;

  const BuyRecentSearchWidget({
    super.key,
    this.isMobile = false,
    this.needBackground = false,
    this.search,
    this.transactionId,
    this.clientId,
    this.hasSave = false,
  });

  @override
  ConsumerState<BuyRecentSearchWidget> createState() => _BuyRecentSearchWidgetState();
}

class _BuyRecentSearchWidgetState extends ConsumerState<BuyRecentSearchWidget> {
  // -------- NEW: optional description + notification toggles --------
  late final TextEditingController _descriptionController;
  late final FocusNode _titleFocusNode;
  bool _showDescription = false;

  bool _enableNotifications = false;
  bool _enableEmailNotification = false;

  bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = v.toString().trim().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes' || s == 'y';
  }

  @override
  void initState() {
    super.initState();

    _descriptionController = TextEditingController(
      text: (widget.search?['description'] ?? '').toString(),
    );

    // Support both snake_case and camelCase
    _enableNotifications = _toBool(
      widget.search?['enable_notifications'] ?? widget.search?['enableNotifications'],
    );
    _enableEmailNotification = _toBool(
      widget.search?['enable_email_notification'] ?? widget.search?['enableEmailNotification'],
    );

    // If edit & has description -> open by default
    _showDescription = _descriptionController.text.trim().isNotEmpty;
    _titleFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final filters = (widget.search?['filters'] as Map<String, dynamic>?) ?? {};
      final buyControllers = ref.read(buySearchControllersProvider);
      final cache = ref.read(buyOfferFilterCacheProvider.notifier);
      final buttonNotifier = ref.read(buyOfferfilterButtonProvider.notifier);
      final dropdownNotifier = ref.read(crmAddDropdownProvider.notifier);

      // Title
      buyControllers.titleController.text = widget.search?['title']?.toString() ?? '';

      // Persist extra saved search fields into cache/service (same method you already use for title)
      cache.setSavedSearchField('title', buyControllers.titleController.text.trim());
      cache.setSavedSearchField('description', _descriptionController.text.trim());
      cache.setSavedSearchField('enable_notifications', _enableNotifications);
      cache.setSavedSearchField('enable_email_notification', _enableEmailNotification);

      // Helper to set both UI buttons and cache filters
      void setFilter(String key) {
        final value = filters[key];
        if (value != null) {
          buttonNotifier.updateFilter(key, value);
          cache.addFilter(key, value);
        }
      }

      // Filters for UI + Cache (especially buttons)
      setFilter('offer_type');
      setFilter('estate_type');
      setFilter('rooms');
      setFilter('bathrooms');
      setFilter('price_min');
      setFilter('price_max');

      // Optional filters
      setFilter('square_footage');
      setFilter('lot_size');

      // Dropdowns (safe fallback)
      final typeOfBuilding = filters['building_type'];
      if (typeOfBuilding != null &&
          FilterPopConst.typeOfBuildingOptions.contains(typeOfBuilding)) {
        dropdownNotifier.updateValue('building_type', typeOfBuilding, ref);
      }

      final buildingMaterial = filters['building_material'];
      if (buildingMaterial != null &&
          FilterPopConst.buildingMaterialOptions.contains(buildingMaterial)) {
        dropdownNotifier.updateValue('building_material', buildingMaterial, ref);
      }

      final heatingType = filters['heating_type'];
      if (heatingType != null && FilterPopConst.heatingTypeOptions.contains(heatingType)) {
        dropdownNotifier.updateValue('heating_type', heatingType, ref);
      }

      final advertiser = filters['advertiser_type'];
      if (advertiser != null && FilterPopConst.advertiserOptions.contains(advertiser)) {
        dropdownNotifier.updateValue('advertiser_type', advertiser, ref);
      }

      if (mounted) setState(() {});
    });

    _descriptionController.addListener(() {
      // Keep cache in sync
      final cache = ref.read(buyOfferFilterCacheProvider.notifier);
      cache.setSavedSearchField('description', _descriptionController.text.trim());
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  Widget _notificationsSection(ThemeColors theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(160), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_none, size: 18, color: theme.textColor),
              const SizedBox(width: 8),
              Text(
                'Notifications'.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'App notifications'.tr,
              style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'wysyłaj_powiadomienia_o_nowych_ogłoszeniach_pasujących_do_tej_wyszukiwarki'.tr,
              style: TextStyle(color: theme.textColor.withAlpha(180)),
            ),
            value: _enableNotifications,
            onChanged: (v) {
              setState(() => _enableNotifications = v);
              ref.read(buyOfferFilterCacheProvider.notifier).setSavedSearchField(
                    'enable_notifications',
                    v,
                  );
            },
          ),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Email notifications'.tr,
              style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Send email when new matching listings appear'.tr,
              style: TextStyle(color: theme.textColor.withAlpha(180)),
            ),
            value: _enableEmailNotification,
            onChanged: (v) {
              setState(() => _enableEmailNotification = v);
              ref.read(buyOfferFilterCacheProvider.notifier).setSavedSearchField(
                    'enable_email_notification',
                    v,
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _descriptionSection(ThemeColors theme) {
    final hasText = _descriptionController.text.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(160), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _showDescription = !_showDescription),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    _showDescription ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: theme.textColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Description (optional)'.tr,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (!_showDescription && hasText)
                    Text(
                      'dodany'.tr,
                      style: TextStyle(
                        color: theme.themeColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState:
                _showDescription ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: _descriptionController,
                cursorColor: theme.textColor,
                style: TextStyle(color: theme.textColor),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'description'.tr,
                  filled: true,
                  fillColor: theme.textFieldColor,
                  hintStyle: TextStyle(color: theme.textColor.withAlpha(160)),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fields = ref.watch(crmAddDropdownProvider);
    final buyControllers = ref.watch(buySearchControllersProvider);
    final buyOfferCache = ref.watch(buyOfferFilterCacheProvider.notifier);
    final theme = ref.watch(themeColorsProvider);

    return Stack(
      children: [
        if (widget.needBackground) ...[
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: theme.adPopBackground.withAlpha((255 * 0.85).toInt()),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
          ),
        ],
        SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: widget.needBackground ? 200.w : 0,
            vertical: widget.needBackground ? 110.h : 0,
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
                        'create_search'.tr,
                        style: TextStyle(
                          color: theme.themeTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      AppIcons.iosArrowDown(color: theme.themeTextColor),
                    ],
                  ),
                ),
              ),

              Container(
                decoration: BoxDecoration(color: theme.adPopBackground),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'name_your_search'.tr,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: UserContactCustomTextField(
                              id: 99,
                              valueKey: 'title',
                              hintText: 'Title'.tr,
                              formatThousands: false,
                              controller: buyControllers.titleController,
                              focusNode: _titleFocusNode,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) {
                                FocusScope.of(context).unfocus();
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Title can't be empty".tr;
                                }
                                return null;
                              },
                              onChanged: (valueKey, value) {
                                // Persist title to saved search fields
                                buyOfferCache.setSavedSearchField(valueKey, value);
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ✅ NEW: Notifications under title
                      _notificationsSection(theme),

                      const SizedBox(height: 12),

                      // ✅ NEW: Optional description (collapsible)
                      _descriptionSection(theme),

                      const SizedBox(height: 30),

                      Text(
                        'Location'.tr,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: theme.dashboardContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dashboardBoarder),
                        ),
                        child: AutoCompleteWidget(
                          provider: 'nm',
                          onLocationChanged: (ref, sel) {
                            final cache = ref.read(buyOfferFilterCacheProvider.notifier);

                            if (sel.isEmpty) {
                              cache.removeFilter('location_type');
                              cache.removeFilter('location_id');
                              cache.removeFilter('city');
                              cache.removeFilter('state');
                              cache.removeFilter('district');
                              return;
                            }

                            cache.addFilter('location_type', sel.type);
                            cache.addFilter('location_id', sel.id);

                            if (sel.city.trim().isNotEmpty) {
                              cache.addFilter('city', sel.city.trim());
                            } else {
                              cache.removeFilter('city');
                            }

                            if (sel.state.trim().isNotEmpty) {
                              cache.addFilter('state', sel.state.trim());
                            } else {
                              cache.removeFilter('state');
                            }

                            if (sel.districts.isNotEmpty) {
                              cache.addFilter('district', sel.districts.join(','));
                            } else {
                              cache.removeFilter('district');
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 30),

                      Text(
                        'Offer type'.tr,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        spacing: 12,
                        children: [
                          Expanded(
                            child: CrmAddFilteredButton(
                              text: 'offer_type_sell'.tr,
                              filterValue: 'sell',
                              filterKey: 'offer_type',
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                          Expanded(
                            child: CrmAddFilteredButton(
                              text: 'offer_type_rent'.tr,
                              filterValue: 'rent',
                              filterKey: 'offer_type',
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      Text(
                        'Market type'.tr,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CrmAddKeyPropertyButton(
                              text: 'Primary market'.tr,
                              filterValue: 'Primary'.tr,
                              filterKey: 'market_type',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CrmAddKeyPropertyButton(
                              text: 'Secondary market'.tr,
                              filterValue: 'Secondary'.tr,
                              filterKey: 'market_type',
                            ),
                          ),
                        ],
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
                            children: FilterPopConst.estateTypes.map((estateType) {
                              return ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 100, maxWidth: 180),
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

                      if (!widget.isMobile)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Column(
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
                                const SizedBox(height: 12),

                                CrmAddCustomDropdownMap(
                                  label: fields['building_type']!.label,
                                  options: FilterPopConst.typeOfBuildingOptions,
                                  value: fields['building_type']!.value,
                                  onChanged: (newValue) {
                                    ref.read(crmAddDropdownProvider.notifier).updateValue(
                                          'building_type',
                                          newValue ?? '',
                                          ref,
                                        );
                                  },
                                  width: 405,
                                  height: 46,
                                ),
                                const SizedBox(height: 16),

                                CrmAddCustomDropdownMap(
                                  label: fields['building_material']!.label,
                                  options: FilterPopConst.buildingMaterialOptions,
                                  value: fields['building_material']!.value,
                                  onChanged: (newValue) {
                                    ref.read(crmAddDropdownProvider.notifier).updateValue(
                                          'building_material',
                                          newValue ?? '',
                                          ref,
                                        );
                                  },
                                  width: 405,
                                  height: 46,
                                ),
                                const SizedBox(height: 16),

                                CrmAddCustomDropdownMap(
                                  label: fields['heating_type']!.label,
                                  options: FilterPopConst.heatingTypeOptions,
                                  value: fields['heating_type']!.value,
                                  onChanged: (newValue) {
                                    ref.read(crmAddDropdownProvider.notifier).updateValue(
                                          'heating_type',
                                          newValue ?? '',
                                          ref,
                                        );
                                  },
                                  width: 405,
                                  height: 46,
                                ),
                                const SizedBox(height: 16),

                                CrmAddCustomDropdownMap(
                                  label: fields['advertiser_type']!.label,
                                  options: FilterPopConst.advertiserOptions,
                                  value: fields['advertiser_type']!.value,
                                  onChanged: (newValue) {
                                    ref.read(crmAddDropdownProvider.notifier).updateValue(
                                          'advertiser_type',
                                          newValue ?? '',
                                          ref,
                                        );
                                  },
                                  width: 405,
                                  height: 46,
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 400,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12.0),
                                child: VerticalDivider(
                                  width: 32,
                                  color: Color.fromRGBO(90, 90, 90, 1),
                                ),
                              ),
                            ),
                            const Expanded(child: PcFiltersWidget()),
                          ],
                        ),

                      if (widget.isMobile)
                        Column(
                          spacing: 10,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'Key Property Features'.tr,
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: CrmAddKeyPropertyButton(
                                    text: 'Primary market'.tr,
                                    filterValue: 'Primary'.tr,
                                    filterKey: 'market_type',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CrmAddKeyPropertyButton(
                                    text: 'Secondary'.tr,
                                    filterValue: 'Secondary'.tr,
                                    filterKey: 'market_type',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const PcFiltersWidget(),
                          ],
                        ),

                      const SizedBox(height: 20),

                      Column(
                        spacing: 10.h,
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
                            children: FilterPopConst.additionalInfo.map((additionalInfo) {
                              return ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 120, maxWidth: 180),
                                child: CrmAddAdditionalInfoFilteredButton(
                                  text: additionalInfo['text']!,
                                  filterKey: additionalInfo['filterKey']!,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          const Spacer(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: 55,
                                width: 150,
                                child: ElevatedButton(
                                  style: elevatedButtonStyleRounded10,
                                  onPressed: () {
                                    // Clear filters
                                    ref.read(buyOfferFilterCacheProvider.notifier).clearFilters(ref);

                                    // Also clear saved search fields
                                    buyControllers.titleController.clear();
                                    _descriptionController.clear();

                                    ref.read(buyOfferFilterCacheProvider.notifier).setSavedSearchField('title', '');
                                    ref.read(buyOfferFilterCacheProvider.notifier).setSavedSearchField('description', '');
                                    ref.read(buyOfferFilterCacheProvider.notifier).setSavedSearchField('enable_notifications', false);
                                    ref.read(buyOfferFilterCacheProvider.notifier).setSavedSearchField('enable_email_notification', false);

                                    setState(() {
                                      _enableNotifications = false;
                                      _enableEmailNotification = false;
                                      _showDescription = false;
                                    });
                                  },
                                  child: Center(
                                    child: Row(
                                      spacing: 10,
                                      children: [
                                        AppIcons.close(color: theme.textColor),
                                        Text("Clear".tr, style: TextStyle(color: theme.textColor)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (widget.hasSave) ...[
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 45,
                              width: 150,
                              child: ElevatedButton(
                                style: elevatedButtonStyleRounded10.copyWith(
                                  backgroundColor: WidgetStatePropertyAll(theme.themeColor),
                                ),
                                onPressed: () => ref.read(navigationService).beamPop(),
                                child: Center(
                                  child: Row(
                                    spacing: 10,
                                    children: [
                                      AppIcons.save(color: theme.themeTextColor),
                                      Text("Save".tr, style: TextStyle(color: theme.themeTextColor)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}