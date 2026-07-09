import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/landing_page/providers/landing_stats_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:get/get_utils/get_utils.dart';

class OverMissionWidgetMobile extends ConsumerWidget {
  final ThemeColors theme;
  final WidgetRef ref;
  const OverMissionWidgetMobile({super.key, required this.ref, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(landingStatsProvider);

    return Container(
      height: 845,
      color: theme.dashboardContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(6)),
              child: Image.asset(
                'assets/images/frame_427322549.webp',
                height: 222,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Text(
              'Our Mission'.tr,
              style: AppTextStyles.libreCaslonHeading
                  .copyWith(fontSize: 26, fontWeight: FontWeight.bold,
                  color: theme.textColor
                  ),
            ),
            Text(
              'We are a passionate team dedicated to creating meaningful experiences through innovative design and technology. Our mission is to connect people, inspire creativity, and empower communities. With a focus on user-centered solutions, we aim to bridge gaps, solve problems, and bring ideas to life.'.tr,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.textColor
                  ),
            ),
            const SizedBox(height:10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppColors.redBeige,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {

                ref.read(navigationService)
                  .pushNamedScreen(Routes.aboutusview);

              },
              child: Text(
                'Learn More'.tr,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height:10),
            _missionStats(theme, statsAsync),
          ],
        ),
      ),
    );
  }

  Widget _missionStats(
      ThemeColors theme,
      AsyncValue<LandingStats> statsAsync,
      ) {
    return statsAsync.when(
      data: (stats) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _mobileStatItem(
                  _formatCompact(stats.usersCount),
                  'active_users'.tr,
                  theme,
                ),
              ),

              VerticalDivider(
                color: theme.textColor.withAlpha(80),
                thickness: 1,
                width: 16,
              ),

              Expanded(
                child: _mobileStatItem(
                  _formatCompact(stats.advertisementsCount),
                  'advertisements_count'.tr,
                  theme,
                ),
              ),

              VerticalDivider(
                color: theme.textColor.withAlpha(80),
                thickness: 1,
                width: 16,
              ),

              Expanded(
                child: _mobileStatItem(
                  _formatCompact(stats.investmentsCount),
                  'investments'.tr,
                  theme,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _mobileStatItem(
      String value,
      String label,
      ThemeColors theme,
      ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
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
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: theme.textColor.withAlpha(125),
          ),
        ),
      ],
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
