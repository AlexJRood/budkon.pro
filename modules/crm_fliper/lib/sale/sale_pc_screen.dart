import 'package:flutter/material.dart';
import 'package:crm_fliper/sale/widget/sale_custom_list_view.dart';
import 'package:crm_fliper/selection_and_negotiations/widgets/custom_vertical_divider.dart';
import 'package:crm_fliper/selection_and_negotiations/widgets/flipper_custom_list_view.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SalePcScreen extends StatelessWidget {
  const SalePcScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return  Padding(
      padding: EdgeInsets.symmetric(horizontal: 160.0.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
            children:[
              FlipperCustomListView(title: 'View All', itemCount: 10, id: 7),
              Row(
                children: [
                  SaleCustomListView(itemCount: 5, title: 'SCHEDULE MEETING (3)',),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0.h),
                    child: CustomVerticalDivider(),
                  ),
                  SaleCustomListView(itemCount: 1, title: 'Follow Up (3)',),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0.h),
                    child: CustomVerticalDivider(),
                  ),
                  SaleCustomListView(itemCount: 4, title: 'Agreedment (3)',),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0.h),
                    child: CustomVerticalDivider(),
                  ),
                  SaleCustomListView(itemCount: 2, title: 'Papers (3)',),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0.h),
                    child: CustomVerticalDivider(),
                  ),
                ],
              ),
            ]
        ),
      ),
    );
  }
}
