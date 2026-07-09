import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_agent/add_client_form/provider/buy_filter_provider.dart';
import 'package:crm_agent/add_client_form/components/buy/buy_from_filter_components.dart';
import 'package:core/theme/apptheme.dart';

class CrmAddEstateTypeFilteredButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;

  const CrmAddEstateTypeFilteredButton({
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
        buyOfferfilterButtonProvider.select((state) => state[filterKey] ?? []),
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
            .read(buyOfferfilterButtonProvider.notifier)
            .updateFilter(filterKey, newSelection);
        ref
            .read(buyOfferFilterCacheProvider.notifier)
            .addFilter(filterKey, newSelection.join(','));
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 175, minHeight: 48),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? theme.textColor : theme.dashboardContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            maxLines: 1,
            style: TextStyle(
              color: isSelected ? theme.dashboardContainer : theme.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
