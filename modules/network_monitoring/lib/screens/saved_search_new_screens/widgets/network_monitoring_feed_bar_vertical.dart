import 'dart:ui' as ui;

import 'package:core/shell/pop_manager/pop_page_manager.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:network_monitoring/browselist/widget/pc.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';
import 'package:network_monitoring/screens/map/map_state.dart';
import 'package:network_monitoring/widgets/filter/filter_monitoring_widget.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:portal/feed/components/view/slected_view_provider.dart';
import 'package:portal/screens/filters/widgets/sort_feed.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';

final verticalBottomBarVisibilityProvider = StateProvider<bool>((ref) => true);

class NetworkMonitoringFeedBarVerticalMobile extends ConsumerWidget {
  const NetworkMonitoringFeedBarVerticalMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return EmmaUiAnchorTarget(
      // @emma-backend: NetworkMonitoringEmmaAnchors.feedMobileVerticalBar
      anchorKey: 'network_monitoring.feed.mobile.vertical_bar',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _VerticalBarButtonShell(
            anchorKey: 'network_monitoring.feed.mobile.filters_button',
            theme: theme,
            child: BuildNavigationOption(
              icon: AppIcons.search(color: theme.textColor),
              label: 'Filters'.tr,
              onTap: () => _openFiltersSheet(context, ref),
            ),
          ),
          const SizedBox(height: 2),
          _VerticalBarButtonShell(
            anchorKey: 'network_monitoring.feed.mobile.sort_button',
            theme: theme,
            child: BuildNavigationOption(
              icon: AppIcons.sort(color: theme.textColor),
              label: 'Sort'.tr,
              onTap: () => _openSortSheet(context, ref),
            ),
          ),
          const SizedBox(height: 2),
          _VerticalBarButtonShell(
            anchorKey: 'network_monitoring.feed.mobile.browse_list_button',
            theme: theme,
            child: BuildNavigationOption(
              icon: AppIcons.archive(color: theme.textColor),
              label: 'Browse list'.tr,
              onTap: () => _openBrowseSheet(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFiltersSheet(BuildContext context, WidgetRef ref) async {
    final theme = ref.read(themeColorsProvider);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(6),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: true,
          builder: (ctx, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: 20,
                  sigmaY: 20,
                ),
                child: Container(
                  padding: const EdgeInsets.only(left: 15),
                  color: theme.textFieldColor.withAlpha((255 * 0.35).toInt()),
                  child: EmmaUiAnchorTarget(
                    // @emma-backend: NetworkMonitoringEmmaAnchors.feedMobileFiltersSheet
                    anchorKey:
                        'network_monitoring.feed.mobile.filters_sheet',
                    child: FilterMonitoringWidget(
                      isMobile: true,
                      scrollController: scrollController,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // The sheet can be dismissed by dragging it down or tapping outside,
    // without hitting the explicit "Search" button. Apply any pending
    // filter changes so they aren't silently discarded.
    final cache = ref.read(networkMonitoringFilterCacheProvider.notifier);
    final filterLogic = ref.read(networkMonitoringFilterProvider.notifier);
    if (filterLogic.hasPendingChangesNM(cache)) {
      filterLogic.applyFiltersFromCacheNM(cache);
    }
  }
}

class _VerticalBarButtonShell extends StatelessWidget {
  final String anchorKey;
  final ThemeColors theme;
  final Widget child;

  const _VerticalBarButtonShell({
    required this.anchorKey,
    required this.theme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return EmmaUiAnchorTarget(
      anchorKey: anchorKey,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
          color: theme.dashboardContainer.withAlpha(60),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6.0),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: child,
          ),
        ),
      ),
    );
  }
}

class BuildNavigationOption extends ConsumerWidget {
  const BuildNavigationOption({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: onTap,
      style: elevatedButtonStyleRounded10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Hero(
            tag: 'network_monitoring_vertical_bar_$label',
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [icon],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openBrowseSheet(BuildContext context, WidgetRef ref) async {
  await showHouslyBottomSheet(
    context: context,
    ref: ref,
    title: 'Browse list'.tr,
    initialChildSize: 0.9,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    bodyBuilder: (ctx, ref, controller) {
      final theme = ref.read(themeColorsProvider);

      return EmmaUiAnchorTarget(
        // @emma-backend: NetworkMonitoringEmmaAnchors.feedMobileBrowseSheet
        anchorKey: 'network_monitoring.feed.mobile.browse_sheet',
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(
                child: PieCanvas(
                  theme: PieTheme(
                    rightClickShowsMenu: true,
                    leftClickShowsMenu: false,
                    buttonTheme: PieButtonTheme(
                      backgroundColor: theme.themeColor.withAlpha(
                        (255 * 0.7).toInt(),
                      ),
                      iconColor: AppColors.white,
                    ),
                    buttonThemeHovered: PieButtonTheme(
                      backgroundColor: theme.themeColor,
                      iconColor: AppColors.white,
                    ),
                  ),
                  child: BrowseListNetworkMonitoringPcWidget(
                    sheetScrollController: controller,
                    isWhiteSpaceNeeded: false,
                    isMobile: true,
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

Future<void> _openSortSheet(BuildContext context, WidgetRef ref) async {
  await showHouslyBottomSheet(
    context: context,
    ref: ref,
    title: 'search_options'.tr,
    initialChildSize: 0.5,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    bodyBuilder: (ctx, ref, controller) {
      return EmmaUiAnchorTarget(
        // @emma-backend: NetworkMonitoringEmmaAnchors.feedMobileSortSheet
        anchorKey: 'network_monitoring.feed.mobile.sort_sheet',
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            spacing: 8,
            children: [
              _MapListSwitchRow(ctx: ctx),
              const CardTypeSelector(isNetworkMonitoring: true),
              const DropdownSortSelector(isNetworkMonitoring: true),
            ],
          ),
        ),
      );
    },
  );
}

class _MapListSwitchRow extends ConsumerWidget {
  const _MapListSwitchRow({required this.ctx});

  final BuildContext ctx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final isMapActive = ref.watch(nmMapViewActiveProvider);

    return EmmaUiAnchorTarget(
      // @emma-backend: NetworkMonitoringEmmaAnchors.feedMobileMapListSwitch
      anchorKey: 'network_monitoring.feed.mobile.map_list_switch',
      child: Container(
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Icon(
              isMapActive ? Icons.map_rounded : Icons.view_list_rounded,
              color: theme.textColor,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isMapActive ? 'Mapa'.tr : 'Lista'.tr,
                style: TextStyle(color: theme.textColor),
              ),
            ),
            Switch(
              value: isMapActive,
              onChanged: (value) {
                ref.read(nmMapViewActiveProvider.notifier).state = value;
                Navigator.of(ctx).maybePop();
              },
            ),
          ],
        ),
      ),
    );
  }
}