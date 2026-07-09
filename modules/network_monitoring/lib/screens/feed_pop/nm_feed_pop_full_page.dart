import 'dart:ui' as ui;
import 'package:get/get_utils/get_utils.dart';
import 'package:core/common/chrome/logo_hously.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';

import 'package:network_monitoring/screens/feed_pop/widgets/detail_row_column.dart';
import 'package:network_monitoring/screens/feed_pop/widgets/nm_like_section_full.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:core/shell/keyboard_shortcuts.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/design.dart';
import 'package:core/user/user/user_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/secure_storage.dart';
import 'package:portal/screens/feed/components/map/map_ad.dart';
import 'package:intl/intl.dart';

void copyToClipboard(BuildContext context, String listingUrl) {
  Clipboard.setData(ClipboardData(text: listingUrl)).then((_) {
    final snackBar = Customsnackbar().showSnackBar(
      "Success".tr,
      "link_copied_to_clipboard".tr,
      "success",
      () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  });
}

class NMFeedPopFullPage extends ConsumerStatefulWidget {
  final dynamic adNetworkPop;
  final String tagNetworkPop;

  const NMFeedPopFullPage({
    super.key,
    required this.adNetworkPop,
    required this.tagNetworkPop,
  });

  @override
  NMFeedPopFullState createState() => NMFeedPopFullState();
}

class NMFeedPopFullState extends ConsumerState<NMFeedPopFullPage>
    with AutomaticKeepAliveClientMixin {
  late String mainImageUrl;
  final SecureStorage secureStorage = SecureStorage();

  bool _isMapActivated = false; // Stan aktywacji mapy
  late FocusNode _focusNode;
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
        widget.adNetworkPop.images.isNotEmpty
            ? widget.adNetworkPop.images[0]
            : '';
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
    final theme = ref.read(themeColorsProvider);

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double mainImageWidth = screenWidth * 0.625;
    double mainImageHeight = mainImageWidth * (650 / 1200);

    // Safe math (avoid null & division by zero)
    final double price =
        (widget.adNetworkPop.price is num)
            ? (widget.adNetworkPop.price as num).toDouble()
            : 0.0;
    final double sqft =
        (widget.adNetworkPop.squareFootage is num)
            ? (widget.adNetworkPop.squareFootage as num).toDouble()
            : 0.0;
    final double pricePerSquareMeter = sqft == 0 ? 0 : (price / sqft);

    // Ustawienie maksymalnej i minimalnej szerokości ekranu
    const double maxWidth = 1920;
    const double minWidth = 480;
    const double maxLogoSize = 30;
    const double minLogoSize = 16;
    double logoSize =
        (screenWidth - minWidth) /
            (maxWidth - minWidth) *
            (maxLogoSize - minLogoSize) +
        minLogoSize;
    logoSize = logoSize.clamp(minLogoSize, maxLogoSize);

    NumberFormat customFormat = NumberFormat.decimalPattern('fr');
    String formattedPrice = customFormat.format(price);

    // ---------- FIX: address & coordinates can come in different shapes ----------
    String composeAddressDisplay(dynamic address) {
      if (address == null) return '';
      // Sometimes it's already a single string.
      if (address is String) return address;
      // Sometimes a Map.
      if (address is Map) {
        final s = (address['street'] ?? '').toString();
        final c = (address['city'] ?? '').toString();
        final st = (address['state'] ?? '').toString();
        return [s, c, st].where((e) => e.trim().isNotEmpty).join(', ');
      }
      // Try object-like access, but guard with try/catch to avoid NoSuchMethodError.
      try {
        final s = (address.street ?? '').toString();
        final c = (address.city ?? '').toString();
        final st = (address.state ?? '').toString();
        return [s, c, st].where((e) => e.trim().isNotEmpty).join(', ');
      } catch (_) {
        return '';
      }
    }

    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    final dynamic rawAddress = widget.adNetworkPop.address;
    final String addressDisplay = composeAddressDisplay(rawAddress);

    // Prefer root lat/lon if available; otherwise try map fields.
    final double? lat =
        toDouble(widget.adNetworkPop.lat) ??
        (rawAddress is Map ? toDouble(rawAddress['lat']) : null);
    final double? lon =
        toDouble(widget.adNetworkPop.lon) ??
        (rawAddress is Map ? toDouble(rawAddress['lon']) : null);
    // ---------------------------------------------------------------------------

    return userAsyncValue.when(
      data: (user) {
        return KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: (KeyEvent event) {
            if (event.logicalKey == ref.read(popKeyProvider) &&
                event is KeyDownEvent) {
              ref.read(navigationService).pushNamedScreen(Routes.filters);
            }
          },
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
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
                GestureDetector(
                  onTap: () => ref.read(navigationService).beamPop(),
                ),
                Positioned(
                  top: 20,
                  left: 20,
                  child: SizedBox(
                    width: 300,
                    height: screenHeight - 40,
                    child: Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: IconButton(
                                style: elevatedButtonStyleRounded10,
                                icon: AppIcons.iosArrowLeft(
                                  color: theme.textColor,
                                ),
                                onPressed:
                                    () => ref.read(navigationService).beamPop(),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 75),
                        Hero(
                          tag: widget.tagNetworkPop,
                          child: GestureDetector(
                            onTap:
                                () => ref
                                    .read(navigationService)
                                    .pushNamedScreen(
                                      Routes.imageView,
                                      data: {
                                        'tag': widget.tagNetworkPop,
                                        'images': widget.adNetworkPop.images,
                                        'initialPage': widget
                                            .adNetworkPop
                                            .images
                                            .indexOf(mainImageUrl),
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
                        const SizedBox(height: 20),
                        SizedBox(
                          width: mainImageWidth,
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.adNetworkPop.images.length,
                            itemBuilder: (context, index) {
                              String imageUrl =
                                  widget.adNetworkPop.images[index];
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    mainImageUrl = imageUrl;
                                  });
                                },
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: index == 0 ? 0 : 10.0,
                                    right:
                                        index ==
                                                widget
                                                        .adNetworkPop
                                                        .images
                                                        .length -
                                                    1
                                            ? 0
                                            : 10.0,
                                  ),
                                  child: Image.network(
                                    imageUrl,
                                    width: 120,
                                    height: 120,
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
                              Row(
                                children: [
                                  Text(
                                    '$formattedPrice ${widget.adNetworkPop.currency}',
                                    style: AppTextStyles.interBold.copyWith(
                                      fontSize: 26,
                                      color: theme.textColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${NumberFormat.decimalPattern().format(pricePerSquareMeter)} ${widget.adNetworkPop.currency}/m²',
                                    style: AppTextStyles.interRegular.copyWith(
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
                                    widget.adNetworkPop.title,
                                    style: AppTextStyles.interBold.copyWith(
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
                                  addressDisplay, // <— use composed address string
                                  style: AppTextStyles.interRegular.copyWith(
                                    fontSize: 16,
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 50),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Description".tr,
                                          style: AppTextStyles.interBold
                                              .copyWith(
                                                fontSize: 2,
                                                color: theme.textColor,
                                              ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          widget.adNetworkPop.description,
                                          style: AppTextStyles.interRegular
                                              .copyWith(
                                                color: theme.textColor,
                                                fontSize: 14,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Expanded(flex: 1, child: SizedBox()),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "details_of_the_announcement".tr,
                                          style: AppTextStyles.interBold
                                              .copyWith(
                                                fontSize: 20,
                                                color: theme.textColor,
                                              ),
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Text(
                                              'Floor area'.tr,
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${widget.adNetworkPop.squareFootage} m²',
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        const Divider(),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Text(
                                              'Batroom number'.tr,
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${widget.adNetworkPop.bathrooms}',
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        const Divider(),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Text(
                                              'Room number'.tr,
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${widget.adNetworkPop.rooms}',
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        const Divider(),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Text(
                                              'Floor'.tr,
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${widget.adNetworkPop.floor}',
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        const Divider(),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Text(
                                              'ownership_form'.tr,
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              widget.adNetworkPop.marketType,
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        const Divider(),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Text(
                                              'parking_space'.tr,
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                            const Spacer(),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Mapa
                              const SizedBox(height: 70),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 400,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20.0),
                                      ),
                                      child:
                                          (lat != null && lon != null)
                                              ? MapAd(
                                                latitude: lat,
                                                longitude: lon,
                                                onMapActivated: () {
                                                  if (!_isMapActivated) {
                                                    _activateMap();
                                                  }
                                                },
                                              )
                                              : Center(
                                                child: Text(
                                                  'no_location'.tr,
                                                  style: AppTextStyles
                                                      .interRegular
                                                      .copyWith(
                                                        fontSize: 14,
                                                        color: theme.textColor,
                                                      ),
                                                ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "additional_info".tr,
                                          style: AppTextStyles.interBold
                                              .copyWith(
                                                fontSize: 20,
                                                color: theme.textColor,
                                              ),
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Text(
                                              'Floor area'.tr,
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${widget.adNetworkPop.squareFootage} m²',
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        const Divider(
                                          color: AppColors.dark,
                                          thickness: 1,
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Text(
                                              'bathroom_number'.tr,
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${widget.adNetworkPop.bathrooms}',
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        const Divider(
                                          color: AppColors.dark,
                                          thickness: 1,
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Text(
                                              'room_number'.tr,
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${widget.adNetworkPop.rooms}',
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        const Divider(),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Text(
                                              'Floor'.tr,
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${widget.adNetworkPop.floor}',
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        const Divider(
                                          color: AppColors.dark,
                                          thickness: 1,
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Text(
                                              'ownership_form'.tr,
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              widget.adNetworkPop.marketType,
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        const Divider(),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Text(
                                              'parking_space'.tr,
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                            const Spacer(),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Expanded(flex: 1, child: SizedBox()),
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "",
                                          style: AppTextStyles.interBold
                                              .copyWith(fontSize: 24),
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Text(
                                              'Floor area'.tr,
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${widget.adNetworkPop.squareFootage} m²',
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        const Divider(),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Text(
                                              'bathroom_number'.tr,
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${widget.adNetworkPop.bathrooms}',
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        const Divider(),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Text(
                                              'bathroom_number'.tr,
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${widget.adNetworkPop.rooms}',
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        const Divider(),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Text(
                                              'Floor'.tr,
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${widget.adNetworkPop.floor}',
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        const Divider(),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Text(
                                              'ownership_form'.tr,
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              widget.adNetworkPop.marketType,
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        const Divider(),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Text(
                                              'parking_space'.tr,
                                              style: AppTextStyles.interRegular
                                                  .copyWith(
                                                    fontSize: 14,
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                            const Spacer(),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 25),
                              PropertyDetailsColumn(
                                adNetworkPop: widget.adNetworkPop,
                              ),
                              const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [Expanded(child: SizedBox())],
                              ),
                              const SizedBox(height: 75),
                            ],
                          ),
                        ),
                      ],
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
                            const SizedBox(height: 60),
                          ],
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: Column(
                            children: [
                              const Spacer(),
                              const SizedBox(height: 30),
                              SizedBox(
                                height: 200,
                                width: 200,
                                child: FullLikeSectionFeedPopNM(
                                  adFeedPop: widget.adNetworkPop,
                                  ref: ref,
                                  context: context,
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                        const Column(
                          children: [Spacer(), SizedBox(height: 20)],
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: IntrinsicWidth(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Spacer(),
                                ElevatedButton(
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                      theme.textColor,
                                    ),
                                  ),
                                  onPressed: () {
                                    if (widget.adNetworkPop
                                        is MonitoringAdsModel) {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('phone_number'.tr),
                                            content: Text(
                                              '${widget.adNetworkPop.phoneNumber}',
                                            ),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () {
                                                  ref
                                                      .read(navigationService)
                                                      .beamPop();
                                                },
                                                child: Text('Close'.tr),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  },
                                  child: Text(
                                    'Call'.tr,
                                    style: TextStyle(
                                      color: theme.textFieldColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
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
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Mistake: $error'.tr),
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
