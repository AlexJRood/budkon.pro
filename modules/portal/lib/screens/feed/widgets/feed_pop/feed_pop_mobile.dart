// ignore_for_file: use_build_context_synchronously

import 'dart:ui' as ui;
import 'package:get/get_utils/get_utils.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:portal/screens/feed/widgets/feed_pop/image_section.dart';
import 'package:core/platform/route_constant.dart';
import 'package:portal/global_widgets/like_section/like_section_mobile.dart';
import 'package:core/theme/design.dart';
import 'package:core/user/user/user_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/platform/secure_storage.dart';
import 'package:portal/global_widgets/card_seller/seller_card_mobile.dart';
import 'package:core/shell/shared/appbar_mobile_back.dart';
import 'package:core/common/install_popup.dart';
import 'package:portal/screens/feed/components/map/map_ad.dart';
import 'package:portal/screens/home_page/widgets/home_page/nearby_ads.dart';
import 'package:portal/screens/home_page/widgets/home_page/similar_ads.dart';
import 'package:intl/intl.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:portal/screens/feed/components/chat/send_portal_ad_message_overlay.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:portal/emma/anchors/anchors_portal.dart';
import 'package:portal/screens/feed/widgets/feed_pop/ai_field_badge.dart';
import 'package:core/platform/ad_type_utils.dart';
import 'package:core/platform/location_context.dart';
import 'package:portal/models/ad_list_view_model.dart';

class FeedPopMobile extends ConsumerStatefulWidget {
  final dynamic adFeedPop;
  final String tagFeedPop;
  final bool isChat;

  const FeedPopMobile({
    super.key,
    required this.adFeedPop,
    required this.tagFeedPop,
    this.isChat = false,
  });

  @override
  _FeedPopMobileState createState() => _FeedPopMobileState();
}

class _FeedPopMobileState extends ConsumerState<FeedPopMobile> {
  final ScrollController _scrollController = ScrollController();
  bool _atTop = true; // Flaga wskazująca, czy jesteśmy na szczycie
  double _dragDistance = 0.0; // Kumulowana odległość przeciągnięcia
  final double _requiredDragDistance = 100.0;
  late String mainImageUrl;
  final SecureStorage secureStorage = SecureStorage();

  bool _isMapActivated = false; // Stan aktywacji mapy

  void _activateMap() {
    if (!_isMapActivated) {
      setState(() {
        _isMapActivated = true;
      });
    }
  }

  bool _isAiField(String fieldName) {
    final fields = widget.adFeedPop.emmaExtractedFields;
    if (fields == null) return false;
    return (fields as List).contains(fieldName);
  }

