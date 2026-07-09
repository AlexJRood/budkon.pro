
import 'package:crm/contact_panel/tabs/saved_search_client/components/from_filter_components.dart';
import 'package:crm/data/clients/ad_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:core/theme/apptheme.dart';


















class ClientPanelAdditionalInfoFilteredButton extends ConsumerWidget {
  final String text;
  final String filterKey;
  final VoidCallback? onClick; // <- zmiana typu
  final bool hasBorder;
  final double height;
  final bool hasIcon;

  

  const ClientPanelAdditionalInfoFilteredButton({
    super.key,
    required this.text,
    required this.filterKey,
    this.onClick,
    this.hasBorder = true,
    this.height = 48,
    this.hasIcon = false,

  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final bool isSelected = ref.watch(
      filterButtonProvider.select((state) => state[filterKey] ?? false),
    );

    return InkWell(
      onTap: () {
        final filterNotifier = ref.read(filterCacheProvider.notifier);
        if (isSelected) {
          ref.read(filterButtonProvider.notifier).updateFilter(filterKey, false);
          filterNotifier.removeFilter(filterKey);
        } else {
          ref.read(filterButtonProvider.notifier).updateFilter(filterKey, true);
          filterNotifier.addFilter(filterKey, 'true');
        }
        onClick?.call(); // <- NA PRAWDĘ wywołaj callback
      },
      child: Container(
        constraints: BoxConstraints(minWidth: 120, minHeight: height),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.themeColor : theme.dashboardContainer,
          borderRadius: BorderRadius.circular(8),
          border: hasBorder ? Border.all(color: theme.dashboardBoarder) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if(hasIcon)...[              
              FaIcon(
                isSelected ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                color: isSelected ? theme.dashboardContainer : theme.textColor,
                size: 18,
              ),       
              const SizedBox(width:8)
            ],

            Text(
              text,
              style: TextStyle(
                color: isSelected ? theme.themeColorText : theme.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                // opcjonalnie:
                decorationColor: isSelected ? theme.dashboardContainer : theme.textColor,
                decorationThickness: 2, // np. 1–2
              ),
            ),

          ],
        ),
      ),
    );
  }
}
