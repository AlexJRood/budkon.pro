import 'dart:math';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/utils.dart';
import 'package:intl/intl.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:portal/cache_manager.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:core/platform/ad_type_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/common/middle_mouse_gesture.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui' as ui;

class VictoriaNAlexCardWidget extends ConsumerWidget {
  final AdsListViewModel ad;
  final String tag;
  final String mainImageUrl;
  final bool isPro;
  final bool isDefaultDarkSystem;
  final Color color;
  final Color textColor;
  final Color textFieldColor;
  final Widget buildShimmerPlaceholder;
  final dynamic buildPieMenuActions;
  final double aspectRatio;
  final bool isMobile;
  final bool isOwnUser;
  final bool isArchive;
  final bool isFeed;

  const VictoriaNAlexCardWidget({
    super.key,
    required this.ad,
    required this.tag,
    required this.mainImageUrl,
    required this.isPro,
    required this.isDefaultDarkSystem,
    required this.color,
    required this.textColor,
    required this.textFieldColor,
    required this.buildShimmerPlaceholder,
    required this.buildPieMenuActions,
    required this.aspectRatio,
    required this.isMobile,
    this.isOwnUser = false,
    this.isArchive = false,
    this.isFeed = false,
  });

  static final NumberFormat _priceFmt = NumberFormat.decimalPattern('fr');