  Widget _adDetailRow(String label, String value, String fieldName, Color textColor) {
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: AppTextStyles.interRegular.copyWith(fontSize: 14, color: textColor)),
            const Spacer(),
            Text(value, style: AppTextStyles.interRegular.copyWith(fontSize: 14, color: textColor)),
            if (_isAiField(fieldName)) ...[
              const SizedBox(width: 6),
              const AiFieldBadge(),
            ],
          ],
        ),
        const SizedBox(height: 5),
        Divider(color: textColor, thickness: 1),
        const SizedBox(height: 5),
      ],
    );
  }

  List<String> _trueAmenities(String estateType) => [
    if (AdTypeUtils.showResidentialAmenities(estateType)) ...[
      if (widget.adFeedPop.balcony) 'additional_info_balcony'.tr,
      if (widget.adFeedPop.terrace) 'additional_info_terrace'.tr,
      if (widget.adFeedPop.garden) 'additional_info_garden'.tr,
      if (widget.adFeedPop.sauna) 'additional_info_sauna'.tr,
      if (widget.adFeedPop.jacuzzi) 'additional_info_jacuzzi'.tr,
      if (widget.adFeedPop.basement) 'additional_info_basement'.tr,
    ],
    if (AdTypeUtils.showElevator(estateType) && widget.adFeedPop.elevator) 'additional_info_elevator'.tr,
    if (AdTypeUtils.showAirConditioning(estateType) && widget.adFeedPop.airConditioning) 'additional_info_air_conditioning'.tr,
    if (AdTypeUtils.showGarage(estateType) && widget.adFeedPop.garage) 'additional_info_garage'.tr,
    if (AdTypeUtils.showParking(estateType) && widget.adFeedPop.parkingSpace) 'additional_info_parking_space'.tr,
  ];

  Widget _amenityChip(String label, Color textColor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      border: Border.all(color: textColor.withAlpha(80)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_outline, size: 14, color: Colors.greenAccent.shade400),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.interRegular.copyWith(fontSize: 13, color: textColor)),
      ],
    ),
  );

  static const _nearbyMeta = <String, (String, IconData)>{
    'schools':        ('poi_schools',        Icons.school),
    'bus_stops':      ('poi_bus_stops',      Icons.directions_bus),
    'tram_stops':     ('poi_tram_stops',     Icons.tram),
    'train_stations': ('poi_train_stations', Icons.train),
    'metro':          ('poi_metro',          Icons.subway),
    'health':         ('poi_health',         Icons.local_hospital),
    'supermarkets':   ('poi_supermarkets',   Icons.shopping_basket),
    'parks':          ('poi_parks',          Icons.park),
    'restaurants':    ('poi_restaurants',    Icons.restaurant),
  };

  static const _attractionMeta = <String, (String, IconData)>{
    'theme_parks':    ('attr_theme_parks',   Icons.roller_skating),
    'zoos':           ('attr_zoos',          Icons.pets),
    'race_tracks':    ('attr_race_tracks',   Icons.speed),
    'ski_resorts':    ('attr_ski_resorts',   Icons.downhill_skiing),
    'water_parks':    ('attr_water_parks',   Icons.pool),
    'national_parks': ('attr_national_parks',Icons.forest),
    'stadiums':       ('attr_stadiums',      Icons.sports_soccer),
  };

  Widget _sectionHeader(String label, Color textColor) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 10),
    child: Text(label, style: AppTextStyles.interBold.copyWith(fontSize: 16, color: textColor)),
  );

  Widget _distanceBadge(String text, Color textColor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: textColor.withAlpha(18),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(text, style: AppTextStyles.interRegular.copyWith(fontSize: 10, color: textColor.withAlpha(180))),
  );

  Widget _locationRow({
    required IconData icon,
    required String label,
    required String value,
    required String badge,
    required Color textColor,
    Color? iconColor,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(icon, size: 15, color: iconColor ?? textColor.withAlpha(160)),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.interMedium.copyWith(fontSize: 12, color: textColor)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value,
                style: AppTextStyles.interRegular.copyWith(fontSize: 11, color: textColor.withAlpha(160)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _distanceBadge(badge, textColor),
          ],
        ),
      );

  Widget _locationContextSection(LocationContext ctx, Color textColor) {
    final sections = <Widget>[];

    // ── W pobliżu ──
    final nearbyRows = <Widget>[];
    for (final entry in _nearbyMeta.entries) {
      final items = ctx.nearby[entry.key] ?? [];
      if (items.isEmpty) continue;
      final first = items.first;
      nearbyRows.add(_locationRow(
        icon: entry.value.$2,
        label: entry.value.$1.tr,
        value: first.name,
        badge: '${first.distanceM} m',
        textColor: textColor,
      ));
    }
    if (nearbyRows.isNotEmpty) {
      sections.add(_sectionHeader('location_nearby'.tr, textColor));
      sections.addAll(nearbyRows);
    }

    // ── Lotniska ──
    if (ctx.airports.isNotEmpty) {
      sections.add(_sectionHeader('location_airports'.tr, textColor));
      for (final a in ctx.airports.take(3)) {
        sections.add(_locationRow(
          icon: Icons.flight,
          label: a.iata,
          value: a.name,
          badge: '${a.distanceKm} km',
          textColor: textColor,
        ));
      }
    }

    // ── Duże miasta ──
    if (ctx.majorCities.isNotEmpty) {
      sections.add(_sectionHeader('location_major_cities'.tr, textColor));
      for (final c in ctx.majorCities) {
        final driveStr = c.driveMinutes != null ? _formatMinutes(c.driveMinutes!.toInt()) : null;
        final transitStr = c.transitMinutesEst != null ? _formatMinutes(c.transitMinutesEst!) : null;
        sections.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              const Icon(Icons.location_city, size: 15),
              const SizedBox(width: 8),
              Text(c.name, style: AppTextStyles.interMedium.copyWith(fontSize: 12, color: textColor)),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _distanceBadge('${c.distanceKm} km', textColor),
                    if (driveStr != null) ...[
                      const SizedBox(width: 4),
                      _distanceBadge('🚗 $driveStr', textColor),
                    ],
                    if (transitStr != null) ...[
                      const SizedBox(width: 4),
                      _distanceBadge('🚆 $transitStr', textColor),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ));
      }
    }

    // ── Przyroda ──
    final nature = ctx.nature;
    if (nature != null && nature.hasAnyData) {
      sections.add(_sectionHeader('location_nature'.tr, textColor));
      if (nature.seaKm != null) {
        sections.add(_locationRow(
          icon: Icons.waves,
          label: 'location_sea'.tr,
          value: '',
          badge: '${nature.seaKm} km',
          textColor: textColor,
          iconColor: Colors.blueAccent.shade100,
        ));
      }
      if (nature.nearestLake != null) {
        final lake = nature.nearestLake!;
        sections.add(_locationRow(
          icon: Icons.water,
          label: 'location_lake'.tr,
          value: lake.name,
          badge: '${lake.distanceKm} km',
          textColor: textColor,
          iconColor: Colors.cyan.shade300,
        ));
      }
      if (nature.nearestMountain != null) {
        final m = nature.nearestMountain!;
        sections.add(_locationRow(
          icon: Icons.landscape,
          label: 'location_mountains'.tr,
          value: m.name,
          badge: '${m.distanceKm} km',
          textColor: textColor,
          iconColor: Colors.brown.shade300,
        ));
      }
    }

    // ── Atrakcje ──
    final hasAttractions = ctx.attractions.values.any((l) => l.isNotEmpty);
    if (hasAttractions) {
      sections.add(_sectionHeader('location_attractions'.tr, textColor));
      for (final entry in _attractionMeta.entries) {
        final items = ctx.attractions[entry.key] ?? [];
        if (items.isEmpty) continue;
        final first = items.first;
        sections.add(_locationRow(
          icon: entry.value.$2,
          label: entry.value.$1.tr,
          value: first.name,
          badge: '${first.distanceKm} km',
          textColor: textColor,
        ));
      }
    }

    // ── Internet ──
    if (ctx.broadband != null) {
      final bb = ctx.broadband!;
      sections.add(_sectionHeader('location_broadband'.tr, textColor));
      final fiberColor = bb.hasFiber == true
          ? Colors.greenAccent.shade400
          : bb.hasFiber == false
              ? Colors.orangeAccent
              : textColor.withAlpha(120);
      final fiberLabel = bb.hasFiber == true
          ? 'location_fiber_yes'.tr
          : bb.hasFiber == false
              ? 'location_fiber_no'.tr
              : 'location_fiber_unknown'.tr;
      sections.add(_locationRow(
        icon: Icons.wifi,
        label: fiberLabel,
        value: bb.operatorsCount != null ? '${'location_operators'.tr}: ${bb.operatorsCount}' : '',
        badge: bb.hasCoverage == true ? 'location_covered'.tr : 'location_not_covered'.tr,
        textColor: textColor,
        iconColor: fiberColor,
      ));
    }

    if (sections.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  @override
  void initState() {
    super.initState();
    mainImageUrl =
        widget.adFeedPop.images.isNotEmpty ? widget.adFeedPop.images[0] : '';
    _scrollController.addListener(_updateTopStatus);
  }

  void _updateTopStatus() {
    final atTop =
        _scrollController.position.pixels <=
        _scrollController.position.minScrollExtent;
    if (_atTop != atTop) {
      setState(() {
        _atTop = atTop;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(userProvider);
    bool hasPopped = false; // Flaga kontrolująca pojedyncze wywołanie beamPop

    NumberFormat customFormat = NumberFormat.decimalPattern('fr');

    double screenWidth = MediaQuery.of(context).size.width;
    double mainImageWidth = screenWidth * 0.97;
    double mainImageHeight = mainImageWidth * (650 / 1200);
    double pricePerSquareMeter = widget.adFeedPop.squareFootage > 0
        ? widget.adFeedPop.price / widget.adFeedPop.squareFootage
        : 0.0;
    // Ustawienie maksymalnej i minimalnej szerokości ekranu
    const double maxWidth = 1920;
    const double minWidth = 480;
    // Ustawienie maksymalnego i minimalnego rozmiaru czcionki
    const double maxLogoSize = 30;
    const double minLogoSize = 16;
    // Obliczenie odpowiedniego rozmiaru czcionki
    double logoSize =
        (screenWidth - minWidth) /
            (maxWidth - minWidth) *
            (maxLogoSize - minLogoSize) +
        minLogoSize;
    // Ograniczenie rozmiaru czcionki do zdefiniowanych minimum i maksimum
    logoSize = logoSize.clamp(minLogoSize, maxLogoSize);

    String formattedPrice = customFormat.format(widget.adFeedPop.price);

    final theme = ref.watch(themeColorsProvider);
    final estateType = (widget.adFeedPop.estateType ?? '').toString();
    final amenityChips = _trueAmenities(estateType);

    return EmmaUiAnchorTarget(
      anchorKey: PortalEmmaAnchors.adDetailMobileRoot.anchorKey,

      spec: PortalEmmaAnchors.adDetailMobileRoot,
      runtimeMode: PortalEmmaAnchors.adDetailMobileRoot.runtimeMode,
      tapMode: PortalEmmaAnchors.adDetailMobileRoot.tapMode,
      child: userAsyncValue.when(
      data: (user) {
        // String userId = user?.userId ?? '';
        return PieCanvas(
          theme: const PieTheme(
            rightClickShowsMenu: true,
            leftClickShowsMenu: false,
            buttonTheme: PieButtonTheme(
              backgroundColor: AppColors.buttonGradient1,
              iconColor: Colors.white,
            ),
            buttonThemeHovered: PieButtonTheme(
              backgroundColor: Color.fromARGB(96, 58, 58, 58),
              iconColor: Colors.white,
            ),
          ),
          child: PopupListener(
            child: NotificationListener<OverscrollIndicatorNotification>(
              onNotification: (notification) {
                if (notification.leading) {
                  notification.disallowIndicator();
                }
                return true;
              },
              child: NotificationListener<OverscrollNotification>(
                onNotification: (OverscrollNotification notification) {
                  if (_atTop && notification.overscroll < 0) {
                    _dragDistance -= notification.overscroll;
                    if (_dragDistance >= _requiredDragDistance && !hasPopped) {
                      hasPopped =
                          true; // Ustawiamy flagę, żeby zapobiec ponownemu wywołaniu
                      ref.read(navigationService).beamPop();
                    }
                  } else {
                    _dragDistance =
                        0.0; // Resetujemy kumulowaną odległość, jeśli nie jesteśmy na szczycie
                  }
                  return true;
                },
                child: Stack(
                  children: [
                    // Ta część odpowiada za efekt rozmycia tła
                    BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Container(
                        color: theme.adPopBackground.withAlpha(
                          (255 * 0.85).toInt(),
                        ),
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    // Obsługa dotknięcia w dowolnym miejscu aby zamknąć modal
                    GestureDetector(
                      onTap: () => ref.read(navigationService).beamPop(),
                    ),

                    // Zawartość modalu
                    Column(
                      children: [
                         AppBarMobileWithBack(isChat: widget.isChat,),
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 5.0,
                                right: 5,
                              ),
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                physics: const ClampingScrollPhysics(),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 15),
                                    // zamiast poprzedniego Hero + CachedNetworkImage + ListView miniaturek:
                                    ImageSectionMobile(
                                      images: widget.adFeedPop.images,
                                      heroTag: widget.tagFeedPop,
                                      mainWidth: mainImageWidth,
                                      mainHeight: mainImageHeight,
                                    ),

                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: mainImageWidth,
                                      child: Column(
                                        children: [
                                          // Cena, cena za m²
                                          Row(
                                            children: [
                                              Text(
                                                '$formattedPrice ${widget.adFeedPop.currency}',
                                                style: AppTextStyles.interBold
                                                    .copyWith(
                                                      fontSize: 22,
                                                      color: theme.textColor,
                                                    ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                '${NumberFormat.decimalPattern().format(pricePerSquareMeter)} ${widget.adFeedPop.currency}/m²',
                                                style: AppTextStyles
                                                    .interRegular
                                                    .copyWith(
                                                      fontSize: 14,
                                                      color: theme.textColor,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Material(
                                              color: Colors.transparent,
                                              child: Text(
                                                widget.adFeedPop.title,
                                                style: AppTextStyles.interBold
                                                    .copyWith(
                                                      fontSize: 18,
                                                      color: theme.textColor,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              '${widget.adFeedPop.street}, ${widget.adFeedPop.city}, ${widget.adFeedPop.state}',
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                          ),
                                          // Opis, szczegóły
                                          const SizedBox(height: 50),

                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "ad_details"
                                                          .tr,
                                                      style: AppTextStyles
                                                          .interBold
                                                          .copyWith(
                                                            fontSize: 20,
                                                            color:
                                                                theme.textColor,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 20),
                                                    _adDetailRow('Floor area'.tr, '${widget.adFeedPop.squareFootage} m²', 'square_footage', theme.textColor),
                                                    if (AdTypeUtils.showRoomsAndBathrooms(estateType)) ...[
                                                      _adDetailRow('Batroom number'.tr, '${widget.adFeedPop.bathrooms}', 'bathrooms', theme.textColor),
                                                      _adDetailRow('Room number'.tr, '${widget.adFeedPop.rooms}', 'rooms', theme.textColor),
                                                    ],
                                                    if (AdTypeUtils.showFloor(estateType) && widget.adFeedPop.totalFloors > 0)
                                                      _adDetailRow('Floor'.tr, '${widget.adFeedPop.floor}/${widget.adFeedPop.totalFloors}', 'floor', theme.textColor),
                                                    if (widget.adFeedPop.marketType.isNotEmpty)
                                                      _adDetailRow('market_type'.tr, AdTypeUtils.marketTypeKey(widget.adFeedPop.marketType).tr, 'market_type', theme.textColor),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 50),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Opis".tr,
                                                      style: AppTextStyles
                                                          .interBold
                                                          .copyWith(
                                                            fontSize: 20,
                                                            color:
                                                                theme.textColor,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      widget
                                                          .adFeedPop
                                                          .description,
                                                      style: AppTextStyles
                                                          .interRegular
                                                          .copyWith(
                                                            fontSize: 14,
                                                            color:
                                                                theme.textColor,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),

                                          //Mapa
                                          const SizedBox(height: 50),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  height: 400,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(20.0), // Zaokrąglone rogi
                                                    // Dodaj inne dekoracje, jak tło, jeśli potrzebujesz
                                                  ),
                                                  child: MapAd(
                                                    latitude:
                                                        widget
                                                            .adFeedPop
                                                            .latitude,
                                                    longitude:
                                                        widget
                                                            .adFeedPop
                                                            .longitude,
                                                    onMapActivated: () {
                                                      if (!_isMapActivated) {
                                                        _activateMap();
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 50),

                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "addition_info"
                                                          .tr,
                                                      style: AppTextStyles
                                                          .interBold
                                                          .copyWith(
                                                            fontSize: 20,
                                                            color:
                                                                theme.textColor,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 20),
                                                    Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Expanded(
                                                          flex: 4,
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              if (widget.adFeedPop.lotSize > 0)
                                                                _adDetailRow('lot_size_label'.tr, '${widget.adFeedPop.lotSize} m²', 'lot_size', theme.textColor),
                                                              if (widget.adFeedPop.heatingType != null && widget.adFeedPop.heatingType.isNotEmpty)
                                                                _adDetailRow('heating_type'.tr, AdTypeUtils.heatingTypeKey(widget.adFeedPop.heatingType!).tr, 'heating_type', theme.textColor),
                                                              if (widget.adFeedPop.buildingMaterial != null && widget.adFeedPop.buildingMaterial.isNotEmpty)
                                                                _adDetailRow('filter_label_building_material'.tr, AdTypeUtils.buildingMaterialKey(widget.adFeedPop.buildingMaterial!).tr, 'building_material', theme.textColor),
                                                              if (widget.adFeedPop.buildYear != null && widget.adFeedPop.buildYear > 0)
                                                                _adDetailRow('Build Year'.tr, '${widget.adFeedPop.buildYear}', 'build_year', theme.textColor),
                                                              if (widget.adFeedPop.propertyForm.isNotEmpty)
                                                                _adDetailRow('Property form'.tr, '${widget.adFeedPop.propertyForm}'.tr, 'property_form', theme.textColor),
                                                              if (widget.adFeedPop.offerType.isNotEmpty)
                                                                _adDetailRow('offer_type'.tr, AdTypeUtils.offerTypeKey(widget.adFeedPop.offerType).tr, 'offer_type', theme.textColor),
                                                            ],
                                                          ),
                                                        ),

                                                        const Expanded(
                                                          flex: 1,
                                                          child: SizedBox(),
                                                        ),

                                                        if (amenityChips.isNotEmpty)
                                                        Expanded(
                                                          flex: 4,
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text('Additional Features'.tr, style: AppTextStyles.interBold.copyWith(fontSize: 16, color: theme.textColor)),
                                                              const SizedBox(height: 10),
                                                              Wrap(
                                                                spacing: 6,
                                                                runSpacing: 6,
                                                                children: amenityChips.map((l) => _amenityChip(l, theme.textColor)).toList(),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 25),
                                          const Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(child: SizedBox()),
                                              // Opis
                                            ],
                                          ),
                                          const SizedBox(height: 75),
                                          SellerCardMobile(
                                            sellerId: widget.adFeedPop.sellerId,
                                            onTap: () {
                                              showPortalAdMessageOverlay(
                                                context: context,
                                                ref: ref,
                                                ad: widget.adFeedPop,
                                              );
                                            },
                                          ),

                                          const SizedBox(height: 75),
                                        ],
                                      ),
                                    ),
                                    if (widget.adFeedPop is AdsListViewModel &&
                                        (widget.adFeedPop as AdsListViewModel).locationContext != null &&
                                        (widget.adFeedPop as AdsListViewModel).locationContext!.hasAnyData) ...[
                                      const SizedBox(height: 20),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: _locationContextSection((widget.adFeedPop as AdsListViewModel).locationContext!, theme.textColor),
                                      ),
                                    ],
                                    SimilarAds(
                                      offerid: widget.adFeedPop.id.toString(),
                                    ),
                                    const SizedBox(height: 50),
                                    if (widget.adFeedPop.latitude != 0 ||
                                        widget.adFeedPop.longitude != 0) ...[
                                      NearbyAds(
                                        offerId: widget.adFeedPop.id.toString(),
                                      ),
                                      const SizedBox(height: 50),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        MobileLikeSectionFeedPop(adFeedPop: widget.adFeedPop),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('${'Error'.tr}: $error'.tr),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateTopStatus);
    _scrollController.dispose();
    super.dispose();
  }
}

extension ContextExtension on BuildContext {
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).removeCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
