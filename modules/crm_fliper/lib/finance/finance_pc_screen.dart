import 'package:core/shell/manager/bar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_fliper/finance/widget/finance_custom_tap_bar.dart';
import 'package:crm_fliper/finance/widget/revenues_widget.dart';
import 'package:crm_fliper/selection_and_negotiations/widgets/nigotiation_header_widget.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FinancePcScreen extends ConsumerWidget {
  const FinancePcScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final tabIndex = ref.watch(financeTabIndexProvider);

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.portal,
      isTopAppBarOff: true,
      childPc: Container(
        color: Colors.black,
        child: Column(
          spacing: 20.h,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(),
            const NegotiationHeaderWidget(),
            FinanceCustomTapBar(appModule: AppModule.agentCrm),
            Expanded(
              child: IndexedStack(
                index: tabIndex,
                children: const [
                  Center(child: RevenuesWidget()),
                  Center(child: RevenuesWidget()),
                  Center(child: RevenuesWidget()),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
