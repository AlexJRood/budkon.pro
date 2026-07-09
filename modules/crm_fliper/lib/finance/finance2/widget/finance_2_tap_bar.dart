
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Finance2TabNotifier extends StateNotifier<int> {
  Finance2TabNotifier() : super(0);

  void changeTab(int index) {
    state = index;
  }
}

final finance2TabProvider =
StateNotifierProvider<Finance2TabNotifier, int>((ref) {
  return Finance2TabNotifier();
});

class Finance2TabBar extends ConsumerWidget {
  const Finance2TabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              FinanceBuildTab(ref:  ref,index:  0,title:  "REVENUE"),
              FinanceBuildTab( ref: ref, index: 1, title: "EXPENSES"),
            ],
          ),
          const Divider(
            color: Colors.white,
          )
        ],
      ),
    );
  }
}

class FinanceBuildTab extends StatelessWidget {
  final int index;
  final String title;
  final WidgetRef ref;
  const FinanceBuildTab({super.key,required this.title,required this.index,required this.ref});

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(finance2TabProvider);
    final isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () => ref.read(finance2TabProvider.notifier).changeTab(index),
      child: Padding(
        padding:  EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}