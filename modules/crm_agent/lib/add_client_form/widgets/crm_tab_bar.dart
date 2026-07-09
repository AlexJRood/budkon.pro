import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

/// ① Animowany pill-style tab bar dla formularza CRM Add.
/// Wspólny dla mobile, tablet i PC.
class CrmTabBar extends StatelessWidget {
  final String selectedTab;
  final ValueChanged<String> onTabSelected;
  final ThemeColors theme;

  const CrmTabBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('VIEW', 'VIEW'.tr),
      ('SELL', 'SELL'.tr),
      ('BUY', 'BUY'.tr),
    ];

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.textFieldColor.withOpacity(0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.bordercolor.withOpacity(0.14)),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = selectedTab == tab.$2;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(tab.$2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isSelected ? theme.themeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.themeColor.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    tab.$2,
                    style: AppTextStyles.interRegular14.copyWith(
                      color: isSelected
                          ? Colors.white
                          : theme.textColor.withOpacity(0.55),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
