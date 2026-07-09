import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart'; // ⬅️ NEW
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:pie_menu/pie_menu.dart';

class FavoriteAdCardWidget extends ConsumerWidget {
  final AdsListViewModel feedAd;
  final String keyTag;
  final String mainImageUrl;
  final String formattedPrice;
  final void Function(WidgetRef ref, int id, BuildContext context)
  handleDisplayedAction;

  const FavoriteAdCardWidget({
    super.key,
    required this.feedAd,
    required this.keyTag,
    required this.mainImageUrl,
    required this.formattedPrice,
    required this.handleDisplayedAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AspectRatio(
      aspectRatio: 1,
      child: PieMenu(
        theme: PieTheme.of(context).copyWith(
          overlayColor:
              (() {
                final theme = ref.watch(themeColorsProvider);
                final bool uiIsDark = theme.textColor.computeLuminance() > 0.5;

                final base = uiIsDark ? Colors.black : Colors.white;
                return base.withValues(alpha: 0.70);
              })(),
        ),
        onPressedWithDevice: (kind) {
          if (kind == PointerDeviceKind.mouse ||
              kind == PointerDeviceKind.touch) {
            handleDisplayedAction(ref, feedAd.id, context);
            final route = '${Routes.fav}/offer/${feedAd.slug}';
            ref
                .read(navigationService)
                .pushNamedScreen(route, data: {'tag': keyTag, 'ad': feedAd});
          }
        },
        actions: buildPieMenuActions(ref, feedAd, context),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Hero(
            tag: keyTag,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  // 🔻 OPTIMIZED IMAGE DECODE
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final dpr = MediaQuery.of(context).devicePixelRatio;
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;

                        // target decode size in physical pixels
                        int targetW = (w * dpr).round().clamp(
                          320,
                          1024,
                        ); // min/max cap
                        int targetH = (h * dpr).round().clamp(240, 1024);

                        return CachedNetworkImage(
                          imageUrl: mainImageUrl,
                          fit: BoxFit.cover,
                          filterQuality:
                              FilterQuality
                                  .low, // cheaper sampling, good for thumbnails
                          memCacheWidth: targetW,
                          memCacheHeight: targetH,
                          maxWidthDiskCache: 1024,
                          maxHeightDiskCache: 1024,
                          placeholder:
                              (context, url) =>
                                  Container(color: Colors.black12),
                          errorWidget:
                              (context, url, error) => Container(
                                color: Colors.grey,
                                alignment: Alignment.center,
                                child: Text(
                                  'No image'.tr,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                        );
                      },
                    ),
                  ),

                  // 🔺 END OPTIMIZED IMAGE
                  Positioned(
                    left: 2,
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((255 * 0.4).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: Text(
                              '$formattedPrice ${feedAd.currency}',
                              style: AppTextStyles.interBold.copyWith(
                                fontSize: 18,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: Text(
                              feedAd.title,
                              style: AppTextStyles.interSemiBold.copyWith(
                                fontSize: 14,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: Text(
                              '${feedAd.city}, ${feedAd.street}',
                              style: AppTextStyles.interRegular.copyWith(
                                fontSize: 12,
                                color: AppColors.white,
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
  }
}
