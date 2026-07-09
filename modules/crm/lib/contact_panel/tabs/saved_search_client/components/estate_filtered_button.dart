import 'package:crm/contact_panel/tabs/saved_search_client/components/from_filter_components.dart';
import 'package:crm/data/clients/ad_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';




class ClientPanelEstateTypeFilteredButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;

  const ClientPanelEstateTypeFilteredButton({
    super.key,
    required this.text,
    required this.filterKey,
    required this.filterValue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// Get selected value (only one allowed)
    final List<String> selectedValues = List<String>.from(
      ref.watch(
        filterButtonProvider.select((state) => state[filterKey] ?? []),
      ),
    );

    final bool isSelected =
        selectedValues.isNotEmpty && selectedValues.first == filterValue;
    final theme = ref.watch(themeColorsProvider);

    return InkWell(
      onTap: () {
        List<String> newSelection =
            isSelected ? [] : [filterValue]; // ✅ Only one selection allowed

        ref
            .read(filterButtonProvider.notifier)
            .updateFilter(filterKey, newSelection);
        ref
            .read(filterCacheProvider.notifier)
            .addFilter(filterKey, newSelection.join(','));
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 175, minHeight: 48),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? theme.themeColor : theme.dashboardContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: Align(
          alignment: Alignment.center,
          child: Text(
            text,
            maxLines: 1,
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
