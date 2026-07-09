import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/icons.dart';
import 'package:crm_fliper/flipper_pop_ups/transaction_pop_up/widget/transaction_sidebar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FlipperPopUpBottomNavigationBar extends ConsumerWidget {
  const FlipperPopUpBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);

    return Container(
      width: 340.w,
      margin:  EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [
          Color.fromRGBO(64, 112, 169, 1),
          Color.fromRGBO(29, 62, 102, 1),
        ]),
        borderRadius:  BorderRadius.all(
          Radius.circular(20.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).toInt()),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ], // Optional shadow for depth
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          ref.read(selectedIndexProvider.notifier).state = index;
        },
        backgroundColor:
            Colors.transparent,
        selectedItemColor: const Color.fromRGBO(161, 236, 230, 1),
        unselectedItemColor: const Color.fromRGBO(255, 255, 255, 1),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 10.sp,
          color: const Color.fromRGBO(161, 236, 230, 1),
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10.sp,
          color: const Color.fromRGBO(255, 255, 255, 1),
        ),
        items: [
          BottomNavigationBarItem(
            icon: AppIcons.home(
              height: 24.h,
              width: 24.w,
              color: Color.fromRGBO(255, 255, 255, 1)
            ),
            label: 'Transaction',
          ),
          BottomNavigationBarItem(
            icon: AppIcons.arrowTrendUp(
                height: 24.h,
                width: 24.w,
                color: Color.fromRGBO(255, 255, 255, 1)
            ),
            label: 'Calculator',
          ),
          BottomNavigationBarItem(
            icon: AppIcons.duplicate(
                height: 24.h,
                width: 24.w,
                color: Color.fromRGBO(255, 255, 255, 1)
            ),
            label: 'Refurbish',
          ),
           BottomNavigationBarItem(
            icon: AppIcons.creditCard(
                height: 24.h,
                width: 24.w,
                color: Color.fromRGBO(255, 255, 255, 1)
            ),
            label: 'Sale',
          ),
        ],
      ),
    );
  }
}
