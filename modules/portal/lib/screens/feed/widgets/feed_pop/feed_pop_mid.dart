// ignore_for_file: use_build_context_synchronously

import 'dart:ui' as ui;

import 'package:core/shell/pop_manager/pop_page_manager.dart';
import 'package:core/common/chrome/back_button.dart';
import 'package:core/common/chrome/logo_hously.dart';
import 'package:core/shell/keyboard_shortcuts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat/new_chat/provider/chat_room_provider.dart';
import 'package:chat/pages/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:portal/global_widgets/card_seller/seller_card.dart';
import 'package:portal/global_widgets/full_screen_image.dart';
import 'package:portal/like_section_mid.dart';
import 'package:portal/screens/feed/components/map/map_ad.dart';
import 'package:portal/screens/feed/provider/feed_pop/fav_provider.dart';
import 'package:portal/screens/home_page/widgets/home_page/nearby_ads.dart';
import 'package:portal/screens/home_page/widgets/home_page/similar_ads.dart';
import 'package:reports/reports/report_pdf_page/widgets/ad_report_dialog.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/secure_storage.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/user/user/user_provider.dart';
import 'package:portal/screens/feed/components/chat/send_portal_ad_message_overlay.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:portal/emma/anchors/anchors_portal.dart';
import 'package:portal/screens/feed/widgets/feed_pop/ai_field_badge.dart';
import 'package:core/platform/ad_type_utils.dart';
import 'package:core/platform/location_context.dart';
import 'package:portal/models/ad_list_view_model.dart';

class FeedPopMid extends ConsumerStatefulWidget {
  final dynamic adFeedPop;
  final String tagFeedPop;
  final bool isChat;

  const FeedPopMid({
    super.key,
    required this.adFeedPop,
    required this.tagFeedPop,
    this.isChat = false
  });

  @override
  FeedPopMidState createState() => FeedPopMidState();
}

class FeedPopMidState extends ConsumerState<FeedPopMid> with AutomaticKeepAliveClientMixin{
  late int _currentImageIndex;
  final SecureStorage secureStorage = SecureStorage();

  bool _isMapActivated = false;
  final ScrollController _scrollController = ScrollController();
  bool _atTop = true;
  double _dragDistance = 0.0;
  final double _requiredDragDistance = 100.0;
  late FocusNode _focusNode;

  List<dynamic> get _images => widget.adFeedPop.images as List<dynamic>;
  String get mainImageUrl =>
      _images.isNotEmpty ? _images[_currentImageIndex].toString() : '';

  void _goToImage(int index) {
    if (_images.isEmpty) return;
    setState(() => _currentImageIndex = index.clamp(0, _images.length - 1));
  }
  // final _chatPageState = const ChatPc().createState();

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

