import 'package:flutter/material.dart';
import 'package:crm_fliper/flipper_pop_ups/transaction_pop_up/widget/transaction_history_mobile.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/icons.dart';

class TransActionDetails extends StatelessWidget {
  final bool isMobile;
  const TransActionDetails({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isMobile ? MediaQuery.of(context).size.width : 340.w,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
          color: const Color.fromRGBO(33, 32, 32, 1),
          border: isMobile
              ? null
              : Border.all(color: const Color.fromRGBO(90, 90, 90, 1))),
      child: Padding(
        padding:  EdgeInsets.symmetric(vertical: 120.0.h),
        child: SingleChildScrollView(
          child: Column(
            spacing: 20,
            children: [
               Text(
                'Transaction Details',
                style: TextStyle(
                    color: Color.fromRGBO(200, 200, 200, 1),
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500),
              ),
               Text(
                '\$100,000',
                style: TextStyle(
                    color: Color.fromRGBO(233, 233, 233, 1),
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold),
              ),
              Container(
                width:isMobile ? double.infinity : 292.w,
                decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color.fromRGBO(90, 90, 90, 1)),
                    borderRadius: BorderRadius.circular(6.r)),
                margin:  EdgeInsets.symmetric(horizontal: 24.w),
                padding:
                     EdgeInsets.symmetric(horizontal: 10.w, vertical: 10),
                child: Column(
                  spacing: 29,
                  children: [
                     Row(
                      spacing: 10,
                      children: [
                        AppIcons.folder(
                          color: Color.fromRGBO(145, 145, 145, 1),
                          height: 24.h,
                          width: 24.w
                        ),
                        Text(
                          'Parker Rd. Allentown',
                          style: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 1),
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700),
                        )
                      ],
                    ),
                    Column(
                      spacing: 3,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          spacing: 10,
                          children: [
                             Text(
                              'Status',
                              style: TextStyle(
                                color: Color.fromRGBO(145, 145, 145, 1),
                                fontSize: 13.sp
                              ),
                            ),
                            Container(
                              width: 85.w,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6.r),
                                  color:
                                      const Color.fromRGBO(166, 227, 184, 0.1)),
                              child:  Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 5.0.h, horizontal: 15.w),
                                child: Text(
                                  'Finalized',
                                  style: TextStyle(
                                      color: Color.fromRGBO(166, 227, 184, 1),
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w200),
                                ),
                              ),
                            )
                          ],
                        ),
                         Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          spacing: 10.w,
                          children: [
                            Text(
                              'Transactions Type ',
                              style: TextStyle(
                                color: Color.fromRGBO(145, 145, 145, 1),
                                  fontSize: 13.sp
                              ),
                            ),
                            Text(
                              'SALE',
                              style: TextStyle(
                                  color: Color.fromRGBO(233, 233, 233, 1),
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500),
                            )
                          ],
                        ),
                         Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          spacing: 10.w,
                          children: [
                            Text(
                              'Transactions ID',
                              style: TextStyle(
                                color: Color.fromRGBO(145, 145, 145, 1),
                                  fontSize: 13.sp
                              ),
                            ),
                            Text(
                              '347789',
                              style: TextStyle(
                                  color: Color.fromRGBO(233, 233, 233, 1),
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500),
                            )
                          ],
                        ),
                         Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          spacing: 10.w,
                          children: [
                            Text(
                              'Buyer',
                              style: TextStyle(
                                color: Color.fromRGBO(145, 145, 145, 1),
                                  fontSize: 13.sp
                              ),
                            ),
                            Text(
                              'Rodica Fizz',
                              style: TextStyle(
                                  color: Color.fromRGBO(233, 233, 233, 1),
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500),
                            )
                          ],
                        ),
                         Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          spacing: 10.w,
                          children: [
                            Text(
                              'Transactions Date',
                              style: TextStyle(
                                color: Color.fromRGBO(145, 145, 145, 1),
                                  fontSize: 13.sp
                              ),
                            ),
                            Text(
                              '01-02-2025',
                              style: TextStyle(
                                  color: Color.fromRGBO(233, 233, 233, 1),
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500),
                            )
                          ],
                        ),
                         Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          spacing: 10.w,
                          children: [
                            Text(
                              'Amount',
                              style: TextStyle(
                                color: Color.fromRGBO(145, 145, 145, 1),
                                  fontSize: 13.sp
                              ),
                            ),
                            Text(
                              '\$100,000',
                              style: TextStyle(
                                  color: Color.fromRGBO(233, 233, 233, 1),
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500),
                            )
                          ],
                        ),
                         Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          spacing: 10.w,
                          children: [
                            Text(
                              'Curency',
                              style: TextStyle(
                                color: Color.fromRGBO(145, 145, 145, 1),
                                  fontSize: 13.sp
                              ),
                            ),
                            Text(
                              'USD',
                              style: TextStyle(
                                  color: Color.fromRGBO(233, 233, 233, 1),
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500),
                            )
                          ],
                        ),
                         Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          spacing: 10.w,
                          children: [
                            Text(
                              'Commission',
                              style: TextStyle(
                                color: Color.fromRGBO(145, 145, 145, 1),
                                  fontSize: 13.sp
                              ),
                            ),
                            Text(
                              '\$20,000',
                              style: TextStyle(
                                  color: Color.fromRGBO(233, 233, 233, 1),
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500),
                            )
                          ],
                        ),
                         Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          spacing: 10.w,
                          children: [
                            Text(
                              'Payment Method',
                              style: TextStyle(
                                color: Color.fromRGBO(145, 145, 145, 1),
                                  fontSize: 13.sp
                              ),
                            ),
                            Text(
                              '**** 3560',
                              style: TextStyle(
                                  color: Color.fromRGBO(233, 233, 233, 1),
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500),
                            )
                          ],
                        ),
                      ],
                    ),
                     Text(
                      'View advertisement',
                      style: TextStyle(
                          color: Color.fromRGBO(166, 227, 184, 1),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                width: isMobile ? double.infinity : 292.w,
                decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color.fromRGBO(90, 90, 90, 1)),
                    borderRadius: BorderRadius.circular(6.r)),
                margin:  EdgeInsets.symmetric(horizontal: 24.w),
                padding:
                     EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 5.h,
                  children: [
                     Text(
                      'Notes',
                      style: TextStyle(
                        color: Color.fromRGBO(145, 145, 145, 1),
                        fontSize: 13.sp
                      ),
                    ),
                    SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: const Divider()),
                     Text(
                      'Transaction succes',
                      style: TextStyle(
                        color: Color.fromRGBO(145, 145, 145, 1),
                          fontSize: 13.sp
                      ),
                    ),
                  ],
                ),
              ),
              if (isMobile) ...[
                const Divider(
                  color: Color.fromRGBO(90, 90, 90, 1),
                ),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 24.w),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) {
                        return const TransactionHistoryMobile();
                      },
                    ));
                  },
                  leading:
                  AppIcons.folder(
                    color: Color.fromRGBO(255, 255, 255, 1),
                    height: 24.h,
                    width: 24.w
                  ),
                  title:  Text(
                    'View History',
                    style: TextStyle(
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500),
                  ),
                  trailing:
                  AppIcons.iosArrowRight(
                    color: Color.fromRGBO(255, 255, 255, 1),
                      height: 24.h,
                      width: 24.w
                  ),
                )
              ],
            ],
          ),
        ),
      ),
    );
  }
}
