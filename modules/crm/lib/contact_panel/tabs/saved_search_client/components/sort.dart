import 'package:crm/data/clients/ad_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:portal/screens/filters/widgets/components/sort_button.dart';
import 'package:core/theme/apptheme.dart';

class ClientPanelDropdownSortSelector extends ConsumerWidget {
  const ClientPanelDropdownSortSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSort = ref.watch(sortButtonProvider)['sort'] ?? 'price_asc';
    final theme = ref.read(themeColorsProvider);

    final sortOptions = [
      {
        'label': 'Cena rosnąco'.tr,
        'value': 'price_asc',
        'icon': Icons.arrow_upward,
      },
      {
        'label': 'Cena malejąco'.tr,
        'value': 'price_desc',
        'icon': Icons.arrow_downward,
      },
      {
        'label': 'Najnowsze'.tr,
        'value': 'date_desc',
        'icon': Icons.new_releases,
      },
      {'label': 'Najstarsze'.tr, 'value': 'date_asc', 'icon': Icons.history},
    ];

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        borderRadius: BorderRadius.circular(8),
        dropdownColor: theme.dashboardContainer,
        value: currentSort,
        onChanged: (newValue) {
          // ignore: unused_local_variable
          final selected = sortOptions.firstWhere(
            (el) => el['value'] == newValue,
          );
          ref.read(sortButtonProvider.notifier).updateFilter('sort', newValue);
          ref.read(filterCacheProvider.notifier).addFilter('sort', newValue);
          ref.read(filterCacheProvider.notifier).setSortOrder(newValue!);
          ref
              .read(filterProvider.notifier)
              .applyFiltersFromCache(
                ref.read(filterCacheProvider.notifier),
                ref,
              );
        },
        items:
            sortOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option['value'] as String,
                child: Row(
                  children: [
                    Icon(
                      option['icon'] as IconData,
                      size: 20,
                      color: theme.textColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      option['label'] as String,
                      style: TextStyle(color: theme.textColor),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}
