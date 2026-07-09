// ============================================
// AddSearchClientPanel.dart (FULL - fixed)
// - rooms + bathrooms are MULTI select (List<String>)
// - supports "any" as a clear option
// - reads old saved filters that might be: "1,2,3" OR ["1","2"] OR single "2"
// - writes to cache as CSV: "1,2,3"
// - notifications section under title
// - optional description (collapsible)
// - live upsert on CREATE + UPDATE
// - FIX: preserve spaces in title on save/update
// - refresh list after sheet close (optional)
// ============================================

import 'dart:ui' as ui;

import 'package:network_monitoring/providers/saved_search/inbox_providers.dart';
import 'package:crm/contact_panel/tabs/saved_search_client/components/controlers.dart';
import 'package:crm/contact_panel/tabs/saved_search_client/components/custom_drop_down.dart';
import 'package:crm/contact_panel/tabs/saved_search_client/components/estate_filtered_button.dart';
import 'package:crm/contact_panel/tabs/saved_search_client/components/filltered_button.dart';
import 'package:crm/contact_panel/tabs/saved_search_client/components/filtered_button.dart';
import 'package:crm/contact_panel/tabs/saved_search_client/components/filters_widget.dart';
import 'package:crm/contact_panel/tabs/saved_search_client/components/from_filter_components.dart';
import 'package:crm/contact_panel/tabs/saved_search_client/components/key_property_button.dart';
import 'package:crm/data/clients/ad_provider.dart';
import 'package:crm/data/clients/client_saved_search.dart';
import 'package:crm/crm/clients/components/user_contact_custom_text_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:core/common/autocompletion/autocomplete.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';
import 'package:core/platform/filters/filters_const.dart';

class AddSearchClientPanel extends ConsumerStatefulWidget {
  final bool isMobile;
  final bool needBackground;
  final bool isEdit;
  final Map<String, dynamic>? search;
  final ScrollController? sheetController;
  final int? transactionId;
  final int? savedSearchId;
  final int? clientId;
  final String headline;
  final bool hasPop;

  const AddSearchClientPanel({
    super.key,
    this.isEdit = false,
    this.isMobile = false,
    this.needBackground = false,
    this.search,
    this.transactionId,
    this.savedSearchId,
    this.clientId,
    this.headline = 'Add new search',
    this.hasPop = true,
    this.sheetController,
  });

  @override
  ConsumerState<AddSearchClientPanel> createState() =>
      _AddSearchClientPanelState();
}

class _AddSearchClientPanelState extends ConsumerState<AddSearchClientPanel> {
  late final TextEditingController _descriptionController;
  bool _showDescription = false;

  bool _enableNotifications = false;
  bool _enableEmailNotification = false;

  bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final ss = v.toString().toLowerCase();
    return ss == 'true' || ss == '1' || ss == 'yes';
  }

  String _normalizeTitlePreserveSpaces(String value) {
    return value
        .replaceAll(RegExp(r'[\u00A0\u2007\u202F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _buildInitialLocationTextFromFilters(Map<String, dynamic> filters) {
    String? s(String k) => filters[k]?.toString().trim();

    final city = s('city');
    final district = s('district');

    if (district != null &&
        district.isNotEmpty &&
        city != null &&
        city.isNotEmpty) {
      return '$district, $city';
    }
    if (city != null && city.isNotEmpty) return city;

    final legacySearch = s('search');
    if (legacySearch != null && legacySearch.isNotEmpty) return legacySearch;

    return '';
  }

  List<String> _parseCsvOrList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final s = value.toString().trim();
    if (s.isEmpty) return [];
    return s
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<String> _normalizeNumericLike(List<String> list) {
    final cleaned = list.where((e) => e.toLowerCase() != 'any').toList();

    int weight(String v) {
      final vv = v.trim();
      final base = vv.replaceAll('+', '');
      final n = int.tryParse(base);
      if (n == null) return 9999;
      return vv.contains('+') ? (n * 1000) : n;
    }

    cleaned.sort((a, b) => weight(a).compareTo(weight(b)));
    return cleaned;
  }

  Widget _notificationsSection(ThemeColors theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.textFieldColor.withAlpha(60),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: theme.dashboardBoarder.withAlpha(120), width: 1),
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
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
            'Send notifications about new listings matching this search'.tr,
              style: TextStyle(color: theme.textColor.withAlpha(180)),
            ),
            value: _enableNotifications,
            onChanged: (v) => setState(() => _enableNotifications = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
             'Email notifications'.tr,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Send email when new matching listings appear'.tr,
              style: TextStyle(color: theme.textColor.withAlpha(180)),
            ),
            value: _enableEmailNotification,
            onChanged: (v) => setState(() => _enableEmailNotification = v),
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
        color: theme.textFieldColor.withAlpha(60),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: theme.dashboardBoarder.withAlpha(120), width: 1),
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
                     'Added'.tr,
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
            crossFadeState: _showDescription
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: _descriptionController,
                cursorColor: theme.textColor,
                style: TextStyle(color: theme.textColor),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Description'.tr,
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
  void initState() {
    super.initState();

    _descriptionController = TextEditingController(
      text: (widget.search?['description'] ?? '').toString(),
    );

    _enableNotifications = _toBool(
      widget.search?['enable_notifications'] ??
          widget.search?['enableNotifications'],
    );
    _enableEmailNotification = _toBool(
      widget.search?['enable_email_notification'] ??
          widget.search?['enableEmailNotification'],
    );

    _showDescription = _descriptionController.text.trim().isNotEmpty;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final filters = (widget.search?['filters'] as Map<String, dynamic>?) ?? {};
      final ctrls = ref.read(filtersControllersProvider);
      final cache = ref.read(filterCacheProvider.notifier);
      final buttonNotifier = ref.read(filterButtonProvider.notifier);
      final dropdownNotifier = ref.read(clientPanelDropdownProvider.notifier);

      ctrls.titleController.text = _normalizeTitlePreserveSpaces(
        widget.search?['title']?.toString() ?? '',
      );
      cache.removeFilter('title');

      String? s(String k) => filters[k]?.toString();

      final city = (filters['city'] ?? '').toString().trim();
      final district = (filters['district'] ?? '').toString().trim();
      final voiv = (filters['voivodeship'] ??
              filters['province'] ??
              filters['voivodship'] ??
              '')
          .toString()
          .trim();

      if (city.isNotEmpty) cache.addFilter('city', city);
      if (district.isNotEmpty) cache.addFilter('district', district);
      if (voiv.isNotEmpty) cache.addFilter('voivodeship', voiv);

      for (final item in FilterPopConst.additionalInfo) {
        final key = item['filterKey']!;
        final isOn = _toBool(filters[key]);
        buttonNotifier.updateFilter(key, isOn);
        if (isOn) {
          cache.addFilter(key, 'true');
        } else {
          cache.removeFilter(key);
        }
      }

      final minPrice = s('min_price');
      final maxPrice = s('max_price');
      if (minPrice != null) {
        ctrls.minPriceController.text = minPrice;
        cache.addFilter('min_price', minPrice);
        buttonNotifier.updateFilter('min_price', minPrice);
      }
      if (maxPrice != null) {
        ctrls.maxPriceController.text = maxPrice;
        cache.addFilter('max_price', maxPrice);
        buttonNotifier.updateFilter('max_price', maxPrice);
      }

      final minSf = s('min_square_footage');
      final maxSf = s('max_square_footage');
      if (minSf != null) {
        ctrls.minSquareFootageController.text = minSf;
        cache.addFilter('min_square_footage', minSf);
        buttonNotifier.updateFilter('min_square_footage', minSf);
      }
      if (maxSf != null) {
        ctrls.maxSquareFootageController.text = maxSf;
        cache.addFilter('max_square_footage', maxSf);
        buttonNotifier.updateFilter('max_square_footage', maxSf);
      }

      void setFilter(String key) {
        final value = filters[key];
        if (value != null) {
          buttonNotifier.updateFilter(key, value);
          cache.addFilter(key, value);
        }
      }

      void setFilterList(String key) {
        final value = filters[key];
        if (value != null) {
          buttonNotifier.updateFilter(key, [value.toString()]);
          cache.addFilter(key, value.toString());
        }
      }

      void setFilterMulti(String key) {
        final value = filters[key];
        final list = _normalizeNumericLike(_parseCsvOrList(value));
        if (list.isEmpty) return;

        buttonNotifier.updateFilter(key, list);
        cache.addFilter(key, list.join(','));
      }

      setFilterList('estate_type');
      setFilter('offer_type');
      setFilter('market_type');

      setFilterMulti('rooms');
      setFilterMulti('bathrooms');

      setFilter('lot_size');

      bool hasOption(List<Map<String, String>> opts, String? v) =>
          v != null && opts.any((o) => o['filterKey'] == v);

      final typeOfBuilding = filters['building_type']?.toString();
      if (hasOption(FilterPopConst.typeOfBuildingOptions, typeOfBuilding)) {
        dropdownNotifier.updateValue('building_type', typeOfBuilding!, ref);
      }

      final buildingMaterial = filters['building_material']?.toString();
      if (hasOption(FilterPopConst.buildingMaterialOptions, buildingMaterial)) {
        dropdownNotifier.updateValue('building_material', buildingMaterial!, ref);
      }

      final heatingType = filters['heating_type']?.toString();
      if (hasOption(FilterPopConst.heatingTypeOptions, heatingType)) {
        dropdownNotifier.updateValue('heating_type', heatingType!, ref);
      }

      final advertiser = filters['advertiser_type']?.toString();
      if (hasOption(FilterPopConst.advertiserOptions, advertiser)) {
        dropdownNotifier.updateValue('advertiser_type', advertiser!, ref);
      }

      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _invalidateNmSavedSearchList(ProviderContainer container) {
    container.invalidate(savedSearchesWithCountersProvider);
    container.invalidate(selectedSavedSearchProvider);
    container.invalidate(savedSearchInboxProvider);
  }

  Future<void> _refreshListsIfPossible() async {
    final container = ProviderScope.containerOf(context, listen: false);

    _invalidateNmSavedSearchList(container);

    if (widget.clientId != null) {
      await ref
          .read(clientSavedSearchesProvider(widget.clientId!).notifier)
          .refresh();
    }
    if (widget.transactionId != null) {
      await ref
          .read(transactionSavedSearchesProvider(widget.transactionId!).notifier)
          .refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dropdownValues = ref.watch(clientPanelDropdownProvider);
    final filterControllers = ref.watch(filtersControllersProvider);

    final filterCache = ref.read(filterCacheProvider.notifier);
    final buttonNotifier = ref.read(filterButtonProvider.notifier);
    final theme = ref.watch(themeColorsProvider);

    final savedFilters =
        (widget.search?['filters'] as Map<String, dynamic>?) ?? {};
    final initialLocationText =
        _buildInitialLocationTextFromFilters(savedFilters);

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
        Column(
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
                      widget.headline.tr,
                      style: TextStyle(
                        color: theme.themeTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    InkWell(
                      onTap: widget.hasPop
                          ? () => Navigator.of(context).maybePop()
                          : null,
                      child: AppIcons.iosArrowDown(color: theme.themeTextColor),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: widget.sheetController,
                child: Container(
                  decoration: BoxDecoration(color: theme.dashboardContainer),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: UserContactCustomTextField(
                                id: 99,
                                valueKey: 'title',
                                hintText: 'Title'.tr,
                                formatThousands: false,
                                controller: filterControllers.titleController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Title can't be empty".tr;
                                  }
                                  return null;
                                },
                                onChanged: (valueKey, value) {},
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _notificationsSection(theme),

                        const SizedBox(height: 12),

                        _descriptionSection(theme),

                        const SizedBox(height: 24),

                        AutoCompleteWidget(
                          provider: 'nm',
                          initialText: initialLocationText,
                          onLocationChanged: (ref, sel) {
                            final cache =
                                ref.read(filterCacheProvider.notifier);

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
                              cache.addFilter(
                                'district',
                                sel.districts.join(','),
                              );
                            } else {
                              cache.removeFilter('district');
                            }
                          },
                        ),

                        const SizedBox(height: 30),

                        Row(
                          spacing: 10,
                          children: [
                            ClientPanelFilteredButton(
                              text: 'For sale'.tr,
                              filterValue: 'sell',
                              filterKey: 'offer_type',
                            ),
                            ClientPanelFilteredButton(
                              text: 'For rent'.tr,
                              filterValue: 'rent',
                              filterKey: 'offer_type',
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'property_type'.tr,
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
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
                                  child: ClientPanelEstateTypeFilteredButton(
                                    text: estateType['text']!.tr,
                                    filterValue: estateType['filterValue']!,
                                    filterKey: 'estate_type',
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        if (!widget.isMobile)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Key Property Features'.tr,
                                      style: TextStyle(
                                        color: theme.textColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClientPanelKeyPropertyButton(
                                            text: 'Primary market'.tr,
                                            filterValue: 'primary',
                                            filterKey: 'market_type',
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ClientPanelKeyPropertyButton(
                                            text: 'Secondary market'.tr,
                                            filterValue: 'secondary',
                                            filterKey: 'market_type',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ClientPanelCustomDropdown(
                                      label: 'Type of building'.tr,
                                      options: FilterPopConst.typeOfBuildingOptions,
                                      value: dropdownValues['building_type']!.value,
                                      onChanged: (newValue) {
                                        ref
                                            .read(clientPanelDropdownProvider.notifier)
                                            .updateValue(
                                              'building_type',
                                              newValue!,
                                              ref,
                                            );
                                      },
                                      width: 405,
                                      height: 46,
                                    ),
                                    const SizedBox(height: 16),
                                    ClientPanelCustomDropdown(
                                      label: 'Building Material'.tr,
                                      options: FilterPopConst.buildingMaterialOptions,
                                      value: dropdownValues['building_material']!.value,
                                      onChanged: (newValue) {
                                        ref
                                            .read(clientPanelDropdownProvider.notifier)
                                            .updateValue(
                                              'building_material',
                                              newValue!,
                                              ref,
                                            );
                                      },
                                      width: 405,
                                      height: 46,
                                    ),
                                    const SizedBox(height: 16),
                                    ClientPanelCustomDropdown(
                                      label: 'Heating type'.tr,
                                      options: FilterPopConst.heatingTypeOptions,
                                      value: dropdownValues['heating_type']!.value,
                                      onChanged: (newValue) {
                                        ref
                                            .read(clientPanelDropdownProvider.notifier)
                                            .updateValue(
                                              'heating_type',
                                              newValue!,
                                              ref,
                                            );
                                      },
                                      width: 405,
                                      height: 46,
                                    ),
                                    const SizedBox(height: 16),
                                    ClientPanelCustomDropdown(
                                      label: 'Advertiser'.tr,
                                      options: FilterPopConst.advertiserOptions,
                                      value: dropdownValues['advertiser_type']!.value,
                                      onChanged: (newValue) {
                                        ref
                                            .read(clientPanelDropdownProvider.notifier)
                                            .updateValue(
                                              'advertiser_type',
                                              newValue!,
                                              ref,
                                            );
                                      },
                                      width: 405,
                                      height: 46,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 322,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                                  child: VerticalDivider(
                                    color: Color.fromRGBO(90, 90, 90, 1),
                                    width: 13,
                                  ),
                                ),
                              ),
                              const Expanded(child: ClientPanelPcFiltersWidget()),
                            ],
                          ),

                        if (widget.isMobile)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Key Property Features'.tr,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClientPanelKeyPropertyButton(
                                      text: 'Primary market'.tr,
                                      filterValue: 'primary',
                                      filterKey: 'market_type',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ClientPanelKeyPropertyButton(
                                      text: 'Secondary market'.tr,
                                      filterValue: 'secondary',
                                      filterKey: 'market_type',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClientPanelCustomDropdown(
                                label: 'Type of building'.tr,
                                options: FilterPopConst.typeOfBuildingOptions,
                                value: dropdownValues['building_type']!.value,
                                onChanged: (newValue) {
                                  ref
                                      .read(clientPanelDropdownProvider.notifier)
                                      .updateValue(
                                        'building_type',
                                        newValue!,
                                        ref,
                                      );
                                },
                                width: 405,
                                height: 46,
                              ),
                              const SizedBox(height: 16),
                              ClientPanelCustomDropdown(
                                label: 'Building Material'.tr,
                                options: FilterPopConst.buildingMaterialOptions,
                                value: dropdownValues['building_material']!.value,
                                onChanged: (newValue) {
                                  ref
                                      .read(clientPanelDropdownProvider.notifier)
                                      .updateValue(
                                        'building_material',
                                        newValue!,
                                        ref,
                                      );
                                },
                                width: 405,
                                height: 46,
                              ),
                              const SizedBox(height: 16),
                              ClientPanelCustomDropdown(
                                label: 'Heating type'.tr,
                                options: FilterPopConst.heatingTypeOptions,
                                value: dropdownValues['heating_type']!.value,
                                onChanged: (newValue) {
                                  ref
                                      .read(clientPanelDropdownProvider.notifier)
                                      .updateValue(
                                        'heating_type',
                                        newValue!,
                                        ref,
                                      );
                                },
                                width: 405,
                                height: 46,
                              ),
                              const SizedBox(height: 16),
                              ClientPanelCustomDropdown(
                                label: 'Advertiser'.tr,
                                options: FilterPopConst.advertiserOptions,
                                value: dropdownValues['advertiser_type']!.value,
                                onChanged: (newValue) {
                                  ref
                                      .read(clientPanelDropdownProvider.notifier)
                                      .updateValue(
                                        'advertiser_type',
                                        newValue!,
                                        ref,
                                      );
                                },
                                width: 405,
                                height: 46,
                              ),
                              const ClientPanelPcFiltersWidget(),
                            ],
                          ),

                        const SizedBox(height: 20),

                        Column(
                          spacing: 10.h,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Additional Features'.tr,
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Wrap(
                              alignment: WrapAlignment.start,
                              spacing: 12,
                              runSpacing: 12,
                              children: FilterPopConst.additionalInfo
                                  .map((additionalInfo) {
                                return ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 120,
                                    maxWidth: 180,
                                  ),
                                  child:
                                      ClientPanelAdditionalInfoFilteredButton(
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
                            SizedBox(
                              height: 55,
                              width: 150,
                              child: ElevatedButton(
                                style: elevatedButtonStyleRounded10,
                                onPressed: () {
                                  filterCache.clearFilters();
                                  buttonNotifier.clearUiFilters();

                                  filterControllers.titleController.clear();
                                  _descriptionController.clear();

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
                                      AppIcons.close(),
                                      Text(
                                        "Clear".tr,
                                        style: TextStyle(color: theme.textColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              height: 45,
                              width: 150,
                              decoration: BoxDecoration(
                                color: theme.themeColor,
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(6)),
                              ),
                              child: ElevatedButton(
                                style: elevatedButtonStyleRounded10,
                                onPressed: () async {
                                  final notifier = ref.read(filterProvider.notifier);

                                  final titleRaw =
                                      filterControllers.titleController.text;
                                  final title =
                                      _normalizeTitlePreserveSpaces(titleRaw);
                                  final description =
                                      _descriptionController.text.trim();

                                  filterControllers.titleController.value =
                                      TextEditingValue(
                                    text: title,
                                    selection: TextSelection.collapsed(
                                      offset: title.length,
                                    ),
                                  );

                                  if (title.isEmpty) return;

                                  if (widget.isEdit &&
                                      widget.savedSearchId != null) {
                                    await notifier.updateSavedFilters(
                                      context: context,
                                      savedSearchId: widget.savedSearchId!,
                                      title: title,
                                      description: description,
                                      enableNotifications: _enableNotifications,
                                      enableEmailNotification:
                                          _enableEmailNotification,
                                      filters: filterCache,
                                      clientId: widget.clientId,
                                      transactionId: widget.transactionId,
                                      onSuccess: (savedId) async {
                                        await _refreshListsIfPossible();

                                        debugPrint('onSuccess: $title');
                                        
        debugPrint('normalize title: $titleRaw');

                                        final container =
                                            ProviderScope.containerOf(
                                          context,
                                          listen: false,
                                        );

                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          _invalidateNmSavedSearchList(
                                            container,
                                          );
                                        });

                                        Navigator.of(context).maybePop();
                                      },
                                    );
                                  } else {
                                    await notifier.saveFilters(
                                      context: context,
                                      title: title,
                                      description: description,
                                      enableNotifications: _enableNotifications,
                                      enableEmailNotification:
                                          _enableEmailNotification,
                                      filters: filterCache,
                                      clientId: widget.clientId,
                                      transactionId: widget.transactionId,
                                      onSuccess: (savedId) async {
                                        notifier.setSavedSearch(
                                          savedId.toString(),
                                          ref,
                                        );

                                        await _refreshListsIfPossible();

                                        final container =
                                            ProviderScope.containerOf(
                                          context,
                                          listen: false,
                                        );

                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          _invalidateNmSavedSearchList(
                                            container,
                                          );
                                        });

                                        Navigator.of(context).maybePop();
                                      },
                                    );
                                  }
                                },
                                child: Center(
                                  child: Row(
                                    spacing: 10,
                                    children: [
                                      AppIcons.save(
                                        color: theme.themeTextColor,
                                      ),
                                      Text(
                                        "Save".tr,
                                        style: TextStyle(
                                          color: theme.themeTextColor,
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
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}