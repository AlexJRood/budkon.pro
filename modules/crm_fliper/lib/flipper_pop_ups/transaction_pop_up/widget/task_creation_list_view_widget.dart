import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/icons.dart';

class TaskCreationListViewWidget extends StatelessWidget {
  final ScrollController? scrollController;
  const TaskCreationListViewWidget({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin:  EdgeInsets.symmetric(vertical: 10.h),
          padding: const EdgeInsets.all(10),
          width: MediaQuery.of(context).size.width,
          decoration:  BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(6.r)),
            color: Color.fromRGBO(41, 41, 41, 1),
          ),
          child: Column(
            spacing: 5,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    spacing: 10.w,
                    children: [
                      Container(
                        decoration:  BoxDecoration(
                            color: Color.fromRGBO(87, 148, 221, 0.1),
                            borderRadius: BorderRadius.all(Radius.circular(6.r))),
                        padding:  EdgeInsets.symmetric(
                            vertical: 5.h, horizontal: 15.w),
                        child: Text(
                          'Pending',
                          style: TextStyle(
                              color: Color.fromRGBO(161, 236, 230, 1),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                            color: Color.fromRGBO(87, 148, 221, 0.1),
                            borderRadius: BorderRadius.all(Radius.circular(6))),
                        padding:  EdgeInsets.symmetric(
                            vertical: 5.h, horizontal: 15.w),
                        child:  Row(
                          spacing: 5.w,
                          children: [
                            AppIcons.calendar(
                              color: Color.fromRGBO(200, 200, 200, 1),
                              height: 12.h,
                              width: 12.h
                            ),
                            Text(
                              'Jan 10,2025',
                              style: TextStyle(
                                  color: Color.fromRGBO(200, 200, 200, 1),
                                  fontSize: 12.sp
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppIcons.moreVertical(
                    color: Color.fromRGBO(200, 200, 200, 1),
                    height: 24.h,
                    width: 24.h
                  )
                ],
              ),
               Text(
                'Sending the keys or property access codes to the buyer.',
                style: TextStyle(
                    color: Color.fromRGBO(255, 255, 255, 1),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500),
              ),
               Text(
                'Comment...',
                style: TextStyle(
                    color: Color.fromRGBO(145, 145, 145, 1),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500),
              )
            ],
          ),
        );
      },
    );
  }
}
