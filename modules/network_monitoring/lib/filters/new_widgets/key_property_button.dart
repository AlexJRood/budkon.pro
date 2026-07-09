import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';

import 'package:network_monitoring/widgets/filter/fileds.dart';
import 'package:core/theme/apptheme.dart';

class KeyPropertyButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;

  const KeyPropertyButton({
    super.key,
    required this.text,
    required this.filterKey,
    required this.filterValue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSelected = ref.watch(
      networkMonitoringFilterButtonProvider.select(
        (state) => state[filterKey] == filterValue,
      ),
    );
    final theme = ref.watch(themeColorsProvider);

    return InkWell(
      onTap: () {
        final filterNotifier = ref.read(
          networkMonitoringFilterCacheProvider.notifier,
        );
        if (isSelected) {
          ref
              .read(networkMonitoringFilterButtonProvider.notifier)
              .updateFilterNM(filterKey, null);
          filterNotifier.removeFilterNM(filterKey);
        } else {
          ref
              .read(networkMonitoringFilterButtonProvider.notifier)
              .updateFilterNM(filterKey, filterValue);
          filterNotifier.addFilterNM(filterKey, filterValue);
        }
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 16,
        ), // Add padding for better spacing
        decoration: BoxDecoration(
          color: isSelected ? theme.themeColor : theme.dashboardContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? theme.themeTextColor : theme.textColor,
            fontWeight: FontWeight.bold, // Make text bold for better visibility
            fontSize: 14, // Set a readable font size
          ),
        ),
      ),
    );
  }
}
