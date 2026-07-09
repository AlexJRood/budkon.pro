import 'package:crm_fliper/selection_and_negotiations/selection_and_negotiation_pc_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/apptheme.dart';

class FlipperCustomTapBar extends ConsumerWidget {
  const FlipperCustomTapBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final color = theme.themeColor;
    final textColor = theme.textColor;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 418.w,
        height: 44.h,
        decoration: BoxDecoration(
          color: theme.themeColor.withAlpha((255 * 0.3).toInt()),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SelectionNegotiationTapBar(
              color: color,
              textColor: textColor,
              ref: ref,
              index: 0,
              title: "Negotiations",
              selectIndex: () => ref.read(tabIndexProvider.notifier).state = 0,
              tabIndex: ref.watch(tabIndexProvider),
            ),
            SelectionNegotiationTapBar(
              color: color,
              textColor: textColor,
              ref: ref,
              index: 1,
              title: "Refurbishment",
              selectIndex: () => ref.read(tabIndexProvider.notifier).state = 1,
              tabIndex: ref.watch(tabIndexProvider),
            ),
            SelectionNegotiationTapBar(
              color: color,
              textColor: textColor,
              ref: ref,
              index: 2,
              title: "Sale",
              selectIndex: () => ref.read(tabIndexProvider.notifier).state = 2,
              tabIndex: ref.watch(tabIndexProvider),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectionNegotiationTapBar extends ConsumerWidget {
  final WidgetRef ref;
  final int index;
  final String title;
  final void Function()? selectIndex;
  final int tabIndex;
  final Color color;
  final Color textColor;
  const SelectionNegotiationTapBar({
    super.key,
    required this.title,
    required this.ref,
    required this.index,
    required this.selectIndex,
    required this.tabIndex,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = tabIndex == index;
    final theme = ref.read(themeColorsProvider);

    return Expanded(
      child: GestureDetector(
        onTap: selectIndex,
        child: Container(
          width: 130,
          height: 45.h,
          decoration: BoxDecoration(
            color: isSelected ? color : theme.dashboardContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                color:
                    isSelected
                        ? theme.themeTextColor
                        : theme.textColor.withAlpha((255 * 0.5).toInt()),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
