import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:portal/screens/filters/filters_page.dart';
import 'package:core/common/autocompletion/provider/autocompletion_provider.dart';

import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;
import 'package:core/theme/apptheme.dart';
import 'package:portal/screens/filter_landing_page/components/filters_components.dart';

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
    if (isTablet) {
      return _buildTabletLayout(context, ref);
    }

    return _buildPcLayout(context, ref);
  }

  Widget _buildTabletLayout(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final tag = UniqueKey().toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Clear (Full Width)
          InkWell(
            onTap: () {
              ref.read(filterCacheProvider.notifier).clearFilters();
              ref.read(filterButtonProvider.notifier).clearUiFilters();
              ref
                  .read(myTextFieldViewModelProvider('portal').notifier)
                  .clear();
              ref.read(filterProvider.notifier).applyFiltersFromCache(
                    ref.read(filterCacheProvider.notifier),
                    ref,
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
                  style: AppTextStyles.interMedium14.copyWith(
                    color: theme.textColor,
                  ),
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
                        pageBuilder: (_, __, ___) => FiltersPage(tag: tag),
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
                        style: AppTextStyles.interMedium.copyWith(
                          color: theme.textColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Search pill
              Expanded(
                child: InkWell(
                  onTap: () {
                    ref.read(filterProvider.notifier).applyFiltersFromCache(
                          ref.read(filterCacheProvider.notifier),
                          ref,
                        );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.themeColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'Search'.tr,
                        style: AppTextStyles.interMedium.copyWith(
                          color: AppColors.white,
                          fontSize: 12,
                        ),
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
    final theme = ref.watch(themeColorsProvider);
    final tag = UniqueKey().toString();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: IntrinsicHeight(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15.0,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 12.h,
                  children: [
                    Row(
                      spacing: 12.h,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: ElevatedButton(
                              style: elevatedButtonStyleRounded10withoutPadding,
                              onPressed: () {
                                ref
                                    .read(filterCacheProvider.notifier)
                                    .clearFilters(ref: ref);
                                ref
                                    .read(filterButtonProvider.notifier)
                                    .clearUiFilters();
                                ref
                                    .read(
                                      myTextFieldViewModelProvider(
                                        'portal',
                                      ).notifier,
                                    )
                                    .clear();
                                ref
                                    .read(filterProvider.notifier)
                                    .applyFiltersFromCache(
                                      ref.read(filterCacheProvider.notifier),
                                      ref,
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
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: ElevatedButton(
                              style: elevatedButtonStyleRounded10withoutPadding,
                              onPressed: () {
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    opaque: false,
                                    pageBuilder: (_, __, ___) =>
                                        FiltersPage(tag: tag),
                                    transitionsBuilder: (_, anim, __, child) {
                                      return FadeTransition(
                                        opacity: anim,
                                        child: child,
                                      );
                                    },
                                  ),
                                );
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
                          flex: 3,
                          child: Center(
                            child: ElevatedButton(
                              style: elevatedButtonStyleRounded10withoutPadding,
                              onPressed: () {
                                ref
                                    .read(filterProvider.notifier)
                                    .applyFiltersFromCache(
                                      ref.read(filterCacheProvider.notifier),
                                      ref,
                                    );
                              },
                              child: Material(
                                color: Colors.transparent,
                                child: Container(
                                  height: 40.h,
                                  decoration: BoxDecoration(
                                    color: theme.themeColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Search'.tr,
                                      style: AppTextStyles.interMedium12dark
                                          .copyWith(
                                            color: AppColors.white,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
