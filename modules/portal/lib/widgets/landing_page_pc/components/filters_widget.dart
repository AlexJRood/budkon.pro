import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:portal/screens/landing_page/providers/landing_page_provider.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import '../../../screens/feed/widgets/map/filters_pv_mobile_page.dart';
import 'package:core/common/autocompletion/models/autocomplete_result.dart';
import 'package:core/common/autocompletion/provider/autocompletion_provider.dart';
import 'package:core/common/autocompletion/services/debouncer.dart';
import 'package:core/platform/filters/filters_const.dart';


void _closePopupSafely(
  BuildContext context, {
  VoidCallback? onClose,
  bool closeRouteOnClose = false,
}) {
  onClose?.call();
  Navigator.of(context).pop();
}

class SelectionWidget extends ConsumerWidget {
  final String title;
  final List<String> options;
  final String? selectedOption;
  final IconData leadingIcon;
  final ValueChanged<String?> onSelect;

  final bool hasMultiTextFields;
  final bool hasSingleTextField;
  final bool isMobile;

  final String? hint1;
  final String? hint2;

  final ValueChanged<String?>? onChange1;
  final ValueChanged<String?>? onChange2;

  final TextEditingController? controller1;
  final TextEditingController? controller2;

  final VoidCallback? onAccept;
  final VoidCallback? onClose;

  final String acceptText;
  final ScrollController? scrollController;

  final bool autofocusFirstField;
  final FocusNode? firstFieldFocusNode;

  const SelectionWidget({
    super.key,
    required this.title,
    required this.options,
    required this.selectedOption,
    required this.leadingIcon,
    required this.onSelect,
    this.hasMultiTextFields = false,
    this.hasSingleTextField = false,
    this.isMobile = false,
    this.hint1,
    this.hint2,
    this.onChange1,
    this.onChange2,
    this.controller1,
    this.controller2,
    this.scrollController,
    this.onAccept,
    this.onClose,
    this.acceptText = 'accept_label',
    this.autofocusFirstField = false,
    this.firstFieldFocusNode,
  });

