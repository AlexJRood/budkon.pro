import 'package:crm_fliper/provider/acivity_time_line_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_fliper/flipper_pop_ups/calculation_pop_up/calculation_pop_up_screen.dart';
import 'package:crm_fliper/flipper_pop_ups/refurbish_pop_up/refurbish_pop_up_screen.dart';
import 'package:crm_fliper/flipper_pop_ups/sale_pop_up/sale_pop_up_screen.dart';
import 'package:crm_fliper/flipper_pop_ups/transaction_pop_up/transaction_pop_up_pc_screen.dart';
import 'package:crm_fliper/flipper_pop_ups/transaction_pop_up/widget/transaction_sidebar.dart';
import 'package:crm_fliper/selection_and_negotiations/widgets/nigotiation_header_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FlipperMainPcPopUp extends ConsumerStatefulWidget {
  const FlipperMainPcPopUp({super.key});

  @override
  ConsumerState<FlipperMainPcPopUp> createState() => _FlipperMainPcPopUpState();
}

class _FlipperMainPcPopUpState extends ConsumerState<FlipperMainPcPopUp> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ref.read(activityTimeLineProvider.notifier).getFlipperActivityTimeLine();
    },);
  }
  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedIndexProvider);

    final List<Widget> screens = [
      const TransactionPopUpPcScreen(),
      const CalculationPopUpScreen(),
      const RefurbishPopUpScreen(),
      const SalePopUpScreen(),
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20.h,
          children: [
            const NegotiationHeaderWidget(),
            Expanded(
              child: Row(
                spacing: 20.w,
                children: [
                  const TransactionSidebar(),
                  Expanded(child: screens[selectedIndex]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
