import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:core/theme/apptheme.dart';

import 'package:crm_agent/crm/providers/daily_market_overview_provider.dart';

class DashboardDailyMarketOverviewWidget extends ConsumerWidget {
  final bool isMobile;
  final double collapsedHeight;

  const DashboardDailyMarketOverviewWidget({
    super.key,
    this.isMobile = false,
    this.collapsedHeight = 260,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final asyncOverview = ref.watch(dailyMarketOverviewProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : collapsedHeight;

        return asyncOverview.when(
          loading: () => _LoadingCard(
            theme: theme,
            height: cardHeight,
          ),
          error: (error, stack) => _ErrorCard(
            theme: theme,
            height: cardHeight,
          ),
          data: (data) {
            final overview = Map<String, dynamic>.from(data.overview);
            final narrative = Map<String, dynamic>.from(data.narrative);
            final fastestSegments = List<Map<String, dynamic>>.from(
              data.fastestSegments.map((e) => Map<String, dynamic>.from(e)),
            );

            final pulse = _pulseKey(
              (overview['pulse_label'] ?? 'Balanced').toString(),
            );

            final bullets = List<String>.from(
              (narrative['bullets'] as List<dynamic>? ?? const [])
                  .map((e) => e?.toString() ?? '')
                  .where((e) => e.trim().isNotEmpty),
            );

            return _CollapsedOverviewCard(
              theme: theme,
              isMobile: isMobile,
              height: cardHeight,
              city: data.city,
              generatedAt: data.generatedAt,
              sampleSize: data.sampleSize,
              pulseKey: pulse,
              headline:
                  (narrative['headline'] ?? 'market_overview_default_headline')
                      .toString()
                      .tr,
              summary:
                  (narrative['summary'] ?? 'market_overview_default_summary')
                      .toString()
                      .tr,
              bullets: bullets,
              fastestSegments: fastestSegments,
              overview: overview,
              onTap: () => _showOverviewDialog(
                context: context,
                theme: theme,
                data: data,
                isMobile: isMobile,
              ),
            );
          },
        );
      },
    );
  }

  static Future<void> _showOverviewDialog({
    required BuildContext context,
    required ThemeColors theme,
    required dynamic data,
    required bool isMobile,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final screen = MediaQuery.of(dialogContext).size;
        final dialogWidth = math.min(screen.width * 0.92, isMobile ? 760.0 : 1180.0);
        final dialogHeight = math.min(screen.height * 0.88, 920.0);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 28,
            vertical: 20,
          ),
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: theme.dashboardBoarder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((255 * 0.18).toInt()),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 22,
                    isMobile ? 16 : 20,
                    isMobile ? 12 : 16,
                    12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${'market_overview_title_city'.tr} ${data.city.toString()}',
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: isMobile ? 18.sp : 22.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _PopupActionChip(
                        theme: theme,
                        icon: Icons.insights_rounded,
                        label: _popupLabel(),
                      ),
                      SizedBox(width: 10.w),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => Navigator.of(dialogContext).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: theme.adPopBackground,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.dashboardBoarder.withAlpha(
                                  (255 * 0.14).toInt(),
                                ),
                              ),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: theme.textColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: theme.dashboardBoarder.withAlpha((255 * 0.12).toInt()),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 16 : 22),
                    child: _OverviewDetailsContent(
                      theme: theme,
                      data: data,
                      isMobile: isMobile,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _popupLabel() => 'full_view'.tr;

  static String _pulseKey(String value) {
    switch (value.trim().toLowerCase()) {
      case 'hot':
        return 'pulse_hot';
      case 'warm':
        return 'pulse_warm';
      case 'slow':
        return 'pulse_slow';
      default:
        return 'pulse_balanced';
    }
  }
}


class _CollapsedOverviewCard extends StatelessWidget {
  final ThemeColors theme;
  final bool isMobile;
  final double height;
  final String city;
  final String? generatedAt;
  final int sampleSize;
  final String pulseKey;
  final String headline;
  final String summary;
  final List<String> bullets;
  final List<Map<String, dynamic>> fastestSegments;
  final Map<String, dynamic> overview;
  final VoidCallback onTap;

