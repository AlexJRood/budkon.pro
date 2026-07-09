import 'package:flutter/material.dart';
import 'package:core/theme/icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Finance2PropertyCard extends StatelessWidget {
  final bool isMobile;
  const Finance2PropertyCard({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isMobile ? 270.h : 375.h,
      child: Card(
        color: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        margin:  EdgeInsets.symmetric(vertical: 8.h),
        child: isMobile
            ? Container(
          color: Colors.red,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius:  BorderRadius.vertical(
                              top: Radius.circular(8.r)),
                          child: Image.asset(
                            "assets/images/landingpage.webp",
                            width: double.infinity, // Take full width
                            height: 130.h, // Adjusted height
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            padding:  EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(0, 0, 0, 0.3),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child:  Text(
                              "Sponsored",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Content Section
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                            "Warszawa, Mokotów, Poland",
                            style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                          ),
                           Text(
                            "Biały Kamień Street",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              AppIcons.straighten(color: Colors.grey, height: 14.h,width: 14.h,),
                               SizedBox(width: 4.w),
                               Text("98 m²",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12.sp)),
                               SizedBox(width: 10.w),
                              AppIcons.bed(color: Colors.grey, height: 14.h,width: 14.h,),
                               SizedBox(width: 4.w),
                               Text("2 Rooms",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12.sp)),
                               SizedBox(width: 10.w),
                              AppIcons.bathroom(color: Colors.grey, height: 14.h,width: 14.h,),
                               SizedBox(width: 4.w),
                               Text("2 Bath",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12.sp)),
                            ],
                          ),
                          const Divider(),
                           Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("FOR SALE",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12.sp)),
                              Text(
                                "\$165,000",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Image.asset(
                          "assets/images/landingpage.webp",
                          width: double.infinity,
                          height: 176.h,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 5,
                        left: 5,
                        child: Container(
                          padding:  EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(0, 0, 0, 0.3),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child:  Text(
                            "Sponsored",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                   SizedBox(height: 10.h),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           Text(
                            "Biały Kamień Street",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold),
                          ),
                           Text(
                            "Warszawa, Mokotów, Poland",
                            style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                          ),
                          Row(
                            children: [
                              AppIcons.straighten(color: Colors.grey, height: 14.h,width: 14.h,),
                               SizedBox(width: 4.w),
                               Text("88 m²",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12.sp)),
                               SizedBox(width: 10.w),
                              AppIcons.bed(color: Colors.grey, height: 14.h,width: 14.h,),
                               SizedBox(width: 4.w),
                               Text("2 Rooms",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12.sp)),
                               SizedBox(width: 10.w),
                              AppIcons.bathroom(color: Colors.grey, height: 14.h,width: 14.h,),
                               SizedBox(width: 4.w),
                               Text("2 Bath",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12.sp)),
                            ],
                          ),
                          const Divider(),
                           Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("FOR SALE",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12.sp)),
                              Text(
                                "\$165,000",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
