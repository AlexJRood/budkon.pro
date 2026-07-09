import 'package:flutter/material.dart';

import 'package:crm_fliper/selection_and_negotiations/widgets/fliper_list_view__custom_card.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FlipperCustomVerticalListView extends StatelessWidget {
  final int itemCount;
  const FlipperCustomVerticalListView({super.key,required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 283.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return  Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0.w),
            child: FlipperListViewCustomCard(
              imageUrl: 'assets/images/landingpage.webp',
              address: 'Warszawa, Mokotów, Poland',
              name: 'Biały Kamień Street',
              price: '250,000',
              profitPotential: '50,000',
            ),
          );
        },
      ),
    );
  }
}
