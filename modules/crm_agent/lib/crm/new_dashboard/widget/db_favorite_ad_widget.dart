import 'dart:ui';

import 'package:fav_board/widgets/fav_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/src/extensions/export.dart';
import 'package:intl/intl.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:portal/screens/feed/provider/feed_pop/fav_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/common/drad_scroll_widget.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';

class DbFavoriteAdWidget extends ConsumerStatefulWidget {
  final bool isMobile;

  /// Optional dedicated controller from dashboard/widget host.
  ///
  /// Do not pass the main page scroll controller if it is already attached
  /// to another scrollable. Prefer one dedicated controller per widget.
  final ScrollController? scrollController;

  const DbFavoriteAdWidget({
    super.key,
    this.isMobile = false,
    this.scrollController,
  });

  @override
  ConsumerState<DbFavoriteAdWidget> createState() => _DbFavoriteAdWidgetState();
}

class _DbFavoriteAdWidgetState extends ConsumerState<DbFavoriteAdWidget> {
  ScrollController? _internalScrollController;

  ScrollController get _effectiveScrollController {
    if (widget.scrollController != null) {
      return widget.scrollController!;
    }

    return _internalScrollController ??= ScrollController();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final notifier = ref.read(favAdsProvider.notifier);
      notifier.applyFilters(ref);
    });
  }

  @override
  void didUpdateWidget(covariant DbFavoriteAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.scrollController != widget.scrollController &&
        widget.scrollController != null) {
      _internalScrollController?.dispose();
      _internalScrollController = null;
    }
  }

  @override
  void dispose() {
    _internalScrollController?.dispose();
    _internalScrollController = null;
    super.dispose();
  }

  int _desktopCrossAxisCount(double width) {
    if (width > 1100) return 3;
    if (width > 680) return 2;
    return 1;
  }

  double _desktopCardHeight({
    required double viewportHeight,
    required bool compact,
  }) {
    if (viewportHeight < 260) return 280;
    if (viewportHeight < 340) return 300;
    if (viewportHeight < 460) return 330;
    return 360;
  }

  double _mobileCardWidth(double viewportWidth) {
    if (viewportWidth < 420) return viewportWidth * 0.82;
    if (viewportWidth < 700) return 320;
    return 360;
  }

  double _lottieSize(
    BoxConstraints constraints, {
    double fallback = 220,
  }) {
    final height = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : fallback;

    final width = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : fallback;

    return (height < width ? height : width).clamp(90.0, fallback);
  }

  Widget _buildHeader({
    required ThemeColors theme,
    required bool compact,
    required bool veryCompact,
  }) {
    if (veryCompact) {
      return SizedBox(
        height: 32,
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Favourite Advertisment'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'See all favourites'.tr,
              onPressed: () {
                ref.read(navigationService).pushStackedScreen(Routes.fav);
              },
              icon: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16.sp,
                color: theme.textColor,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: compact ? 34 : 40,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Favourite Advertisment'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor,
                fontSize: compact ? 14.sp : 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              ref.read(navigationService).pushStackedScreen(Routes.fav);
            },
            child: Container(
              width: compact ? 40 : 96.w,
              height: compact ? 30 : 32.h,
              padding: compact ? null : EdgeInsets.symmetric(horizontal: 8.w),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: theme.dashboardBoarder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!compact) ...[
                    Flexible(
                      child: Text(
                        'See all'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: compact ? 14.sp : 14.sp,
                    color: theme.textColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopGrid({
    required List<dynamic> data,
    required NumberFormat customFormat,
    required BoxConstraints constraints,
    required bool compact,
  }) {
    final crossAxisCount = _desktopCrossAxisCount(constraints.maxWidth);

    final cardHeight = _desktopCardHeight(
      viewportHeight: constraints.maxHeight,
      compact: compact,
    );

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),
      child: GridView.builder(
        controller: _effectiveScrollController,
        addAutomaticKeepAlives: false,
        addSemanticIndexes: false,
        cacheExtent: 260,
        primary: false,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(
          top: 8,
          bottom: 8,
        ),
        itemCount: data.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisExtent: cardHeight,
          crossAxisSpacing: 15,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final stateData = data[index];

          final tag = 'fav-${stateData.id}-$index';
          final formattedPrice = customFormat.format(stateData.price);

          final mainImageUrl = stateData.images.isNotEmpty
              ? stateData.images[0]
              : 'default_image_url';

          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FavoriteAdCardWidget(
              feedAd: stateData,
              keyTag: tag,
              mainImageUrl: mainImageUrl,
              formattedPrice: formattedPrice,
              handleDisplayedAction: handleDisplayedAction,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileHorizontalList({
    required List<dynamic> data,
    required NumberFormat customFormat,
    required BoxConstraints constraints,
  }) {
    final cardWidth = _mobileCardWidth(constraints.maxWidth);

    return DragScrollView(
      controller: _effectiveScrollController,
      child: ListView.separated(
        controller: _effectiveScrollController,
        primary: false,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(
          top: 8,
          bottom: 8,
        ),
        itemCount: data.length,
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final stateData = data[index];

          final tag = 'fav-${stateData.id}-$index';
          final formattedPrice = customFormat.format(stateData.price);

          final mainImageUrl = stateData.images.isNotEmpty
              ? stateData.images[0]
              : 'default_image_url';

          return SizedBox(
            width: cardWidth,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FavoriteAdCardWidget(
                feedAd: stateData,
                keyTag: tag,
                mainImageUrl: mainImageUrl,
                formattedPrice: formattedPrice,
                handleDisplayedAction: handleDisplayedAction,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody({
    required NumberFormat customFormat,
    required bool compact,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ref.watch(favAdsProvider).when(
              data: (data) {
                if (data.isEmpty) {
                  return Center(
                    child: AppLottie.noResults(
                      size: _lottieSize(
                        constraints,
                        fallback: 260,
                      ),
                    ),
                  );
                }

                if (widget.isMobile) {
                  return _buildMobileHorizontalList(
                    data: data,
                    customFormat: customFormat,
                    constraints: constraints,
                  );
                }

                return _buildDesktopGrid(
                  data: data,
                  customFormat: customFormat,
                  constraints: constraints,
                  compact: compact,
                );
              },
              error: (error, stackTrace) {
                if (kDebugMode) {
                  debugPrint(error.toString());
                }

                return Center(
                  child: AppLottie.error(
                    size: _lottieSize(
                      constraints,
                      fallback: 260,
                    ),
                  ),
                );
              },
              loading: () {
                if (kDebugMode) {
                  debugPrint('loading');
                }

                return Center(
                  child: AppLottie.loading(
                    size: _lottieSize(
                      constraints,
                      fallback: 260,
                    ),
                  ),
                );
              },
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customFormat = NumberFormat.decimalPattern('fr');
    final theme = ref.watch(themeColorsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.maxHeight.isFinite;

        final fallbackHeight = widget.isMobile ? 420.0 : 360.0;
        final height = hasBoundedHeight ? constraints.maxHeight : fallbackHeight;

        final compact = height < 310 || constraints.maxWidth < 520;
        final veryCompact = height < 210;

        final content = ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent,
            child: Column(
              children: [
                _buildHeader(
                  theme: theme,
                  compact: compact,
                  veryCompact: veryCompact,
                ),
                SizedBox(height: veryCompact ? 4 : 8),
                Expanded(
                  child: _buildBody(
                    customFormat: customFormat,
                    compact: compact,
                  ),
                ),
              ],
            ),
          ),
        );

        if (hasBoundedHeight) {
          return SizedBox.expand(
            child: content,
          );
        }

        return SizedBox(
          height: fallbackHeight,
          child: content,
        );
      },
    );
  }
}