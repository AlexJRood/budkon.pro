import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:network_monitoring/screens/network_home_page/widgets/network_home_filter_pop_widget.dart';
import 'package:network_monitoring/widgets/filter/controllers.dart';
import 'package:core/common/autocompletion/provider/autocompletion_provider.dart';

import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';
import 'package:network_monitoring/widgets/filter/fileds.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/button_style.dart';

class FilterButtonsWidget extends ConsumerWidget {
  final dynamic navigationHistoryProvider;
  final bool isMobile;
  final bool isTablet;

  const FilterButtonsWidget({
    super.key,
    this.isMobile = false,
    this.isTablet = false,
    required this.navigationHistoryProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isMobile) {
      return _buildMobileLayout(context, ref);
    }

    if (isTablet) {
      return _buildTabletLayout(context, ref);
    }

    return _buildPcLayout(context, ref);
  }

  Widget _buildTabletLayout(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Clear (Full Width)
          InkWell(
            onTap: () {
              final controllers = ref.read(nmControllersProvider);
              controllers.clearAll(ref);
              ref.read(networkMonitoringFilterCacheProvider.notifier).clearFiltersNM();
              ref.read(networkMonitoringFilterButtonProvider.notifier).clearUiFiltersNM(ref);
              ref.read(networkMonitoringFilterProvider.notifier).applyFiltersFromCacheNM(
                    ref.read(networkMonitoringFilterCacheProvider.notifier),
                  );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.textColor.withAlpha(50)),
              ),
              child: Center(
                child: Text(
                  'Clear'.tr,
                  style: AppTextStyles.interMedium14.copyWith(color: theme.textColor),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Row 2: All Filters & Search
          Row(
            spacing: 8,
            children: [
              // All filters pill
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (_, __, ___) => NetworkHomeFilterPopWidget(),
                        transitionsBuilder: (_, anim, __, child) {
                          return FadeTransition(opacity: anim, child: child);
                        },
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.textColor.withAlpha(100)),
                    ),
                    child: Center(
                      child: Text(
                        'All Filters'.tr,
                        style: AppTextStyles.interMedium.copyWith(color: theme.textColor, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Search pill
              Expanded(
                child: InkWell(
                  onTap: () {
                    ref
                        .read(networkMonitoringFilterProvider.notifier)
                        .applyFiltersFromCacheNM(
                          ref.read(networkMonitoringFilterCacheProvider.notifier),
                        );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.textColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'Search'.tr,
                        style: AppTextStyles.interMedium.copyWith(color: theme.textFieldColor, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPcLayout(BuildContext context, WidgetRef ref) {
    final tag = UniqueKey().toString();
    final theme = ref.read(themeColorsProvider);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: IntrinsicHeight(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 15.0,
                vertical: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 12.h,
                children: [
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: ElevatedButton(
                        style: elevatedButtonStyleRounded10withoutPadding,
                        onPressed: () {
                          final controllers = ref.read(nmControllersProvider);
                          controllers.clearAll(ref);
                          ref
                              .read(networkMonitoringFilterCacheProvider.notifier)
                              .clearFiltersNM();
                          ref
                              .read(networkMonitoringFilterButtonProvider.notifier)
                              .clearUiFiltersNM(ref);
                          ref
                              .read(networkMonitoringFilterProvider.notifier)
                              .applyFiltersFromCacheNM(
                                ref.read(
                                  networkMonitoringFilterCacheProvider.notifier,
                                ),
                              );
                        },
                        child: Container(
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                'Clear'.tr,
                                style: AppTextStyles.interMedium12dark.copyWith(
                                  color: theme.textColor,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: ElevatedButton(
                        style: elevatedButtonStyleRounded10withoutPadding,
                        onPressed: () {
                          if (isMobile) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                              ),
                              builder: (context) {
                                return DraggableScrollableSheet(
                                  initialChildSize: 0.85,
                                  minChildSize: 0.4,
                                  maxChildSize: 0.95,
                                  expand: false,
                                  builder:
                                      (context, scrollController) =>
                                          NetworkHomeFilterPopWidget(
                                            isMobile: isMobile,
                                            scrollController: scrollController,
                                          ),
                                );
                              },
                            );
                          } else {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                opaque: false,
                                pageBuilder:
                                    (_, __, ___) => NetworkHomeFilterPopWidget(),
                                transitionsBuilder: (_, anim, __, child) {
                                  return FadeTransition(
                                    opacity: anim,
                                    child: child,
                                  );
                                },
                              ),
                            );
                          }
                        },
                        child: Hero(
                          tag: tag,
                          child: Container(
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: theme.textColor),
                            ),
                            child: Center(
                              child: Material(
                                color: Colors.transparent,
                                child: Text(
                                  'All filters'.tr,
                                  style: AppTextStyles.interMedium12dark
                                      .copyWith(
                                        color: theme.textColor,
                                        fontSize: 12.sp,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: ElevatedButton(
                        style: elevatedButtonStyleRounded10withoutPadding,
                        onPressed: () {
                          ref
                              .read(networkMonitoringFilterProvider.notifier)
                              .applyFiltersFromCacheNM(
                                ref.read(
                                  networkMonitoringFilterCacheProvider.notifier,
                                ),
                              );
                          if (isMobile) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: theme.textColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                'Search'.tr,
                                style: AppTextStyles.interMedium.copyWith(
                                  color: theme.textFieldColor,
                                  fontSize: 12.sp,
                                ),
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
  }

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    // Current mobile layout is likely the same as PC for now but just in case
    return _buildPcLayout(context, ref);
  }
}
