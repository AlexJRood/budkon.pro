import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';

import 'package:network_monitoring/widgets/filter/fileds.dart';
import 'package:core/theme/apptheme.dart';

class EstateTypeFilteredButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;

  const EstateTypeFilteredButton({
    super.key,
    required this.text,
    required this.filterKey,
    required this.filterValue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> selectedValues = List<String>.from(
      ref.watch(
        networkMonitoringFilterButtonProvider.select(
          (state) => state[filterKey] ?? [],
        ),
      ),
    );
    final bool isSelected =
        selectedValues.isNotEmpty && selectedValues.first == filterValue;
    final theme = ref.watch(themeColorsProvider);

    return InkWell(
      onTap: () {
        List<String> newSelection = isSelected ? [] : [filterValue];

        ref
            .read(networkMonitoringFilterButtonProvider.notifier)
            .updateFilterNM(filterKey, newSelection);
        ref
            .read(networkMonitoringFilterCacheProvider.notifier)
            .addFilterNM(filterKey, newSelection.join(','));
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 175, minHeight: 48),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? theme.themeColor : theme.dashboardContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            maxLines: 1,
            style: TextStyle(
              color: isSelected ? theme.themeTextColor : theme.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
