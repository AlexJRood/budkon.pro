import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/icons.dart';
import 'package:crm_fliper/finance/finance2/widget/finance_2_property_card.dart';
import 'package:crm_fliper/finance/finance2/widget/finance_2_tap_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Finance2PcCustomListView extends ConsumerWidget {
  const Finance2PcCustomListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(finance2TabProvider);
    String selectedSort = "Price (Highest - Lowest)";
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(child: Finance2TabBar()),
            Row(
              spacing: 10.w,
              children: [
                 Text(
                  'Sort by:',
                  style: TextStyle(
                      color: Color.fromRGBO(145, 145, 145, 1),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700),
                ),
                Container(
                  height: 42.h,
                  decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                          color: const Color.fromRGBO(255, 255, 255, 1)),
                      borderRadius: BorderRadius.circular(6.r)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButton<String>(
                      dropdownColor: Colors.grey[900],
                      value: selectedSort,
                      icon: AppIcons.iosArrowDown(color: Colors.white),
                      underline: Container(),
                      items: [
                        "Price (Highest - Lowest)",
                        "Price (Lowest - Highest)"
                      ]
                          .map((String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value,
                                    style:  TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500)),
                              ))
                          .toList(),
                      onChanged: (String? newValue) {
                        selectedSort = newValue!;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        selectedTab == 0
            ? ListView.builder(
          addAutomaticKeepAlives: false,
          cacheExtent: 300.0,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 15,
                itemBuilder: (context, index) {
                  return const Finance2PropertyCard();
                },
              )
            : ListView.builder(
          addAutomaticKeepAlives: false,
          cacheExtent: 300.0,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return const Finance2PropertyCard();
                },
              ),
      ],
    );
  }
}
