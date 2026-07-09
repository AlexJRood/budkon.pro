import 'package:crm/contact_panel/tabs/saved_search_client/components/from_filter_components.dart';
import 'package:crm/data/clients/ad_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

// lib/crm/contact_panel/tabs/saved_search_client/components/multi_value_filtered_button.dart

import 'package:crm/contact_panel/tabs/saved_search_client/components/from_filter_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

class ClientPanelMultiValueFilteredButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;

  final double minWidth;
  final double height;

  const ClientPanelMultiValueFilteredButton({
    super.key,
    required this.text,
    required this.filterKey,
    required this.filterValue,
    this.minWidth = 70,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final List<String> selectedValues = List<String>.from(
      ref.watch(filterButtonProvider.select((state) => state[filterKey] ?? <String>[])),
    );

    final bool isSelected = selectedValues.contains(filterValue);

    return InkWell(
      onTap: () {
        final next = [...selectedValues];

        if (isSelected) {
          next.remove(filterValue);
        } else {
          next.add(filterValue);
        }

        // Optional: sort numeric-like values so it's stable: 1,2,3,4...
        next.sort((a, b) => (int.tryParse(a) ?? 999).compareTo(int.tryParse(b) ?? 999));

        ref.read(filterButtonProvider.notifier).updateFilter(filterKey, next);

        final cache = ref.read(filterCacheProvider.notifier);
        if (next.isEmpty) {
          cache.removeFilter(filterKey);
        } else {
          cache.addFilter(filterKey, next.join(','));
        }
      },
      child: Container(
        constraints: BoxConstraints(minWidth: minWidth, minHeight: height),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.themeColor : theme.dashboardContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? theme.themeColorText : theme.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}




class ClientPanelFilteredButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;
  final double? minHeight;
  final double? minWidth;
  final AlignmentGeometry? alignment;

  const ClientPanelFilteredButton({
    super.key,
    required this.text,
    required this.filterKey,
    required this.filterValue,
    this.minHeight = 48,
    this.minWidth,
    this.alignment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final bool isSelected = ref.watch(filterButtonProvider
        .select((state) => state[filterKey] == filterValue));

    return InkWell(
      onTap: () {
        final filterNotifier = ref.read(filterCacheProvider.notifier);
        if (isSelected) {
          ref.read(filterButtonProvider.notifier).updateFilter(filterKey, null);
          filterNotifier.removeFilter(filterKey);
        } else {
          ref
              .read(filterButtonProvider.notifier)
              .updateFilter(filterKey, filterValue);
          filterNotifier.addFilter(filterKey, filterValue);
        }
      },
      child: Container(
        constraints: (minHeight != null || minWidth != null)
            ? BoxConstraints(
          minHeight: minHeight ?? 40,
          minWidth: minWidth ?? 0,
        )
            : null,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
        alignment: alignment ?? Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? theme.themeColor : theme.dashboardContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.dashboardBoarder,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? theme.themeColorText : theme.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
