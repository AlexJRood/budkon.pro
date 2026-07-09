import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/components/open_nm_ad.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import '../../browselist/utils/pie_menu.dart';
import 'package:core/common/middle_mouse_gesture.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:get/get_utils/get_utils.dart';

import 'package:core/platform/platforms/html_utils_stub.dart'
  if (dart.library.html) 'package:core/platform/platforms/html_utils_web.dart';


class NetworkMonitoringAlexCardWidget extends ConsumerWidget {
  /// Safer, typed model with helpers.
  final dynamic ad;

  /// Hero tag – unique (e.g. 'ad-123').
  final String tag;

  /// Kept for backward-compatibility; not used (model provides mainImageUrl).
  final String mainImageUrl;

  final bool isPro; // external flag; we’ll OR with ad.isPro for display
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


  const NetworkMonitoringAlexCardWidget({
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
    this.clientId
  });



  /// Build safe single-line address
  String _addressLine() {
    final parts = <String>[];
    if ((ad.city ?? '').trim().isNotEmpty) parts.add(ad.city!.trim());
    if ((ad.street ?? '').trim().isNotEmpty) parts.add(ad.street!.trim());
    return parts.isEmpty ? '-' : parts.join(', ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showPro = isPro || ad.isPro; // respect either flag

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: MiddleClickDetector(
        onMiddleClick: () {
          // custom middle-click action
          handleBrowseListRemoveActionNM(ref, ad, context, transactionId, clientId);
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
          onPressedWithDevice: (kind) async {
            if (kind == PointerDeviceKind.mouse || kind == PointerDeviceKind.touch) {
              await openAdUrl(context, ref, ad, transactionId, clientId, tag);
            }
          },
          actions: buildPieMenuActions,
          child: Hero(
            tag: tag,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: showPro
                    ? Border.all(color: AppColors.light, width: 3.0)
                    : Border.all(),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    // Main image (safe fallback + placeholders)
                    AspectRatio(
                      aspectRatio: aspectRatio,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final dpr = MediaQuery.of(context).devicePixelRatio;
                          final w = constraints.maxWidth;
                          final h = constraints.maxHeight; // due to AspectRatio
                          // keep disk cache bounded
                          final diskW = (w * 2).clamp(0, 1024).round();
                          final diskH = (h * 2).clamp(0, 1024).round();

                          return CachedNetworkImage(
                            imageUrl: ad.mainImageUrl,
                            fit: BoxFit.cover,
                            // ↓↓↓ RAM/perf friendly additions
                            filterQuality: FilterQuality.low,
                            memCacheWidth:  (w * dpr).round(),
                            memCacheHeight: (h * dpr).round(),
                            maxWidthDiskCache:  diskW,
                            maxHeightDiskCache: diskH,
                            // ↑↑↑
                            placeholder: (context, url) => buildShimmerPlaceholder,
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey,
                              alignment: Alignment.center,
                              child:Text(
                                'No picture'.tr,
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Sponsored badge for PRO
                    Positioned(
                      right: -2,
                      top: -2,
                      child: showPro
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                              decoration: BoxDecoration(
                                color: AppColors.light,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Sponsored'.tr,
                                    style: AppTextStyles.interMedium12dark,
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    // Price + title + address (bottom-left)
                    Positioned(
                      left: 2,
                      bottom: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isDefaultDarkSystem
                              ? textFieldColor.withAlpha((255 * 0.5).toInt())
                              : color.withAlpha((255 * 0.5).toInt()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Price (safe formatted with currency)
                            Material(
                              color: Colors.transparent,
                              child: Text(
                                ad.priceText,
                                style: AppTextStyles.interBold.copyWith(
                                  fontSize: isTablet ? 16 : 18,
                                  color: textColor,
                                ),
                              ),
                            ),
                            // Title (safe)
                            Material(
                              color: Colors.transparent,
                              child: Text(
                                ad.safeTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.interSemiBold.copyWith(
                                  color: textColor,
                                  fontSize: isTablet ? 13 : 14,
                                ),
                              ),
                            ),
                            // Address (safe)
                            Material(
                              color: Colors.transparent,
                              child: Text(
                                _addressLine(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.interRegular.copyWith(
                                  color: textColor,
                                  fontSize: isTablet ? 11 : 12,
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
      ),
    );
  }
}
