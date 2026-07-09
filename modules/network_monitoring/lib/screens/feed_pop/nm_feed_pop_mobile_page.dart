// ignore_for_file: use_build_context_synchronously

import 'dart:ui' as ui;
import 'package:get/get_utils/get_utils.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:network_monitoring/screens/feed_pop/providers/fav/provider.dart';
import 'package:network_monitoring/screens/feed_pop/widgets/detail_row_column.dart';
import 'package:network_monitoring/screens/feed_pop/widgets/nm_like_section_mobile.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/user/user/user_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/secure_storage.dart';
import 'package:core/shell/shared/appbar_mobile_back.dart';
import 'package:core/common/install_popup.dart';
import 'package:portal/screens/feed/components/map/map_ad.dart';
import 'package:intl/intl.dart';

class NMFeedPopMobilePage extends ConsumerStatefulWidget {
  final dynamic adFeedPop;
  final String tagFeedPop;

  const NMFeedPopMobilePage({
    super.key,
    required this.adFeedPop,
    required this.tagFeedPop,
  });

  @override
  NMFeedPopMobileState createState() => NMFeedPopMobileState();
}

class NMFeedPopMobileState extends ConsumerState<NMFeedPopMobilePage> {
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
        _isMapActivated =
            true; // Zmienia stan na aktywny, co pozwala na interakcje z mapą
      });
    }
  }

  @override
  void initState() {
    super.initState();
    mainImageUrl =
        widget.adFeedPop.images.isNotEmpty ? widget.adFeedPop.images[0] : '';
    _scrollController.addListener(_updateTopStatus);
  }

  Future<void> handleFavoriteAction(
    WidgetRef ref,
    int adId,
    BuildContext context,
  ) async {
    final isUserLoggedIn = ApiServices.isUserLoggedIn();
    if (isUserLoggedIn) {
      final isFav = await ref
          .read(nMFavAdsProvider.notifier)
          .isFavoriteNM(adId);
      if (isFav) {
        await ref.read(nMFavAdsProvider.notifier).removeFromFavoritesNM(adId,null,null);
        context.showSnackBar('fav_removed'.tr);
      } else {
        await ref.read(nMFavAdsProvider.notifier).addToFavoritesNM(adId, null, null);
        context.showSnackBar('fav_added'.tr);
      }
      // ignore: unused_result
      ref.refresh(nMFavAdsProvider);
    } else {
      context.showSnackBar(
        'login_required_favorites'.tr,
      );
    }
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
    final theme = ref.read(themeColorsProvider);


    NumberFormat customFormat = NumberFormat.decimalPattern('fr');

    double screenWidth = MediaQuery.of(context).size.width;
    double mainImageWidth = screenWidth * 0.97;
    double mainImageHeight = mainImageWidth * (650 / 1200);
    double pricePerSquareMeter =
        widget.adFeedPop.price / widget.adFeedPop.squareFootage;
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
    const double maxPhotoListSize = 120;
    const double minPhotoListSize = 75;
    // Obliczenie odpowiedniego rozmiaru czcionki
    double photoListSize =
        (screenWidth - minWidth) /
            (maxWidth - minWidth) *
            (maxPhotoListSize - minPhotoListSize) +
        minPhotoListSize;
    String formattedPrice = customFormat.format(widget.adFeedPop.price);

    return userAsyncValue.when(
      data: (user) {
        // String userId = user?.userId ?? '';
        return PopupListener(
          child: SafeArea(
            top: false,
            bottom: false,
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
                      if (_dragDistance >= _requiredDragDistance) {
                        ref
                            .read(navigationService)
                            .beamPop(
                              context,
                            ); // Zamknij stronę, jeśli próg został przekroczony
                        _dragDistance = 0.0; // Resetuj kumulowaną odległość
                      }
                    } else {
                      _dragDistance =
                          0.0; // Resetuj kumulowaną odległość, jeśli nie jesteśmy na szczycie
                    }
                    return true;
                  },
                  child: Stack(
                    children: [
                      // Ta część odpowiada za efekt rozmycia tła
                      BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        color: theme.adPopBackground.withAlpha((255 * 0.55).toInt()),
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
                          const AppBarMobileWithBack(),
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
                                      Hero(
                                        tag: widget.tagFeedPop,
                                        child: GestureDetector(
                                          onTap:
                                              () => ref
                                                  .read(navigationService)
                                                  .pushNamedScreen(
                                                    Routes.imageView,
                                                    data: {
                                                      'tag': widget.tagFeedPop,
                                                      'images':
                                                          widget
                                                              .adFeedPop
                                                              .images,
                                                      'initialPage': widget
                                                          .adFeedPop
                                                          .images
                                                          .indexOf(
                                                            mainImageUrl,
                                                          ),
                                                    },
                                                  ),
                                          child: Image.network(
                                            mainImageUrl,
                                            width: mainImageWidth,
                                            height: mainImageHeight,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      SizedBox(
                                        width:
                                            mainImageWidth, // Ograniczenie szerokości kontenera miniatur do szerokości głównego obrazu
                                        height:
                                            photoListSize, // Ustaw wysokość kontenera dla miniatur
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount:
                                              widget.adFeedPop.images.length,
                                          itemBuilder: (context, index) {
                                            String imageUrl =
                                                widget.adFeedPop.images[index];
                                            return GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  mainImageUrl =
                                                      imageUrl; // Aktualizacja głównego obrazu na kliknięty obraz
                                                });
                                              },
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  left:
                                                      index == 0
                                                          ? 0
                                                          : 7.5, // Nie dodawaj paddingu po lewej stronie pierwszego obrazu
                                                  right:
                                                      index ==
                                                              imageUrl.length -
                                                                  1
                                                          ? 0
                                                          : 7.5, // Nie dodawaj paddingu po prawej stronie ostatniego obrazu
                                                ),
                                                child: Image.network(
                                                  imageUrl,
                                                  width: photoListSize,
                                                  height: photoListSize,
                                                  fit: BoxFit.cover,
                                                ),
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
                                                      .copyWith(fontSize: 22, color: theme.textColor,),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  '${NumberFormat.decimalPattern().format(pricePerSquareMeter)} ${widget.adFeedPop.currency}/m²',
                                                  style: AppTextStyles.interRegular
                                                      .copyWith(fontSize: 14, color: theme.textColor,),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Material(
                                                color: Colors.transparent,
                                                child: Text(widget.adFeedPop.title,
                                                    style: AppTextStyles.interBold
                                                        .copyWith(fontSize: 18, color: theme.textColor,)),
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                  '${widget.adFeedPop.address.street}, ${widget.adFeedPop.address.city}, ${widget.adFeedPop.address.state}',
                                                  style: AppTextStyles.interRegular
                                                      .copyWith(fontSize: 14, color: theme.textColor,)),
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
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text("ad_details".tr,
                                                          style: AppTextStyles
                                                              .interBold
                                                              .copyWith(
                                                                  fontSize: 20, color: theme.textColor,)),
                                                      const SizedBox(height: 20),
                                                      Row(
                                                        children: [
                                                          Text('Floor area'.tr,
                                                              style: AppTextStyles
                                                                  .interRegular
                                                                  .copyWith(
                                                                      fontSize:
                                                                          14, color: theme.textColor,)),
                                                          const Spacer(),
                                                          Text(
                                                              '${widget.adFeedPop.squareFootage} m²',
                                                              style: AppTextStyles
                                                                  .interRegular
                                                                  .copyWith(
                                                                      fontSize:
                                                                          14, color: theme.textColor,)),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 5),
                                                      const Divider(),
                                                      const SizedBox(height: 5),
                                                      Row(
                                                        children: [
                                                          Text('bathroom_number'.tr,
                                                              style: AppTextStyles
                                                                  .interRegular
                                                                  .copyWith(
                                                                      fontSize:
                                                                          14, color: theme.textColor,)),
                                                          const Spacer(),
                                                          Text(
                                                              '${widget.adFeedPop.bathrooms}',
                                                              style: AppTextStyles
                                                                  .interRegular
                                                                  .copyWith(
                                                                      fontSize:
                                                                          14, color: theme.textColor,)),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 5),
                                                      const Divider(),
                                                      const SizedBox(height: 5),
                                                      Row(
                                                        children: [
                                                          Text('room_number'.tr,
                                                              style: AppTextStyles
                                                                  .interRegular
                                                                  .copyWith(
                                                                      fontSize:
                                                                          14, color: theme.textColor,)),
                                                          const Spacer(),
                                                          Text(
                                                              '${widget.adFeedPop.rooms}',
                                                              style: AppTextStyles
                                                                  .interRegular
                                                                  .copyWith(
                                                                      fontSize:
                                                                          14, color: theme.textColor,)),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 5),
                                                      const Divider(),
                                                      const SizedBox(height: 5),
                                                      Row(
                                                        children: [
                                                          Text('Floor'.tr,
                                                              style: AppTextStyles
                                                                  .interRegular
                                                                  .copyWith(
                                                                      fontSize:
                                                                          14, color: theme.textColor,)),
                                                          const Spacer(),
                                                          Text(
                                                              '${widget.adFeedPop.floor}/${widget.adFeedPop.totalFloors}',
                                                              style: AppTextStyles
                                                                  .interRegular
                                                                  .copyWith(
                                                                      fontSize:
                                                                          14, color: theme.textColor,)),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 5),
                                                      const Divider(),
                                                      const SizedBox(height: 5),
                                                      Row(
                                                        children: [
                                                          Text('ownership_form'.tr,
                                                              style: AppTextStyles
                                                                  .interRegular
                                                                  .copyWith(
                                                                      fontSize:
                                                                          14, color: theme.textColor,)),
                                                          const Spacer(),
                                                          Text(
                                                              widget.adFeedPop
                                                                  .marketType,
                                                              style: AppTextStyles
                                                                  .interRegular
                                                                  .copyWith(
                                                                      fontSize:
                                                                          14, color: theme.textColor,)),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 5),
                                                      const Divider(),
                                                      const SizedBox(height: 5),
                                                      Row(
                                                        children: [
                                                          Text('parking_space'.tr,
                                                              style: AppTextStyles
                                                                  .interRegular
                                                                  .copyWith(
                                                                      fontSize:
                                                                          14, color: theme.textColor,)),
                                                          const Spacer(),
                                                          // Text(widget.adFeedPop., style: AppTextStyles.interRegular.copyWith(fontSize: 14, color: theme.textColor,)),
                                                        ],
                                                      ),
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
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text("Opis".tr,
                                                          style: AppTextStyles
                                                              .interBold
                                                              .copyWith(
                                                                  fontSize: 20, color: theme.textColor,)),
                                                      const SizedBox(height: 10),
                                                      Text(
                                                          widget.adFeedPop
                                                              .description,
                                                          style: AppTextStyles
                                                              .interRegular
                                                              .copyWith(
                                                                  fontSize: 14, color: theme.textColor,)),
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
                                                              .address
                                                              .lat,
                                                      longitude:
                                                          widget
                                                              .adFeedPop
                                                              .address
                                                              .lon,
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
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text("addition_info".tr,
                                                          style: AppTextStyles
                                                              .interBold
                                                              .copyWith(
                                                                  fontSize: 20, color: theme.textColor,)),
                                                      const SizedBox(height: 20),
                                                      Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Expanded(
                                                            flex: 4,
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Text(
                                                                        'Floor area'.tr,
                                                                        style: AppTextStyles
                                                                            .interRegular
                                                                            .copyWith(
                                                                                fontSize:
                                                                                    14, color: theme.textColor,)),
                                                                    const Spacer(),
                                                                    Text(
                                                                        '${widget.adFeedPop.squareFootage} m²',
                                                                        style: AppTextStyles
                                                                            .interRegular
                                                                            .copyWith(
                                                                                fontSize:
                                                                                    14, color: theme.textColor,)),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height: 5),
                                                                const Divider(),
                                                                const SizedBox(
                                                                  height: 5,
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    Text(
                                                                        'bathroom_number'.tr,
                                                                        style: AppTextStyles
                                                                            .interRegular
                                                                            .copyWith(
                                                                                fontSize:
                                                                                    14, color: theme.textColor,)),
                                                                    const Spacer(),
                                                                    Text(
                                                                        '${widget.adFeedPop.bathrooms}',
                                                                        style: AppTextStyles
                                                                            .interRegular
                                                                            .copyWith(
                                                                                fontSize:
                                                                                    14, color: theme.textColor,)),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height: 5),
                                                                const Divider(),
                                                                const SizedBox(
                                                                  height: 5,
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    Text(
                                                                        'room_number'.tr,
                                                                        style: AppTextStyles
                                                                            .interRegular
                                                                            .copyWith(
                                                                                fontSize:
                                                                                    14, color: theme.textColor,)),
                                                                    const Spacer(),
                                                                    Text(
                                                                        '${widget.adFeedPop.rooms}',
                                                                        style: AppTextStyles
                                                                            .interRegular
                                                                            .copyWith(
                                                                                fontSize:
                                                                                    14, color: theme.textColor,)),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height: 5),
                                                                const Divider(),
                                                                const SizedBox(
                                                                  height: 5,
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    Text('Floor'.tr,
                                                                        style: AppTextStyles
                                                                            .interRegular
                                                                            .copyWith(
                                                                                fontSize:
                                                                                    14, color: theme.textColor,)),
                                                                    const Spacer(),
                                                                    Text(
                                                                        '${widget.adFeedPop.floor}/${widget.adFeedPop.totalFloors}',
                                                                        style: AppTextStyles
                                                                            .interRegular
                                                                            .copyWith(
                                                                                fontSize:
                                                                                    14, color: theme.textColor,)),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height: 5),
                                                                const Divider(),
                                                                const SizedBox(
                                                                  height: 5,
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    Text(
                                                                        'ownership_form'.tr,
                                                                        style: AppTextStyles
                                                                            .interRegular
                                                                            .copyWith(
                                                                                fontSize:
                                                                                    14, color: theme.textColor,)),
                                                                    const Spacer(),
                                                                    Text(
                                                                        widget
                                                                            .adFeedPop
                                                                            .marketType,
                                                                        style: AppTextStyles
                                                                            .interRegular
                                                                            .copyWith(
                                                                                fontSize:
                                                                                    14, color: theme.textColor,)),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height: 5),
                                                                const Divider(),
                                                                const SizedBox(
                                                                  height: 5,
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    Text(
                                                                        'parking_space'.tr,
                                                                        style: AppTextStyles
                                                                            .interRegular
                                                                            .copyWith(
                                                                                fontSize:
                                                                                    14, color: theme.textColor,)),
                                                                    const Spacer(),
                                                                    // Text(widget.adFeedPop., style: AppTextStyles.interRegular.copyWith(fontSize: 14, color: theme.textColor,)),
                                                                  ],
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
                                                            flex: 4,
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Text(
                                                                        'Floor area'.tr,
                                                                        style: AppTextStyles
                                                                            .interRegular
                                                                            .copyWith(
                                                                                fontSize:
                                                                                    14, color: theme.textColor,)),
                                                                    const Spacer(),
                                                                    Text(
                                                                        '${widget.adFeedPop.squareFootage} m²',
                                                                        style: AppTextStyles
                                                                            .interRegular
                                                                            .copyWith(
                                                                                fontSize:
                                                                                    14, color: theme.textColor,)),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height: 5),
                                                                const Divider(),
                                                                const SizedBox(
                                                                  height: 5,
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    Text(
                                                                        'bathroom_number'.tr,
                                                                        style: AppTextStyles
                                                                            .interRegular
                                                                            .copyWith(
                                                                                fontSize:
                                                                                    14, color: theme.textColor,)),
                                                                    const Spacer(),
                                                                    Text(
                                                                        '${widget.adFeedPop.bathrooms}',
                                                                        style: AppTextStyles
                                                                            .interRegular
                                                                            .copyWith(
                                                                                fontSize:
                                                                                    14, color: theme.textColor,)),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height: 5),
                                                                const Divider(),
                                                                const SizedBox(
                                                                  height: 5,
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    Text(
                                                                        'room_number'.tr,
                                                                        style: AppTextStyles
                                                                            .interRegular
                                                                            .copyWith(
                                                                                fontSize:
                                                                                    14, color: theme.textColor,)),
                                                                    const Spacer(),
                                                                    Text(
                                                                        '${widget.adFeedPop.rooms}',
                                                                        style: AppTextStyles
                                                                            .interRegular
                                                                            .copyWith(
                                                                                fontSize:
                                                                                    14, color: theme.textColor,)),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height: 5),
                                                                const Divider(),
                                                                const SizedBox(
                                                                  height: 5,
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    Text('Floor'.tr,
                                                                        style: AppTextStyles
                                                                            .interRegular
                                                                            .copyWith(
                                                                                fontSize:
                                                                                    14, color: theme.textColor,)),
                                                                    const Spacer(),
                                                                    Text(
                                                                        '${widget.adFeedPop.floor}/${widget.adFeedPop.totalFloors}',
                                                                        style: AppTextStyles
                                                                            .interRegular
                                                                            .copyWith(
                                                                                fontSize:
                                                                                    14, color: theme.textColor,)),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height: 5),
                                                                const Divider(),
                                                                const SizedBox(
                                                                  height: 5,
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    Text(
                                                                        'ownership_form'.tr,
                                                                        style: AppTextStyles
                                                                            .interRegular
                                                                            .copyWith(
                                                                                fontSize:
                                                                                    14, color: theme.textColor,)),
                                                                    const Spacer(),
                                                                    Text(
                                                                        widget
                                                                            .adFeedPop
                                                                            .marketType,
                                                                        style: AppTextStyles
                                                                            .interRegular
                                                                            .copyWith(
                                                                                fontSize:
                                                                                    14, color: theme.textColor,)),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                  height: 5,
                                                                ),
                                                                const Divider(
                                                                  color:
                                                                      AppColors
                                                                          .dark,
                                                                  thickness: 1,
                                                                ),
                                                                const SizedBox(
                                                                  height: 5,
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    Text(
                                                                        'parking_space'.tr,
                                                                        style: AppTextStyles
                                                                            .interRegular
                                                                            .copyWith(
                                                                                fontSize:
                                                                                    14, color: theme.textColor,)),
                                                                    const Spacer(),
                                                                    // Text(widget.adFeedPop., style: AppTextStyles.interRegular.copyWith(fontSize: 14, color: theme.textColor,)),
                                                                  ],
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
                                            PropertyDetailsColumn(
                                              adNetworkPop: widget.adFeedPop,
                                            ),
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
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          MobileLikeSectionFeedPopNM(
                            adFeedPop: widget.adFeedPop,
                            ref: ref,
                            context: context,
                          ),
                        ],
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
      error: (error, stack) => Text('Error: $error'.tr),
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
