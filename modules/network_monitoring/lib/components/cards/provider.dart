import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:network_monitoring/components/cards/selected_card.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';

final viewModeProviderNM = StateProvider<String>((ref) => 'grid');

class CardTypeSelectorNM extends ConsumerWidget {
  final bool isClientView;
  /// Gdy `true` – pokazuje tylko ikony, a label wyświetla się w tooltipie.
  final bool compact;

  const CardTypeSelectorNM({
    super.key,
    this.isClientView = false,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCardProviderNM);
    final theme = ref.read(themeColorsProvider);

    final cardOptions = [
      {
        'label': 'Grid'.tr,
        'value': CardTypeNM.vanda,
        'icon': ({Color? color}) => AppIcons.gridView(color: color),
      },
      {
        'label': 'List'.tr,
        'value': CardTypeNM.list,
        'icon': ({Color? color}) => AppIcons.viewList(color: color),
      },
      {
        'label': 'Full'.tr,
        'value': CardTypeNM.full,
        'icon': ({Color? color}) => AppIcons.expand(color: color),
      },
      {
        'label': 'Map'.tr,
        'value': CardTypeNM.map,
        'icon': ({Color? color}) => AppIcons.mapView(color: color),
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(6)
      ),
      child: Row(
        children: cardOptions.map((option) {
          final label = option['label'] as String;
          final value = option['value'] as CardTypeNM;
          final isSelected = selected == value;
          final iconBuilder = option['icon'] as Widget Function({Color? color});
          final iconColor = isSelected ? Colors.white : theme.textColor;
      
          // zawartość przycisku – zależnie od trybu
          final Widget button = compact
              ? ElevatedButton(
                  onPressed: () => ref.read(selectedCardProviderNM.notifier).state = value,
                  style: isSelected ? buttonStyleRounded10ThemeRed : elevatedButtonStyleRounded10,
                  child: iconBuilder(color: iconColor),
                )
              : ElevatedButton.icon(
                  onPressed: () => ref.read(selectedCardProviderNM.notifier).state = value,
                  icon: iconBuilder(color: iconColor),
                  label: Text(
                    label,
                    style: TextStyle(color: isSelected ? Colors.white : theme.textColor),
                  ),
                  style: isSelected ? buttonStyleRounded10ThemeRed : elevatedButtonStyleRounded10,
                );
      
          return Tooltip(
              message: label,
              waitDuration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: theme.textFieldColor,
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle: TextStyle(color: theme.textColor),
              child: SizedBox(
                width: compact ? 44 : 120,
                height: 35,
                child: button,
              ),
          );
        }).toList(),
      ),
    );
  }
}
