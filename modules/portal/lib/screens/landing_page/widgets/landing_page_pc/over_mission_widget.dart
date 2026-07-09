import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';

import 'package:portal/screens/landing_page/providers/landing_stats_provider.dart';

class OverMissionWidget extends ConsumerWidget {
  final double paddingDynamic;
  final bool isTablet;

  const OverMissionWidget({
    super.key,
    required this.paddingDynamic,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final statsAsync = ref.watch(landingStatsProvider);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: paddingDynamic,
        vertical: 20,
      ),
      child: isTablet
          ? Column(
              children: [
                _missionImage(),
                const SizedBox(height: 30),
                _missionText(theme,ref),
                const SizedBox(height: 30),
                _missionStats(theme, statsAsync),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _missionImage()),
                const SizedBox(width: 40),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _missionText(theme,ref),
                      const SizedBox(height: 40),
                      _missionStats(theme, statsAsync),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _missionImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        'assets/images/frame_427322549.webp',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _missionText(dynamic theme,WidgetRef ref) {
    return Column(
      crossAxisAlignment:
          isTablet ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'Our Mission'.tr,
          style: AppTextStyles.libreCaslonHeading.copyWith(
            fontSize: isTablet ? 28 : 36,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'company_description'.tr,
          textAlign: isTablet ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: theme.textColor.withAlpha((255 * 0.8).toInt()),
            fontSize: isTablet ? 14 : 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 25),
        Center(
          child: isTablet
              ? ElevatedButton(
                  style: elevatedButtonStyleRounded10,
                  onPressed: () {
                    ref.read(navigationService).pushNamedScreen(Routes.aboutusview);
                  },
                  child: Text(
                    'Learn More'.tr,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(120),
                    ),
                  ),
                )
              : Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    style: elevatedButtonStyleRounded10,
                    onPressed: () {
                      ref.read(navigationService).pushNamedScreen(Routes.aboutusview);
                    },
                    child: Text(
                      'Learn More'.tr,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(120),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }



Widget _missionStats(
  dynamic theme,
  AsyncValue<LandingStats> statsAsync,
) {
  return statsAsync.when(
    data: (stats) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem(
            _formatCompact(stats.usersCount),
            'active_users'.tr,
            theme,
          ),
          _statItem(
            _formatCompact(stats.advertisementsCount),
            'advertisements_count'.tr,
            theme,
          ),
          _statItem(
            _formatCompact(stats.investmentsCount),
            'investments'.tr,
            theme,
          ),
        ],
      );
    },
    loading: () {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _loadingStatItem('active_users'.tr, theme),
          _loadingStatItem('advertisements_count'.tr, theme),
          _loadingStatItem('investments'.tr, theme),
        ],
      );
    },
    error: (error, stackTrace) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem('', 'active_users'.tr, theme),
          _statItem('', 'advertisements_count'.tr, theme),
          _statItem('', 'investments'.tr, theme),
        ],
      );
    },
  );
}

  Widget _statItem(
    String value,
    String label,
    dynamic theme,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: theme.textColor.withAlpha((255 * 0.6).toInt()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingStatItem(
    String label,
    dynamic theme,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: isTablet ? 52 : 72,
            height: isTablet ? 28 : 38,
            decoration: BoxDecoration(
              color: theme.textColor.withAlpha(18),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: theme.textColor.withAlpha((255 * 0.6).toInt()),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompact(int value) {
    if (value <= 0) return '0';

    if (value >= 1000000) {
      final formatted = _trimDecimal(value / 1000000);
      return '${formatted}M+';
    }

    if (value >= 1000) {
      final formatted = _trimDecimal(value / 1000);
      return '${formatted}K+';
    }

    return '$value';
  }

  String _trimDecimal(double value) {
    final fixed = value.toStringAsFixed(1);

    if (fixed.endsWith('.0')) {
      return fixed.substring(0, fixed.length - 2);
    }

    return fixed;
  }
}