  const _CollapsedOverviewCard({
    required this.theme,
    required this.isMobile,
    required this.height,
    required this.city,
    required this.generatedAt,
    required this.sampleSize,
    required this.pulseKey,
    required this.headline,
    required this.summary,
    required this.bullets,
    required this.fastestSegments,
    required this.overview,
    required this.onTap,
  });

  String _formatGeneratedAt() {
    if (generatedAt == null || generatedAt!.isEmpty) {
      return 'market_overview_not_available'.tr;
    }

    try {
      final dt = DateTime.parse(generatedAt!).toLocal();
      return DateFormat('dd.MM.yyyy • HH:mm').format(dt);
    } catch (_) {
      return generatedAt!;
    }
  }

  Color _pulseColor() {
    switch (pulseKey) {
      case 'pulse_hot':
        return Colors.redAccent;
      case 'pulse_warm':
        return Colors.orangeAccent;
      case 'pulse_slow':
        return Colors.blueGrey;
      default:
        return theme.themeColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pulseColor = _pulseColor();

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight <= 270;
              final narrow = constraints.maxWidth <= 700;

              final horizontalPadding = compact ? 14.0 : 18.0;
              final verticalPadding = compact ? 10.0 : 16.0;
              final titleFont = compact ? 17.sp : 18.sp;
              final summaryLines = compact ? 2 : 3;
              final showThirdMetric = !narrow;
              final metricsCount = showThirdMetric ? 3 : 2;

              final metrics = [
                _PreviewMetricData(
                  title: 'market_overview_active_inventory'.tr,
                  value: _Formatters.number(overview['active_inventory']),
                ),
                _PreviewMetricData(
                  title: 'market_overview_new_7_days'.tr,
                  value: _Formatters.number(overview['new_listings_7d']),
                ),
                _PreviewMetricData(
                  title: 'market_overview_median_days'.tr,
                  value: _Formatters.decimal(overview['median_days_on_market']),
                ),
              ].take(metricsCount).toList();

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${'market_overview_title_city'.tr} $city',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: titleFont,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              SizedBox(
                                height: 34,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  children: [
                                    _HeaderChip(
                                      theme: theme,
                                      background: pulseColor.withAlpha((255 * 0.15).toInt()),
                                      foreground: pulseColor,
                                      label: pulseKey.tr,
                                    ),
                                    SizedBox(width: 8.w),
                                    _HeaderChip(
                                      theme: theme,
                                      background: theme.adPopBackground,
                                      foreground: theme.textColor.withAlpha((255 * 0.82).toInt()),
                                      label: _formatGeneratedAt(),
                                    ),
                                    SizedBox(width: 8.w),
                                    _HeaderChip(
                                      theme: theme,
                                      background: theme.adPopBackground,
                                      foreground: theme.textColor.withAlpha((255 * 0.82).toInt()),
                                      label: '${'market_overview_based_on'.tr} ${sampleSize.toString()}'
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: theme.adPopBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.dashboardBoarder.withAlpha((255 * 0.10).toInt()),
                            ),
                          ),
                          child: Icon(
                            Icons.open_in_full_rounded,
                            color: theme.themeColor,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: List.generate(metrics.length, (index) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: index == metrics.length - 1 ? 0 : 10,
                            ),
                            child: _PreviewMetricTile(
                              theme: theme,
                              title: metrics[index].title,
                              value: metrics[index].value,
                              compact: compact,
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 12.h),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: compact ? 6 : 14,
                        ),
                        decoration: BoxDecoration(
                          color: theme.adPopBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.dashboardBoarder.withAlpha((255 * 0.10).toInt()),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              headline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: compact ? 13.sp : 14.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: compact ? 2.h : 6.h),
                            Expanded(
                              child: Text(
                                summary,
                                maxLines: summaryLines,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.textColor.withAlpha((255 * 0.78).toInt()),
                                  fontSize: compact ? 11.5.sp : 12.sp,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            if (!compact && bullets.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                '• ${bullets.first.tr}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.textColor.withAlpha((255 * 0.70).toInt()),
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
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
    );
  }
}

class _PreviewMetricData {
  final String title;
  final String value;

  const _PreviewMetricData({
    required this.title,
    required this.value,
  });
}

class _PreviewMetricTile extends StatelessWidget {
  final ThemeColors theme;
  final String title;
  final String value;
  final bool compact;

  const _PreviewMetricTile({
    required this.theme,
    required this.title,
    required this.value,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 58 : 64,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dashboardBoarder.withAlpha((255 * 0.10).toInt()),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.textColor.withAlpha((255 * 0.65).toInt()),
              fontSize: compact ? 10.sp : 10.5.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: compact ? 3 : 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.textColor,
              fontSize: compact ? 13.sp : 16.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
class _OverviewDetailsContent extends StatelessWidget {
  final ThemeColors theme;
  final dynamic data;
  final bool isMobile;

  const _OverviewDetailsContent({
    required this.theme,
    required this.data,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final overview = Map<String, dynamic>.from(data.overview);
    final narrative = Map<String, dynamic>.from(data.narrative);
    final saleSnapshot = Map<String, dynamic>.from(data.saleSnapshot);
    final rentSnapshot = Map<String, dynamic>.from(data.rentSnapshot);
    final fastestSegments = List<Map<String, dynamic>>.from(
      data.fastestSegments.map((e) => Map<String, dynamic>.from(e)),
    );

    final pulse = DashboardDailyMarketOverviewWidget._pulseKey(
      (overview['pulse_label'] ?? 'Balanced').toString(),
    );

    final bullets = List<String>.from(
      (narrative['bullets'] as List<dynamic>? ?? const [])
          .map((e) => e?.toString() ?? '')
          .where((e) => e.trim().isNotEmpty),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 920;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderSection(
              theme: theme,
              city: data.city,
              generatedAt: data.generatedAt,
              sampleSize: data.sampleSize,
              pulseKey: pulse,
            ),
            SizedBox(height: 18.h),
            if (isCompact) ...[
              _NarrativeCard(
                theme: theme,
                narrative: narrative,
                bullets: bullets,
              ),
              SizedBox(height: 14.h),
              _MetricsGrid(
                theme: theme,
                width: width,
                overview: overview,
              ),
              SizedBox(height: 14.h),
              _SecondaryGrid(
                theme: theme,
                width: width,
                overview: overview,
                saleSnapshot: saleSnapshot,
                rentSnapshot: rentSnapshot,
                currency: data.currency,
                fastestSegments: fastestSegments,
              ),
            ] else ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 7,
                      child: _MetricsGrid(
                        theme: theme,
                        width: width * 0.58,
                        overview: overview,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      flex: 5,
                      child: _NarrativeCard(
                        theme: theme,
                        narrative: narrative,
                        bullets: bullets,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              _SecondaryGrid(
                theme: theme,
                width: width,
                overview: overview,
                saleSnapshot: saleSnapshot,
                rentSnapshot: rentSnapshot,
                currency: data.currency,
                fastestSegments: fastestSegments,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PopupActionChip extends StatelessWidget {
  final ThemeColors theme;
  final IconData icon;
  final String label;

  const _PopupActionChip({
    required this.theme,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.dashboardBoarder.withAlpha((255 * 0.10).toInt()),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.themeColor,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}


class _HeaderSection extends StatelessWidget {
  final ThemeColors theme;
  final String city;
  final String? generatedAt;
  final int sampleSize;
  final String pulseKey;

  const _HeaderSection({
    required this.theme,
    required this.city,
    required this.generatedAt,
    required this.sampleSize,
    required this.pulseKey,
  });

  String _formatGeneratedAt() {
    if (generatedAt == null || generatedAt!.isEmpty) {
      return 'market_overview_not_available'.tr;
    }

    try {
      final dt = DateTime.parse(generatedAt!).toLocal();
      return DateFormat('dd.MM.yyyy • HH:mm').format(dt);
    } catch (_) {
      return generatedAt!;
    }
  }

  Color _pulseColor() {
    switch (pulseKey) {
      case 'pulse_hot':
        return Colors.redAccent;
      case 'pulse_warm':
        return Colors.orangeAccent;
      case 'pulse_slow':
        return Colors.blueGrey;
      default:
        return theme.themeColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pulseColor = _pulseColor();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _HeaderChip(
          theme: theme,
          background: pulseColor.withAlpha((255 * 0.15).toInt()),
          foreground: pulseColor,
          label: pulseKey.tr,
        ),
        _HeaderChip(
          theme: theme,
          background: theme.themeColor.withAlpha((255 * 0.10).toInt()),
          foreground: theme.themeColor,
          label: '${'market_overview_city_chip'.tr} $city',
        ),
        _HeaderChip(
          theme: theme,
          background: theme.adPopBackground,
          foreground: theme.textColor.withAlpha((255 * 0.82).toInt()),
          label: '${'market_overview_updated'.tr} ${_formatGeneratedAt()}',
        ),
        _HeaderChip(
          theme: theme,
          background: theme.adPopBackground,
          foreground: theme.textColor.withAlpha((255 * 0.82).toInt()),
          label: '${'market_overview_based_on'.tr} ${sampleSize.toString()}',
        ),
        _HeaderChip(
          theme: theme,
          background: theme.themeColor.withAlpha((255 * 0.10).toInt()),
          foreground: theme.themeColor,
          label: 'market_overview_emma_placeholder'.tr,
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final ThemeColors theme;
  final Color background;
  final Color foreground;
  final String label;

  const _HeaderChip({
    required this.theme,
    required this.background,
    required this.foreground,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 11.sp,
        ),
      ),
    );
  }
}

class _NarrativeCard extends StatelessWidget {
  final ThemeColors theme;
  final Map<String, dynamic> narrative;
  final List<String> bullets;

  const _NarrativeCard({
    required this.theme,
    required this.narrative,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    final headline =
        (narrative['headline'] ?? 'market_overview_default_headline')
            .toString()
            .tr;
    final summary =
        (narrative['summary'] ?? 'market_overview_default_summary')
            .toString()
            .tr;

    return Container(
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.dashboardBoarder.withAlpha((255 * 0.10).toInt()),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                color: theme.themeColor.withAlpha((255 * 0.75).toInt()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 13,
                        color: theme.themeColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'market_overview_summary_title'.tr,
                        style: TextStyle(
                          color: theme.themeColor,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    headline,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    summary,
                    style: TextStyle(
                      color: theme.textColor.withAlpha((255 * 0.78).toInt()),
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.55,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Divider(
                    color: theme.dashboardBoarder.withAlpha((255 * 0.12).toInt()),
                    height: 1,
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Icon(
                        Icons.signal_cellular_alt_rounded,
                        size: 13,
                        color: theme.textColor.withAlpha((255 * 0.65).toInt()),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'market_overview_key_signals'.tr,
                        style: TextStyle(
                          color: theme.textColor.withAlpha((255 * 0.75).toInt()),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  if (bullets.isEmpty)
                    Text(
                      'market_overview_no_signals'.tr,
                      style: TextStyle(
                        color: theme.textColor.withAlpha((255 * 0.65).toInt()),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    Column(
                      children: bullets.take(4).map((item) {
                        return _InsightBullet(
                          theme: theme,
                          text: item.tr,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightBullet extends StatelessWidget {
  final ThemeColors theme;
  final String text;

  const _InsightBullet({
    required this.theme,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: theme.themeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: theme.textColor.withAlpha((255 * 0.82).toInt()),
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final ThemeColors theme;
  final double width;
  final Map<String, dynamic> overview;

  const _MetricsGrid({
    required this.theme,
    required this.width,
    required this.overview,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricData(
        title: 'market_overview_active_inventory'.tr,
        value: _Formatters.number(overview['active_inventory']),
        change: null,
        icon: Icons.inventory_2_outlined,
      ),
      _MetricData(
        title: 'market_overview_new_7_days'.tr,
        value: _Formatters.number(overview['new_listings_7d']),
        change: _Formatters.percent(overview['new_listings_7d_change_pct']),
        icon: Icons.north_east_rounded,
      ),
      _MetricData(
        title: 'market_overview_removed_7_days'.tr,
        value: _Formatters.number(overview['removed_listings_7d']),
        change: _Formatters.percent(overview['removed_listings_7d_change_pct']),
        icon: Icons.south_east_rounded,
      ),
      _MetricData(
        title: 'market_overview_median_days'.tr,
        value: _Formatters.decimal(overview['median_days_on_market']),
        change: _Formatters.percent(overview['median_days_on_market_change_pct']),
        icon: Icons.timelapse_rounded,
      ),
      _MetricData(
        title: 'market_overview_velocity_score'.tr,
        value: _Formatters.decimal(overview['velocity_score']),
        change: null,
        icon: Icons.bolt_rounded,
      ),
      _MetricData(
        title: 'market_overview_24h_flow'.tr,
        value:
            '${_Formatters.number(overview['new_listings_24h'])} / ${_Formatters.number(overview['removed_listings_24h'])}',
        change: null,
        icon: Icons.compare_arrows_rounded,
      ),
    ];

    final cols = width >= 480 ? 3 : 2;
    final rowCount = (metrics.length / cols).ceil();
    final dividerColor = theme.dashboardBoarder.withAlpha((255 * 0.10).toInt());

    return Container(
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        children: List.generate(rowCount, (rowIdx) {
          final start = rowIdx * cols;
          final end = math.min(start + cols, metrics.length);
          final rowItems = metrics.sublist(start, end);

          return Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  children: [
                    for (int i = 0; i < rowItems.length; i++) ...[
                      if (i > 0)
                        VerticalDivider(width: 1, color: dividerColor),
                      Expanded(
                        child: _MetricCell(theme: theme, data: rowItems[i]),
                      ),
                    ],
                  ],
                ),
              ),
              if (rowIdx < rowCount - 1)
                Divider(height: 1, color: dividerColor),
            ],
          );
        }),
      ),
    );
  }
}

class _MetricData {
  final String title;
  final String value;
  final String? change;
  final IconData icon;

  const _MetricData({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
  });
}

class _MetricCell extends StatelessWidget {
  final ThemeColors theme;
  final _MetricData data;

  const _MetricCell({
    required this.theme,
    required this.data,
  });

  Color _changeColor(String? value) {
    if (value == null || value == '-') {
      return theme.textColor.withAlpha((255 * 0.45).toInt());
    }
    if (value.startsWith('+')) return Colors.redAccent;
    if (value.startsWith('-')) return Colors.greenAccent.shade400;
    return theme.textColor.withAlpha((255 * 0.45).toInt());
  }

  @override
  Widget build(BuildContext context) {
    final hasChange = data.change != null && data.change != '-';
    final changeColor = _changeColor(data.change);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, size: 13, color: theme.themeColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor.withAlpha((255 * 0.55).toInt()),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.value,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          if (hasChange)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: changeColor.withAlpha((255 * 0.12).toInt()),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                data.change!,
                style: TextStyle(
                  color: changeColor,
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            Text(
              'market_overview_live_market_data'.tr,
              style: TextStyle(
                color: theme.textColor.withAlpha((255 * 0.35).toInt()),
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _SecondaryGrid extends StatelessWidget {
  final ThemeColors theme;
  final double width;
  final Map<String, dynamic> overview;
  final Map<String, dynamic> saleSnapshot;
  final Map<String, dynamic> rentSnapshot;
  final String currency;
  final List<Map<String, dynamic>> fastestSegments;

  const _SecondaryGrid({
    required this.theme,
    required this.width,
    required this.overview,
    required this.saleSnapshot,
    required this.rentSnapshot,
    required this.currency,
    required this.fastestSegments,
  });

  int _columns(double width) {
    if (width >= 1280) return 3;
    if (width >= 860) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final cols = _columns(width);
    const spacing = 12.0;

    final priceCard = _PriceSnapshotCard(
      theme: theme,
      saleSnapshot: saleSnapshot,
      rentSnapshot: rentSnapshot,
      currency: currency,
    );
    final flowCard = _MarketFlowCard(theme: theme, overview: overview);
    final segmentsCard = _FastestSegmentsCard(
      theme: theme,
      fastestSegments: fastestSegments,
    );

    if (cols == 1) {
      return Column(
        children: [
          priceCard,
          const SizedBox(height: spacing),
          flowCard,
          const SizedBox(height: spacing),
          segmentsCard,
        ],
      );
    }

    if (cols == 3) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: priceCard),
            const SizedBox(width: spacing),
            Expanded(child: flowCard),
            const SizedBox(width: spacing),
            Expanded(child: segmentsCard),
          ],
        ),
      );
    }

    // cols == 2
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: priceCard),
              const SizedBox(width: spacing),
              Expanded(child: flowCard),
            ],
          ),
        ),
        const SizedBox(height: spacing),
        segmentsCard,
      ],
    );
  }
}

class _PriceSnapshotCard extends StatelessWidget {
  final ThemeColors theme;
  final Map<String, dynamic> saleSnapshot;
  final Map<String, dynamic> rentSnapshot;
  final String currency;

  const _PriceSnapshotCard({
    required this.theme,
    required this.saleSnapshot,
    required this.rentSnapshot,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final saleChange =
        _Formatters.percent(saleSnapshot['average_price_change_pct']);
    final rentChange =
        _Formatters.percent(rentSnapshot['average_price_change_pct']);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dashboardBoarder.withAlpha((255 * 0.10).toInt()),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'market_overview_price_snapshot'.tr,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 14.h),
          _MiniPriceRow(
            theme: theme,
            icon: Icons.home_outlined,
            title: 'market_overview_sale'.tr,
            value: _Formatters.pricePerM2(
              saleSnapshot['average_price_per_sqm'],
              currency,
            ),
            change: saleChange,
            sampleSize: saleSnapshot['sample_size'],
          ),
          SizedBox(height: 12.h),
          Divider(
            color: theme.dashboardBoarder.withAlpha((255 * 0.10).toInt()),
            height: 1,
          ),
          SizedBox(height: 12.h),
          _MiniPriceRow(
            theme: theme,
            icon: Icons.key_outlined,
            title: 'market_overview_rent'.tr,
            value: _Formatters.pricePerM2(
              rentSnapshot['average_price_per_sqm'],
              currency,
            ),
            change: rentChange,
            sampleSize: rentSnapshot['sample_size'],
          ),
        ],
      ),
    );
  }
}

class _MiniPriceRow extends StatelessWidget {
  final ThemeColors theme;
  final IconData icon;
  final String title;
  final String value;
  final String change;
  final dynamic sampleSize;

  const _MiniPriceRow({
    required this.theme,
    required this.icon,
    required this.title,
    required this.value,
    required this.change,
    required this.sampleSize,
  });

  Color _changeColor() {
    if (change == '-') {
      return theme.textColor.withAlpha((255 * 0.55).toInt());
    }
    if (change.startsWith('+')) {
      return Colors.redAccent;
    }
    return Colors.greenAccent.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: theme.themeColor.withAlpha((255 * 0.10).toInt()),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Icon(icon, size: 14, color: theme.themeColor),
          ),
        ),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                color: theme.themeColor,
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              '$change • ${'market_overview_based_on_short'.tr} ${(sampleSize ?? 0).toString()}',
              style: TextStyle(
                color: _changeColor(),
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MarketFlowCard extends StatelessWidget {
  final ThemeColors theme;
  final Map<String, dynamic> overview;

  const _MarketFlowCard({
    required this.theme,
    required this.overview,
  });

  @override
  Widget build(BuildContext context) {
    final newCount = _Formatters.toDouble(overview['new_listings_7d']);
    final removedCount = _Formatters.toDouble(overview['removed_listings_7d']);
    final total = newCount + removedCount;

    final newRatio = total > 0 ? (newCount / total).clamp(0.0, 1.0) : 0.5;
    final removedRatio =
        total > 0 ? (removedCount / total).clamp(0.0, 1.0) : 0.5;

    String signalKey;
    if (removedCount > newCount * 1.1) {
      signalKey = 'market_overview_flow_demand_ahead';
    } else if (newCount > removedCount * 1.1) {
      signalKey = 'market_overview_flow_supply_ahead';
    } else {
      signalKey = 'market_overview_flow_balanced';
    }

    final newFlex = math.max(1, (newRatio * 1000).round());
    final removedFlex = math.max(1, (removedRatio * 1000).round());

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dashboardBoarder.withAlpha((255 * 0.10).toInt()),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'market_overview_market_flow'.tr,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            signalKey.tr,
            style: TextStyle(
              color: theme.themeColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                flex: newFlex,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.themeColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: removedFlex,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha((255 * 0.85).toInt()),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: _FlowLegend(
                  theme: theme,
                  color: theme.themeColor,
                  label: 'market_overview_new_7_days'.tr,
                  value: _Formatters.number(overview['new_listings_7d']),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _FlowLegend(
                  theme: theme,
                  color: Colors.redAccent,
                  label: 'market_overview_removed_7_days'.tr,
                  value: _Formatters.number(overview['removed_listings_7d']),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlowLegend extends StatelessWidget {
  final ThemeColors theme;
  final Color color;
  final String label;
  final String value;

  const _FlowLegend({
    required this.theme,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: TextStyle(
              color: theme.textColor.withAlpha((255 * 0.78).toInt()),
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _FastestSegmentsCard extends StatelessWidget {
  final ThemeColors theme;
  final List<Map<String, dynamic>> fastestSegments;

  const _FastestSegmentsCard({
    required this.theme,
    required this.fastestSegments,
  });

  String _segmentPulseKey(String value) {
    switch (value.trim().toLowerCase()) {
      case 'hot':
        return 'pulse_hot';
      case 'warm':
        return 'pulse_warm';
      case 'slow':
        return 'pulse_slow';
      default:
        return 'pulse_balanced';
    }
  }

  Color _segmentPulseColor(String pulseKey) {
    switch (pulseKey) {
      case 'pulse_hot':
        return Colors.redAccent;
      case 'pulse_warm':
        return Colors.orangeAccent;
      case 'pulse_slow':
        return Colors.blueGrey;
      default:
        return theme.themeColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dashboardBoarder.withAlpha((255 * 0.10).toInt()),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'market_overview_fastest_segments'.tr,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12.h),
          if (fastestSegments.isEmpty)
            Text(
              'market_overview_no_segments'.tr,
              style: TextStyle(
                color: theme.textColor.withAlpha((255 * 0.70).toInt()),
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fastestSegments.take(5).map((item) {
                final propertyType =
                    (item['property_type'] ?? 'Unknown').toString().tr;
                final label = (item['label'] ?? 'Balanced').toString();
                final pulseKey = _segmentPulseKey(label);
                final pulseColor = _segmentPulseColor(pulseKey);

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: pulseColor.withAlpha((255 * 0.10).toInt()),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: pulseColor.withAlpha((255 * 0.25).toInt()),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: pulseColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '$propertyType • ${pulseKey.tr}',
                        style: TextStyle(
                          color: pulseColor,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final ThemeColors theme;
  final double height;

  const _LoadingCard({
    required this.theme,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dashboardBoarder.withAlpha((255 * 0.15).toInt()),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.themeColor,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'market_overview_loading'.tr,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final ThemeColors theme;
  final double height;

  const _ErrorCard({
    required this.theme,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.red.withAlpha((255 * 0.22).toInt()),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'market_overview_error'.tr,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Formatters {
  static double toDouble(dynamic value) {
    if (value == null) return 0;
    return double.tryParse(value.toString()) ?? 0;
  }

  static String number(dynamic value) {
    final parsed = double.tryParse((value ?? '').toString());
    if (parsed == null) return '-';
    return NumberFormat('#,##0', Get.locale?.toLanguageTag()).format(parsed);
  }

  static String decimal(dynamic value) {
    final parsed = double.tryParse((value ?? '').toString());
    if (parsed == null) return '-';
    return NumberFormat('#,##0.##', Get.locale?.toLanguageTag()).format(parsed);
  }

  static String percent(dynamic value) {
    final parsed = double.tryParse((value ?? '').toString());
    if (parsed == null) return '-';

    final formatted = NumberFormat(
      '#,##0.##',
      Get.locale?.toLanguageTag(),
    ).format(parsed.abs());

    if (parsed > 0) return '+$formatted%';
    if (parsed < 0) return '-$formatted%';
    return '0%';
  }

  static String pricePerM2(dynamic value, String currency) {
    final parsed = double.tryParse((value ?? '').toString());
    if (parsed == null) return '-';

    final formatted = NumberFormat(
      '#,##0.##',
      Get.locale?.toLanguageTag(),
    ).format(parsed);
    return '$formatted $currency/m²';
  }
}