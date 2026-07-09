import 'dart:math';
import 'dart:ui';
import 'package:chat/pages/chat_screen_mobile_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/utils.dart';
import 'package:intl/intl.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:portal/screens/feed/widgets/feed_pop/feed_pop.dart';
import 'package:portal/screens/feed/widgets/feed_pop/feed_pop_mobile.dart';
import 'package:core/platform/ad_type_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/common/middle_mouse_gesture.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
class VictoriaNAlexCardWidgetList extends ConsumerWidget {
  final dynamic ad;
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
  final bool isDraft;
  final bool isChat;

  const VictoriaNAlexCardWidgetList({
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
    this.isDraft = false,
    this.isChat = false,
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

    Widget placeholderBox(Color bg, Color fg) => Container(
      color: bg,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 28,
        color: fg.withAlpha(89),
      ),
    );

    String? firstImageUrl(dynamic ad) {
      try {
        final imgs = ad.images;
        if (imgs is List && imgs.isNotEmpty) {
          final first = imgs.first;

          if (first is String && first.trim().isNotEmpty) return first.trim();

          if (first is Map) {
            final u = (first['url'] ??
                first['image'] ??
                first['imageUrl'] ??
                first['src'] ??
                first['path']);
            if (u is String && u.trim().isNotEmpty) return u.trim();
          } else {
            try {
              final u = (first.url ??
                  first.image ??
                  first.imageUrl ??
                  first.src ??
                  first.path);
              if (u is String && u.trim().isNotEmpty) return u.trim();
            } catch (_) {}
          }
        }
      } catch (_) {}
      return null;
    }

    const int kMaxDecodeLongSide = 1200;
    const int kMinDecodeLongSide = 320;

    double _bucketDpr(double dpr) {
      const buckets = [1.0, 1.5, 2.0, 3.0];
      double best = buckets.first;
      double bestDiff = (dpr - best).abs();
      for (final b in buckets) {
        final d = (dpr - b).abs();
        if (d < bestDiff) {
          best = b;
          bestDiff = d;
        }
      }
      return best;
    }

    Widget netOrPlaceholder(
        String? url, {
          double? width,
          double? height,
          BoxFit fit = BoxFit.cover,
          required Color bg,
          required Color fg,
        }) {
      if (url == null || url.isEmpty) {
        return placeholderBox(bg, fg);
      }

      final dprRaw = MediaQuery.of(context).devicePixelRatio;
      final dpr = _bucketDpr(dprRaw);

      int? targetW;
      if (width != null && width.isFinite && width > 0) {
        var w = (width * dpr).round();
        w = w.clamp(kMinDecodeLongSide, kMaxDecodeLongSide);
        targetW = w;
      }

      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (c, e, s) => placeholderBox(bg, fg),
        filterQuality: FilterQuality.medium,
        cacheWidth: targetW,
      );
    }

    final imageUrl = firstImageUrl(ad);

    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;

        double itemWidth = containerWidth;
        itemWidth = max(150.0, min(itemWidth, 250.0));

        double minBaseTextSize = 12;
        double maxBaseTextSize = 14;
        double baseTextSize = minBaseTextSize +
            (itemWidth - 150) / (240 - 150) * (maxBaseTextSize - minBaseTextSize);
        baseTextSize = max(minBaseTextSize, min(baseTextSize, maxBaseTextSize));

        double minBasePadding = 2;
        double maxBasePadding = 4;
        double basePadding = minBasePadding +
            (itemWidth - 150) / (240 - 150) * (maxBasePadding - minBasePadding);
        basePadding =
            max(minBasePadding, min(basePadding, maxBasePadding));

        double minBase = 4;
        double maxBase = 10;
        double base =
            minBase + (itemWidth - 150) / (240 - 150) * (maxBase - minBase);
        base = max(minBase, min(base, maxBase));


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
                if (kind != PointerDeviceKind.mouse &&
                    kind != PointerDeviceKind.touch) {
                  return;
                }

                handleDisplayedAction(ref, ad.id, context);

                if (isChat) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FeedPopPage(
                        adFeedPop: ad,
                        tagFeedPop: tag,
                        isChat: true,
                      ),
                    ),
                  );
                  return;
                }

                if (isDraft) {
                  debugPrint('Younis draft');

                  ref.read(navigationService).openPopup(
                    '/pro/draft/${ad.id}',
                    data: ad,
                  );
                  return;
                }

                debugPrint('Younis else $isChat');

                ref.read(navigationService).openPopup(
                  '$path/offer/${ad.slug}',
                  data: {
                    'tag': tag,
                    'ad': ad,
                    'isChat': false,
                  },
                );
              },
              actions: buildPieMenuActions,
              child: Hero(
                tag: tag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: isChat ? 1.03 : 16 / 9,
                        child: LayoutBuilder(
                          builder: (c, cs) => ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(isMobile ? 0 : 6),
                            ),
                            child: netOrPlaceholder(
                              imageUrl,
                              width: cs.maxWidth,
                              height: cs.maxHeight.isFinite
                                  ? cs.maxHeight
                                  : null,
                              fit: BoxFit.cover,
                              bg: theme.popupcontainercolor,
                              fg: theme.textColor,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
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
                                padding: EdgeInsets.all(isChat ? 6 : base),
                                child: Material(
                                  color: Colors.transparent,
                                  child: Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [


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
                                                  fontSize: isChat ? baseTextSize-2 : baseTextSize
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
                                          fontSize: isChat ? baseTextSize-2 : baseTextSize + 2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.clip,
                                      ),
                                      SizedBox(height: basePadding),
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.start,
                                        children: [
                                          if (ad.squareFootage != null &&
                                              ad.squareFootage
                                                  .toString()
                                                  .trim()
                                                  .isNotEmpty) ...[
                                            IconText(
                                              icon: AppIcons.magic(
                                                color: theme.textColor,
                                                width:isChat ? baseTextSize-2 : baseTextSize + 1,
                                                height:isChat ? baseTextSize-2 : baseTextSize + 1,
                                              ),
                                              text:
                                              '${ad.squareFootage} ㎡',
                                              color: theme.textColor,
                                              baseTextSize:isChat ? baseTextSize-2 : baseTextSize,
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
                                                width: isChat ? baseTextSize-2 : baseTextSize + 1,
                                                height: isChat ? baseTextSize-2 : baseTextSize + 1,
                                              ),
                                              text: '${ad.rooms} Rooms'.tr,
                                              color: theme.textColor,
                                              baseTextSize: isChat ? baseTextSize-2 : baseTextSize,
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
                                                width: isChat ? baseTextSize-2 : baseTextSize + 1,
                                                height: isChat ? baseTextSize-2 : baseTextSize + 1,
                                              ),
                                              text:
                                              '${ad.bathrooms} Bath'.tr,
                                              color: theme.textColor,
                                              baseTextSize: isChat ? baseTextSize-2 : baseTextSize,
                                            ),
                                          ],
                                        ],
                                      ),
                                      Divider(color: theme.textColor),
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
                                              fontSize: isChat ? baseTextSize + 2 : baseTextSize + 6,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
