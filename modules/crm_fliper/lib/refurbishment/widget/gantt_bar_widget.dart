import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GanttBarWidget extends StatelessWidget {
  final double start;
  final double end;
  const GanttBarWidget({super.key, required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: start * 100.w),
        Container(
          height: 24.h,
          width: (end - start) * 100.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.r),
            gradient: const LinearGradient(
              colors: [Colors.cyanAccent, Colors.blueAccent],
            ),
          ),
        ),
      ],
    );
  }
}
