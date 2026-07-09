import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';
import 'package:network_monitoring/widgets/filter/fileds.dart';
import 'package:core/theme/apptheme.dart';

class FilteredMultiButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;
  final double? minHeight;
  final double? minWidth;
  final AlignmentGeometry? alignment;

  const FilteredMultiButton({
    super.key,
    required this.text,
    required this.filterKey,
    required this.filterValue,
    this.minHeight = 46,
    this.minWidth = 46,
    this.alignment,
  });

  Set<String> _parseToSet(dynamic raw) {
    if (raw == null) return <String>{};
    if (raw is String) {
      if (raw.trim().isEmpty || raw == 'any') return <String>{};
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();
    }
    if (raw is Iterable) {
      return raw.map((e) => e.toString()).toSet();
    }
    return <String>{};
  }

  String _joinFromSet(Set<String> set) {
    // English comment: Keep stable ordering; put "6+" at the end.
    final items = set.toList();
    int rank(String v) {
      if (v == '6+') return 999;
      final n = int.tryParse(v);
      return n ?? 998;
    }

    items.sort((a, b) => rank(a).compareTo(rank(b)));
    return items.join(',');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final rawValue = ref.watch(
      networkMonitoringFilterButtonProvider.select((state) => state[filterKey]),
    );

    final selectedSet = _parseToSet(rawValue);
    final bool isSelected = selectedSet.contains(filterValue);

    return InkWell(
      onTap: () {
        final buttonNotifier =
            ref.read(networkMonitoringFilterButtonProvider.notifier);
        final cacheNotifier =
            ref.read(networkMonitoringFilterCacheProvider.notifier);

        // English comment: "Any" clears the whole multi-selection.
        if (filterValue == 'any') {
          buttonNotifier.updateFilterNM(filterKey, null);
          cacheNotifier.removeFilterNM(filterKey);
          return;
        }

        final next = {...selectedSet};
        if (next.contains(filterValue)) {
          next.remove(filterValue);
        } else {
          next.add(filterValue);
        }

        if (next.isEmpty) {
          buttonNotifier.updateFilterNM(filterKey, null);
          cacheNotifier.removeFilterNM(filterKey);
        } else {
          final joined = _joinFromSet(next);
          buttonNotifier.updateFilterNM(filterKey, joined);
          cacheNotifier.addFilterNM(filterKey, joined);
        }
      },
      child: Container(
        constraints: (minHeight != null || minWidth != null)
            ? BoxConstraints(
                minHeight: minHeight ?? 0,
                minWidth: minWidth ?? 0,
              )
            : null,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        alignment: alignment ?? Alignment.centerLeft,
        decoration: BoxDecoration(
          color: isSelected ? theme.themeColor : theme.dashboardContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? theme.themeTextColor : theme.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
