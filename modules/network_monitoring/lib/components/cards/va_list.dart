import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:network_monitoring/browselist/utils/pie_menu.dart';
import 'package:network_monitoring/components/open_nm_ad.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/common/middle_mouse_gesture.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/icons.dart';
import 'package:core/platform/platforms/html_utils_stub.dart'
    if (dart.library.html) 'package:core/platform/platforms/html_utils_web.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

class NetworkMonitoringVictoriaNAlexCardWidgetList extends ConsumerWidget {
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

  final Future<void> Function()? onOpenOverride;
  final VoidCallback? onMiddleClickOverride;
  final bool enableDefaultNmActions;

  const NetworkMonitoringVictoriaNAlexCardWidgetList({
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
    this.onOpenOverride,
    this.onMiddleClickOverride,
    this.enableDefaultNmActions = true,
  });

  String _addressLine() {
    final parts = <String>[
      if ((ad?.street ?? '').toString().trim().isNotEmpty) ad.street,
      if ((ad?.city ?? '').toString().trim().isNotEmpty) ad.city,
      if ((ad?.state ?? '').toString().trim().isNotEmpty) ad.state,
    ].map((e) => e.toString()).toList();
    return parts.join(', ');
  }

  String _offerLabel() {
    final t = (ad?.offerType ?? '').toString().toLowerCase();
    if (t == 'rent' || t == 'wynajem') return 'FOR RENT'.tr;
    if (t == 'sale' || t == 'sprzedaż' || t == 'sprzedaz') return 'FOR SALE'.tr;
    return 'FOR SALE'.tr;
  }

  String _priceText() {
    final rawCurrency = (ad?.currency ?? '').toString().trim();
    // Scraper sometimes puts formatted price+unit into currency field (e.g. "1 850 zł/m").
    // Detect this by checking if currency contains digits — use it directly to avoid duplication.
    if (rawCurrency.isNotEmpty && rawCurrency.contains(RegExp(r'\d'))) {
      return rawCurrency;
    }
    final p = ad?.price;
    if (p == null) return rawCurrency.isNotEmpty ? rawCurrency : '-';
    final formatted = NumberFormat.decimalPattern('fr')
        .format(p is num ? p.round() : (num.tryParse(p.toString()) ?? 0));
    return rawCurrency.isEmpty ? formatted : '$formatted $rawCurrency';
  }

  String _titleText() {
    final t = (ad?.title ?? '').toString().trim();
    return t.isNotEmpty ? t : 'no_title'.tr;
  }

  String _imageUrl() {
    final fromModel = (() {
      final imgs = ad?.images;
      if (imgs is List && imgs.isNotEmpty && imgs.first != null) {
        return imgs.first.toString();
      }
      return '';
    })();

    return (mainImageUrl.isNotEmpty ? mainImageUrl : fromModel).toString();
  }

  Widget _metaRow(Color color, double baseTextSize) {
    final children = <Widget>[];

    final sq =
        (ad?.squareFootageText ?? ad?.squareFootage?.toString() ?? '').toString();
    if (sq.trim().isNotEmpty && sq != '-') {
      children.add(
        _IconText(
          icon: AppIcons.magic(
            color: color,
            width: baseTextSize + 1,
            height: baseTextSize + 1,
          ),
          color: color,
          text: '$sq ㎡',
          baseTextSize: baseTextSize,
        ),
      );
    }

    final rooms = (ad?.roomsText ?? ad?.rooms?.toString() ?? '').toString();
    if (rooms.trim().isNotEmpty && rooms != '-') {
      if (children.isNotEmpty) {
        children.add(
          Text(
            '  |  ',
            style: TextStyle(color: color, fontSize: baseTextSize + 2),
          ),
        );
      }
      children.add(
        _IconText(
          icon: AppIcons.bed(
            color: color,
            width: baseTextSize + 1,
            height: baseTextSize + 1,
          ),
          color: color,
          text: '$rooms ${"Rooms".tr}',
          baseTextSize: baseTextSize,
        ),
      );
    }

    final baths =
        (ad?.bathroomsText ?? ad?.bathrooms?.toString() ?? '').toString();
    if (baths.trim().isNotEmpty && baths != '-') {
      if (children.isNotEmpty) {
        children.add(
          Text(
            '  |  ',
            style: TextStyle(color: color, fontSize: baseTextSize + 2),
          ),
        );
      }
      children.add(
        _IconText(
          icon: AppIcons.bathroom(
            color: color,
            width: baseTextSize + 1,
            height: baseTextSize + 1,
          ),
          color: color,
          text: '$baths ${"Bath".tr}',
          baseTextSize: baseTextSize,
        ),
      );
    }

    return Row(children: children);
  }

  Future<void> _handleOpen(BuildContext context, WidgetRef ref) async {
    if (onOpenOverride != null) {
      await onOpenOverride!.call();
      return;
    }

    await openAdUrl(context, ref, ad, transactionId, clientId, tag);
  }

  void _handleMiddleClick(BuildContext context, WidgetRef ref) {
    if (onMiddleClickOverride != null) {
      onMiddleClickOverride!.call();
      return;
    }

    if (!enableDefaultNmActions) return;

    handleBrowseListRemoveActionNM(
      ref,
      ad,
      context,
      transactionId,
      clientId,
    );
  }

