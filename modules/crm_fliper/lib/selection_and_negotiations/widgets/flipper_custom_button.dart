import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FlipperCustomButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;

  const FlipperCustomButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.width = 100,
    this.height = 66,
    this.backgroundColor = const Color.fromRGBO(33, 32, 32, 1),
    this.iconColor = const Color.fromRGBO(233, 233, 233, 1),
    this.textColor = const Color.fromRGBO(233, 233, 233, 1),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 25.sp,
            ),
             SizedBox(height: 4.h), // Adds spacing between icon and text
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
