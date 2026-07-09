import 'package:core/common/chrome/logo_hously.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NegotiationHeaderWidget extends StatelessWidget {
  final bool isMobile;
  const NegotiationHeaderWidget({super.key,this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72.h,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                return Container(
                  margin:  EdgeInsets.symmetric(horizontal: 10.w),
                  height: 33.h,
                  width: 253.w,
                  decoration: BoxDecoration(
                    color:  Color.fromRGBO(33, 32, 32, 1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child:  Center(
                    child: Text(
                      'Transaction name /title',
                      style: TextStyle(
                        color: Color.fromRGBO(145, 145, 145, 1),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if(!isMobile)
            const LogoHouslyWidget(),
        ],
      ),
    );
  }
}
