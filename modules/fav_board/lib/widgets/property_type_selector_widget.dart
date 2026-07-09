import 'package:fav_board/providers/portal_board_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

import 'package:get/get_utils/get_utils.dart';

class PropertyTypeSelector extends ConsumerWidget {
  final bool isMobile;

  const PropertyTypeSelector({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedBoard = ref.watch(selectedBoardProvider);
    final selected = ref.watch(selectedPropertyTypeProvider);
    final theme = ref.read(themeColorsProvider);
    final Set<String> optionsSet = {};

    if (selectedBoard != null && selectedBoard.advertisements != null) {
      for (final ad in selectedBoard.advertisements!) {
        if (ad.estateType != null && ad.estateType!.isNotEmpty) {
          optionsSet.add(ad.estateType!);
        }
      }
    }

    final List<String> options = ['All'.tr, ...optionsSet];

    if (isMobile) {
      return SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sort by:'.tr,
                style: TextStyle(
                  color: theme.textColor.withAlpha((255 * 0.6).toInt()),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((type) {
                final isSelected =
                    (type == 'All'.tr && selected == null) || selected == type;

                return ListTile(
                  title: Text(
                    type,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing:
                      isSelected
                          ? Icon(Icons.check, color: theme.textColor)
                          : null,
                  onTap: () {
                    ref.read(selectedPropertyTypeProvider.notifier).state =
                        type == 'All'.tr ? null : type;
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
      );
    }

    // Desktop layout
    return Row(
      children:
          options.map((type) {
            final isSelected =
                (type == 'All'.tr && selected == null) || selected == type;

            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: GestureDetector(
                onTap: () {
                  ref.read(selectedPropertyTypeProvider.notifier).state =
                      type == 'All'.tr ? null : type;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? theme.themeColor : Colors.transparent,
                    border: Border.all(color: theme.textColor),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: Text(
                      type,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.white : theme.textColor,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
