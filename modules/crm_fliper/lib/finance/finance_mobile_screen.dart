import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/common/chrome/side_menu_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_fliper/finance/widget/revenues_widget.dart';
import 'package:crm_fliper/selection_and_negotiations/widgets/nigotiation_header_widget.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';

import 'package:crm_fliper/finance/widget/finance_custom_tap_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FinanceMobileScreen extends ConsumerWidget {
  const FinanceMobileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final tabIndex = ref.watch(financeTabIndexProvider);

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.portal,
      isTopAppBarOff: true,
      childMobile: Container(
        color: Colors.black,
        child: Stack(
          children: [
            Column(
              children: [
                Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.menu,
                            size: 38,
                            color: Color.fromRGBO(255, 255, 255, 1),
                          ),
                          onPressed: () {
                            SideMenuManager.toggleMenu(
                                ref: ref, menuKey: sideMenuKey);
                          },
                        ),
                        IndexedStack(
                          index: tabIndex,
                          children:  [
                            Text(
                              'Revenues',
                              style: TextStyle(
                                  color: Color.fromRGBO(255, 255, 255, 1),
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Expenses',
                              style: TextStyle(
                                  color: Color.fromRGBO(255, 255, 255, 1),
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.more_horiz,
                          color: Color.fromRGBO(255, 255, 255, 1),
                          size: 38,
                        ),
                      ],
                    ),
                    const NegotiationHeaderWidget(
                      isMobile: true,
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: tabIndex,
                        children: const [
                          Center(
                            child: RevenuesWidget(
                              isMobile: true,
                            ),
                          ),
                          Center(
                            child: RevenuesWidget(
                              isMobile: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
               Positioned(
                  bottom: 60,
                  right: 0,
                  left: 0,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28.0.h),
                    child: FinanceCustomTapBar(appModule: AppModule.agentCrm),
                  )),
          ],
        ),
      ),
    );
  }
}
