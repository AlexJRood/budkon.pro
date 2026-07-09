import 'package:flutter/material.dart';
import 'package:core/common/gradiant_text_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FlipperListViewCustomCard extends StatelessWidget {
  final String address;
  final String name;
  final String price;
  final String profitPotential;
  final String imageUrl;

  const FlipperListViewCustomCard({
    super.key,
    required this.price,
    required this.name,
    required this.address,
    required this.profitPotential,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250.h,
      width: 330.w,
      margin: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(41, 41, 41, 1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Top Image
          Expanded(
            child: ClipRRect(
              borderRadius:
              BorderRadius.vertical(top: Radius.circular(6.r)),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// Bottom Content
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address,
                  style: TextStyle(
                    color: Color.fromRGBO(200, 200, 200, 1),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  name,
                  style: TextStyle(
                    color: Color.fromRGBO(255, 255, 255, 1),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '~\$ $price',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: Color.fromRGBO(255, 255, 255, 1),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GradientText(
                      'Profit Potential:',
                      gradient: const LinearGradient(colors: [
                        Color.fromRGBO(87, 148, 221, 1),
                        Color.fromRGBO(87, 222, 210, 1),
                      ]),
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    GradientText(
                      '\$ $profitPotential',
                      gradient: const LinearGradient(colors: [
                        Color.fromRGBO(87, 148, 221, 1),
                        Color.fromRGBO(87, 222, 210, 1),
                      ]),
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