  Widget _buildImage(ThemeColors theme) {
    final imageUrl = _imageUrl().trim();

    if (imageUrl.isEmpty) {
      return _NmCardMediaFallback(
        theme: theme,
        title: _titleText(),
        subtitle: _addressLine(),
      );
    }

    return Image.network(
      imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return _NmCardMediaFallback(
          theme: theme,
          title: _titleText(),
          subtitle: _addressLine(),
        );
      },
      filterQuality: FilterQuality.low,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (isMobile) {
          return Container(
            height: 80,
            margin: const EdgeInsets.only(bottom: 4),
            child: MiddleClickDetector(
              onMiddleClick: () => _handleMiddleClick(context, ref),
              child: PieMenu(
                theme: PieTheme.of(context).copyWith(
                  overlayColor: (() {
                    final theme = ref.watch(themeColorsProvider);
                    final bool uiIsDark =
                        theme.textColor.computeLuminance() > 0.5;
                    final base = uiIsDark ? Colors.black : Colors.white;
                    return base.withValues(alpha: 0.70);
                  })(),
                ),
                onPressedWithDevice: (kind) async {
                  if (kind == PointerDeviceKind.mouse ||
                      kind == PointerDeviceKind.touch) {
                    await _handleOpen(context, ref);
                  }
                },
                actions: buildPieMenuActions,
                child: Hero(
                  tag: tag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: constraints.maxWidth * 0.3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildImage(theme),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            color: theme.sideBarbackground.withAlpha(
                              (255 * 0.9).toInt(),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _addressLine(),
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w300,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _titleText(),
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Text(
                                      _offerLabel(),
                                      style: TextStyle(
                                        color: theme.textColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        _priceText(),
                                        textAlign: TextAlign.end,
                                        style: TextStyle(
                                          color: theme.textColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
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

        double itemWidth = max(150.0, min(constraints.maxWidth, 250.0));
        double baseTextSize = 12 + (itemWidth - 150) / (240 - 150) * (14 - 12);
        baseTextSize = baseTextSize.clamp(12, 14);
        double basePadding = 2 + (itemWidth - 150) / (240 - 150) * (4 - 2);
        basePadding = basePadding.clamp(2, 4);
        double base = 4 + (itemWidth - 150) / (240 - 150) * (10 - 4);
        base = base.clamp(4, 10);

        return AspectRatio(
          aspectRatio: aspectRatio,
          child: MiddleClickDetector(
            onMiddleClick: () => _handleMiddleClick(context, ref),
            child: PieMenu(
              theme: PieTheme.of(context).copyWith(
                overlayColor: (() {
                  final theme = ref.watch(themeColorsProvider);
                  final bool uiIsDark =
                      theme.textColor.computeLuminance() > 0.5;
                  final base = uiIsDark ? Colors.black : Colors.white;
                  return base.withValues(alpha: 0.70);
                })(),
              ),
              onPressedWithDevice: (kind) async {
                if (kind == PointerDeviceKind.mouse ||
                    kind == PointerDeviceKind.touch) {
                  await _handleOpen(context, ref);
                }
              },
              actions: buildPieMenuActions,
              child: Hero(
                tag: tag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AspectRatio(
                        aspectRatio: isTablet ? 1 : 4 / 3,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(10),
                          ),
                          child: _buildImage(theme),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              color: theme.sideBarbackground.withAlpha(
                                (255 * 0.80).toInt(),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: base + 2,
                                  vertical: base,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (_addressLine().isNotEmpty)
                                        Text(
                                          _addressLine(),
                                          style: AppTextStyles.interLight.copyWith(
                                            color: theme.textColor.withAlpha(180),
                                            fontSize: baseTextSize - 1,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      SizedBox(height: basePadding / 2),
                                      Text(
                                        _titleText(),
                                        style: AppTextStyles.interMedium.copyWith(
                                          color: theme.textColor,
                                          fontSize: baseTextSize + 1,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: basePadding),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: _metaRow(
                                          theme.textColor.withAlpha(200),
                                          baseTextSize - 1,
                                        ),
                                      ),
                                      const Spacer(),
                                      Divider(
                                        color: theme.textColor.withAlpha(60),
                                        height: basePadding * 2,
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.textColor.withAlpha(20),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              _offerLabel(),
                                              style: AppTextStyles.interLight.copyWith(
                                                color: theme.textColor.withAlpha(180),
                                                fontSize: baseTextSize - 2,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              _priceText(),
                                              textAlign: TextAlign.end,
                                              style: AppTextStyles.interSemiBold.copyWith(
                                                color: theme.textColor,
                                                fontSize: isTablet
                                                    ? baseTextSize + 1
                                                    : baseTextSize + 2,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
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

class _IconText extends StatelessWidget {
  final Widget icon;
  final String text;
  final Color color;
  final double baseTextSize;

  const _IconText({
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

class _NmCardMediaFallback extends StatelessWidget {
  final ThemeColors theme;
  final String title;
  final String subtitle;

  const _NmCardMediaFallback({
    required this.theme,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.textFieldColor.withAlpha(160),
            theme.dashboardContainer.withAlpha(220),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_work_outlined,
            size: 30,
            color: theme.textColor.withAlpha(220),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          if (subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor.withAlpha(180),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}