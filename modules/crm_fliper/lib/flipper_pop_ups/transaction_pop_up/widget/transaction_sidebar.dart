import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

final selectedIndexProvider = StateProvider<int>((ref) => 0);

class TransactionSidebar extends ConsumerWidget {
  const TransactionSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);

    final List<Map<String, dynamic>> menuItems = [
      {'icon': Icons.home_outlined, 'label': 'Transaction'},
      {'icon': Icons.trending_up, 'label': 'Calculator'},
      {'icon': Icons.note_outlined, 'label': 'Refurbish '},
      {'icon': Icons.house_outlined, 'label': 'Sale'},
    ];

    return Container(
      height: MediaQuery.of(context).size.height,
      width: 68.w,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(50, 50, 50, 1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(menuItems.length, (index) {
          final item = menuItems[index];
          return GestureDetector(
            onTap: () => ref.read(selectedIndexProvider.notifier).state = index,
            child: Padding(
              padding:  EdgeInsets.symmetric(vertical: 10.h),
              child: Column(
                children: [
                  Icon(
                    item['icon'],
                    size: 24.sp,
                    color:
                        selectedIndex == index ? Colors.white : Colors.white38,
                  ),
                   SizedBox(height: 4.h),
                  Text(
                    item['label'],
                    style: TextStyle(
                      color: selectedIndex == index
                          ? Colors.white
                          : Colors.white38,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

