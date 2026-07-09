import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_agent/add_client_form/provider/buy_filter_provider.dart';
import 'package:crm_agent/add_client_form/components/buy/buy_from_filter_components.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';


// ============================================
// buy_filltered_button.dart (FULL - fixed)
// - now MULTI select using List<String>
// - stores CSV in cache: "1,2,3"
// - "Any" clears selection
// ============================================

class CrmAddMultiFilteredButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;
  final double? minHeight;
  final double? minWidth;
  final AlignmentGeometry? alignment;

  const CrmAddMultiFilteredButton({
    super.key,
    required this.text,
    required this.filterKey,
    required this.filterValue,
    this.minHeight = 46,
    this.minWidth = 40,
    this.alignment,
  });

  bool _isAny() => filterValue.toLowerCase() == 'any';

  int _weight(String v) {
    final vv = v.trim();
    final base = vv.replaceAll('+', '');
    final n = int.tryParse(base);
    if (n == null) return 9999;
    return vv.contains('+') ? (n * 1000) : n;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final _raw = ref.watch(
      buyOfferfilterButtonProvider.select((state) => state[filterKey]),
    );
    final List<String> selected = _raw == null
        ? []
        : _raw is List
            ? List<String>.from(_raw)
            : (_raw is String && _raw.isNotEmpty)
                ? _raw.split(',')
                : [];

    final bool isSelected = _isAny() ? selected.isEmpty : selected.contains(filterValue);

    return InkWell(
      onTap: () {
        final cache = ref.read(buyOfferFilterCacheProvider.notifier);
        final uiNotifier = ref.read(buyOfferfilterButtonProvider.notifier);

        if (_isAny()) {
          // Clear selection
          uiNotifier.updateFilter(filterKey, <String>[]);
          cache.removeFilter(filterKey);
          return;
        }

        final next = [...selected];

        if (next.contains(filterValue)) {
          next.remove(filterValue);
        } else {
          next.add(filterValue);
        }

        next.sort((a, b) => _weight(a).compareTo(_weight(b)));

        uiNotifier.updateFilter(filterKey, next);

        if (next.isEmpty) {
          cache.removeFilter(filterKey);
        } else {
          cache.addFilter(filterKey, next.join(','));
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
        alignment: alignment ?? Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? theme.textColor : theme.dashboardContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.dashboardBoarder,
          ),
        ),
        child: Text(
          text.tr,
          style: TextStyle(
            color: isSelected ? theme.dashboardContainer : theme.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}



class CrmAddFilteredButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;
  final double? minHeight;
  final double? minWidth;
  final AlignmentGeometry? alignment;

  const CrmAddFilteredButton({
    super.key,
    required this.text,
    required this.filterKey,
    required this.filterValue,
    this.minHeight = 46,
    this.minWidth = 40,
    this.alignment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final bool isSelected = ref.watch(buyOfferfilterButtonProvider
        .select((state) => state[filterKey] == filterValue));

    return InkWell(
      onTap: () {
        final filterNotifier = ref.read(buyOfferFilterCacheProvider.notifier);
        if (isSelected) {
          ref.read(buyOfferfilterButtonProvider.notifier).updateFilter(filterKey, null);
          filterNotifier.removeFilter(filterKey);
        } else {
          ref
              .read(buyOfferfilterButtonProvider.notifier)
              .updateFilter(filterKey, filterValue);
          filterNotifier.addFilter(filterKey, filterValue);
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
        alignment: alignment ?? Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? theme.textColor : theme.dashboardContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.dashboardBoarder,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? theme.dashboardContainer : theme.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
