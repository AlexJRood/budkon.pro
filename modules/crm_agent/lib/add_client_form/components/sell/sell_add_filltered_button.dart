import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_agent/add_client_form/provider/sell_estate_data_provider.dart';
import 'package:crm_agent/add_client_form/components/buy/buy_from_filter_components.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';

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
    this.minHeight = 40,
    this.minWidth = 40,
    this.alignment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final bool isSelected = ref.watch(
      buyOfferfilterButtonProvider.select(
        (state) => state[filterKey] == filterValue,
      ),
    );

    return ElevatedButton(
      style: elevatedButtonStyleRounded10withoutPadding,
      onPressed: () {
        final filterNotifier = ref.read(sellOfferFilterCacheProvider.notifier);
        if (isSelected) {
          ref
              .read(buyOfferfilterButtonProvider.notifier)
              .updateFilter(filterKey, null);
          filterNotifier.removeData(filterKey);
        } else {
          ref
              .read(buyOfferfilterButtonProvider.notifier)
              .updateFilter(filterKey, filterValue);
          filterNotifier.addData(filterKey, filterValue);
        }
      },
      child: Container(
        constraints:
            (minHeight != null || minWidth != null)
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
          border: Border.all(color: isSelected ? theme.textColor : theme.dashboardBoarder),
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
