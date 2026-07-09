// screens/network_home_page/widgets/nm_recently_viewed_ads.dart
// Horizontally scrolling cards with stable provider key & hero tags.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:network_monitoring/components/cards/va.dart';
import 'package:network_monitoring/components/open_nm_ad.dart';
import 'package:network_monitoring/pie_menu/network_monitoring.dart';
import 'package:network_monitoring/providers/displayed/provider.dart';
import 'package:core/common/drad_scroll_widget.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:pie_menu/pie_menu.dart';

import 'package:core/theme/lottie.dart';
// ✅ Needed for the phone popup WebView:
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class NMRecentlyViewedAds extends ConsumerStatefulWidget {
  const NMRecentlyViewedAds({super.key});

  @override
  ConsumerState<NMRecentlyViewedAds> createState() => _NMRecentlyViewedAdsState();
}

class _NMRecentlyViewedAdsState extends ConsumerState<NMRecentlyViewedAds> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  NumberFormat _safeNumberFormat(BuildContext context) {
    // BIERZEMY LOCALE Z KONTEKSTU; fallback bez argumentus
    final locale = Localizations.maybeLocaleOf(context)?.languageCode;
    try {
      return locale != null
          ? NumberFormat.decimalPattern(locale)
          : NumberFormat.decimalPattern();
    } catch (_) {
      return NumberFormat.decimalPattern();
    }
  }

  @override
  Widget build(BuildContext context) {
    const scope = DisplayedScope(clientId: null, transactionId: null);
    final asyncAds = ref.watch(nMDisplayedAdsProvider(scope));
    final theme = ref.read(themeColorsProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final itemWidth = isMobile ? 220.0 : 260.0;
    final itemHeight = isMobile ? 260.0 : 300.0;
    final baseTextSize = isMobile ? 12.0 : 16.0;

    final formatter = _safeNumberFormat(context);

    return asyncAds.when(
      data: (ads) {
        // PUSTA LISTA — pokaż mały, elegancki empty state, brak „szarego bloku”
        if (ads.isEmpty) {
          return Center(child: AppLottie.noResults(size: 450));
        }

        return SizedBox(
          height: itemHeight, // tylko dla scrollerka z kartami
          child: DragScrollView(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    ads.map((ad) {
                      final heroTag = 'recentlyViewed-${ad.id}';
                      final mainImageUrl =
                          (ad.images.isNotEmpty == true)
                              ? (ad.images.first ?? '')
                              : '';
                      final priceText =
                          ad.price != null
                              ? '${formatter.format(ad.price)} ${ad.currency}'
                              : '-';

                      return PieMenu(
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
                          if (kind == PointerDeviceKind.mouse ||
                              kind == PointerDeviceKind.touch)  {
                          await openAdUrl(context, ref, ad, null, null, '${ad.id}');
                          }
                        },
                        actions: buildPieMenuActionsNM(
                          ref,
                          ad,
                          context,
                          null,
                          null,
                        ),
                        child: Hero(
                          tag: heroTag,
                          child: Container(
                            width: itemWidth,
                            height: itemHeight,
                            margin: EdgeInsets.only(right: baseTextSize),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (mainImageUrl.isNotEmpty)
                                  CachedNetworkImage(
                                    imageUrl: mainImageUrl,
                                    fit: BoxFit.cover,
                                    placeholder:
                                        (context, url) => ShimmerPlaceholder(
                                          width: itemWidth,
                                          height: itemHeight,
                                        ),
                                    errorWidget:
                                        (context, url, error) => Container(
                                          color: AppColors.white,
                                          child: const Icon(
                                            Icons.broken_image_outlined,
                                          ),
                                        ),
                                  )
                                else
                                  Container(
                                    color: AppColors.white,
                                    child: const Icon(Icons.image_not_supported),
                                  ),


                           Positioned.fill(
                                  child: Container(
                                    decoration: ad.isActive == false
                                     ? BoxDecoration(
                                      color: theme.themeColor.withAlpha(150),
                                      borderRadius: BorderRadius.circular(8),
                                     )
                                     : BoxDecoration(
                                      gradient: LinearGradient(
                                        end: Alignment.topRight,
                                        begin: Alignment.bottomLeft,
                                        colors: [AppColors.dark50, AppColors.dark15,]),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),


                                // podpis
                                Positioned(
                                  left: 8,
                                  right: 8,
                                  bottom: 6,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                       ad.isActive == true
                                        ? priceText
                                        : 'ad_has_expired'.tr,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.interBold.copyWith(
                                          fontSize: baseTextSize,
                                          color: AppColors.white,
                                        ),
                                      ),
                                      Text(
                                        '${ad.city}, ${ad.street}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.interRegular
                                            .copyWith(
                                              fontSize: baseTextSize - 2,
                                              color: AppColors.white,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        );
      },
      loading:
          () => ShimmerLoadingRow(
            itemWidth: itemWidth,
            itemHeight: itemHeight,
            placeholderwidget: ShimmerPlaceholder(
              width: itemWidth,
              height: itemHeight,
            ),
          ),
      error:
          (error, stackTrace) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(
              'An error occurred: $error'.tr,
              style: AppTextStyles.interRegular.copyWith(fontSize: 16),
            ),
          ),
    );
  }
}
