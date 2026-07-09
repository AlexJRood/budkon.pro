import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_fliper/refurbishment/refurbishment_mobile_screen.dart';
import 'package:crm_fliper/sale/sale_mobile_screen.dart';
import 'package:crm_fliper/selection_and_negotiations/selection_and_negotiation_pc_screen.dart';
import 'package:crm_fliper/selection_and_negotiations/widgets/flipper_custom_tap_bar.dart';
import 'package:crm_fliper/selection_and_negotiations/widgets/negotiation_widget.dart';
import 'package:crm_fliper/selection_and_negotiations/widgets/nigotiation_header_widget.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/common/chrome/side_menu_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/icons.dart';

class SelectionAndNegotiationMobileScreen extends ConsumerWidget {
  const SelectionAndNegotiationMobileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(tabIndexProvider);
    final sideMenuKey = GlobalKey<SideMenuState>();

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.portal,
      isTopAppBarOff: true,
      childMobile: Container(
        color: Colors.black,
        child: Stack(
              children: [
                Column(
                  spacing: 20.h,
                  children: [
                    SizedBox(
                      height: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            icon:
                            AppIcons.menu(
                              color: Color.fromRGBO(255, 255, 255, 1),
                              height: 38.h,
                              width: 38.h
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
                                'Negotiations',
                                style: TextStyle(
                                    color: Color.fromRGBO(255, 255, 255, 1),
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'Refurbishment',
                                style: TextStyle(
                                    color: Color.fromRGBO(255, 255, 255, 1),
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'Negotiations',
                                style: TextStyle(
                                    color: Color.fromRGBO(255, 255, 255, 1),
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          AppIcons.moreVertical(
                            color: Color.fromRGBO(255, 255, 255, 1),
                            height: 38.h,
                            width: 38.h
                          )
                        ],
                      ),
                    ),
                    const NegotiationHeaderWidget(
                      isMobile: true,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 40.0),
                        child: IndexedStack(
                          index: tabIndex,
                          children: const [
                            Center(
                              child: NegotiationWidget(
                                isMobile: true,
                              ),
                            ),
                            Center(
                              child: RefurbishmentMobileScreen(),
                            ),
                            Center(
                              child: SaleMobileScreen(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                 Positioned(
                    bottom: 60,
                    right: 0,
                    left: 0,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 28.0.w),
                      child: FlipperCustomTapBar(),
                    )),
              ],
            ),
          ),
        );
  }
}
