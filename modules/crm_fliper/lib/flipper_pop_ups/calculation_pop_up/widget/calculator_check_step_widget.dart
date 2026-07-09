import 'package:flutter/material.dart';
import 'package:core/theme/icons.dart';
import 'package:core/common/gradiant_text_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CalculatorCheckStepWidget extends StatelessWidget {
  final String title;
  final int number;
  final String price;
  final bool isLast;
  const CalculatorCheckStepWidget(
      {super.key,
      required this.title,
      required this.number,
      required this.price,
      this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          spacing: 5.h,
          children: [
            Container(
              height: 30.h,
              width: 30.w,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32.r),
                  color: Colors.transparent,
                  border: Border.all(
                      color: const Color.fromRGBO(200, 200, 200, 1))),
              child: Center(
                child:
                    AppIcons.check(color: Color.fromRGBO(200, 200, 200, 1)),
              ),
            ),
            Container(
              height: 60.h,
              width: 1.w,
              color: Colors.white,
            )
          ],
        ),
         SizedBox(width: 20.w),
        Expanded(
          child: Column(
            spacing: 5.h,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STEP$number: ',
                    style:  TextStyle(
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp),
                  ),
                  GradientText(
                    title,
                    gradient: const LinearGradient(colors: [
                      Color.fromRGBO(87, 222, 210, 1),
                      Color.fromRGBO(87, 148, 221, 1)
                    ]),
                    style:  TextStyle(
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontWeight: FontWeight.w700,
                        fontSize: 18.sp),
                  )
                ],
              ),
              Column(
                spacing: 10.h,
                children: [
                  Container(
                    height: 46.h,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.r),
                        color: const Color.fromRGBO(166, 227, 184, 0.1)),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        '\$ $price',
                        style:  TextStyle(
                            color: Color.fromRGBO(145, 145, 145, 1),
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (isLast)
                     Row(
                      spacing: 20.w,
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Calculate \$ per SF',
                          style: TextStyle(
                              color: Color.fromRGBO(166, 227, 184, 1),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Calculate refurbishment',
                          style: TextStyle(
                              color: Color.fromRGBO(166, 227, 184, 1),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    )
                ],
              )
            ],
          ),
        )
      ],
    );
  }
}
