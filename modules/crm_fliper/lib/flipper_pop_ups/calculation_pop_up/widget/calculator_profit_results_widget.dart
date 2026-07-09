import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class CalculatorProfitResultsWidget extends StatelessWidget {
  const CalculatorProfitResultsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: 340.w,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(33, 32, 32, 1),
        border: Border.all(color: const Color.fromRGBO(90, 90, 90, 1)),
      ),
      child:  Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: Text(
                'PROFIT RESULTS',
                style: TextStyle(
                  color: Color.fromRGBO(255, 255, 255, 1),
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            BuildProfitRow(label: 'After Repair Value', value: '\$100,000'),
            Divider(),
            BuildProfitRow(label: 'Purchase Price', value: '\$100,000'),
            Divider(),
            BuildProfitRow(label: 'Repair Costs', value: '\$100,000'),
            Divider(),
            BuildProfitRow(label: 'Fixed Costs', value: '\$100,000'),
            Divider(),
            BuildProfitRow(label: 'Buying Costs', value: '\$100,000'),
            Divider(),
            BuildProfitRow(label: 'Selling Costs', value: '\$100,000'),
            Divider(),
            BuildProfitRow(label: 'Financing Costs', value: '\$100,000'),
            Divider(),
            SizedBox(height: 16.h),
            BuildProfitRow(
                label: 'Calculated Profit',
                value: '\$100,000',
                isHighlighted: true),
          ],
        ),
      ),
    );
  }
}

class BuildProfitRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;
  const BuildProfitRow(
      {super.key,
      required this.value,
      required this.label,
      this.isHighlighted = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:  EdgeInsets.symmetric(vertical: 8.0.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isHighlighted
                  ? const Color.fromRGBO(166, 227, 184, 1)
                  : const Color.fromRGBO(145, 145, 145, 1),
              fontSize: 14.sp,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isHighlighted
                  ? const Color.fromRGBO(166, 227, 184, 1)
                  : const Color.fromRGBO(255, 255, 255, 1),
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
