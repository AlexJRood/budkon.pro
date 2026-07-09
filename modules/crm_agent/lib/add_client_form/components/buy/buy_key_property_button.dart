import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_agent/add_client_form/provider/buy_filter_provider.dart';
import 'package:crm_agent/add_client_form/components/buy/buy_from_filter_components.dart';
import 'package:core/theme/apptheme.dart';

class CrmAddKeyPropertyButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;

  const CrmAddKeyPropertyButton({
    super.key,
    required this.text,
    required this.filterKey,
    required this.filterValue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final bool isSelected = ref.watch(
      buyOfferfilterButtonProvider.select(
        (state) => state[filterKey] == filterValue,
      ),
    );

    return InkWell(
      onTap: () {
        final filterNotifier = ref.read(buyOfferFilterCacheProvider.notifier);
        if (isSelected) {
          ref
              .read(buyOfferfilterButtonProvider.notifier)
              .updateFilter(filterKey, null);
          filterNotifier.removeFilter(filterKey);
        } else {
          ref
              .read(buyOfferfilterButtonProvider.notifier)
              .updateFilter(filterKey, filterValue);
          filterNotifier.addFilter(filterKey, filterValue);
        }
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 46),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 16,
        ), // Add padding for better spacing
        decoration: BoxDecoration(
          color: isSelected ? theme.textColor : theme.dashboardContainer,
          borderRadius: BorderRadius.circular(8), // Add rounded corners
          border: Border.all(
            color: theme.dashboardBoarder,
          ), // Border for unselected state
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? theme.dashboardContainer : theme.textColor,
            fontWeight: FontWeight.bold, // Make text bold for better visibility
            fontSize: 14, // Set a readable font size
          ),
        ),
      ),
    );
  }
}
