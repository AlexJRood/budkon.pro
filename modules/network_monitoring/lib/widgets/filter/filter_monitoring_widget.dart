import 'dart:math' as math;

import 'package:core/shell/keyboard_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';
import 'package:network_monitoring/providers/tag_input_provider.dart';
import 'package:network_monitoring/widgets/filter/controllers.dart';
import 'package:network_monitoring/widgets/filter/estate_type_widget.dart';
import 'package:network_monitoring/widgets/filter/fileds.dart';
import 'package:network_monitoring/widgets/filter/filter_buttons_widget.dart';
import 'package:network_monitoring/widgets/filter/filters_widget.dart';
import 'package:network_monitoring/widgets/filter/market_filters_widget.dart';
import 'package:network_monitoring/widgets/filter/offer_type_widget.dart';
import 'package:core/platform/navigation_history_provider.dart';
import 'package:core/common/autocompletion/autocomplete.dart';
import 'package:core/theme/apptheme.dart';

class FilterNetworkMonitoringNotifier extends StateNotifier<FilterNetowrkMonitoringState> {
  FilterNetworkMonitoringNotifier() : super(FilterNetowrkMonitoringState());
}

final filterNetworkMonitoringProvider =
    StateNotifierProvider<FilterNetworkMonitoringNotifier, FilterNetowrkMonitoringState>(
        (ref) => FilterNetworkMonitoringNotifier());

class FilterMonitoringWidget extends ConsumerStatefulWidget {
  const FilterMonitoringWidget({
    super.key,
    this.scrollController,
    this.isMobile = false,
  });
  final bool isMobile;
  final ScrollController? scrollController;

  @override
  FilterNetowrkMonitoringState createState() => FilterNetowrkMonitoringState();
}

