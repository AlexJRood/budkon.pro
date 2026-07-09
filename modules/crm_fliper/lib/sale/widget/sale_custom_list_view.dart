import 'package:flutter/material.dart';
import 'package:crm_fliper/sale/widget/sale_custom_list_view_card.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SaleCustomListView extends StatelessWidget {
  final int itemCount;
  final String title;
  const SaleCustomListView(
      {super.key, required this.itemCount, required this.title});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 354.w,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style:  TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700),
            ),
             SizedBox(height: 10.h),
            Expanded(
              child: ListView.builder(
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  return const SaleCustomListViewCard(
                      name: "John Doe",
                      email: "john.doe@gmail.com",
                      title: "Negotiation meeting",
                      date: "December 17, 10:30 - 12:00",
                      description:
                      "He likes the location, but wants a negotiable price.");
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

