import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';
import 'package:tms_app/todo/provider/task_filters_provider.dart';

class QuickRangeChips extends StatelessWidget {
  final dynamic theme;
  final QuickRange current;
  final void Function(QuickRange) onSelected;

  const QuickRangeChips({
    super.key,
    required this.theme,
    required this.current,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final items = <MapEntry<QuickRange, String>>[
      MapEntry(QuickRange.any, 'Any'.tr),
      MapEntry(QuickRange.today, 'Today'.tr),
      MapEntry(QuickRange.yesterday, 'Yesterday'.tr),
      MapEntry(QuickRange.last7Days, 'Last week'.tr),
      MapEntry(QuickRange.last30Days, 'Last month'.tr),
      MapEntry(QuickRange.next7Days, 'Next week'.tr),
      MapEntry(QuickRange.next30Days, 'Next month'.tr),
      MapEntry(QuickRange.custom, 'Custom'.tr),
    ];

    // ✅ MOBILE: 2-column grid, identical size
    if (isMobile) {
      const double h = 44;
      const double radius = 10;
      const double gap = 12;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: gap,
          mainAxisSpacing: gap,
          childAspectRatio: 3.1, // controls width/height feel
        ),
        itemBuilder: (context, index) {
          final e = items[index];
          final selected = current == e.key;

          return SizedBox(
            height: h,
            child: _FullWidthSelectChip(
              theme: theme,
              radius: radius,
              height: h,
              label: e.value,
              selected: selected,
              onTap: () => onSelected(e.key),
            ),
          );
        },
      );
    }

    // ✅ WEB/DESKTOP: keep your existing Wrap style
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in items)
          Builder(
            builder: (_) {
              final isSelected = current == e.key;

              return ChoiceChip(
                label: Text(
                  e.value,
                  style: TextStyle(
                    color: isSelected
                        ? theme.themeTextColor   // ✅ SELECTED text color
                        : theme.textColor,       // ✅ NORMAL text color
                  ),
                ),
                selected: isSelected,
                selectedColor: theme.themeColor,
                checkmarkColor: theme.themeTextColor,
                backgroundColor: theme.adPopBackground,
                onSelected: (_) => onSelected(e.key),
              );
            },
          ),
      ],
    );
  }
}

/// ✅ FULL-WIDTH custom chip (forces same size + perfect centered text)
class _FullWidthSelectChip extends StatelessWidget {
  final ThemeColors theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double radius;
  final double height;

  const _FullWidthSelectChip({
    required this.theme,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.radius,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? theme.themeColor : theme.dashboardContainer;
    final borderColor = selected
        ? Colors.transparent
        : theme.textColor.withAlpha((255 * 0.45).toInt());

    final textColor = selected ? theme.themeTextColor : theme.textColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Container(
          width: double.infinity, // ✅ force full grid cell width
          height: height, // ✅ fixed height
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              // ✅ left reserved space
              SizedBox(
                width: 24,
                child: selected
                    ? Icon(Icons.check, size: 18, color: textColor)
                    : const SizedBox.shrink(),
              ),

              // ✅ perfectly centered text (won't shift)
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor),
                ),
              ),

              // ✅ right reserved space (balances the left icon)
              const SizedBox(width: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomRangeRow extends StatelessWidget {
  final dynamic theme;
  final DateTime? from;
  final DateTime? to;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onClear;
  final String Function(DateTime?) fmt;

  const CustomRangeRow({
    super.key,
    required this.theme,
    required this.from,
    required this.to,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onClear,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.popupcontainercolor.withAlpha((255 * 0.25).toInt()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.textColor.withAlpha((255 * 0.12).toInt()),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onPickFrom,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.textColor.withAlpha((255 * 0.15).toInt()),
                  ),
                ),
                child: Text(
                  'From: ${fmt(from)}',
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: onPickTo,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.textColor.withAlpha((255 * 0.15).toInt()),
                  ),
                ),
                child: Text(
                  'To: ${fmt(to)}',
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onClear,
            child: Text('Clear'.tr, style: TextStyle(color: theme.textColor)),
          ),
        ],
      ),
    );
  }
}
