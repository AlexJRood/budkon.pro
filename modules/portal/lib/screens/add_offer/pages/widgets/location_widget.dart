import 'dart:developer';

import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/common/shared_widgets/location_components.dart';
import 'package:portal/screens/add_offer/pages/widgets/map_widget_add_offer.dart';
import 'package:portal/screens/add_offer/provider/add_offer_provider.dart';
import 'package:core/ui/forms/form_fields.dart';
import 'package:core/common/autocompletion/autocomplete.dart';
import 'package:core/common/autocompletion/models/autocomplete_result.dart';
import 'package:core/common/autocompletion/provider/autocompletion_provider.dart';
import 'package:core/theme/apptheme.dart';

class HeaderLocationWidgetAddOffer extends ConsumerStatefulWidget {
  final bool isMobile;

  const HeaderLocationWidgetAddOffer({
    super.key,
    this.isMobile = false,
  });

  @override
  ConsumerState<HeaderLocationWidgetAddOffer> createState() =>
      _HeaderLocationWidgetAddOfferState();
}

class _HeaderLocationWidgetAddOfferState
    extends ConsumerState<HeaderLocationWidgetAddOffer> {
  final TextEditingController _stateReadonlyController =
  TextEditingController();
  final TextEditingController _cityReadonlyController =
  TextEditingController();
  final TextEditingController _districtReadonlyController =
  TextEditingController();
  final TextEditingController _countyReadonlyController =
  TextEditingController();
  final TextEditingController _communeReadonlyController =
  TextEditingController();

  final FocusNode _streetFocusNode = FocusNode();
  final FocusNode _zipcodeFocusNode = FocusNode();

  final GlobalKey _streetFieldKey = GlobalKey();
  final GlobalKey _zipcodeFieldKey = GlobalKey();

  ProviderSubscription<dynamic>? _autocompleteSub;

  String get _providerKey =>
      widget.isMobile
          ? 'add-offer-location-mobile'
          : 'add-offer-location-desktop';

  @override
  void initState() {
    super.initState();

    _streetFocusNode.addListener(() {
      if (_streetFocusNode.hasFocus) {
        _scrollToField(_streetFieldKey);
      }
    });

    _zipcodeFocusNode.addListener(() {
      if (_zipcodeFocusNode.hasFocus) {
        _scrollToField(_zipcodeFieldKey);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final addOfferState = ref.read(addOfferProvider);
      _syncLocationControllers(addOfferState);
      _bindAutocompleteListener();
    });
  }

  void _scrollToField(GlobalKey key) {
    final fieldContext = key.currentContext;
    if (fieldContext == null) return;

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;

      Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    });
  }

  @override
  void dispose() {
    _autocompleteSub?.close();

    _stateReadonlyController.dispose();
    _cityReadonlyController.dispose();
    _districtReadonlyController.dispose();
    _countyReadonlyController.dispose();
    _communeReadonlyController.dispose();

    _streetFocusNode.dispose();
    _zipcodeFocusNode.dispose();

    super.dispose();
  }

  void _bindAutocompleteListener() {
    _autocompleteSub?.close();

    _autocompleteSub = ref.listenManual(
      myTextFieldViewModelProvider(_providerKey),
          (previous, next) {
        if (!mounted) return;

        final addOfferState = ref.read(addOfferProvider);
        final addOfferNotifier = ref.read(addOfferProvider.notifier);

        final results =
            (next['searchResults'] as List?)?.cast<AutocompleteResult>() ??
                const <AutocompleteResult>[];
        final query = (next['lastSearchQuery'] ?? '').toString();

        if (query.trim().isEmpty) return;

        final preview = _buildPreviewSelection(results, query);
        if (preview.isEmpty) return;

        _applySelection(
          preview,
          addOfferState,
          addOfferNotifier,
          persistGeoFields: false,
        );

        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  void _syncLocationControllers(dynamic addOfferState) {
    _stateReadonlyController.text = addOfferState.stateController.text;
    _cityReadonlyController.text = addOfferState.cityController.text;

    final district = _readExtraField(addOfferState, 'district');
    final county = _readExtraField(addOfferState, 'county');
    final commune = _readExtraField(addOfferState, 'commune');

    _districtReadonlyController.text = district;
    _countyReadonlyController.text = county;
    _communeReadonlyController.text = commune;
  }

  String _readExtraField(dynamic addOfferState, String key) {
    try {
      final value = addOfferState.extraLocationData?[key];
      return value?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  void _writeExtraField(
      dynamic addOfferNotifier,
      String key,
      dynamic value,
      ) {
    try {
      addOfferNotifier.updateField(key, value);
    } catch (_) {}
  }

  void _clearLocation(dynamic addOfferState, dynamic addOfferNotifier) {
    addOfferState.countryController.text = '';
    addOfferState.stateController.text = '';
    addOfferState.cityController.text = '';

    _stateReadonlyController.clear();
    _cityReadonlyController.clear();
    _districtReadonlyController.clear();
    _countyReadonlyController.clear();
    _communeReadonlyController.clear();

    _writeExtraField(addOfferNotifier, 'country', '');
    _writeExtraField(addOfferNotifier, 'state', '');
    _writeExtraField(addOfferNotifier, 'city', '');
    _writeExtraField(addOfferNotifier, 'district', '');
    _writeExtraField(addOfferNotifier, 'county', '');
    _writeExtraField(addOfferNotifier, 'commune', '');
    _writeExtraField(addOfferNotifier, 'geo_id', '');
    _writeExtraField(addOfferNotifier, 'geo_type', '');
    _writeExtraField(addOfferNotifier, 'geo_level', null);
    _writeExtraField(addOfferNotifier, 'location_display', '');
    _writeExtraField(addOfferNotifier, 'location_name', '');
    _writeExtraField(addOfferNotifier, 'location_path', <String>[]);
    _writeExtraField(addOfferNotifier, 'locality_sym', '');
  }

  void _applySelection(
    LocationSelection selection,
    dynamic addOfferState,
    dynamic addOfferNotifier, {
    required bool persistGeoFields,
  }) {
    if (selection.isEmpty) {
      _clearLocation(addOfferState, addOfferNotifier);
      if (mounted) setState(() {});
      return;
    }

    addOfferState.countryController.text = 'Poland';
    addOfferState.stateController.text = selection.state;
    addOfferState.cityController.text = selection.city;

    _stateReadonlyController.text = selection.state;
    _cityReadonlyController.text = selection.city;
    _districtReadonlyController.text = selection.district;
    _countyReadonlyController.text = selection.county;
    _communeReadonlyController.text = selection.commune;

    _writeExtraField(addOfferNotifier, 'country', 'Poland');
    _writeExtraField(addOfferNotifier, 'state', selection.state);
    _writeExtraField(addOfferNotifier, 'city', selection.city);
    _writeExtraField(addOfferNotifier, 'district', selection.district);
    _writeExtraField(addOfferNotifier, 'county', selection.county);
    _writeExtraField(addOfferNotifier, 'commune', selection.commune);

    if (persistGeoFields) {
      _writeExtraField(addOfferNotifier, 'geo_id', selection.id);
      _writeExtraField(addOfferNotifier, 'geo_type', selection.type);
      _writeExtraField(addOfferNotifier, 'geo_level', selection.level);
      _writeExtraField(
        addOfferNotifier,
        'location_display',
        selection.display,
      );
      _writeExtraField(addOfferNotifier, 'location_name', selection.name);
      _writeExtraField(addOfferNotifier, 'location_path', selection.path);
      _writeExtraField(
        addOfferNotifier,
        'locality_sym',
        selection.localitySym,
      );
    }

    log(
      'AddOffer location => country=Poland, state=${selection.state}, city=${selection.city}, district=${selection.district}',
    );

    if (mounted) setState(() {});
  }

  void _applyLocationSelection(
    LocationSelection selection,
    dynamic addOfferState,
    dynamic addOfferNotifier,
  ) {
    _applySelection(
      selection,
      addOfferState,
      addOfferNotifier,
      persistGeoFields: true,
    );
  }

  String _voivodeshipFromResult(AutocompleteResult result) {
    if (result.path.isEmpty) return '';
    if (result.isLocality) return result.path.first.toString();
    if (result.isDistrict9 || result.isDistrict10) {
      return result.path.last.toString();
    }
    return '';
  }

  String _countyFromResult(AutocompleteResult result) {
    if (!result.isLocality) return '';
    if (result.path.length >= 2) return result.path[1].toString();
    return '';
  }

  String _communeFromResult(AutocompleteResult result) {
    if (!result.isLocality) return '';
    if (result.path.length >= 3) return result.path[2].toString();
    return '';
  }

  String _cityFromResult(AutocompleteResult result) {
    if (result.isLocality) return result.name;

    if (result.isDistrict9 || result.isDistrict10) {
      if (result.path.isNotEmpty) return result.path.first.toString();

      final parts = result.display.split(',');
      if (parts.length >= 2) {
        return parts.last.trim();
      }
    }

    return '';
  }

  LocationSelection _selectionFromLocality(AutocompleteResult locality) {
    return LocationSelection(
      type: locality.type,
      id: locality.id,
      level: locality.level,
      name: locality.name,
      localitySym: locality.id,
      city: _cityFromResult(locality),
      state: _voivodeshipFromResult(locality),
      county: _countyFromResult(locality),
      commune: _communeFromResult(locality),
      districts: const [],
      display: locality.display,
      path: List<String>.from(locality.path),
    );
  }

  LocationSelection _selectionFromDistrict(
    AutocompleteResult district,
    List<AutocompleteResult> allResults,
  ) {
    AutocompleteResult? parentLocality;

    final localitySym = district.localitySym;
    if (localitySym != null && localitySym.isNotEmpty) {
      try {
        parentLocality = allResults.firstWhere(
          (result) => result.isLocality && result.id == localitySym,
        );
      } catch (_) {
        parentLocality = null;
      }
    }

    final county =
        parentLocality != null ? _countyFromResult(parentLocality) : '';
    final commune =
        parentLocality != null ? _communeFromResult(parentLocality) : '';

    return LocationSelection(
      type: district.type,
      id: district.id,
      level: district.level,
      name: district.name,
      localitySym: district.localitySym ?? '',
      city: _cityFromResult(district),
      state: _voivodeshipFromResult(district),
      county: county,
      commune: commune,
      districts: [district.name],
      display: district.display,
      path: List<String>.from(district.path),
    );
  }

  LocationSelection _buildPreviewSelection(
    List<AutocompleteResult> results,
    String query,
  ) {
    if (results.isEmpty || query.trim().isEmpty) {
      return const LocationSelection.empty();
    }

    final normalizedQuery = query.trim().toLowerCase();
    AutocompleteResult candidate = results.first;

    try {
      candidate = results.firstWhere(
        (result) => result.name.trim().toLowerCase() == normalizedQuery,
      );
    } catch (_) {
      try {
        candidate = results.firstWhere(
          (result) => result.display.trim().toLowerCase().contains(
                normalizedQuery,
              ),
        );
      } catch (_) {
        candidate = results.first;
      }
    }

    if (candidate.isLocality) {
      return _selectionFromLocality(candidate);
    }

    if (candidate.isDistrict9 || candidate.isDistrict10) {
      return _selectionFromDistrict(candidate, results);
    }

    return const LocationSelection.empty();
  }

  Widget _buildReadonlyField({
    required String label,
    required String value,
    required ThemeColors theme,
  }) {
    final displayValue = value.trim().isEmpty ? '-' : value.trim();

    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dashboardBoarder.withAlpha(120),
        ),
        color: theme.dashboardContainer.withAlpha(35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: theme.textColor.withAlpha(160),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                displayValue,
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
    final theme = ref.watch(themeColorsProvider);
    final addOfferState = ref.watch(addOfferProvider);
    final addOfferNotifier = ref.watch(addOfferProvider.notifier);

    final autoState = ref.watch(myTextFieldViewModelProvider(_providerKey));
    final autoResults =
        (autoState['searchResults'] as List?)?.cast<AutocompleteResult>() ??
            const <AutocompleteResult>[];

    final initialLocationText =
    addOfferState.cityController.text.isNotEmpty
        ? addOfferState.cityController.text
        : '';

    final countryValue =
        addOfferState.countryController.text.trim().isEmpty
            ? 'Poland'
            : addOfferState.countryController.text.trim();

    Widget locationAutocomplete() {
      return AutoCompleteWidget(
        provider: _providerKey,
        initialText: initialLocationText,
        hintText: 'Search city / district'.tr,
        onQueryChanged: (ref, query) {
          if (query.trim().isEmpty) {
            _clearLocation(addOfferState, addOfferNotifier);
          } else {
            final preview = _buildPreviewSelection(autoResults, query);
            if (!preview.isEmpty) {
              _applySelection(
                preview,
                addOfferState,
                addOfferNotifier,
                persistGeoFields: false,
              );
            }
          }

          if (mounted) setState(() {});
        },
        onLocationChanged: (ref, selection) {
          _applyLocationSelection(
            selection,
            addOfferState,
            addOfferNotifier,
          );
        },
      );
    }

    final content = widget.isMobile
        ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          "Location".tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).iconTheme.color,
          ),
        ),
        const SizedBox(height: 16),
        locationAutocomplete(),
        const SizedBox(height: 10),
        _buildReadonlyField(
          label: 'county'.tr,
          value: countryValue,
          theme: theme,
        ),
        const SizedBox(height: 10),
        _buildReadonlyField(
          label: 'State'.tr,
          value: _stateReadonlyController.text,
          theme: theme,
        ),
        const SizedBox(height: 10),
        _buildReadonlyField(
          label: 'City'.tr,
          value: _cityReadonlyController.text,
          theme: theme,
        ),
        const SizedBox(height: 10),
        _buildReadonlyField(
          label: 'heating_type_district'.tr,
          value: _districtReadonlyController.text,
          theme: theme,
        ),
        const SizedBox(height: 10),
        _buildReadonlyField(
          label: 'county'.tr,
          value: _countyReadonlyController.text,
          theme: theme,
        ),
        if (_communeReadonlyController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildReadonlyField(
            label: 'commune'.tr,
            value: _communeReadonlyController.text,
            theme: theme,
          ),
        ],
        const SizedBox(height: 10),
        Container(
          key: _streetFieldKey,
          child: GradientTextField(
            focusNode: _streetFocusNode,
            controller: addOfferState.streetController,
            hintText: 'Street Address'.tr,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) {
              FocusScope.of(context).requestFocus(_zipcodeFocusNode);
            },
          ),
        ),
        const SizedBox(height: 10),
        Container(
          key: _zipcodeFieldKey,
          child: GradientTextField(
            focusNode: _zipcodeFocusNode,
            controller: addOfferState.zipcodeController,
            hintText: 'Zipcode'.tr,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              FocusScope.of(context).unfocus();
            },
          ),
        ),
        const SizedBox(height: 10),
        GradientDropdownAddOffer(
          isPc: true,
          value: addOfferState.distanceFilterController.text,
          selectedItem: addOfferState.distanceFilterController.text,
          items: const ['0 km', '1 km', '5 km', '10 km', '20 km'],
          onChanged: (value) {
            addOfferNotifier.updateField('distanceFilter', value);
          },
          hintText: 'Distance Filter'.tr,
        ),
        const SizedBox(height: 16),
        MapaWidgetAddOffer(),
        const SizedBox(height: 16),
      ],
    )
        : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        locationAutocomplete(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildReadonlyField(
                label: 'county'.tr,
                value: countryValue,
                theme: theme,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildReadonlyField(
                label: 'State'.tr,
                value: _stateReadonlyController.text,
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildReadonlyField(
                label: 'City'.tr,
                value: _cityReadonlyController.text,
                theme: theme,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildReadonlyField(
                label: 'heating_type_district'.tr,
                value: _districtReadonlyController.text,
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildReadonlyField(
                label: 'commune'.tr,
                value: _communeReadonlyController.text,
                theme: theme,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildReadonlyField(
                label: 'county'.tr,
                value: _countyReadonlyController.text,
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                key: _streetFieldKey,
                child: GradientTextField(
                  focusNode: _streetFocusNode,
                  controller: addOfferState.streetController,
                  hintText: 'Street Address'.tr,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_zipcodeFocusNode);
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                key: _zipcodeFieldKey,
                child: GradientTextField(
                  focusNode: _zipcodeFocusNode,
                  controller: addOfferState.zipcodeController,
                  hintText: 'Zipcode'.tr,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );

    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final bottomBar = BottomBarSize.resolve(context);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(
          bottom: keyboard + bottomBar + 40,
        ),
        child: content,
      ),
    );
  }
}