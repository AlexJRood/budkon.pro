import 'package:flutter/material.dart';
import 'package:core/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

final isListProvider = StateProvider<bool>((ref) {
  final settings = ref.watch(settingProvider);
  return settings?.meta['isFinanceListView'] == true;
});

class FinanceViewModeSelector extends ConsumerWidget {
  final VoidCallback? onSelectionChanged;
  final bool isMobile;

  const FinanceViewModeSelector({
    super.key,
    this.onSelectionChanged,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isListView = ref.watch(isListProvider);
    final theme = ref.watch(themeColorsProvider);

    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.textColor.withAlpha(24),
        ),
      ),
      padding: const EdgeInsets.all(3),
      margin: isMobile ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewModeButton(
            label: 'Board'.tr,
            icon: Icons.view_module_rounded,
            selected: !isListView,
            onTap: () => _setMode(ref, false),
          ),
          const SizedBox(width: 3),
          _ViewModeButton(
            label: 'List'.tr,
            icon: Icons.view_list_rounded,
            selected: isListView,
            onTap: () => _setMode(ref, true),
          ),
        ],
      ),
    );
  }

  void _setMode(WidgetRef ref, bool value) {
    ref.read(isListProvider.notifier).state = value;

    ref.read(settingProvider.notifier).editSinglePropertyOfSetting(
      key: 'meta',
      value: {
        ...ref.read(settingProvider)?.meta ?? {},
        'isFinanceListView': value,
      },
    );

    onSelectionChanged?.call();
  }
}

class _ViewModeButton extends ConsumerWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 42,
          height: 39,
          decoration: BoxDecoration(
            color: selected ? theme.themeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: selected
                ? theme.themeTextColor
                : theme.textColor.withAlpha(150),
            size: 21,
          ),
        ),
      ),
    );
  }
}
