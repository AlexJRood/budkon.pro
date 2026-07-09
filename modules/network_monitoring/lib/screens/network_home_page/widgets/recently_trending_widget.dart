// screens/network_home_page/widgets/recently_trending_widget.dart
// Tabs + list area. Keeps fixed height to avoid Expanded/Infinity traps.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:network_monitoring/screens/nm_home.dart';
import 'package:network_monitoring/widgets/component.dart';
import 'package:core/theme/apptheme.dart';

class RecentlyTrendingWidget extends ConsumerWidget {
  final bool isMobile;

  const RecentlyTrendingWidget({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRecentlyViewedSelected = ref.watch(monitoringSelectedTabProvider);
    final theme = ref.read(themeColorsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            spacing: 12,
            children: [
              GestureDetector(
                onTap:
                    () => ref
                        .read(monitoringSelectedTabProvider.notifier)
                        .toggleTab(true),
                child: Text(
                  'Recently Viewed'.tr,
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 20,
                    fontWeight: FontWeight.w700,
                    color:
                        isRecentlyViewedSelected
                            ? theme.textColor
                            : theme.textColor.withAlpha((255 * 0.7).toInt()),
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 16),

        // Content (for now: recently viewed list; you can branch by tab if needed)
        const NMRecentlyViewedAds(),
      ],
    );
  }
}
