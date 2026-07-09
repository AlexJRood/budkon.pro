import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_agent/add_client_form/provider/sell_estate_data_provider.dart';
import 'package:crm_agent/add_client_form/components/sell/sell_data_components.dart';
import 'package:core/theme/apptheme.dart';

class CrmAddAdditionalInfoFilteredButton extends ConsumerWidget {
  final String text;
  final String filterKey;

  const CrmAddAdditionalInfoFilteredButton({
    super.key,
    required this.text,
    required this.filterKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSelected = ref.watch(
      sellOfferfilterButtonProvider.select(
        (state) => state[filterKey] ?? false,
      ),
    );
    final theme = ref.watch(themeColorsProvider);

    return InkWell(
      onTap: () {
        final filterNotifier = ref.read(sellOfferFilterCacheProvider.notifier);
        if (isSelected) {
          ref
              .read(sellOfferfilterButtonProvider.notifier)
              .updateFilter(filterKey, false);
          filterNotifier.removeData(filterKey);
        } else {
          ref
              .read(sellOfferfilterButtonProvider.notifier)
              .updateFilter(filterKey, true);
          filterNotifier.addData(filterKey, 'true');
        }
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 120, minHeight: 48),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.textColor : theme.dashboardContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dashboardBoarder),
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
