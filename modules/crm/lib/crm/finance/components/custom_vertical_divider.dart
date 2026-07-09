import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class CustomVerticalDivider extends StatelessWidget {
  const CustomVerticalDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 2, // Thickness of the divider
      child: DottedBorder(
        color: Colors.grey.shade600, // Dashed line color
        strokeWidth: 1.5,
        dashPattern: const [9, 9], // Adjusted for better spacing
        borderType: BorderType.Rect,
        padding: EdgeInsets.zero,
        child: Container(),
      ),
    );
  }
}
