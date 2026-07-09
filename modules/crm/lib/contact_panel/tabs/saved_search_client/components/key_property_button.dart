import 'package:crm/contact_panel/tabs/saved_search_client/components/from_filter_components.dart';
import 'package:crm/data/clients/ad_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

class ClientPanelKeyPropertyButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final String filterValue;

  const ClientPanelKeyPropertyButton({
    super.key,
    required this.text,
    required this.filterKey,
    required this.filterValue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final bool isSelected = ref.watch(
      filterButtonProvider.select(
        (state) => state[filterKey] == filterValue,
      ),
    );

    return InkWell(
      onTap: () {
        final filterNotifier = ref.read(filterCacheProvider.notifier);
        if (isSelected) {
          ref
              .read(filterButtonProvider.notifier)
              .updateFilter(filterKey, null);
          filterNotifier.removeFilter(filterKey);
        } else {
          ref
              .read(filterButtonProvider.notifier)
              .updateFilter(filterKey, filterValue);
          filterNotifier.addFilter(filterKey, filterValue);
        }
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 16,
        ), // Add padding for better spacing
        decoration: BoxDecoration(
          color: isSelected ? theme.themeColor : theme.dashboardContainer,
          borderRadius: BorderRadius.circular(8), // Add rounded corners
          border: Border.all(
            color: theme.dashboardBoarder,
          ), // Border for unselected state
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? theme.themeColorText : theme.textColor,
            fontWeight: FontWeight.bold, // Make text bold for better visibility
            fontSize: 14, // Set a readable font size
          ),
        ),
      ),
    );
  }
}
