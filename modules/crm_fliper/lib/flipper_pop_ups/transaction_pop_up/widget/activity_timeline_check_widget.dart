import 'package:flutter/material.dart';
import 'package:core/theme/icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ActivityTimelineCheckWidget extends StatelessWidget {
  final String title;
  final String date;
  final bool isMobile;
  const ActivityTimelineCheckWidget(
      {super.key,
      required this.title,
      required this.date,
      this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              height: 30.h,
              width: 30.h,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: Colors.transparent,
                  border: Border.all(
                      color: const Color.fromRGBO(200, 200, 200, 1))),
              child: Center(
                child:
                    AppIcons.check(color: Color.fromRGBO(200, 200, 200, 1)),
              ),
            ),
            Container(
              height: 70.h,
              width: 1.w,
              color: Colors.white,
            )
          ],
        ),
         SizedBox(width: 20.w),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10.h,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:  TextStyle(
                      color: Color.fromRGBO(255, 255, 255, 1),
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp),
                ),
                Text(
                  date,
                  style:  TextStyle(
                      color: Color.fromRGBO(145, 145, 145, 1),
                      fontWeight: FontWeight.w400,
                      fontSize: 12.sp),
                ),
              ],
            ),
            if (isMobile)
              Padding(
                padding:  EdgeInsets.symmetric(horizontal: 28.0.w),
                child: Container(
                  padding:
                       EdgeInsets.symmetric(vertical: 5.h, horizontal: 10.w),
                  decoration: const BoxDecoration(
                      border: Border(
                          left: BorderSide(
                              color: Color.fromRGBO(87, 148, 221, 1)))),
                  child:  Column(
                    children: [
                      Row(
                        spacing: 20.w,
                        children: [
                          Text(
                            'Initial Price:',
                            style: TextStyle(
                                color: Color.fromRGBO(200, 200, 200, 1),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '\$120,000',
                            style: TextStyle(
                                color: Color.fromRGBO(200, 200, 200, 1),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Row(
                        spacing: 20.w,
                        children: [
                          Text(
                            'Seller Offer:',
                            style: TextStyle(
                                color: Color.fromRGBO(233, 233, 233, 1),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '\$118,000',
                            style: TextStyle(
                                color: Color.fromRGBO(233, 233, 233, 1),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        )
      ],
    );
  }
}
