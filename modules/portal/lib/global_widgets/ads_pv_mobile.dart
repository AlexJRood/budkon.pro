import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:portal/global_widgets/map_pv_mobile.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class AdsPvMobile extends ConsumerWidget {
  const AdsPvMobile({
    super.key,
    required this.pageController,
  });

  final PageController pageController;

  String _buildLocation(AdsListViewModel ad) {
    final parts = <String>[
      if (ad.city.trim().isNotEmpty) ad.city.trim(),
      if (ad.street.trim().isNotEmpty) ad.street.trim(),
    ];
    return parts.join(', ');
  }

  void _openAd(BuildContext context, WidgetRef ref, AdsListViewModel ad) {
    final nav = ref.read(navigationService);
    final path = nav.currentPath == '/' ? '' : nav.currentPath;
    final tag = 'fullmapViewMobile_${ad.id}';

    final routeSlug =
        ad.slug.trim().isNotEmpty ? ad.slug.trim() : ad.id.toString();

    handleDisplayedAction(ref, ad.id, context);

    nav.openPopup(
      '$path/offer/$routeSlug',
      data: {
        'tag': tag,
        'ad': ad,
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAds = ref.watch(filteredAdsProvider);
    final theme = ref.watch(themeColorsProvider);

    final safeTop = MediaQuery.of(context).padding.top;
    final topPadding = safeTop + 76;
    final bottomPadding = 60.0;

    return Padding(
      padding: EdgeInsets.only(
        top: topPadding,
        bottom: bottomPadding,
      ),
      child: Column(
        children: [
          _AdsPvMobileHeader(
            count: filteredAds.length,
            onBackToMap: () {
              pageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
              );
            },
          ),
          Expanded(
            child: filteredAds.isEmpty
                ? _EmptyAdsPvMobileState(theme: theme)
                : ListView.separated(
                    padding: const EdgeInsets.only(
                      left: 10,
                      right: 10,
                      top: 8,
                      bottom: 20,
                    ),
                    itemCount: filteredAds.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final ad = filteredAds[index];
                      final tag = 'fullmapViewMobile_${ad.id}';

                      return _AdsPvMobileCard(
                        ad: ad,
                        tag: tag,
                        location: _buildLocation(ad),
                        onTap: () => _openAd(context, ref, ad),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AdsPvMobileHeader extends StatelessWidget {
  const _AdsPvMobileHeader({
    required this.count,
    required this.onBackToMap,
  });

  final int count;
  final VoidCallback onBackToMap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 6),
      child: Material(
        color: Colors.black.withAlpha(65),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: onBackToMap,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 2),
              const Expanded(
                child: Text(
                  'Ogłoszenia z mapy',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(28),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyAdsPvMobileState extends StatelessWidget {
  const _EmptyAdsPvMobileState({
    required this.theme,
  });

  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 34,
              color: theme.textColor.withAlpha(170),
            ),
            const SizedBox(height: 12),
            Text(
              'Brak ogłoszeń w bieżącym widoku mapy',
              textAlign: TextAlign.center,
              style: AppTextStyles.interSemiBold.copyWith(
                color: theme.textColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Przesuń mapę, przybliż widok albo wróć i zmień warstwy lub obszar zaznaczenia.',
              textAlign: TextAlign.center,
              style: AppTextStyles.interRegular.copyWith(
                color: theme.textColor.withAlpha(170),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdsPvMobileCard extends ConsumerWidget {
  const _AdsPvMobileCard({
    required this.ad,
    required this.tag,
    required this.location,
    required this.onTap,
  });

  final AdsListViewModel ad;
  final String tag;
  final String location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: PieMenu(
        theme: PieTheme.of(context).copyWith(
          overlayColor: (() {
            final bool uiIsDark = theme.textColor.computeLuminance() > 0.5;
            final base = uiIsDark ? Colors.black : Colors.white;
            return base.withValues(alpha: 0.70);
          })(),
        ),
        onPressedWithDevice: (kind) {
          if (kind == PointerDeviceKind.mouse ||
              kind == PointerDeviceKind.touch ||
              kind == PointerDeviceKind.stylus ||
              kind == PointerDeviceKind.unknown) {
            onTap();
          }
        },
        actions: buildPieMenuActions(ref, ad, context),
        child: Hero(
          tag: tag,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: ad.isPro
                  ? Border.all(color: Colors.white, width: 4)
                  : null,
              boxShadow: [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black.withAlpha(22),
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    ad.images.isNotEmpty ? ad.images.first : 'default_image_url',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey,
                      alignment: Alignment.center,
                      child: const Text(
                        'no_image',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  if (ad.isPro)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.light,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Sponsored',
                          style: AppTextStyles.interMedium12dark,
                        ),
                      ),
                    ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(85),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${NumberFormat.decimalPattern().format(ad.price)} ${ad.currency}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.interBold.copyWith(
                              fontSize: 18,
                              color: theme.textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ad.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.interSemiBold.copyWith(
                              fontSize: 14,
                              color: theme.textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.interRegular.copyWith(
                              fontSize: 12,
                              color: theme.textColor,
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