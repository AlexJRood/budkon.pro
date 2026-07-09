import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/utils.dart';
import 'package:portal/screens/filter_landing_page/components/filters_components.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:portal/screens/filter_landing_page/providers/tag_input_provider.dart';
import 'package:portal/screens/pop_pages/pages/view_pop_changer_page.dart';
import 'package:core/platform/filters/filters_const.dart';
import 'dart:ui' as ui;
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';

class AcceptRowButtonsFilters extends ConsumerWidget {
  final bool isNeedToNavigate;
  final bool isMobile;
  final VoidCallback? onClearFilters;

  const AcceptRowButtonsFilters({
    super.key,
    this.isNeedToNavigate = false,
    this.isMobile = false,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMobile) const Spacer(flex: 5),
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 50,
            child: ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(6),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: ElevatedButton(
                  style: elevatedButtonStyleRounded10,
                  onPressed: () {
                    final currentSearchItems = ref.read(tagInputProvider('search')).items;
                    final currentExcludeItems = ref.read(tagInputProvider('exclude')).items;

                    final cache = ref.read(filterCacheProvider.notifier);
                    cache.clearFilters(ref: ref);
                    ref.read(filterButtonProvider.notifier).clearUiFilters();

                    if (currentSearchItems.isNotEmpty) {
                      cache.addFilter(FilterPopConst.search, currentSearchItems.join(','), ref: ref);
                    }

                    if (currentExcludeItems.isNotEmpty) {
                      cache.addFilter(FilterPopConst.exclude, currentExcludeItems.join(','), ref: ref);
                    }

                    onClearFilters?.call();
                  },
                  child: Text(
                    'Clear filters'.tr,
                    style: AppTextStyles.interMedium.copyWith(
                      fontSize: 12,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        Expanded(
          flex: 2,
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              style: buttonStyleRounded10ThemeRedWithPadding15,
              onPressed: () {
                final cache = ref.read(filterCacheProvider.notifier);
                ref.read(filterProvider.notifier).applyFiltersFromCache(cache, ref);

                Navigator.of(context).pop();
                if (isNeedToNavigate) {
                  String selectedFeedView = ref.read(
                    selectedFeedViewProvider,
                  );
                  ref
                      .read(navigationService)
                      .pushNamedReplacementScreen(selectedFeedView);
                }
              },
              child: Text(
                'apply_filters'.tr,
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
