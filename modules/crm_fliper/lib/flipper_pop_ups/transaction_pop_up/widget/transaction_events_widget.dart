import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/icons.dart';

class TransActionEventsWidget extends StatelessWidget {
  final bool isMobile;
  const TransActionEventsWidget({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 450.h,
      width: isMobile ? null : MediaQuery.of(context).size.width,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.r),
        color: const Color.fromRGBO(33, 32, 32, 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Events',
                style: TextStyle(
                  color: Color.fromRGBO(255, 255, 255, 1),
                  fontSize: 16.sp,
                ),
              ),
              AppIcons.add(
                color: Color.fromRGBO(233, 233, 233, 1),
                height: 24.h,
                width: 24.h,
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              addAutomaticKeepAlives: false,
              cacheExtent: 300.0,
              itemCount: 2,
              itemBuilder: (context, index) {
                return Container(
                  constraints: BoxConstraints(minHeight: 74.h),
                  margin: EdgeInsets.symmetric(vertical: 10.h),
                  width: MediaQuery.of(context).size.width,
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(41, 41, 41, 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 74.h, child: VerticalDivider()),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 5.h,
                            horizontal: 10.w,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Negotiation meeting',
                                style: TextStyle(
                                  color: Color.fromRGBO(166, 227, 184, 1),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'December 17, 10:30-12:00',
                                style: TextStyle(
                                  color: Color.fromRGBO(255, 255, 255, 1),
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Location: Warszawa, Mokotów, Poland',
                                style: TextStyle(
                                  color: Color.fromRGBO(255, 255, 255, 1),
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
