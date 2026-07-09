import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_agent/add_client_form/provider/sell_estate_data_provider.dart';
import 'package:crm_agent/add_client_form/components/sell/sell_data_components.dart';
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
        sellOfferfilterButtonProvider.select((state) => state[filterKey] ?? []),
      ),
    );
    final theme = ref.watch(themeColorsProvider);
    final bool isSelected =
        selectedValues.isNotEmpty && selectedValues.first == filterValue;

    return InkWell(
      onTap: () {
        List<String> newSelection = isSelected ? [] : [filterValue];

        ref
            .read(sellOfferfilterButtonProvider.notifier)
            .updateFilter(filterKey, newSelection);
        ref
            .read(sellOfferFilterCacheProvider.notifier)
            .addData(filterKey, newSelection.join(','));
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
              color: isSelected ? theme.textFieldColor : theme.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
