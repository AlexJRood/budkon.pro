import 'package:flutter/material.dart';
import 'package:crm_fliper/selection_and_negotiations/widgets/custom_vertical_divider.dart';
import 'package:crm_fliper/selection_and_negotiations/widgets/flipper_custom_list_view.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RevenuesWidget extends StatelessWidget {
  final bool isMobile;
  const RevenuesWidget({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: isMobile ? 10.w : 160.0.w, vertical: 20.h),
      child: const SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FlipperCustomListView(title: 'New (6)', itemCount: 10, id: 8),
            CustomVerticalDivider(),
            FlipperCustomListView(title: 'Paid (2)', itemCount: 10, id: 9),
            CustomVerticalDivider(),
            FlipperCustomListView(title: '', itemCount: 0, id: 10),
          ],
        ),
      ),
    );
  }
}