  String _offerLabel(dynamic ad) {
    final t = (ad?.offerType ?? '').toString().toLowerCase();
    if (t == 'rent' || t == 'wynajem') return 'FOR RENT'.tr;
    if (t == 'sale' || t == 'sprzedaż' || t == 'sprzedaz') return 'FOR SALE'.tr;
    return 'FOR SALE'.tr;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = ref.read(navigationService).currentPath;
    final theme = ref.read(themeColorsProvider);
    final path = currentPath == '/' ? '' : currentPath;

    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;

        double itemWidth = containerWidth;
        itemWidth = max(150.0, min(itemWidth, 250.0));

        double minBaseTextSize = 12;
        double maxBaseTextSize = 14;
        double baseTextSize =
            minBaseTextSize +
            (itemWidth - 150) /
                (240 - 150) *
                (maxBaseTextSize - minBaseTextSize);
        baseTextSize = max(minBaseTextSize, min(baseTextSize, maxBaseTextSize));

        double minBasePadding = 2;
        double maxBasePadding = 4;
        double basePadding =
            minBasePadding +
            (itemWidth - 150) / (240 - 150) * (maxBasePadding - minBasePadding);
        basePadding = max(minBasePadding, min(basePadding, maxBasePadding));

        double minBase = 4;
        double maxBase = 10;
        double base =
            minBase + (itemWidth - 150) / (240 - 150) * (maxBase - minBase);
        base = max(minBase, min(base, maxBase));

        final dpr = MediaQuery.of(context).devicePixelRatio;
        final cardHeight = itemWidth / aspectRatio;
        final targetMemW = (itemWidth * dpr).round();
        final targetMemH = (cardHeight * dpr).round();

        final diskW = min(1024, (itemWidth * 2).round());
        final diskH = min(1024, (cardHeight * 2).round());
        final img = mainImageUrl.trim();


        final locationParts = <String>[
          if (ad.street.trim().isNotEmpty) ad.street.trim(),
          if (ad.district.trim().isNotEmpty) ad.district.trim(),
          if (ad.city.trim().isNotEmpty) ad.city.trim(),
          if (ad.state.trim().isNotEmpty) ad.state.trim(),
        ];
        
        return AspectRatio(
          aspectRatio: aspectRatio,
          child: MiddleClickDetector(
            onMiddleClick: () {
              debugPrint('Middle click detected!');
              handleBrowseListAction(ref, ad, context);
            },
            child: PieMenu(
              theme: PieTheme.of(context).copyWith(
                        overlayColor:
                            (() {
                              final theme = ref.watch(themeColorsProvider);
                              final bool uiIsDark =
                                  theme.textColor.computeLuminance() > 0.5;

                              final base =
                                  uiIsDark ? Colors.black : Colors.white;
                              return base.withValues(alpha: 0.70);
                            })(),
                      ),
              onPressedWithDevice: (kind) {
                if (kind == PointerDeviceKind.mouse ||
                    kind == PointerDeviceKind.touch) {
                  handleDisplayedAction(ref, ad, context);
                  // if (isFeed == true) {
                    ref.read(navigationService).openPopup(
                      '$path/offer/${ad.slug}',
                      data: {'tag': tag, 'ad': ad},
                    );
                  // }
                }
              },
              actions: buildPieMenuActions,
              child: Hero(
                tag: tag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(isMobile ? 0 : 6),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: img,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                cacheManager:
                                    CacheManagerFeedAdsPhotos.instance,
                                filterQuality: FilterQuality.low,
                                memCacheWidth: targetMemW,
                                memCacheHeight: targetMemH,
                                maxWidthDiskCache: diskW,
                                maxHeightDiskCache: diskH,
                              ),
                            ),
                          ),
                          ClipRRect(
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(
                                sigmaX: 20,
                                sigmaY: 20,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    isMobile ? 0 : 6,
                                  ),
                                  color: theme.sideBarbackground.withAlpha(
                                    (255 * 0.75).toInt(),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(base),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (isArchive)
                                          Row(
                                            spacing: 5.w,
                                            children: [
                                              AppIcons.warningAmber(
                                                color: Colors.red,
                                                height: 16.h,
                                                width: 16.w,
                                              ),
                                              Text(
                                                'expired_ad'.tr,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge?.copyWith(
                                                  color: Colors.red,
                                                  fontSize: 12.sp,
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (isArchive)
                                          SizedBox(height: basePadding / 2),


                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                locationParts.join(', '),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTextStyles.interLight.copyWith(
                                                  color: theme.textColor,
                                                  fontSize: baseTextSize,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),




                                        SizedBox(height: basePadding / 2),
                                        Text(
                                          '${ad.title},',
                                          style: AppTextStyles.interMedium
                                              .copyWith(
                                                color: theme.textColor,
                                                fontSize: baseTextSize + 2,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.clip,
                                        ),
                                        SizedBox(height: basePadding),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            if (ad.squareFootage
                                                .toString()
                                                .trim()
                                                .isNotEmpty) ...[
                                              IconText(
                                                icon: AppIcons.magic(
                                                  color: theme.textColor,
                                                  width: baseTextSize + 1,
                                                  height: baseTextSize + 1,
                                                ),
                                                text: '${ad.squareFootage} ㎡',
                                                color: theme.textColor,
                                                baseTextSize: baseTextSize,
                                              ),
                                            ],
                                            if (AdTypeUtils.showRoomsAndBathrooms(ad.estateType) && ad.rooms > 0) ...[
                                              Text(
                                                '  |  ',
                                                style: TextStyle(
                                                  color: theme.textColor,
                                                  fontSize: baseTextSize + 2,
                                                ),
                                              ),
                                              IconText(
                                                icon: AppIcons.bed(
                                                  color: theme.textColor,
                                                  width: baseTextSize + 1,
                                                  height: baseTextSize + 1,
                                                ),
                                                text: '${ad.rooms} Rooms'.tr,
                                                color: theme.textColor,
                                                baseTextSize: baseTextSize,
                                              ),
                                            ],
                                            if (AdTypeUtils.showRoomsAndBathrooms(ad.estateType) && ad.bathrooms > 0) ...[
                                              Text(
                                                '  |  ',
                                                style: TextStyle(
                                                  color: theme.textColor,
                                                  fontSize: baseTextSize + 2,
                                                ),
                                              ),
                                              IconText(
                                                icon: AppIcons.bathroom(
                                                  color: theme.textColor,
                                                  width: baseTextSize + 1,
                                                  height: baseTextSize + 1,
                                                ),
                                                text: '${ad.bathrooms} Bath'.tr,
                                                color: theme.textColor,
                                                baseTextSize: baseTextSize,
                                              ),
                                            ],
                                          ],
                                        ),
                                        Divider(color: theme.textColor.withAlpha(100)),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _offerLabel(ad),
                                              style: AppTextStyles.interLight
                                                  .copyWith(
                                                    color: theme.textColor,
                                                    fontSize: baseTextSize,
                                                  ),
                                            ),
                                            Text(
                                              '${_priceFmt.format(ad.price)} ${ad.currency}',
                                              style: AppTextStyles.interSemiBold
                                                  .copyWith(
                                                    color: theme.textColor,
                                                    fontSize: baseTextSize + 6,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        if (isOwnUser)
                                          Padding(
                                            padding: EdgeInsets.only(
                                              top: basePadding,
                                            ),
                                            child: SizedBox(
                                              height: 37,
                                              child: ElevatedButton(
                                                style: elevatedButtonStyleRounded10.copyWith(
                                                  backgroundColor:
                                                      WidgetStateProperty.all(
                                                        CustomColors.secondaryWidgetColor(
                                                          context,
                                                          ref,
                                                        ),
                                                      ),
                                                  foregroundColor:
                                                      WidgetStateProperty.all(
                                                        theme.textButtonColor,
                                                      ),
                                                  elevation:
                                                      WidgetStateProperty.all(0),
                                                  padding:
                                                      WidgetStateProperty.all(
                                                        EdgeInsets.symmetric(
                                                          vertical: 15.h,
                                                        ),
                                                      ),
                                                  shape: WidgetStateProperty.all(
                                                    RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(5),
                                                    ),
                                                  ),
                                                ),
                                                onPressed: () {},
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    AppIcons.magic(
                                                      height: baseTextSize + 2,
                                                      width: baseTextSize + 2,
                                                      color:
                                                          CustomColors.secondaryWidgetTextColor(
                                                            context,
                                                            ref,
                                                          ),
                                                    ),
                                                    SizedBox(
                                                      width: basePadding * 2,
                                                    ),
                                                    Text(
                                                      'promote_the_ad'.tr,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.copyWith(
                                                            fontSize:
                                                                baseTextSize,
                                                            color:
                                                                CustomColors.secondaryWidgetTextColor(
                                                                  context,
                                                                  ref,
                                                                ),
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isArchive)
                        Positioned(
                          top: 60.h,
                          right: 30.w,
                          left: 30.w,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              AppIcons.eyeDropper(
                                color: Colors.white,
                                height: 36.h,
                                width: 36.w,
                              ),
                              Text(
                                'Expired ad'.tr,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
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
    );
  }

}

class IconText extends StatelessWidget {
  final Widget icon;
  final String text;
  final Color color;
  final double baseTextSize;

  const IconText({
    super.key,
    required this.color,
    required this.baseTextSize,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 5.0.sp),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: baseTextSize)),
        ],
      ),
    );
  }
}
