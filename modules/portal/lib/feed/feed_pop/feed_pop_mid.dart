// ignore_for_file: use_build_context_synchronously

import 'dart:ui' as ui;

import 'package:core/common/chrome/logo_hously.dart';
import 'package:core/shell/keyboard_shortcuts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat/new_chat/provider/chat_room_provider.dart';
import 'package:chat/pages/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/get_utils.dart';
// import 'package:portal/screens/chat/chat_pc.dart';

import 'package:intl/intl.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:portal/global_widgets/card_seller/seller_card.dart';
import 'package:portal/global_widgets/full_screen_image.dart';
import 'package:portal/like_section_mid.dart';
import 'package:portal/screens/feed/components/map/map_ad.dart';
import 'package:portal/screens/feed/provider/feed_pop/fav_provider.dart';
import 'package:portal/screens/home_page/widgets/home_page/nearby_ads.dart';
import 'package:portal/screens/home_page/widgets/home_page/similar_ads.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/secure_storage.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/user/user/user_provider.dart';

class FeedPopMid extends ConsumerStatefulWidget {
  final dynamic adFeedPop;
  final String tagFeedPop;

  const FeedPopMid({
    super.key,
    required this.adFeedPop,
    required this.tagFeedPop,
  });

  @override
  _FeedPopMidState createState() => _FeedPopMidState();
}

class _FeedPopMidState extends ConsumerState<FeedPopMid> with AutomaticKeepAliveClientMixin{
  late String mainImageUrl;
  final SecureStorage secureStorage = SecureStorage();
  // final _chatPageState = const ChatPc().createState();

  bool _isMapActivated = false; // Stan aktywacji mapy
  final ScrollController _scrollController = ScrollController();
  bool _atTop = true; // Flaga wskazująca, czy jesteśmy na szczycie
  double _dragDistance = 0.0; // Kumulowana odległość przeciągnięcia
  final double _requiredDragDistance = 100.0;
  late FocusNode _focusNode;

  // final _chatPageState = const ChatPc().createState();

