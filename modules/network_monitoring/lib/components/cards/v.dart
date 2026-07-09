// network_monitoring/components/cards/v.dart
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:network_monitoring/cache_manager.dart';
import 'package:network_monitoring/components/open_nm_ad.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/common/middle_mouse_gesture.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';

import '../../browselist/utils/pie_menu.dart';
import 'package:core/platform/ad_type_utils.dart';

// ✅ re-export dla innych miejsc w projekcie
export '../open_nm_ad.dart' show openAdUrl;

class NetworkMonitoringVictoriaCardWidget extends ConsumerWidget {
  const NetworkMonitoringVictoriaCardWidget({
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
    this.isTablet = false,
    this.transactionId,
    this.clientId,
  });

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
  final bool isTablet;
  final int? transactionId;
  final int? clientId;

  String _addressLine(dynamic ad) {
    final parts = <String>[
      if ((ad?.street ?? '').toString().trim().isNotEmpty) ad.street,
      if ((ad?.city ?? '').toString().trim().isNotEmpty) ad.city,
      if ((ad?.state ?? '').toString().trim().isNotEmpty) ad.state,
    ].map((e) => e.toString()).toList();
    return parts.join(', ');
  }

  String _offerLabel(dynamic ad) {
    final t = (ad?.offerType ?? '').toString().toLowerCase();
    if (t == 'rent' || t == 'wynajem') return 'FOR RENT'.tr;
    if (t == 'sale' || t == 'sprzedaż' || t == 'sprzedaz') return 'FOR SALE'.tr;
    return 'FOR SALE'.tr;
  }

  Widget _metaRow(Color color, bool isTablet) {
    final children = <Widget>[];

    final sq = (ad.squareFootageText ?? ad.squareFootage?.toString() ?? '').toString();
    if (sq.trim().isNotEmpty && sq != '-') {
      children.add(
        IconText(
          icon: AppIcons.magic(color: color),
          color: color,
          text: '$sq ㎡',
          isTablet: isTablet,
        ),
      );
    }

    final estateType = (ad.estateType ?? '').toString();
    final rooms = (ad.roomsText ?? ad.rooms?.toString() ?? '').toString();
    if (AdTypeUtils.showRoomsAndBathrooms(estateType) && rooms.trim().isNotEmpty && rooms != '-' && rooms != '0') {
      if (children.isNotEmpty) {
        children.add(Text('  |  ', style: TextStyle(color: color, fontSize: isTablet ? 10.sp : 12.sp)));
      }
      children.add(
        IconText(
          icon: AppIcons.bed(width: isTablet ? 16.sp : 20.sp, height: isTablet ? 16.sp : 20.sp, color: color),
          color: color,
          text: '$rooms ${"Rooms".tr}',
          isTablet: isTablet,
        ),
      );
    }

    final baths = (ad.bathroomsText ?? ad.bathrooms?.toString() ?? '').toString();
    if (AdTypeUtils.showRoomsAndBathrooms(estateType) && baths.trim().isNotEmpty && baths != '-' && baths != '0') {
      if (children.isNotEmpty) {
        children.add(Text('  |  ', style: TextStyle(color: color, fontSize: isTablet ? 10.sp : 12.sp)));
      }
      children.add(
        IconText(
          icon: AppIcons.bathroom(width: isTablet ? 16.sp : 20.sp, height: isTablet ? 16.sp : 20.sp, color: color),
          color: color,
          text: '$baths ${"Bath".tr}',
          isTablet: isTablet,
        ),
      );
    }

    return Row(children: children);
  }

  String _priceText() =>
      (ad.priceText ??
              (() {
                final p = ad.price;
                final c = (ad.currency ?? '').toString().trim();
                if (p == null) return '-';
                final str = p is num ? p.round().toString() : p.toString();
                return c.isEmpty ? str : '$str $c';
              })())
          .toString();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: MiddleClickDetector(
        onMiddleClick: () => handleBrowseListRemoveActionNM(
          ref,
          ad,
          context,
          transactionId,
          clientId,
        ),
        child: PieMenu(
          theme: PieTheme.of(context).copyWith(
            overlayColor: (() {
              final t = ref.watch(themeColorsProvider);
              final bool uiIsDark = t.textColor.computeLuminance() > 0.5;
              final base = uiIsDark ? Colors.black : Colors.white;
              return base.withValues(alpha: 0.70);
            })(),
          ),
          onPressedWithDevice: (kind) async {
            if (kind == PointerDeviceKind.mouse || kind == PointerDeviceKind.touch) {
              await openAdUrl(context, ref, ad, transactionId, clientId, tag);
            }
          },
          actions: buildPieMenuActions,
          child: Hero(
            tag: tag,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final dpr = MediaQuery.of(context).devicePixelRatio;
                  final w = constraints.maxWidth;
                  final h = w / aspectRatio;

                  final diskW = (w * 2).clamp(0, 1024).round();
                  final diskH = (h * 2).clamp(0, 1024).round();

                  final memW = (w * dpr).round();
                  final memH = (h * dpr).round();

                  return Container(
                    color: theme.dashboardContainer,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(isMobile ? 0 : 6),
                            ),
                            child: CachedNetworkImage(
                              cacheManager: NetworkMonitoringCacheManagerFeedAds.instance,
                              imageUrl: mainImageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.low,
                              memCacheWidth: memW,
                              memCacheHeight: memH,
                              maxWidthDiskCache: diskW,
                              maxHeightDiskCache: diskH,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: ClipRRect(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(isMobile ? 0 : 6),
                              color: theme.textFieldColor.withAlpha(184),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _addressLine(ad),
                                    style: TextStyle(
                                      color: theme.textColor.withAlpha(184),
                                      fontSize: isTablet ? 10.sp : 12.sp,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    (ad.safeTitle ?? ad.title ?? '').toString(),
                                    style: AppTextStyles.interMedium.copyWith(
                                      color: theme.textColor,
                                      fontSize: isTablet ? 12.sp : 14.sp,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  _metaRow(theme.textColor.withAlpha(184), isTablet),
                                  Divider(color: theme.textColor.withAlpha(100)),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _offerLabel(ad),
                                        style: TextStyle(
                                          color: theme.textColor.withAlpha(184),
                                          fontSize: isTablet ? 10.sp : 12.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        _priceText(),
                                        style: AppTextStyles.interMedium22.copyWith(
                                          color: theme.textColor,
                                          fontSize: isTablet ? 18.sp : 22.sp,
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
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class IconText extends StatelessWidget {
  const IconText({
    super.key,
    required this.color,
    required this.icon,
    required this.text,
    this.isTablet = false,
  });

  final Widget icon;
  final String text;
  final Color color;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 5.0),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: isTablet ? 10.sp : 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}