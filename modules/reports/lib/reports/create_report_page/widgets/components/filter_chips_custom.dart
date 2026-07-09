import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/backgroundgradient.dart';

class CustomFilterChip extends ConsumerWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CustomFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
   
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? CustomColors.secondaryWidgetColor(context, ref) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color:
                isSelected ? Colors.transparent :CustomColors.secondaryWidgetColor(context, ref).withAlpha(153),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:CustomColors.secondaryWidgetTextColor(context, ref),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}




class CustomFilterChipMobile extends ConsumerWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CustomFilterChipMobile({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        width: 140,
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
           color: isSelected ? CustomColors.secondaryWidgetColor(context, ref) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
color:
                isSelected ? Colors.transparent :CustomColors.secondaryWidgetColor(context, ref).withAlpha(153),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(overflow: TextOverflow.ellipsis,
           color:CustomColors.secondaryWidgetTextColor(context, ref),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}