  InputDecoration _inputDecoration(
    ThemeColors theme, {
    required String? hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: theme.textColor.withAlpha(170),fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: theme.textColor,size: 18,),
      filled: true,
      fillColor: theme.textFieldColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _leadingIconBox(ThemeColors theme) {
    return Container(
      height: 32,
      width: 32,
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: Center(
        child: Icon(leadingIcon, color: theme.textColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: isMobile ? null : 400,
          width: isMobile ? double.infinity : 462,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (onClose != null)
                    IconButton(
                      tooltip: 'Close'.tr,
                      onPressed: onClose,
                      icon: Icon(Icons.close, color: theme.textColor),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (hasMultiTextFields)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller1,
                        focusNode: firstFieldFocusNode,
                        keyboardType: TextInputType.number,
                        autofocus: autofocusFirstField,
                        cursorColor: theme.textColor,
                        style: TextStyle(color: theme.textColor),
                        decoration: _inputDecoration(
                          theme,
                          hintText: hint1,
                          prefixIcon: leadingIcon,
                        ),
                        onChanged: onChange1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '-',
                      style: TextStyle(color: theme.textColor, fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: controller2,
                        keyboardType: TextInputType.number,
                        cursorColor: theme.textColor,
                        style: TextStyle(color: theme.textColor),
                        decoration: _inputDecoration(
                          theme,
                          hintText: hint2,
                          prefixIcon: leadingIcon,
                        ),
                        onChanged: onChange2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 82,
                      height: 56,
                      child: ElevatedButton(
                        style: buttonStyleRounded10ThemeRed,
                        onPressed: onAccept,
                        child: Text(
                          acceptText.tr,
                          style: const TextStyle(color: AppColors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              if (hasSingleTextField)
                TextField(
                  controller: controller1,
                  focusNode: firstFieldFocusNode,
                  autofocus: autofocusFirstField,
                  cursorColor: theme.textColor,
                  style: TextStyle(color: theme.textColor),
                  decoration: _inputDecoration(
                    theme,
                    hintText: hint1,
                    prefixIcon: Icons.search,
                  ),
                  onChanged: onChange1,
                ),
              if (hasMultiTextFields || hasSingleTextField)
                const SizedBox(height: 16),
              Expanded(
                child: options.isEmpty
                    ? Center(
                        child: Text(
                         'no_options'.tr,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(170),
                          ),
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (_) => true,
                        child: ListView.builder(
                          controller: scrollController,
                          primary: false,
                          physics: const ClampingScrollPhysics(),
                          addAutomaticKeepAlives: false,
                          cacheExtent: 300,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options[index];
                            final isSelected = option == selectedOption;

                            if (kDebugMode) {
                              debugPrint('SelectionWidget option: $option');
                              debugPrint(
                                'SelectionWidget selectedOption: $selectedOption',
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: isSelected
                                    ? theme.adPopBackground
                                    : theme.dashboardContainer,
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => onSelect(isSelected ? null : option),
                                  child: ListTile(
                                    leading: _leadingIconBox(theme),
                                    title: Text(
                                      option,
                                      style: TextStyle(color: theme.textColor),
                                    ),
                                    trailing: Icon(
                                      isSelected
                                          ? Icons.remove_circle_outline
                                          : Icons.add_circle_outline,
                                      color: theme.textColor,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
class LocationSelection {
  final String type;
  final String id;
  final String city;
  final String state;
  final List<String> districts;
  final String display;
  final List<String> path;

  const LocationSelection({
    required this.type,
    required this.id,
    required this.city,
    required this.state,
    required this.districts,
    required this.display,
    required this.path,
  });

  const LocationSelection.empty()
      : type = '',
        id = '',
        city = '',
        state = '',
        districts = const [],
        display = '',
        path = const [];

  bool get isEmpty => type.isEmpty || id.isEmpty;
}

class LocationSearchWidget extends ConsumerStatefulWidget {
  final String? providerKey;
  final bool isMobile;
  final bool autofocus;
  final bool closeRouteOnClose;
  final ScrollController? scrollController;
  final FocusNode? searchFocusNode;

  final void Function(LocationSelection selection)? onSelected;
  final VoidCallback? onClose;

  const LocationSearchWidget({
    super.key,
    this.providerKey,
    this.isMobile = false,
    this.autofocus = false,
    this.closeRouteOnClose = false,
    this.scrollController,
    this.searchFocusNode,
    this.onSelected,
    this.onClose,
  });

  @override
  ConsumerState<LocationSearchWidget> createState() =>
      _LocationSearchAutocompletePanelState();
}

class _LocationSearchAutocompletePanelState
    extends ConsumerState<LocationSearchWidget> {
  final DebouncerRequest _debouncer = DebouncerRequest(milliseconds: 280);
  final Set<String> _expandedLocalityIds = <String>{};
  final FocusNode _internalSearchFocusNode = FocusNode(
    debugLabel: 'location-search-internal-focus',
  );

  bool _localLoading = false;
  bool _isClosing = false;

  FocusNode get _effectiveSearchFocusNode =>
      widget.searchFocusNode ?? _internalSearchFocusNode;

  void _setLocalLoading(bool value) {
    if (!mounted) return;
    if (_localLoading == value) return;
    setState(() => _localLoading = value);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _setLocalLoading(false);

      final key = widget.providerKey;
      if (key != null && key.isNotEmpty) {
        final model = ref.read(myTextFieldViewModelProvider(key).notifier);
        model.setLoading(false);
      }

      if (widget.autofocus) {
        _effectiveSearchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _debouncer.cancel();
    _internalSearchFocusNode.dispose();
    super.dispose();
  }

  void _closePopup(BuildContext context) {
    if (_isClosing) return;
    _isClosing = true;

    _debouncer.cancel();
    _setLocalLoading(false);

    FocusScope.of(context).unfocus();

    _closePopupSafely(
      context,
      onClose: widget.onClose,
      closeRouteOnClose: widget.closeRouteOnClose,
    );

    Future.microtask(() {
      _isClosing = false;
    });
  }

  String _voivodeshipFromResult(AutocompleteResult r) {
    if (r.path.isEmpty) return '';
    if (r.isLocality) return r.path.first.toString();
    if (r.isDistrict9 || r.isDistrict10) return r.path.last.toString();
    return '';
  }

  String _cityFromResult(AutocompleteResult r) {
    if (r.isLocality) return r.name;
    if (r.isDistrict9 || r.isDistrict10) {
      if (r.path.isNotEmpty) return r.path.first.toString();
      final parts = r.display.split(',');
      if (parts.length >= 2) return parts.last.trim();
    }
    return '';
  }

  LocationSelection _selectionFromLocality(AutocompleteResult l) {
    return LocationSelection(
      type: l.type,
      id: l.id,
      city: _cityFromResult(l),
      state: _voivodeshipFromResult(l),
      districts: const [],
      display: l.display,
      path: List<String>.from(l.path),
    );
  }

  LocationSelection _selectionFromDistrict(AutocompleteResult d) {
    return LocationSelection(
      type: d.type,
      id: d.id,
      city: _cityFromResult(d),
      state: _voivodeshipFromResult(d),
      districts: [d.name],
      display: d.display,
      path: List<String>.from(d.path),
    );
  }

  void _emit(LocationSelection selection) {
    widget.onSelected?.call(selection);
  }

  Future<void> _search(MyTextFieldViewModel model, String text) async {
    final q = text.trim();

    _debouncer.run(() async {
      if (q.isEmpty || q.length < 2) {
        _expandedLocalityIds.clear();
        model.clearExpandedCities();
        _setLocalLoading(false);
        model.setLoading(false);
        return;
      }

      _setLocalLoading(true);
      model.setLoading(true);

      try {
        await model.filterCitiesAndDistricts(q);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Autocomplete search error: $e');
        }
      } finally {
        _setLocalLoading(false);
        model.setLoading(false);
      }
    });
  }

  Widget _leadingIconBox(IconData icon) {
    return Container(
      height: 32,
      width: 32,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, 1),
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      child: Center(
        child: Icon(icon, color: const Color.fromRGBO(90, 90, 90, 1)),
      ),
    );
  }

  InputDecoration _searchDecoration(ThemeColors theme, String query) {
    return InputDecoration(
      hintText: 'search_location'.tr,
      prefixIcon: Icon(Icons.search, color: theme.textColor),
      hintStyle: TextStyle(color: theme.textColor.withAlpha(170)),
      filled: true,
      fillColor: theme.textFieldColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      suffixIcon: query.isNotEmpty
          ? IconButton(
              icon: Icon(Icons.close, color: theme.textColor),
              onPressed: () {
                final key = widget.providerKey ?? '';
                final model = ref.read(
                  myTextFieldViewModelProvider(key).notifier,
                );

                _debouncer.cancel();
                _setLocalLoading(false);
                model.setLoading(false);
                model.clear();
                _expandedLocalityIds.clear();
                _emit(const LocationSelection.empty());
              },
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    final key = widget.providerKey ?? '';
    final model = ref.watch(myTextFieldViewModelProvider(key).notifier);
    final state = ref.watch(myTextFieldViewModelProvider(key));

    final List recent = (state['recentList'] as List?) ?? const [];

    final query = model.searchController.text.trim();
    final queryLower = query.toLowerCase();

    final List<AutocompleteResult> results = List<AutocompleteResult>.from(
      model.searchResults,
    );

    final List<AutocompleteResult> localities =
        results.where((r) => r.isLocality).toList();

    final List<AutocompleteResult> districts =
        results.where((r) => r.isDistrict9 || r.isDistrict10).toList();

    final Map<String, List<AutocompleteResult>> districtsByLocality =
        <String, List<AutocompleteResult>>{};

    for (final d in districts) {
      final localityKey = d.localitySym ?? '';
      if (localityKey.isEmpty) continue;
      (districtsByLocality[localityKey] ??= <AutocompleteResult>[]).add(d);
    }

    if (localities.length > 1) {
      localities.sort((a, b) => b.score.compareTo(a.score));
    }

    final bool hasLocalities = localities.isNotEmpty;
    final bool districtExactMatch = districts.any(
      (d) => d.name.toLowerCase() == queryLower,
    );

    final bool showDirectDistrictSection =
        (!hasLocalities) || districtExactMatch;

    final List<AutocompleteResult> directDistricts = showDirectDistrictSection
        ? districts
            .where((d) => d.name.toLowerCase().startsWith(queryLower))
            .toList()
        : <AutocompleteResult>[];

    if (directDistricts.length > 1) {
      directDistricts.sort((a, b) => b.score.compareTo(a.score));
    }

    final bool showRecentlySelected = query.isEmpty && recent.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: widget.isMobile ? null : 400,
          width: widget.isMobile ? double.infinity : 462,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Suggested locations:'.tr,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (widget.onClose != null)
                    IconButton(
                      tooltip: 'Close'.tr,
                      onPressed: () => _closePopup(context),
                      icon: Icon(Icons.close, color: theme.textColor),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: model.searchController,
                focusNode: _effectiveSearchFocusNode,
                autofocus: widget.autofocus,
                cursorColor: theme.textColor,
                style: TextStyle(color: theme.textColor),
                decoration: _searchDecoration(theme, query),
                onChanged: (txt) => _search(model, txt),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Stack(
                  children: [
                    NotificationListener<ScrollNotification>(
                      onNotification: (_) => true,
                      child: ListView(
                        controller: widget.scrollController,
                        primary: false,
                        physics: const ClampingScrollPhysics(),
                        addAutomaticKeepAlives: false,
                        cacheExtent: 400,
                        children: [
                          if (showRecentlySelected) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Recently selected'.tr,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ...recent.map((r) {
                              final AutocompleteResult? result =
                              r is AutocompleteResult ? r : null;

                              final txt = result?.display ??
                                  result?.name ??
                                  (r is Map ? (r['display'] ?? r['name'] ?? '').toString() : r.toString());

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () async {
                                      model.searchController.text = txt;
                                      await _search(model, txt);
                                    },
                                    child: ListTile(
                                      leading: _leadingIconBox(Icons.history),
                                      title: Text(
                                        txt,
                                        style: TextStyle(
                                          color: theme.textColor.withAlpha(120),
                                        ),
                                      ),
                                      trailing: Icon(
                                        Icons.north_west,
                                        color: theme.textColor.withAlpha(120),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                          if (!showRecentlySelected) ...[
                            if (directDistricts.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'districts'.tr,
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              ...directDistricts.map((d) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Material(
                                    color: theme.adPopBackground,
                                    borderRadius: BorderRadius.circular(8),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        model.selectDistrictFromList(d.name, d);
                                        _emit(_selectionFromDistrict(d));
                                        _closePopup(context);
                                      },
                                      child: ListTile(
                                        leading: _leadingIconBox(Icons.location_on),
                                        title: Text(
                                          d.name,
                                          style: TextStyle(
                                            color: theme.textColor,
                                          ),
                                        ),
                                        subtitle: Text(
                                          d.display,
                                          style: TextStyle(
                                            color: theme.textColor.withAlpha(120),
                                            fontSize: 12,
                                          ),
                                        ),
                                        trailing: Icon(
                                          Icons.add_circle_outline,
                                          color: theme.textColor.withAlpha(120),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              const Divider(),
                              const SizedBox(height: 8),
                            ],
                            if (localities.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Localities'.tr,
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              ...localities.map((l) {
                                final localityId = l.id;
                                final attached =
                                    districtsByLocality[localityId] ??
                                        const <AutocompleteResult>[];
                                final isExpanded =
                                    _expandedLocalityIds.contains(localityId);

                                final sortedAttached =
                                    List<AutocompleteResult>.from(attached);

                                if (sortedAttached.length > 1) {
                                  sortedAttached.sort(
                                    (a, b) => b.score.compareTo(a.score),
                                  );
                                }

                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        child: ListTile(
                                          leading: _leadingIconBox(
                                            Icons.location_city,
                                          ),
                                          title: Text(
                                            l.name,
                                            style: TextStyle(
                                              color: theme.textColor,
                                            ),
                                          ),
                                          subtitle: Text(
                                            l.display,
                                            style: TextStyle(
                                              color: theme.textColor.withAlpha(120),
                                              fontSize: 12,
                                            ),
                                          ),
                                          trailing: attached.isNotEmpty
                                              ? IconButton(
                                                  icon: Icon(
                                                    isExpanded
                                                        ? Icons.keyboard_arrow_up
                                                        : Icons.keyboard_arrow_down,
                                                    color: theme.textColor
                                                        .withAlpha(120),
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      if (isExpanded) {
                                                        _expandedLocalityIds
                                                            .remove(localityId);
                                                      } else {
                                                        _expandedLocalityIds
                                                            .add(localityId);
                                                      }
                                                    });
                                                  },
                                                )
                                              : Icon(
                                                  Icons.add_circle_outline,
                                                  color: theme.textColor
                                                      .withAlpha(120),
                                                ),
                                          onTap: () {
                                            model.handleCitySelection(l.name, l);
                                            _emit(_selectionFromLocality(l));
                                            _closePopup(context);
                                          },
                                        ),
                                      ),
                                    ),
                                    if (isExpanded && sortedAttached.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 44,
                                          right: 8,
                                          bottom: 8,
                                        ),
                                        child: Column(
                                          children: sortedAttached.map((d) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              child: Material(
                                                color: theme.textColor.withAlpha(180),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  onTap: () {
                                                    model.selectDistrictFromList(
                                                      d.name,
                                                      d,
                                                    );
                                                    _emit(
                                                      _selectionFromDistrict(d),
                                                    );
                                                    _closePopup(context);
                                                  },
                                                  child: ListTile(
                                                    leading: _leadingIconBox(
                                                      Icons.place_outlined,
                                                    ),
                                                    title: Text(
                                                      d.name,
                                                      style: TextStyle(
                                                        color: theme.textFieldColor,
                                                      ),
                                                    ),
                                                    subtitle: Text(
                                                      d.display,
                                                      style: TextStyle(
                                                        color: theme.textFieldColor
                                                            .withAlpha(180),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    trailing: Icon(
                                                      Icons.add_circle_outline,
                                                      color: theme.textFieldColor,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                  ],
                                );
                              }),
                            ],
                            if (directDistricts.isEmpty &&
                                localities.isEmpty &&
                                query.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                'no_results'.tr,
                                  style: TextStyle(color: theme.textColor),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    if (_localLoading)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            alignment: Alignment.topCenter,
                            padding: const EdgeInsets.only(top: 8),
                            child: const LinearProgressIndicator(minHeight: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PriceRangeWidget extends ConsumerStatefulWidget {
  final VoidCallback? onClose;
  final bool isMobile;
  final bool closeRouteOnClose;
  final ScrollController? scrollController;

  const PriceRangeWidget({
    super.key,
    this.onClose,
    this.isMobile = false,
    this.closeRouteOnClose = false,
    this.scrollController,
  });

  @override
  ConsumerState<PriceRangeWidget> createState() => _PriceRangeWidgetState();
}

class _PriceRangeWidgetState extends ConsumerState<PriceRangeWidget> {
  late final TextEditingController controller1;
  late final TextEditingController controller2;

  @override
  void initState() {
    super.initState();
    controller1 = TextEditingController();
    controller2 = TextEditingController();

    final cache = ref.read(filterCacheProvider.notifier).filters;
    final min = cache[FilterPopConst.minPrice];
    final max = cache[FilterPopConst.maxPrice];

    String toText(dynamic value) {
      if (value == null) return '';
      if (value is int) return value.toString();
      if (value is double) return value.toStringAsFixed(0);
      return value.toString().trim();
    }

    controller1.text = toText(min);
    controller2.text = toText(max);
  }

  @override
  void dispose() {
    controller1.dispose();
    controller2.dispose();
    super.dispose();
  }

  int? _parsePrice(String value) {
    final cleaned = value
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .replaceAll('PLN', '')
        .replaceAll('zł', '')
        .replaceAll('\$', '')
        .trim();

    return int.tryParse(cleaned);
  }

  void _closePopup(BuildContext context) {
    _closePopupSafely(
      context,
      onClose: widget.onClose,
      closeRouteOnClose: widget.closeRouteOnClose,
    );
  }

  @override
  Widget build(BuildContext context) {
    final presets = FilterPopConst.priceRangePresets;
    final selectedPriceRange = ref.watch(selectedPriceRangeProvider);

    return SelectionWidget(
      title: 'Price range:'.tr,
      options: presets.map((e) => e.label).toList(),
      selectedOption: selectedPriceRange,
      leadingIcon: Icons.attach_money,
      isMobile: widget.isMobile,
      scrollController: widget.scrollController,
      autofocusFirstField: true,
      onClose: () => _closePopup(context),
      onSelect: (priceLabel) {
        if (priceLabel != null) {
          final preset = FilterPopConst.pricePresetFromLabel(priceLabel);

          if (preset != null) {
            ref.read(selectedPriceRangeProvider.notifier).state = preset.label;
            ref
                .read(filterCacheProvider.notifier)
                .addFilter(FilterPopConst.minPrice, preset.min);
            ref
                .read(filterCacheProvider.notifier)
                .addFilter(FilterPopConst.maxPrice, preset.max);
          }
        } else {
          ref.read(selectedPriceRangeProvider.notifier).state = '';
          ref
              .read(filterCacheProvider.notifier)
              .addFilter(FilterPopConst.minPrice, '');
          ref
              .read(filterCacheProvider.notifier)
              .addFilter(FilterPopConst.maxPrice, '');
        }

        ref.read(isPriceSelectedProvider.notifier).state = false;
        _closePopup(context);
      },
      hasMultiTextFields: true,
      hint1: 'Min price'.tr,
      hint2: 'Max price'.tr,
      onChange1: (val) {
        ref
            .read(filterCacheProvider.notifier)
            .addFilter(FilterPopConst.minPrice, val?.replaceAll(',', ''));
      },
      onChange2: (val) {
        ref
            .read(filterCacheProvider.notifier)
            .addFilter(FilterPopConst.maxPrice, val?.replaceAll(',', ''));
      },
      controller1: controller1,
      controller2: controller2,
      onAccept: () {
        final minValue = _parsePrice(controller1.text);
        final maxValue = _parsePrice(controller2.text);

        if (minValue == null || maxValue == null) return;

        final label = '$minValue PLN - $maxValue PLN';

        ref.read(selectedPriceRangeProvider.notifier).state = label;
        ref
            .read(filterCacheProvider.notifier)
            .addFilter(FilterPopConst.minPrice, minValue);
        ref
            .read(filterCacheProvider.notifier)
            .addFilter(FilterPopConst.maxPrice, maxValue);

        ref.read(isPriceSelectedProvider.notifier).state = false;
        _closePopup(context);
      },
    );
  }
}

class MeterRangeWidget extends ConsumerStatefulWidget {
  final VoidCallback? onClose;
  final bool isMobile;
  final bool closeRouteOnClose;
  final ScrollController? scrollController;

  const MeterRangeWidget({
    super.key,
    this.onClose,
    this.isMobile = false,
    this.closeRouteOnClose = false,
    this.scrollController,
  });

  @override
  ConsumerState<MeterRangeWidget> createState() => _MeterRangeWidgetState();
}

class _MeterRangeWidgetState extends ConsumerState<MeterRangeWidget> {
  late final TextEditingController controller1;
  late final TextEditingController controller2;

  @override
  void initState() {
    super.initState();
    controller1 = TextEditingController();
    controller2 = TextEditingController();

    final cache = ref.read(filterCacheProvider.notifier).filters;
    final min = cache[FilterPopConst.minSquareFootage];
    final max = cache[FilterPopConst.maxSquareFootage];

    String toText(dynamic value) {
      if (value == null) return '';
      if (value is int) return value.toString();
      if (value is double) return value.toStringAsFixed(0);
      return value.toString().trim();
    }

    controller1.text = toText(min);
    controller2.text = toText(max);
  }

  @override
  void dispose() {
    controller1.dispose();
    controller2.dispose();
    super.dispose();
  }

  int? _parseMeter(String value) {
    final cleaned = value
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .replaceAll('m²', '')
        .replaceAll('m2', '')
        .trim();

    return int.tryParse(cleaned);
  }

  void _closePopup(BuildContext context) {
    _closePopupSafely(
      context,
      onClose: widget.onClose,
      closeRouteOnClose: widget.closeRouteOnClose,
    );
  }

  @override
  Widget build(BuildContext context) {
    final presets = FilterPopConst.meterRangePresets;
    final selectedMeterRange = ref.watch(selectedMeterRangeProvider);

    return SelectionWidget(
      title: 'Meter range:'.tr,
      options: presets.map((e) => e.label).toList(),
      selectedOption: selectedMeterRange,
      leadingIcon: Icons.straighten,
      isMobile: widget.isMobile,
      scrollController: widget.scrollController,
      autofocusFirstField: true,
      onClose: () => _closePopup(context),
      onSelect: (meterLabel) {
        if (meterLabel != null) {
          final preset = FilterPopConst.meterPresetFromLabel(meterLabel);

          if (preset != null) {
            ref.read(selectedMeterRangeProvider.notifier).state = preset.label;
            ref
                .read(filterCacheProvider.notifier)
                .addFilter(FilterPopConst.minSquareFootage, preset.min);
            ref
                .read(filterCacheProvider.notifier)
                .addFilter(FilterPopConst.maxSquareFootage, preset.max);
          }
        } else {
          ref.read(selectedMeterRangeProvider.notifier).state = '';
          ref
              .read(filterCacheProvider.notifier)
              .addFilter(FilterPopConst.minSquareFootage, '');
          ref
              .read(filterCacheProvider.notifier)
              .addFilter(FilterPopConst.maxSquareFootage, '');
        }

        ref.read(isSelectedMeterRangeProvider.notifier).state = false;
        _closePopup(context);
      },
      hasMultiTextFields: true,
      hint1: 'Min, m²'.tr,
      hint2: 'Max, m²'.tr,
      controller1: controller1,
      controller2: controller2,
      onChange1: (val) {
        ref
            .read(filterCacheProvider.notifier)
            .addFilter(
              FilterPopConst.minSquareFootage,
              val?.replaceAll(',', ''),
            );
      },
      onChange2: (val) {
        ref
            .read(filterCacheProvider.notifier)
            .addFilter(
              FilterPopConst.maxSquareFootage,
              val?.replaceAll(',', ''),
            );
      },
      onAccept: () {
        final minValue = _parseMeter(controller1.text);
        final maxValue = _parseMeter(controller2.text);

        if (minValue == null || maxValue == null) return;

        final label = '$minValue - $maxValue m²';

        ref.read(selectedMeterRangeProvider.notifier).state = label;
        ref
            .read(filterCacheProvider.notifier)
            .addFilter(FilterPopConst.minSquareFootage, minValue);
        ref
            .read(filterCacheProvider.notifier)
            .addFilter(FilterPopConst.maxSquareFootage, maxValue);

        ref.read(isSelectedMeterRangeProvider.notifier).state = false;
        _closePopup(context);
      },
    );
  }
}


class PropertyTypes extends ConsumerWidget {
  final VoidCallback? onClose;
  final bool isMobile;
  final bool closeRouteOnClose;
  final ScrollController? scrollController;

  const PropertyTypes({
    super.key,
    this.onClose,
    this.isMobile = false,
    this.closeRouteOnClose = false,
    this.scrollController,
  });

  void _closePopup(BuildContext context) {
    _closePopupSafely(
      context,
      onClose: onClose,
      closeRouteOnClose: closeRouteOnClose,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertyTypes = FilterPopConst.estateTypes;
    final propertyLabels = propertyTypes.map((e) => e['text']!).toList();

    final selectedRawValue = ref.watch(selectedPropertyProvider);
    final selectedLabel =
        FilterPopConst.estateTypeTextFromValue(selectedRawValue);

    return SelectionWidget(
      title: 'Choose property type:'.tr,
      options: propertyLabels,
      selectedOption: selectedLabel,
      leadingIcon: Icons.house_outlined,
      isMobile: isMobile,
      scrollController: scrollController,
      onClose: () => _closePopup(context),
      onSelect: (propertyLabel) {
        if (propertyLabel != null) {
          final filterValue =
              FilterPopConst.estateTypeValueFromLabel(propertyLabel);

          if (filterValue != null && filterValue.isNotEmpty) {
            ref.read(selectedPropertyProvider.notifier).state = filterValue;

            ref
                .read(filterButtonProvider.notifier)
                .updateFilter(FilterPopConst.estateType, <String>[filterValue]);

            ref
                .read(filterCacheProvider.notifier)
                .addFilter(FilterPopConst.estateType, filterValue);
          }
        } else {
          ref.read(selectedPropertyProvider.notifier).state = '';

          ref
              .read(filterButtonProvider.notifier)
              .updateFilter(FilterPopConst.estateType, <String>[]);

          ref
              .read(filterCacheProvider.notifier)
              .addFilter(FilterPopConst.estateType, '');
        }

        ref.read(isPropertyVisibleProvider.notifier).state = false;
        _closePopup(context);
      },
    );
  }
}