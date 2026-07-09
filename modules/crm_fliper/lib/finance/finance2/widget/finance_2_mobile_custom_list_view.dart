import 'package:flutter/material.dart';
import 'package:crm_fliper/finance/finance2/widget/finance_2_property_card.dart';
import 'package:crm_fliper/finance/finance2/widget/finance_2_tap_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Finance2MobileCustomListView extends StatelessWidget {
  const Finance2MobileCustomListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Finance2TabBar(),
         SizedBox(height: 10.h), // Added spacing instead of `spacing` property
         Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Icons.sort,
              color: Color.fromRGBO(145, 145, 145, 1),
            ),
            SizedBox(width: 10.w), // Added spacing instead of `spacing` property
            Text(
              'Sort',
              style: TextStyle(
                color: Color.fromRGBO(145, 145, 145, 1),
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
         SizedBox(height: 10.h),
        Expanded(
          child: ListView.builder(
            addAutomaticKeepAlives: false,
            cacheExtent: 300.0,
            itemCount: 10,
            itemBuilder: (context, index) {
              return const Finance2PropertyCard(isMobile: true,);
            },
          ),
        ),
      ],
    );
  }
}