  Widget _adDetailRow(
    String label,
    String value,
    String fieldName,
    Color textColor,
  ) {
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
    'theme_parks':    ('attr_theme_parks',    Icons.roller_skating),
    'zoos':           ('attr_zoos',           Icons.pets),
    'race_tracks':    ('attr_race_tracks',    Icons.speed),
    'ski_resorts':    ('attr_ski_resorts',    Icons.downhill_skiing),
    'water_parks':    ('attr_water_parks',    Icons.pool),
    'national_parks': ('attr_national_parks', Icons.forest),
    'stadiums':       ('attr_stadiums',       Icons.sports_soccer),
  };

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  Widget _distanceBadge(String text, Color textColor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: textColor.withAlpha(20), borderRadius: BorderRadius.circular(10)),
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
            Icon(icon, size: 16, color: iconColor ?? textColor.withAlpha(160)),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.interMedium.copyWith(fontSize: 12, color: textColor)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(value, style: AppTextStyles.interRegular.copyWith(fontSize: 12, color: textColor.withAlpha(160)), overflow: TextOverflow.ellipsis),
            ),
            _distanceBadge(badge, textColor),
          ],
        ),
      );

  Widget _sectionHeader(String label, Color textColor) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Text(label, style: AppTextStyles.interBold.copyWith(fontSize: 18, color: textColor)),
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
        icon: entry.value.$2, label: entry.value.$1.tr,
        value: first.name, badge: '${first.distanceM} m', textColor: textColor,
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
        sections.add(_locationRow(icon: Icons.flight, label: a.iata, value: a.name, badge: '${a.distanceKm} km', textColor: textColor));
      }
    }

    // ── Duże miasta ──
    if (ctx.majorCities.isNotEmpty) {
      sections.add(_sectionHeader('location_major_cities'.tr, textColor));
      for (final c in ctx.majorCities) {
        sections.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              const Icon(Icons.location_city, size: 16),
              const SizedBox(width: 8),
              Text(c.name, style: AppTextStyles.interMedium.copyWith(fontSize: 12, color: textColor)),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _distanceBadge('${c.distanceKm} km', textColor),
                    if (c.driveMinutes != null) ...[const SizedBox(width: 4), _distanceBadge('🚗 ${_formatMinutes(c.driveMinutes!.toInt())}', textColor)],
                    if (c.transitMinutesEst != null) ...[const SizedBox(width: 4), _distanceBadge('🚆 ${_formatMinutes(c.transitMinutesEst!)}', textColor)],
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
      if (nature.seaKm != null)
        sections.add(_locationRow(icon: Icons.waves, label: 'location_sea'.tr, value: '', badge: '${nature.seaKm} km', textColor: textColor, iconColor: Colors.blueAccent.shade100));
      if (nature.nearestLake != null)
        sections.add(_locationRow(icon: Icons.water, label: 'location_lake'.tr, value: nature.nearestLake!.name, badge: '${nature.nearestLake!.distanceKm} km', textColor: textColor, iconColor: Colors.cyan.shade300));
      if (nature.nearestMountain != null)
        sections.add(_locationRow(icon: Icons.landscape, label: 'location_mountains'.tr, value: nature.nearestMountain!.name, badge: '${nature.nearestMountain!.distanceKm} km', textColor: textColor, iconColor: Colors.brown.shade300));
    }

    // ── Atrakcje ──
    if (ctx.attractions.values.any((l) => l.isNotEmpty)) {
      sections.add(_sectionHeader('location_attractions'.tr, textColor));
      for (final entry in _attractionMeta.entries) {
        final items = ctx.attractions[entry.key] ?? [];
        if (items.isEmpty) continue;
        final first = items.first;
        sections.add(_locationRow(icon: entry.value.$2, label: entry.value.$1.tr, value: first.name, badge: '${first.distanceKm} km', textColor: textColor));
      }
    }

    // ── Internet ──
    if (ctx.broadband != null) {
      final bb = ctx.broadband!;
      final fiberColor = bb.hasFiber == true ? Colors.greenAccent.shade400 : bb.hasFiber == false ? Colors.orangeAccent : textColor.withAlpha(120);
      final fiberLabel = bb.hasFiber == true ? 'location_fiber_yes'.tr : bb.hasFiber == false ? 'location_fiber_no'.tr : 'location_fiber_unknown'.tr;
      sections.add(_sectionHeader('location_broadband'.tr, textColor));
      sections.add(_locationRow(
        icon: Icons.wifi, label: fiberLabel,
        value: bb.operatorsCount != null ? '${'location_operators'.tr}: ${bb.operatorsCount}' : '',
        badge: bb.hasCoverage == true ? 'location_covered'.tr : 'location_not_covered'.tr,
        textColor: textColor, iconColor: fiberColor,
      ));
    }

    if (sections.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: sections);
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
    _currentImageIndex = 0;
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

  Future<void> handleFavoriteAction(
    WidgetRef ref,
    int adId,
    BuildContext context,
  ) async {
    final isUserLoggedIn = ApiServices.isUserLoggedIn();
    if (isUserLoggedIn) {
      final isFav = await ref.read(favAdsProvider.notifier).isFavorite(adId);
      if (isFav) {
        await ref.read(favAdsProvider.notifier).removeFromFavorites(adId);
        context.showSnackBar('fav_removed'.tr);
      } else {
        await ref.read(favAdsProvider.notifier).addToFavorites(adId);
        context.showSnackBar('fav_added'.tr);
      }
      // ignore: unused_result
      ref.refresh(favAdsProvider);
    } else {
      context.showSnackBar(
        'login_required_favorites'.tr,
      );
    }
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
    final userAsyncValue = ref.watch(userProvider);
    // final lastPage = ref.read(navigationHistoryProvider.notifier).lastPage;
    bool _hasPopped = false; // Flaga kontrolująca pojedyncze wywołanie beamPop

    NumberFormat customFormat = NumberFormat.decimalPattern('fr');
    ScrollController _scrollController = ScrollController();
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double mainImageWidth = screenWidth * 0.75;
    double mainImageHeight = mainImageWidth * (650 / 1200);
    double pricePerSquareMeter = widget.adFeedPop.squareFootage > 0 ? widget.adFeedPop.price / widget.adFeedPop.squareFootage : 0.0;
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
      anchorKey: PortalEmmaAnchors.adDetailMidRoot.anchorKey,

      spec: PortalEmmaAnchors.adDetailMidRoot,
      runtimeMode: PortalEmmaAnchors.adDetailMidRoot.runtimeMode,
      tapMode: PortalEmmaAnchors.adDetailMidRoot.tapMode,
      child: userAsyncValue.when(
      data: (user) {
        // String userId = user?.userId ?? '';
        return Focus(
          focusNode: _focusNode,
          onKeyEvent: (FocusNode node, KeyEvent event) {
            if (event.logicalKey == ref.read(popKeyProvider) &&
                event is KeyDownEvent) {
              if (Navigator.canPop(context)) {
                ref.read(navigationService).beamPop();
              }
              return KeyEventResult.handled;
            }
            if (event is KeyDownEvent || event is KeyRepeatEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                _goToImage(_currentImageIndex - 1);
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                _goToImage(_currentImageIndex + 1);
                return KeyEventResult.handled;
              }
              if (_scrollController.hasClients) {
                final offset = _scrollController.offset;
                final max = _scrollController.position.maxScrollExtent;
                final viewport = _scrollController.position.viewportDimension;
                if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  _scrollController.animateTo(
                    (offset - 200).clamp(0.0, max),
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                  );
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  _scrollController.animateTo(
                    (offset + 200).clamp(0.0, max),
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                  );
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
                  _scrollController.animateTo(
                    (offset - viewport * 0.85).clamp(0.0, max),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
                  _scrollController.animateTo(
                    (offset + viewport * 0.85).clamp(0.0, max),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                  return KeyEventResult.handled;
                }
              }
            }
            return KeyEventResult.ignored;
          },
          child: PieCanvas(
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
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: NotificationListener<OverscrollIndicatorNotification>(
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
                      if (_dragDistance >= _requiredDragDistance &&
                          !_hasPopped) {
                        _hasPopped =
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
                        filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          color: theme.adPopBackground.withAlpha(140),
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      // Obsługa dotknięcia w dowolnym miejscu aby zamknąć modal
                      GestureDetector(
                        onTap: () {
                          if (widget.isChat) {
                            Navigator.of(context).pop();
                          } else {
                            ref.read(navigationService).beamPop();
                          }
                        },
                      ),

                      Positioned(
                        top: 10,
                        left: 10,
                        child: SizedBox(
                          width: 250,
                          height: screenHeight - 60,
                          child: Stack(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [BackButtonHously(isChat: widget.isChat), const Spacer()],
                              ),
                            ],
                          ),
                        ),
                      ),


                      // Zawartość modalu
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 25.0,
                            right: 200,
                          ),
                          child: GestureDetector(
                            onVerticalDragUpdate: (details) {
                              // Check if the user is at the top of the scrollable content
                              if (_scrollController.offset == 0 &&
                                  details.primaryDelta! > 0 &&
                                  !_hasPopped) {
                                _hasPopped =
                                    true; // Ustawiamy flagę, żeby zapobiec ponownemu wywołaniu
                                ref.read(navigationService).beamPop();
                              } else {
                                _scrollController.jumpTo(
                                  _scrollController.offset -
                                      details.primaryDelta!,
                                );
                              }
                            },
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 75),
                                  SizedBox(
                                    width: mainImageWidth,
                                    height: mainImageHeight,
                                    child: Stack(
                                      children: [
                                        Hero(
                                          tag: widget.tagFeedPop,
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                PageRouteBuilder(
                                                  opaque: false,
                                                  pageBuilder: (_, animation, __) =>
                                                      FadeTransition(
                                                        opacity: animation,
                                                        child: FullScreenImageView(
                                                          tag: widget.tagFeedPop,
                                                          images: widget.adFeedPop.images,
                                                          initialPage: _currentImageIndex,
                                                        ),
                                                      ),
                                                ),
                                              );
                                            },
                                            child: CachedNetworkImage(
                                              imageUrl: mainImageUrl,
                                              width: mainImageWidth,
                                              height: mainImageHeight,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  ShimmerPlaceholder(
                                                    width: mainImageWidth,
                                                    height: mainImageHeight,
                                                  ),
                                              errorWidget: (context, url, error) => Stack(
                                                children: [
                                                  ShimmerPlaceholder(
                                                    width: mainImageWidth,
                                                    height: mainImageHeight,
                                                  ),
                                                  Center(
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: Text(
                                                        'no image found'.tr,
                                                        style: TextStyle(color: AppColors.redBeige),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (_images.length > 1) ...[
                                          Positioned(
                                            left: 8,
                                            top: 0,
                                            bottom: 0,
                                            child: Center(
                                              child: _PhotoNavButton(
                                                icon: Icons.chevron_left_rounded,
                                                enabled: _currentImageIndex > 0,
                                                onTap: () => _goToImage(_currentImageIndex - 1),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            right: 8,
                                            top: 0,
                                            bottom: 0,
                                            child: Center(
                                              child: _PhotoNavButton(
                                                icon: Icons.chevron_right_rounded,
                                                enabled: _currentImageIndex < _images.length - 1,
                                                onTap: () => _goToImage(_currentImageIndex + 1),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: mainImageWidth,
                                    height: 120,
                                    // Ensure the height is sufficient for both ListView scenarios
                                    child:
                                        widget.adFeedPop.images.isNotEmpty
                                            ? ListView.builder(
                                          addAutomaticKeepAlives: false,
                                          cacheExtent: 300.0,
                                              scrollDirection: Axis.horizontal,
                                              itemCount:
                                                  widget
                                                      .adFeedPop
                                                      .images
                                                      .length,
                                              itemBuilder: (context, index) {
                                                final imageUrl = _images[index].toString();
                                                final isActive = index == _currentImageIndex;
                                                return GestureDetector(
                                                  onTap: () => _goToImage(index),
                                                  child: Padding(
                                                    padding: EdgeInsets.only(
                                                      left: index == 0 ? 0 : 10.0,
                                                      right: index == _images.length - 1 ? 0 : 10.0,
                                                    ),
                                                    child: AnimatedContainer(
                                                      duration: const Duration(milliseconds: 150),
                                                      decoration: BoxDecoration(
                                                        border: isActive
                                                            ? Border.all(color: Colors.greenAccent, width: 2)
                                                            : null,
                                                        boxShadow: isActive
                                                            ? [BoxShadow(color: Colors.greenAccent.withAlpha(80), blurRadius: 8)]
                                                            : null,
                                                      ),
                                                      child: CachedNetworkImage(
                                                        imageUrl: imageUrl,
                                                        width: 120,
                                                        height: 120,
                                                        fit: BoxFit.cover,
                                                        placeholder: (context, url) =>
                                                            const ShimmerPlaceholder(width: 120, height: 120),
                                                        errorWidget: (context, url, error) => const Stack(
                                                          children: [
                                                            ShimmerPlaceholder(width: 120, height: 120),
                                                            Center(
                                                              child: Material(
                                                                color: Colors.transparent,
                                                                child: Icon(Icons.error),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                            : ListView.builder(
                                          addAutomaticKeepAlives: false,
                                          cacheExtent: 300.0,
                                              scrollDirection: Axis.horizontal,
                                              itemCount:
                                                  10, // Show 10 placeholder items
                                              itemBuilder: (context, index) {
                                                return Padding(
                                                  padding: EdgeInsets.only(
                                                    left: index == 0 ? 0 : 10.0,
                                                    // No padding for the first item
                                                    right:
                                                        index == 9
                                                            ? 0
                                                            : 10.0, // No padding for the last item
                                                  ),
                                                  child: const Stack(
                                                    children: [
                                                      ShimmerPlaceholder(
                                                        width: 120,
                                                        height: 120,
                                                      ),
                                                      Padding(
                                                        padding: EdgeInsets.all(50),
                                                        child: Icon(
                                                          Icons.error,
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
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
                                                    fontSize: 26,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${NumberFormat.decimalPattern().format(pricePerSquareMeter)} ${widget.adFeedPop.currency}/m²',
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 16,
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
                                                    fontSize: 22,
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
                                                  fontSize: 16,
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
                                            // Opis
                                            Expanded(
                                              flex: 6,
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
                                            const Expanded(
                                              flex: 1,
                                              child: SizedBox(),
                                            ),
                                            // Szczegóły
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text("ad_details".tr, style: AppTextStyles.interBold.copyWith(fontSize: 20, color: theme.textColor)),
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

                                        //Mapa
                                        const SizedBox(height: 70),
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
                                                      widget.adFeedPop.latitude,
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
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              flex: 4,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text("addition_info".tr, style: AppTextStyles.interBold.copyWith(fontSize: 20, color: theme.textColor)),
                                                  const SizedBox(height: 20),
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
                                            const Expanded(flex: 1, child: SizedBox()),
                                            if (amenityChips.isNotEmpty)
                                            Expanded(
                                              flex: 4,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Additional Features'.tr, style: AppTextStyles.interBold.copyWith(fontSize: 20, color: theme.textColor)),
                                                  const SizedBox(height: 16),
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children: amenityChips.map((l) => _amenityChip(l, theme.textColor)).toList(),
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
                                      ],
                                    ),
                                  ),
                                  if (widget.adFeedPop is AdsListViewModel &&
                                      (widget.adFeedPop as AdsListViewModel).locationContext != null &&
                                      (widget.adFeedPop as AdsListViewModel).locationContext!.hasAnyData) ...[
                                    const SizedBox(height: 30),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: _locationContextSection((widget.adFeedPop as AdsListViewModel).locationContext!, theme.textColor),
                                    ),
                                  ],
                                  const SizedBox(height: 100),
                                  SimilarAds(
                                    offerid: widget.adFeedPop.id.toString(),
                                  ),
                                  const SizedBox(height: 100),
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
                      Positioned(
                        top: 20,
                        right: 20,
                        child: SizedBox(
                          width: widget.isChat ? 220 : 300,
                          height: screenHeight - 40,
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  // SizedBox(
                                  //     height:40,
                                  //     width: 180,
                                  //     child: LogoHouslyWidget()),
                                  const SizedBox(height: 20),
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: SellerCard(
                                      sellerId: widget.adFeedPop.sellerId,
                                      onTap: () {
                                        // Navigacja do strony użytkownika
                                        // Navigator.push(
                                        //   context,
                                        //   MaterialPageRoute(builder: (context) => UserProfilePage()),
                                        // );
                                      },
                                    ),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                              Column(
                                children: [
                                  const Spacer(),
                                  Row(
                                    children: [
                                      const Spacer(),
                                      IntrinsicWidth(
                                        child: MidLikeSectionFeedPop(
                                          adFeedPop: widget.adFeedPop.id,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                ],
                              ),
                              const Column(
                                children: [Spacer(), SizedBox(height: 20)],
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: IntrinsicWidth(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Spacer(),
                                      ElevatedButton(
                                        style: elevatedButtonStyleRounded10,
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text(
                                                  'Phone Number'.tr,
                                                  style: TextStyle(
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).iconTheme.color,
                                                  ),
                                                ),
                                                content: Text(
                                                  '${widget.adFeedPop.phoneNumber}',
                                                  style: TextStyle(
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).iconTheme.color,
                                                  ),
                                                ), // Wyświetlanie numeru telefonu
                                                actions: <Widget>[
                                                  TextButton(
                                                    style: ButtonStyle(
                                                      backgroundColor:
                                                          WidgetStatePropertyAll(
                                                            theme
                                                                .textFieldColor,
                                                          ),
                                                    ),
                                                    onPressed: () {
                                                      ref
                                                          .read(
                                                            navigationService,
                                                          )
                                                          .beamPop();
                                                    },
                                                    child: Text(
                                                      'close'.tr,
                                                      style: TextStyle(
                                                        color:
                                                            Theme.of(
                                                              context,
                                                            ).iconTheme.color,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        child: Text(
                                          'Call'.tr,
                                          style: TextStyle(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).iconTheme.color,
                                          ),
                                        ), // Może wymagać zmiany na bardziej odpowiedni tekst
                                      ),
                                      const SizedBox(height: 15),
                                      ElevatedButton(
                                        style: elevatedButtonStyleRounded10,
                                        onPressed: () {
                                          showPortalAdMessageOverlay(
                                            context: context,
                                            ref: ref,
                                            ad: widget.adFeedPop,
                                          );
                                        },
                                        child: Text(
                                          'Send a message'.tr,
                                          style: TextStyle(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).iconTheme.color,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 10),

                                      ElevatedButton(
                                        style:
                                            buttonStyleRounded10ThemeRedWithPadding15,
                                        onPressed: () {
                                          showAdReportDialog(
                                            context,
                                            widget.adFeedPop.id,
                                          );
                                        },
                                        child: Text(
                                          'Create Report'.tr,
                                          style: TextStyle(
                                            color: theme.themeTextColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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
}

Future<void> showAdReportDialog(BuildContext context, int advertisementId) {
  return PopPageManager.show(
    context,
    child: AdReportDialog(advertisementId: advertisementId),
    tag: 'ad_report_dialog_$advertisementId',
    isBig: true,
    autoHeight: false,
    hasBackButton: true,
  );
}


extension ContextExtension on BuildContext {
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).removeCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}

class _PhotoNavButton extends StatelessWidget {
  const _PhotoNavButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.3,
      duration: const Duration(milliseconds: 150),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(140),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
