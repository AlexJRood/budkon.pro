import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';

class NegotiationHistoryListViewWidget extends StatelessWidget {
  const NegotiationHistoryListViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      addAutomaticKeepAlives: false,
      cacheExtent: 300.0,
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            spacing: 10.h,
            children: [
              const SizedBox(),
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monday, Feb 01, 2025',
                    style: TextStyle(
                        color: Color.fromRGBO(145, 145, 145, 1),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500),
                  ),
                  Expanded(
                      child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.0.w),
                    child: Divider(),
                  ))
                ],
              ),
              Container(
                height: 50.h,
                width: MediaQuery.of(context).size.width,
                decoration:
                    const BoxDecoration(color: Color.fromRGBO(41, 41, 41, 1)),
                child: Row(
                  children: [
                    const VerticalDivider(),
                    Expanded(
                      child: Container(
                        padding:  EdgeInsets.symmetric(
                            vertical: 5.h, horizontal: 10.w),
                        child:  Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              spacing: 30.w,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Initial Price:',
                                  style: TextStyle(
                                      color: Color.fromRGBO(200, 200, 200, 1),
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  '\$120,000',
                                  style: TextStyle(
                                      color: Color.fromRGBO(200, 200, 200, 1),
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Seller Offer:',
                                  style: TextStyle(
                                      color: Color.fromRGBO(233, 233, 233, 1),
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '\$118,000',
                                  style: TextStyle(
                                      color: Color.fromRGBO(233, 233, 233, 1),
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