  void _activateMap() {
    if (!_isMapActivated) {
      setState(() {
        _isMapActivated = true;
      });
    }
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
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

   @override
  bool get wantKeepAlive => true;

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
  Widget build(BuildContext context) {
     super.build(context);
    final userAsyncValue = ref.watch(userProvider);
    // final lastPage = ref.read(navigationHistoryProvider.notifier).lastPage;
    bool hasPopped = false; // Flaga kontrolująca pojedyncze wywołanie beamPop

    NumberFormat customFormat = NumberFormat.decimalPattern('fr');
    ScrollController scrollController = ScrollController();
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double mainImageWidth = screenWidth * 0.75;
    double mainImageHeight = mainImageWidth * (650 / 1200);
    double pricePerSquareMeter = 1200;
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

    return userAsyncValue.when(
      data: (user) {
        // String userId = user?.userId ?? '';
        return KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: (KeyEvent event) {
            // Check if the pressed key matches the stored pop key
            if (event.logicalKey == ref.read(popKeyProvider) &&
                event is KeyDownEvent) {
              if (Navigator.canPop(context)) {
                ref.read(navigationService).beamPop();
              }
            }
            KeyBoardShortcuts().handleKeyEvent(
              event,
              scrollController,
              200,
              50,
            );
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
                          !hasPopped) {
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
                        filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          color: theme.adPopBackground.withAlpha(
                            (255 * 0.55).toInt(),
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
                              if (scrollController.offset == 0 &&
                                  details.primaryDelta! > 0 &&
                                  !hasPopped) {
                                hasPopped =
                                    true; // Ustawiamy flagę, żeby zapobiec ponownemu wywołaniu
                                ref.read(navigationService).beamPop();
                              } else {
                                scrollController.jumpTo(
                                  scrollController.offset -
                                      details.primaryDelta!,
                                );
                              }
                            },
                            child: SingleChildScrollView(
                              controller: scrollController,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 75),
                                  Hero(
                                    tag: widget.tagFeedPop,
                                    child: GestureDetector(
                                      onTap: () {
                                        // Dodanie nawigacji do pełnoekranowego widoku zdjęcia
                                        Navigator.of(context).push(
                                          PageRouteBuilder(
                                            opaque: false,
                                            pageBuilder:
                                                (
                                                  _,
                                                  animation,
                                                  __,
                                                ) => FadeTransition(
                                                  opacity: animation,
                                                  child: FullScreenImageView(
                                                    tag: widget.tagFeedPop,
                                                    images:
                                                        widget.adFeedPop.images,
                                                    initialPage: widget
                                                        .adFeedPop
                                                        .images
                                                        .indexOf(mainImageUrl),
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
                                        placeholder:
                                            (context, url) =>
                                                ShimmerPlaceholder(
                                                  width: mainImageWidth,
                                                  height: mainImageHeight,
                                                ),
                                        errorWidget:
                                            (context, url, error) => Stack(
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
                                                      style: TextStyle(
                                                        color:
                                                            AppColors.redBeige,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                      ),
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
                                                String imageUrl =
                                                    widget
                                                        .adFeedPop
                                                        .images[index];
                                                return GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      mainImageUrl =
                                                          imageUrl; // Update the main image on click
                                                    });
                                                  },
                                                  child: Padding(
                                                    padding: EdgeInsets.only(
                                                      left:
                                                          index == 0 ? 0 : 10.0,
                                                      // No padding for the first image
                                                      right:
                                                          index ==
                                                                  widget
                                                                          .adFeedPop
                                                                          .images
                                                                          .length -
                                                                      1
                                                              ? 0
                                                              : 10.0, // No padding for the last image
                                                    ),
                                                    child: CachedNetworkImage(
                                                      imageUrl: imageUrl,
                                                      width: 120,
                                                      height: 120,
                                                      fit: BoxFit.cover,
                                                      placeholder:
                                                          (context, url) =>
                                                              const ShimmerPlaceholder(
                                                                width: 120,
                                                                height: 120,
                                                              ),
                                                      errorWidget:
                                                          (
                                                            context,
                                                            url,
                                                            error,
                                                          ) => const Stack(
                                                            children: [
                                                              ShimmerPlaceholder(
                                                                width: 120,
                                                                height: 120,
                                                              ),
                                                              Center(
                                                                child: Material(
                                                                  color:
                                                                      Colors
                                                                          .transparent,
                                                                  child: Icon(
                                                                    Icons.error,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
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
                                                    'description'.tr,
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
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'ad_details'.tr,
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
                                                    children: [
                                                      Text(
                                                        'Floor area'.tr,
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        '${widget.adFeedPop.squareFootage} m²',
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Divider(
                                                    color: theme.textColor,
                                                    thickness: 1,
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'bathroom_number'.tr,
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        '${widget.adFeedPop.bathrooms}',
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Divider(
                                                    color: theme.textColor,
                                                    thickness: 1,
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'room_number'.tr,
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        '${widget.adFeedPop.rooms}',
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Divider(
                                                    color: theme.textColor,
                                                    thickness: 1,
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'Floor'.tr,
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        '${widget.adFeedPop.floor}/${widget.adFeedPop.totalFloors}',
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Divider(
                                                    color: theme.textColor,
                                                    thickness: 1,
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'ownership_form'.tr,
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        widget
                                                            .adFeedPop
                                                            .marketType,
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Divider(
                                                    color: theme.textColor,
                                                    thickness: 1,
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'parking_space'.tr,
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                      const Spacer(),
                                                      // Text(widget.adFeedPop., style: AppTextStyles.interRegular.copyWith(fontSize: 14)),
                                                    ],
                                                  ),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              flex: 4,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "addition_info".tr,
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
                                                    children: [
                                                      Text(
                                                        'Floor area'.tr,
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        '${widget.adFeedPop.squareFootage} m²',
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Divider(
                                                    color: theme.textColor,
                                                    thickness: 1,
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'bathroom_number'.tr,
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        '${widget.adFeedPop.bathrooms}',
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Divider(
                                                    color: theme.textColor,
                                                    thickness: 1,
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'room_number'.tr,
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        '${widget.adFeedPop.rooms}',
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Divider(
                                                    color: theme.textColor,
                                                    thickness: 1,
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'Floor'.tr,
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        '${widget.adFeedPop.floor}/${widget.adFeedPop.totalFloors}',
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Divider(
                                                    color: theme.textColor,
                                                    thickness: 1,
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'ownership_form'.tr,
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        widget
                                                            .adFeedPop
                                                            .marketType,
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Divider(
                                                    color: theme.textColor,
                                                    thickness: 1,
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'parking_space'.tr,
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                      const Spacer(),
                                                      // Text(widget.adFeedPop., style: AppTextStyles.interRegular.copyWith(fontSize: 14)),
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
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "",
                                                    style: AppTextStyles
                                                        .interBold
                                                        .copyWith(
                                                          fontSize: 24,
                                                          color:
                                                              theme.textColor,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 20),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'Floor area'.tr,
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        '${widget.adFeedPop.squareFootage} m²',
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Divider(
                                                    color: theme.textColor,
                                                    thickness: 1,
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'bathroom_number'.tr,
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        '${widget.adFeedPop.bathrooms}',
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Divider(
                                                    color: theme.textColor,
                                                    thickness: 1,
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'room_number'.tr,
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        '${widget.adFeedPop.rooms}',
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Divider(
                                                    color: theme.textColor,
                                                    thickness: 1,
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'Floor'.tr,
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        '${widget.adFeedPop.floor}/${widget.adFeedPop.totalFloors}',
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Divider(
                                                    color: theme.textColor,
                                                    thickness: 1,
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'ownership_form'.tr,
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        widget
                                                            .adFeedPop
                                                            .marketType,
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Divider(
                                                    color: theme.textColor,
                                                    thickness: 1,
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'parking_space'.tr,
                                                        style: AppTextStyles
                                                            .interRegular
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  theme
                                                                      .textColor,
                                                            ),
                                                      ),
                                                      const Spacer(),
                                                      // Text(widget.adFeedPop., style: AppTextStyles.interRegular.copyWith(fontSize: 14)),
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
                                      ],
                                    ),
                                  ),
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
                          width: 300,
                          height: screenHeight - 40,
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  LogoHouslyWidget(),
                                  const SizedBox(height: 20),
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: SellerCard(
                                      sellerId: widget.adFeedPop.sellerId,
                                      onTap: () {
                                        ref
                                            .read(navigationService)
                                            .pushNamedScreen(Routes.settings);
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
                                                backgroundColor: theme.dashboardContainer,
                                                title: Text(
                                                  'Phone Number'.tr,
                                                  style: TextStyle(
                                                    color:theme.textColor,
                                                  ),
                                                ),
                                                content: Text(
                                                  '${widget.adFeedPop.phoneNumber}',
                                                  style: TextStyle(
                                                    color:
                                                        theme.textColor,
                                                  ),
                                                ), // Wyświetlanie numeru telefonu
                                                actions: <Widget>[
                                                  TextButton(
                                                    style: ButtonStyle(
                                                      backgroundColor:
                                                          WidgetStatePropertyAll(
                                                            theme
                                                                .textColor,
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
                                                      'Close'.tr,
                                                      style: TextStyle(
                                                        color: theme.themeColor,
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
                                          final userId =
                                              ref
                                                  .read(userStateProvider)
                                                  ?.userId;
                                          if (userId != null) {
                                            final currentContext = context;

                                            ref
                                                .read(
                                                  fetchRoomsProvider.notifier,
                                                )
                                                .createRoom(widget.adFeedPop.id)
                                                .whenComplete(() {
                                                  if (currentContext.mounted) {
                                                    Navigator.of(
                                                      currentContext,
                                                    ).push(
                                                      PageRouteBuilder(
                                                        opaque: false,
                                                        pageBuilder:
                                                            (_, __, ___) =>
                                                                const ChatPage(),
                                                        transitionsBuilder: (
                                                          _,
                                                          anim,
                                                          __,
                                                          child,
                                                        ) {
                                                          return FadeTransition(
                                                            opacity: anim,
                                                            child: child,
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  }
                                                });
                                          }
                                        },
                                        child: Text(
                                          'Send message'.tr,
                                          style: TextStyle(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).iconTheme.color,
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
    );
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
