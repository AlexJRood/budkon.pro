import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:portal/screens/filters/widgets/components/sort_button.dart';
import 'package:core/theme/apptheme.dart';

class DropdownSortSelector extends ConsumerWidget {
  final bool isNetworkMonitoring;
  final bool isTablet;

  const DropdownSortSelector({
    super.key,
    this.isNetworkMonitoring = false,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSort = ref.watch(sortButtonProvider)['sort'] ?? 'date_desc';
    final theme = ref.read(themeColorsProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    final fontSize = isTablet
        ? (((screenWidth - 800) / 400) * 3 + 11).clamp(11.0, 14.0)
        : 14.0;

    final sortOptions = [
      {
        'label': 'sort_price_asc'.tr,
        'value': 'price_asc',
        'icon': Icons.arrow_upward,
      },
      {
        'label': 'sort_price_desc'.tr,
        'value': 'price_desc',
        'icon': Icons.arrow_downward,
      },
      {
        'label': 'sort_newest'.tr,
        'value': 'date_desc',
        'icon': Icons.new_releases,
      },
      {
        'label': 'sort_oldest'.tr,
        'value': 'date_asc',
        'icon': Icons.history,
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 0 : 5),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: isTablet,
          borderRadius: BorderRadius.circular(8),
          dropdownColor: theme.dashboardContainer,
          value: currentSort,
          onChanged: (newValue) {
            // ignore: unused_local_variable
            final selected = sortOptions.firstWhere(
              (el) => el['value'] == newValue,
            );
            ref
                .read(sortButtonProvider.notifier)
                .updateFilter('sort', newValue);
            if (isNetworkMonitoring) {
              ref
                  .read(networkMonitoringFilterCacheProvider.notifier)
                  .addFilterNM('sort', newValue);
              ref
                  .read(networkMonitoringFilterCacheProvider.notifier)
                  .setSortOrderNM(newValue!);
              ref
                  .read(networkMonitoringFilterProvider.notifier)
                  .applyFiltersFromCacheNM(
                    ref.read(networkMonitoringFilterCacheProvider.notifier),
                  );
            } else {
              ref
                  .read(filterCacheProvider.notifier)
                  .addFilter('sort', newValue);
              ref.read(filterCacheProvider.notifier).setSortOrder(newValue!);
              ref
                  .read(filterProvider.notifier)
                  .applyFiltersFromCache(
                    ref.read(filterCacheProvider.notifier),
                    ref,
                  );
            }
          },
          items: sortOptions.map((option) {
            return DropdownMenuItem<String>(
              value: option['value'] as String,
              child: Row(
                children: [
                  Icon(
                    option['icon'] as IconData,
                    size: isTablet ? 16 : 20,
                    color: theme.textColor,
                  ),
                  SizedBox(width: isTablet ? 4 : 8),
                  if (isTablet)
                    Flexible(
                      child: Text(
                        option['label'] as String,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: fontSize,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    Text(
                      option['label'] as String,
                      style: TextStyle(color: theme.textColor),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
