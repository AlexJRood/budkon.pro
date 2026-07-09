import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:portal/screens/feed/components/cards/selected_card.dart';
import 'package:network_monitoring/components/cards/selected_card.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';

final viewModeProvider = StateProvider<String>((ref) => 'grid');


enum FeedMapViewMode { feed, map }

class MapFeedToggleSelector extends ConsumerWidget {
  final FeedMapViewMode currentView;
  final String feedRoute;
  final String mapRoute;

  const MapFeedToggleSelector({
    super.key,
    required this.currentView,
    required this.feedRoute,
    required this.mapRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    Widget buildButton({
      required String tooltip,
      required bool selected,
      required Widget icon,
      required VoidCallback onPressed,
    }) {
      return SizedBox(
        height: 40,
        width: 40,
        child: Tooltip(
          message: tooltip,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: selected ? theme.themeColor : theme.dashboardContainer,
          ),
          textStyle: TextStyle(
            color: selected ? AppColors.white : theme.textColor,
            fontSize: 16,
          ),
          child: ElevatedButton(
            style: selected
                ? buttonStyleRounded10ThemeRed
                : elevatedButtonStyleRounded10,
            onPressed: onPressed,
            child: icon,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildButton(
            tooltip: 'Feed'.tr,
            selected: currentView == FeedMapViewMode.feed,
            icon: Icon(
              Icons.grid_view_rounded,
              size: 18,
              color: currentView == FeedMapViewMode.feed
                  ? AppColors.white
                  : theme.textColor,
            ),
            onPressed: () {
              if (currentView == FeedMapViewMode.feed) return;
              ref.read(navigationService).pushNamedReplacementScreen(feedRoute);
            },
          ),
          buildButton(
            tooltip: 'Map'.tr,
            selected: currentView == FeedMapViewMode.map,
            icon: Icon(
              Icons.map_rounded,
              size: 18,
              color: currentView == FeedMapViewMode.map
                  ? AppColors.white
                  : theme.textColor,
            ),
            onPressed: () {
              if (currentView == FeedMapViewMode.map) return;
              ref.read(navigationService).pushNamedReplacementScreen(mapRoute);
            },
          ),
        ],
      ),
    );
  }
}
class CardTypeSelector extends ConsumerWidget {
  final bool isNetworkMonitoring;
  const CardTypeSelector({super.key, this.isNetworkMonitoring = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = isNetworkMonitoring
        ? ref.watch(selectedCardProviderNM)
        : ref.watch(selectedCardProvider);
    final theme = ref.read(themeColorsProvider);

    final cardOptions = isNetworkMonitoring
        ? [
            {
              'label': 'Grid'.tr,
              'value': CardTypeNM.vanda,
              'icon': (Color? c) => AppIcons.gridView(color: c),
            },
            {
              'label': 'list'.tr,
              'value': CardTypeNM.list,
              'icon': (Color? c) => AppIcons.viewList(color: c),
            },
            {
              'label': 'Full'.tr,
              'value': CardTypeNM.full,
              'icon': (Color? c) => AppIcons.expand(color: c),
            },
          ]
        : [
            {
              'label': 'Grid'.tr,
              'value': CardType.vanda,
              'icon': (Color? c) => AppIcons.gridView(color: c),
            },
            {
              'label': 'list'.tr,
              'value': CardType.list,
              'icon': (Color? c) => AppIcons.viewList(color: c),
            },
            {
              'label': 'Full'.tr,
              'value': CardType.full,
              'icon': (Color? c) => AppIcons.expand(color: c),
            },
          ];

    return Container(
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: cardOptions.map((option) {
          final isSelected = selected == option['value'];
          final iconBuilder = option['icon'] as Widget Function(Color?);
          final iconColor = isSelected ? AppColors.white : theme.textColor;

          return SizedBox(
            height: 40,
            width: 40,
            child: Tooltip(
              message: option['label'] as String,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: isSelected
                    ? theme.themeColor
                    : theme.dashboardContainer,
              ),
              textStyle: TextStyle(
                color: isSelected ? AppColors.white : theme.textColor,
                fontSize: 18,
              ),
              child: ElevatedButton(
                style: isSelected
                    ? buttonStyleRounded10ThemeRed
                    : elevatedButtonStyleRounded10,
                onPressed: () {
                  if (isNetworkMonitoring) {
                    ref.read(selectedCardProviderNM.notifier).state =
                        option['value'] as CardTypeNM;
                  } else {
                    ref.read(selectedCardProvider.notifier).state =
                        option['value'] as CardType;
                  }
                },
                child: iconBuilder(iconColor),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}