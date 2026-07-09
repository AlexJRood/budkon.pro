import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map/bdot_category_catalog.dart';
import 'package:map/providers.dart';
import 'package:map/map_state.dart';
import 'package:core/theme/apptheme.dart';
import 'package:get/get_utils/get_utils.dart';

class PortalMapControlsPanel extends ConsumerStatefulWidget {
  const PortalMapControlsPanel({super.key});

  @override
  ConsumerState<PortalMapControlsPanel> createState() =>
      _PortalMapControlsPanelState();
}

class _PortalMapControlsPanelState
    extends ConsumerState<PortalMapControlsPanel> {
  bool _showControlsExpanded = true;

  static const List<Color> _bdotPalette = [
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.orange,
    Colors.deepOrange,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.indigo,
    Colors.brown,
    Colors.blueGrey,
    Colors.grey,
    Colors.black,
  ];

  Future<void> _refreshStreetLayerIfNeeded() async {
    final controller = ref.read(portalMapControllerProvider);
    if (controller == null) return;

    final streetService = ref.read(streetLayerServiceProvider);
    if (!streetService.showLayer) return;

    await streetService.onViewportChanged(
      ref: ref,
      mapController: controller,
    );
  }

  Widget _buildColorPaletteRow({
    required ThemeColors theme,
    required Color selected,
    required ValueChanged<Color> onSelect,
    VoidCallback? onReset,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'color'.tr,
              style: TextStyle(
                color: theme.textColor.withAlpha(180),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (onReset != null)
              TextButton(
                onPressed: onReset,
                child: Text('Reset'.tr),
              ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _bdotPalette.map((color) {
            final isSelected = color.value == selected.value;

            return InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onSelect(color),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isSelected ? Colors.white : Colors.white.withAlpha(70),
                    width: isSelected ? 3 : 1.4,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withAlpha(130),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInfoNote({
    required ThemeColors theme,
    required String text,
    Color? color,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          color: color ?? theme.textColor.withAlpha(170),
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildSectionLabel(
    ThemeColors theme,
    String label, {
    IconData? icon,
    String? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: theme.themeColor, size: 16),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: TextStyle(
                color: theme.textColor.withAlpha(160),
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactCheckbox({
    required ThemeColors theme,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String title,
  }) {
    return CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: TextStyle(
          color: theme.textColor,
          fontSize: 13,
        ),
      ),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildZoomSettingRow({
    required ThemeColors theme,
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    ValueChanged<double>? onChangeEnd,
  }) {
    final safeValue = value.clamp(min, max).toDouble();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: theme.textColor),
              ),
            ),
            Text(
              safeValue.toStringAsFixed(1),
              style: TextStyle(color: theme.textColor),
            ),
          ],
        ),
        Slider(
          value: safeValue,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final currentZoom = ref.watch(mapZoomProvider);

    final parcelService = ref.read(parcelLayerServiceProvider);
    final streetService = ref.read(streetLayerServiceProvider);
    final mpzpService = ref.read(mpzpLayerServiceProvider);
    final gesutService = ref.read(gesutLayerServiceProvider);
    final fiberService = ref.read(fiberLayerServiceProvider);
    final landUseService = ref.read(landUseLayerServiceProvider);
    final propertyPriceService = ref.read(propertyPriceLayerServiceProvider);
    final bdotCategoriesService = ref.read(bdotCategoriesLayerServiceProvider);

    return ListenableBuilder(
      listenable: Listenable.merge([
        parcelService,
        streetService,
        mpzpService,
        gesutService,
        fiberService,
        landUseService,
        propertyPriceService,
        bdotCategoriesService,
      ]),
      builder: (context, _) {
        final canShowMpzp = mpzpService.canShow(currentZoom);
        final canShowGesut = gesutService.canShow(currentZoom);
        final canShowFiber = fiberService.canShow(currentZoom);
        final canShowStreets = streetService.canShow(currentZoom);

        final showPrecincts = parcelService.canShowPrecincts(currentZoom);
        final showParcels = parcelService.canShowDetails(currentZoom);

        final canShowLandUseOverview =
            landUseService.canShowOverview(currentZoom);
        final canShowLandUseDetails =
            landUseService.canShowDetails(currentZoom);

        final canShowPriceImplementations =
            propertyPriceService.canShowImplementations(currentZoom);
        final canShowPriceGrouping =
            propertyPriceService.canShowGrouping(currentZoom);
        final canShowPriceDetails =
            propertyPriceService.canShowDetails(currentZoom);

        final parcelPrecinctsMax =
            (parcelService.detailsMinZoom - 0.5).clamp(8.5, 18.0).toDouble();

        final parcelDetailsMin = (parcelService.precinctsMinZoom + 0.5)
            .clamp(8.5, 20.0)
            .toDouble();

        final landUseOverviewMax =
            (landUseService.detailsMinZoom - 0.5).clamp(6.5, 18.0).toDouble();

        final landUseDetailsMin = (landUseService.overviewMinZoom + 0.5)
            .clamp(6.5, 20.0)
            .toDouble();

        final priceImplMax = (propertyPriceService.groupingMinZoom - 0.5)
            .clamp(6.5, 18.0)
            .toDouble();

        final priceGroupingMin =
            (propertyPriceService.implementationsMinZoom + 0.5)
                .clamp(6.5, 19.0)
                .toDouble();

        final priceGroupingMax = (propertyPriceService.detailsMinZoom - 0.5)
            .clamp(7.0, 19.0)
            .toDouble();

        final priceDetailsMin = (propertyPriceService.groupingMinZoom + 0.5)
            .clamp(7.0, 20.0)
            .toDouble();

        return Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.72,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: _showControlsExpanded
                          ? 'hide_settings'.tr
                          : 'show_settings'.tr,
                      onPressed: () {
                        setState(() {
                          _showControlsExpanded = !_showControlsExpanded;
                        });
                      },
                      icon: Icon(
                        _showControlsExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: theme.textColor,
                      ),
                    ),
                  ),

                  if (_showControlsExpanded) ...[
                    _buildSectionLabel(
                      theme,
                      'streets_wfs_clickable'.tr,
                      icon: Icons.route_rounded,
                      trailing: canShowStreets
                          ? 'zoom_ok'.tr
                          : '${'visible_from'.tr}${streetService.minVisibleZoom.toStringAsFixed(1)}+',
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: streetService.showLayer,
                      onChanged: (value) {
                        streetService.setEnabled(value);
                        if (value) {
                          unawaited(_refreshStreetLayerIfNeeded());
                        }
                      },
                      title: Text(
                        'show_clickable_streets'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                    _buildZoomSettingRow(
                      theme: theme,
                      label: 'streets_from_zoom'.tr,
                      value: streetService.minVisibleZoom,
                      min: 12,
                      max: 20,
                      divisions: 16,
                      onChanged: streetService.setMinVisibleZoom,
                      onChangeEnd: (_) {
                        unawaited(_refreshStreetLayerIfNeeded());
                      },
                    ),
                    _buildZoomSettingRow(
                      theme: theme,
                      label: 'opacity'.tr,
                      value: streetService.opacity,
                      min: 0.2,
                      max: 1.0,
                      divisions: 8,
                      onChanged: streetService.setOpacity,
                    ),
                    _buildZoomSettingRow(
                      theme: theme,
                      label: 'thickness'.tr,
                      value: streetService.strokeWidth,
                      min: 2.0,
                      max: 8.0,
                      divisions: 12,
                      onChanged: streetService.setStrokeWidth,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        canShowStreets
                            ? 'click_street_for_data'.tr
                            : 'zoom_to_load_streets'.trParams({
                                'zoom': streetService.minVisibleZoom
                                    .toStringAsFixed(1),
                              }),
                        style: TextStyle(
                          color: theme.textColor.withAlpha(180),
                          fontSize: 11,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    Divider(color: Colors.white.withAlpha(25), height: 1),

                    _buildSectionLabel(
                      theme,
                      'parcels_egib'.tr,
                      icon: Icons.crop_square_rounded,
                      trailing: showParcels
                          ? 'parcels'.tr
                          : showPrecincts
                              ? 'precincts'.tr
                              : 'zoom_in'.tr,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: parcelService.showBoundaries,
                      onChanged: parcelService.setShowBoundaries,
                      title: Text(
                        'show_parcel_boundaries'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                    _buildZoomSettingRow(
                      theme: theme,
                      label: 'precincts_from_zoom'.tr,
                      value: parcelService.precinctsMinZoom,
                      min: 8.0,
                      max: parcelPrecinctsMax,
                      divisions: 20,
                      onChanged: parcelService.setPrecinctsMinZoom,
                    ),
                    _buildZoomSettingRow(
                      theme: theme,
                      label: 'parcels_from_zoom'.tr,
                      value: parcelService.detailsMinZoom,
                      min: parcelDetailsMin,
                      max: 20.0,
                      divisions: 23,
                      onChanged: parcelService.setDetailsMinZoom,
                    ),
                    _buildZoomSettingRow(
                      theme: theme,
                      label: 'opacity'.tr,
                      value: parcelService.opacity,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      onChanged: parcelService.setOpacity,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        showParcels
                            ? 'click_parcel_for_data'.tr
                            : showPrecincts
                                ? '${'precincts_visible'.tr}${parcelService.detailsMinZoom.toStringAsFixed(1)}+'
                                : 'zoom_for_precincts_start'.tr +
                                    parcelService.precinctsMinZoom
                                        .toStringAsFixed(1) +
                                    'zoom_for_precincts_middle'.tr +
                                    parcelService.detailsMinZoom
                                        .toStringAsFixed(1) +
                                    'zoom_for_precincts_end'.tr,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(180),
                          fontSize: 11,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    Divider(color: Colors.white.withAlpha(25), height: 1),

                    _buildSectionLabel(
                      theme,
                      'land_use_layer'.tr,
                      icon: Icons.terrain_rounded,
                      trailing: canShowLandUseDetails
                          ? 'details'.tr
                          : canShowLandUseOverview
                              ? 'Districts'.tr
                              : 'zoom_in'.tr,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: landUseService.showLayer,
                      onChanged: landUseService.setShowLayer,
                      title: Text(
                        'show_land_use'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                    if (landUseService.showLayer) ...[
                      _buildCompactCheckbox(
                        theme: theme,
                        value: landUseService.showPowiaty,
                        onChanged: (value) {
                          landUseService.setShowPowiaty(value ?? false);
                        },
                        title: 'districts_label'.tr,
                      ),
                      _buildCompactCheckbox(
                        theme: theme,
                        value: landUseService.showUzytki,
                        onChanged: (value) {
                          landUseService.setShowUzytki(value ?? false);
                        },
                        title: 'land_use_label'.tr,
                      ),
                      _buildCompactCheckbox(
                        theme: theme,
                        value: landUseService.showKontury,
                        onChanged: (value) {
                          landUseService.setShowKontury(value ?? false);
                        },
                        title: 'contours'.tr,
                      ),
                      _buildCompactCheckbox(
                        theme: theme,
                        value: landUseService.showKlasouzytki,
                        onChanged: (value) {
                          landUseService.setShowKlasouzytki(value ?? false);
                        },
                        title: 'Klasoużytki',
                      ),
                      _buildZoomSettingRow(
                        theme: theme,
                        label: 'overview_from_zoom'.tr,
                        value: landUseService.overviewMinZoom,
                        min: 6.0,
                        max: landUseOverviewMax,
                        divisions: 24,
                        onChanged: landUseService.setOverviewMinZoom,
                      ),
                      _buildZoomSettingRow(
                        theme: theme,
                        label: 'details_from_zoom'.tr,
                        value: landUseService.detailsMinZoom,
                        min: landUseDetailsMin,
                        max: 20.0,
                        divisions: 27,
                        onChanged: landUseService.setDetailsMinZoom,
                      ),
                      _buildZoomSettingRow(
                        theme: theme,
                        label: 'opacity'.tr,
                        value: landUseService.opacity,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        onChanged: landUseService.setOpacity,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          canShowLandUseDetails
                              ? 'click_on_map_to_get_land_use_data'.tr
                              : canShowLandUseOverview
                                  ? 'districts_layer_visible_at_this_zoom'.tr
                                  : 'zoom_in_to_see_districts_and_land_use_details'
                                      .tr,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(180),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),
                    Divider(color: Colors.white.withAlpha(25), height: 1),

                    _buildSectionLabel(
                      theme,
                      'property_prices'.tr,
                      icon: Icons.attach_money_rounded,
                      trailing: canShowPriceDetails
                          ? 'transactions'.tr
                          : canShowPriceGrouping
                              ? 'grouping'.tr
                              : canShowPriceImplementations
                                  ? 'implementations'.tr
                                  : 'zoom_in'.tr,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: propertyPriceService.showLayer,
                      onChanged: propertyPriceService.setShowLayer,
                      title: Text(
                        'show_property_prices'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                    if (propertyPriceService.showLayer) ...[
                      _buildCompactCheckbox(
                        theme: theme,
                        value: propertyPriceService.showImplementations,
                        onChanged: (value) {
                          propertyPriceService
                              .setShowImplementations(value ?? false);
                        },
                        title: 'implementations_label'.tr,
                      ),
                      _buildCompactCheckbox(
                        theme: theme,
                        value: propertyPriceService.showGrouping,
                        onChanged: (value) {
                          propertyPriceService.setShowGrouping(value ?? false);
                        },
                        title: 'grouping_label'.tr,
                      ),
                      _buildCompactCheckbox(
                        theme: theme,
                        value: propertyPriceService.showTransactions,
                        onChanged: (value) {
                          propertyPriceService
                              .setShowTransactions(value ?? false);
                        },
                        title: 'transactions_label'.tr,
                      ),
                      _buildCompactCheckbox(
                        theme: theme,
                        value: propertyPriceService.showBasketTransactions,
                        onChanged: (value) {
                          propertyPriceService
                              .setShowBasketTransactions(value ?? false);
                        },
                        title: 'basket_transactions'.tr,
                      ),
                      _buildZoomSettingRow(
                        theme: theme,
                        label: 'implementations_from_zoom'.tr,
                        value: propertyPriceService.implementationsMinZoom,
                        min: 6.0,
                        max: priceImplMax,
                        divisions: 24,
                        onChanged:
                            propertyPriceService.setImplementationsMinZoom,
                      ),
                      _buildZoomSettingRow(
                        theme: theme,
                        label: 'grouping_from_zoom'.tr,
                        value: propertyPriceService.groupingMinZoom,
                        min: priceGroupingMin,
                        max: priceGroupingMax,
                        divisions: 24,
                        onChanged: propertyPriceService.setGroupingMinZoom,
                      ),
                      _buildZoomSettingRow(
                        theme: theme,
                        label: 'transactions_from_zoom'.tr,
                        value: propertyPriceService.detailsMinZoom,
                        min: priceDetailsMin,
                        max: 20.0,
                        divisions: 22,
                        onChanged: propertyPriceService.setDetailsMinZoom,
                      ),
                      _buildZoomSettingRow(
                        theme: theme,
                        label: 'opacity'.tr,
                        value: propertyPriceService.opacity,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        onChanged: propertyPriceService.setOpacity,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          canShowPriceDetails
                              ? 'click_on_map_to_get_transaction_data'.tr
                              : canShowPriceGrouping
                                  ? 'transaction_groups_visible_at_this_zoom'.tr
                                  : canShowPriceImplementations
                                      ? 'implementation_range_visible_at_this_zoom'
                                          .tr
                                      : 'zoom_in_to_see_implementations_grouping_and_transactions'
                                          .tr,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(180),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),
                    Divider(color: Colors.white.withAlpha(25), height: 1),

                    _buildSectionLabel(
                      theme,
                      'bdot10k'.tr,
                      icon: Icons.layers_rounded,
                      trailing: 'schema_plus_overlays'.tr,
                    ),
                    _buildZoomSettingRow(
                      theme: theme,
                      label: 'opacity'.tr,
                      value: bdotCategoriesService.opacity,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      onChanged: bdotCategoriesService.setOpacity,
                    ),
                    _buildZoomSettingRow(
                      theme: theme,
                      label: 'color_strength'.tr,
                      value: bdotCategoriesService.tintStrength,
                      min: 0.0,
                      max: 0.7,
                      divisions: 14,
                      onChanged: bdotCategoriesService.setTintStrength,
                    ),
                    _buildInfoNote(
                      theme: theme,
                      text: 'color_works_as_client_side_filter'.tr,
                    ),

                    if (BdotCategoryCatalog.overlayDefinitions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'active_wms_overlays'.tr,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(190),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...BdotCategoryCatalog.overlayDefinitions.map((def) {
                        final enabled =
                            bdotCategoriesService.isEnabled(def.category);
                        final minZoom =
                            bdotCategoriesService.minZoomOf(def.category);
                        final color =
                            bdotCategoriesService.colorOf(def.category);
                        final visibleNow = bdotCategoriesService.canShow(
                          def.category,
                          currentZoom,
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withAlpha(18),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SwitchListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                value: enabled,
                                onChanged: def.isRenderable
                                    ? (value) {
                                        bdotCategoriesService
                                            .setCategoryEnabled(
                                          def.category,
                                          value,
                                        );
                                      }
                                    : null,
                                title: Row(
                                  children: [
                                    Icon(def.icon, color: color, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${def.label} (${def.shortCode})',
                                        style:
                                            TextStyle(color: theme.textColor),
                                      ),
                                    ),
                                    Text(
                                      visibleNow
                                          ? 'zoom_ok'.tr
                                          : 'visible_from_zoom'.trParams({
                                              'zoom':
                                                  minZoom.toStringAsFixed(1),
                                            }),
                                      style: TextStyle(
                                        color:
                                            theme.textColor.withAlpha(160),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildZoomSettingRow(
                                theme: theme,
                                label: 'visible_from_zoom'.tr,
                                value: minZoom,
                                min: 6.0,
                                max: 20.0,
                                divisions: 28,
                                onChanged: (value) {
                                  bdotCategoriesService.setCategoryMinZoom(
                                    def.category,
                                    value,
                                  );
                                },
                              ),
                              _buildColorPaletteRow(
                                theme: theme,
                                selected: color,
                                onSelect: (newColor) {
                                  bdotCategoriesService.setCategoryColor(
                                    def.category,
                                    newColor,
                                  );
                                },
                                onReset: () {
                                  bdotCategoriesService.resetCategoryColor(
                                    def.category,
                                  );
                                },
                              ),
                              if (def.note != null &&
                                  def.note!.trim().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                _buildInfoNote(
                                  theme: theme,
                                  text: def.note!,
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'full_bdot10k_range'.tr,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(190),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...BdotCategoryCatalog.schemaDefinitions.map((def) {
                      final enabled =
                          bdotCategoriesService.isEnabled(def.category);
                      final minZoom =
                          bdotCategoriesService.minZoomOf(def.category);
                      final color =
                          bdotCategoriesService.colorOf(def.category);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withAlpha(14),
                          ),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: EdgeInsets.zero,
                            leading: Icon(
                              def.icon,
                              color: color,
                              size: 18,
                            ),
                            title: Text(
                              '${def.label} (${def.shortCode})',
                              style: TextStyle(
                                color: theme.textColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${def.classes.length} ${'classes_count'.tr}',
                                        style: TextStyle(
                                          color:
                                              theme.textColor.withAlpha(170),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    Switch(
                                      value: enabled,
                                      onChanged: def.isRenderable
                                          ? (value) {
                                              bdotCategoriesService
                                                  .setCategoryEnabled(
                                                def.category,
                                                value,
                                              );
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                                _buildZoomSettingRow(
                                  theme: theme,
                                  label: 'visible_from_zoom'.tr,
                                  value: minZoom,
                                  min: 6.0,
                                  max: 20.0,
                                  divisions: 28,
                                  onChanged: (value) {
                                    bdotCategoriesService.setCategoryMinZoom(
                                      def.category,
                                      value,
                                    );
                                  },
                                ),
                                _buildColorPaletteRow(
                                  theme: theme,
                                  selected: color,
                                  onSelect: (newColor) {
                                    bdotCategoriesService.setCategoryColor(
                                      def.category,
                                      newColor,
                                    );
                                  },
                                  onReset: () {
                                    bdotCategoriesService.resetCategoryColor(
                                      def.category,
                                    );
                                  },
                                ),
                                if (def.note != null &&
                                    def.note!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  _buildInfoNote(
                                    theme: theme,
                                    text: def.isRenderable
                                        ? 'category_has_real_wms'.tr
                                        : 'category_only_in_bdot10k_schema'.tr,
                                    color: def.isRenderable
                                        ? theme.textColor.withAlpha(170)
                                        : Colors.orangeAccent.withAlpha(220),
                                  ),
                                ],
                              ],
                            ),
                            children: [
                              const SizedBox(height: 6),
                              ...def.classes.map((clazz) {
                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(7),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white.withAlpha(10),
                                    ),
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${clazz.code}  ',
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                        TextSpan(
                                          text: clazz.label,
                                          style: TextStyle(
                                            color:
                                                theme.textColor.withAlpha(220),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 10),
                    Divider(color: Colors.white.withAlpha(25), height: 1),

                    _buildSectionLabel(
                      theme,
                      'mpzp'.tr,
                      icon: Icons.layers_outlined,
                      trailing:
                          canShowMpzp ? 'zoom_ok'.tr : 'visible_from_13'.tr,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: mpzpService.showLayer,
                      onChanged: mpzpService.setShowLayer,
                      title: Text(
                        'show_spatial_planning'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                    if (mpzpService.showLayer) ...[
                      _buildCompactCheckbox(
                        theme: theme,
                        value: mpzpService.showBoundaries,
                        onChanged: (value) {
                          mpzpService.setShowBoundaries(value ?? false);
                        },
                        title: 'plan_boundaries'.tr,
                      ),
                      _buildCompactCheckbox(
                        theme: theme,
                        value: mpzpService.showZones,
                        onChanged: (value) {
                          mpzpService.setShowZones(value ?? false);
                        },
                        title: 'plan_zones'.tr,
                      ),
                      _buildCompactCheckbox(
                        theme: theme,
                        value: mpzpService.showBuildingLines,
                        onChanged: (value) {
                          mpzpService.setShowBuildingLines(value ?? false);
                        },
                        title: 'building_lines'.tr,
                      ),
                      _buildZoomSettingRow(
                        theme: theme,
                        label: 'opacity'.tr,
                        value: mpzpService.opacity,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        onChanged: mpzpService.setOpacity,
                      ),
                    ],

                    const SizedBox(height: 10),
                    Divider(color: Colors.white.withAlpha(25), height: 1),

                    _buildSectionLabel(
                      theme,
                      'land_development_gesut'.tr,
                      icon: Icons.hub_outlined,
                      trailing:
                          canShowGesut ? 'zoom_ok'.tr : 'visible_from_17'.tr,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: gesutService.showLayer,
                      onChanged: gesutService.setShowLayer,
                      title: Text(
                        'show_land_development'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                    if (gesutService.showLayer) ...[
                      _buildCompactCheckbox(
                        theme: theme,
                        value: gesutService.showWater,
                        onChanged: (value) {
                          gesutService.setShowWater(value ?? false);
                        },
                        title: 'water_supply'.tr,
                      ),
                      _buildCompactCheckbox(
                        theme: theme,
                        value: gesutService.showSewer,
                        onChanged: (value) {
                          gesutService.setShowSewer(value ?? false);
                        },
                        title: 'sewerage'.tr,
                      ),
                      _buildCompactCheckbox(
                        theme: theme,
                        value: gesutService.showGas,
                        onChanged: (value) {
                          gesutService.setShowGas(value ?? false);
                        },
                        title: 'gas'.tr,
                      ),
                      _buildCompactCheckbox(
                        theme: theme,
                        value: gesutService.showPower,
                        onChanged: (value) {
                          gesutService.setShowPower(value ?? false);
                        },
                        title: 'electricity'.tr,
                      ),
                      _buildCompactCheckbox(
                        theme: theme,
                        value: gesutService.showTelecom,
                        onChanged: (value) {
                          gesutService.setShowTelecom(value ?? false);
                        },
                        title: 'telecommunications'.tr,
                      ),
                      _buildCompactCheckbox(
                        theme: theme,
                        value: gesutService.showHeat,
                        onChanged: (value) {
                          gesutService.setShowHeat(value ?? false);
                        },
                        title: 'heating'.tr,
                      ),
                      _buildCompactCheckbox(
                        theme: theme,
                        value: gesutService.showDevices,
                        onChanged: (value) {
                          gesutService.setShowDevices(value ?? false);
                        },
                        title: 'devices'.tr,
                      ),
                      _buildZoomSettingRow(
                        theme: theme,
                        label: 'opacity'.tr,
                        value: gesutService.opacity,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        onChanged: gesutService.setOpacity,
                      ),
                    ],

                    const SizedBox(height: 10),
                    Divider(color: Colors.white.withAlpha(25), height: 1),

                    _buildSectionLabel(
                      theme,
                      'fiber_coverage_siis'.tr,
                      icon: Icons.cable_outlined,
                      trailing: canShowFiber
                          ? 'zoom_ok'.tr
                          : '${'visible_from'.tr}${fiberService.minZoom.toStringAsFixed(1)}+',
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: fiberService.showLayer,
                      onChanged: fiberService.setShowLayer,
                      title: Text(
                        'show_fiber_coverage'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                    if (fiberService.showLayer) ...[
                      _buildCompactCheckbox(
                        theme: theme,
                        value: fiberService.showAddressPoints,
                        onChanged: (value) {
                          fiberService.setShowAddressPoints(value ?? false);
                        },
                        title: 'fiber_layer_address_points'.tr,
                      ),
                      _buildCompactCheckbox(
                        theme: theme,
                        value: fiberService.showBuildings,
                        onChanged: (value) {
                          fiberService.setShowBuildings(value ?? false);
                        },
                        title: 'fiber_layer_buildings'.tr,
                      ),
                      _buildCompactCheckbox(
                        theme: theme,
                        value: fiberService.showSimba2,
                        onChanged: (value) {
                          fiberService.setShowSimba2(value ?? false);
                        },
                        title: 'fiber_layer_simba2'.tr,
                      ),
                      _buildZoomSettingRow(
                        theme: theme,
                        label: 'opacity'.tr,
                        value: fiberService.opacity,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        onChanged: fiberService.setOpacity,
                      ),
                      _buildZoomSettingRow(
                        theme: theme,
                        label: 'visible_from_zoom'.tr,
                        value: fiberService.minZoom,
                        min: 6.0,
                        max: 16.0,
                        divisions: 20,
                        onChanged: fiberService.setMinZoom,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}