class FilterNetowrkMonitoringState extends ConsumerState<FilterMonitoringWidget>
    with AutomaticKeepAliveClientMixin {
  String selectedOfferType = '';
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        _syncFilters();
      }
    });
  }

  void setSelectedOfferType(String value) {
    setState(() {
      selectedOfferType = value;
      final c = ref.read(nmControllersProvider);
      c.offerTypeController.text = value;
    });
  }

  void _syncFilters() {
    final filters = ref.read(networkMonitoringFilterCacheProvider.notifier).filters;
    final buttonNotifier = ref.read(networkMonitoringFilterButtonProvider.notifier);
    final cache = ref.read(networkMonitoringFilterCacheProvider.notifier);

    void set(String key) {
      final value = filters[key];
      if (value != null) {
        buttonNotifier.updateFilterNM(key, value.toString());
        cache.addFilterNM(key, value.toString());
      }
    }

    void setList(String key) {
      final raw = filters[key];
      if (raw == null) return;

      // Supports both List and CSV string.
      final List<String> values = switch (raw) {
        List l => l.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList(),
        String s => s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        _ => [raw.toString()]
      };

      buttonNotifier.updateFilterNM(key, values); // UI state as list
      cache.addFilterNM(key, values.join(',')); // cache/server as CSV
    }

    set('rooms');
    set('offer_type');
    set('market_type');
    setList('estate_type');

    // If you want to sync city/state/district into UI chips/buttons later, add it here.
    // For now location is controlled by AutoCompleteWidget -> cache filters.
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final c = ref.watch(nmControllersProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const double dynamicBoxHeight = 25;
    const double dynamicBoxHeightGroup = 10;
    const double dynamicBoxHeightGroupSmall = 8;
    const double dynamiSpacerBoxWidth = 15;
    const double dynamicSpace = 5;

    final double filterBarWidth = math.max(screenWidth * 0.75, 450);
    final double filterBarHeigth = math.max(screenHeight, 400);

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        KeyBoardShortcuts().handleKeyEvent(event, c.scrollController, 50, 100);
      },
      child: Stack(
        children: [
          Center(
            child: SizedBox(
              width: filterBarWidth,
              height: filterBarHeigth,
              child: _buildFilterContent(
                c: c,
                dynamicBoxHeight: dynamicBoxHeight,
                dynamicBoxHeightGroup: dynamicBoxHeightGroup,
                dynamicBoxHeightGroupSmall: dynamicBoxHeightGroupSmall,
                dynamiSpacerBoxWidth: dynamiSpacerBoxWidth,
                dynamicSpace: dynamicSpace,
              ),
            ),
          ),
          if (!widget.isMobile)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FilterButtonsWidget(
                isMobile: widget.isMobile,
                navigationHistoryProvider: navigationHistoryProvider,
              ),
            ),
        ],
      ),
    );
  }

  /// Shared scroll + filter list content extracted to avoid duplication
  /// between the tablet (fill-width) and pc (centred SizedBox) branches.
  Widget _buildFilterContent({
    required dynamic c,
    required double dynamicBoxHeight,
    required double dynamicBoxHeightGroup,
    required double dynamicBoxHeightGroupSmall,
    required double dynamiSpacerBoxWidth,
    required double dynamicSpace,
  }) {
    final theme = ref.read(themeColorsProvider);
    return Column(
      children: [
        if (widget.isMobile)
          Padding(
            padding: const EdgeInsets.all(15),
            child: Container(
              height: 5,
              width: 180,
              decoration: BoxDecoration(
                color: theme.textColor,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
        Expanded(
          child: ScrollbarTheme(
            data: ScrollbarThemeData(
              thumbColor: WidgetStateProperty.all(
                theme.textColor.withAlpha((255 * 0.35).toInt()),
              ),
              thickness: WidgetStateProperty.all(6.0),
              radius: const Radius.circular(10.0),
            ),
            child: Scrollbar(
              thumbVisibility: true,
              controller: widget.scrollController ?? c.scrollController,
              child: ListView(
                controller: widget.scrollController ?? c.scrollController,
                physics: const ClampingScrollPhysics(),
                padding: widget.isMobile
                    ? const EdgeInsets.only(top: 20, right: 15)
                    : const EdgeInsets.only(
                        top: 10,
                        bottom: 20.0,
                        left: 20.0,
                        right: 20.0,
                      ),
                children: [
                  if (!widget.isMobile) const SizedBox(height: 60),
                  const SizedBox(height: 20),
                  OfferTypeWidget(
                    dynamicBoxHeightGroupSmall: dynamicBoxHeightGroupSmall,
                  ),
                  SizedBox(height: dynamicBoxHeight),
                  AutoCompleteWidget(
                    provider: 'network_monitoring',
                    onLocationChanged: (ref, sel) {
                      ref
                          .read(networkMonitoringFilterCacheProvider.notifier)
                          .setLocationSelectionNM(sel);
                    },
                  ),
                  SizedBox(height: dynamicBoxHeight),
                  EstateTypeWidget(
                    dynamicSpace: dynamicSpace,
                    dynamicBoxHeightGroupSmall: dynamicBoxHeightGroupSmall,
                  ),
                  SizedBox(height: dynamicBoxHeight),
                  FiltersWidget(
                    minSquareFootageController: c.minSquareFootageController,
                    maxSquareFootageController: c.maxSquareFootageController,
                    minPriceController: c.minPriceController,
                    maxPriceController: c.maxPriceController,
                    minPricePerMeterController: c.minPricePerMeterController,
                    maxPricePerMeterController: c.maxPricePerMeterController,
                    minRoomsController: c.minRoomsController,
                    maxRoomsController: c.maxRoomsController,
                    dynamicBoxHeightGroupSmall: dynamicBoxHeightGroupSmall,
                    dynamiSpacerBoxWidth: dynamiSpacerBoxWidth,
                    dynamicBoxHeightGroup: dynamicBoxHeightGroup,
                    dynamicBoxHeight: dynamicBoxHeight,
                    dynamicSpace: dynamicSpace,
                    ref: ref,
                  ),
                  SizedBox(height: dynamicBoxHeight),
                  MarketFiltersWidget(
                    currentCountry: c.countryController.toString(),
                    dynamicBoxHeightGroup: dynamicBoxHeightGroup,
                    dynamicBoxHeightGroupSmall: dynamicBoxHeightGroupSmall,
                    ref: ref,
                  ),
                  SizedBox(height: dynamicBoxHeight * (widget.isMobile ? 2 : 3)),
                  if (widget.isMobile)
                    FilterButtonsWidget(
                      isMobile: widget.isMobile,
                      navigationHistoryProvider: navigationHistoryProvider,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
