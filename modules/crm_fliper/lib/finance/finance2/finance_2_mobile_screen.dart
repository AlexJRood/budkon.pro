import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/icons.dart';
import 'package:crm_fliper/finance/finance2/widget/finance_2_custom_text_field.dart';
import 'package:crm_fliper/finance/finance2/widget/finance_2_mobile_custom_list_view.dart';
import 'package:crm_fliper/selection_and_negotiations/widgets/nigotiation_header_widget.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/common/chrome/side_menu_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Finance2MobileScreen extends ConsumerWidget {
  const Finance2MobileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.portal,
      isTopAppBarOff: true,
      childMobile: Container(
        color: Colors.black,
        child: Column(
              spacing: 10.h,
              children: [
                Padding(
                  padding:
                       EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: AppIcons.menu(height: 38.h,width: 38.h, color: Colors.white),
                        onPressed: () {
                          SideMenuManager.toggleMenu(
                              ref: ref, menuKey: sideMenuKey);
                        },
                      ),
                       Text(
                        'Finance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      AppIcons.moreVertical(color: Colors.white, height: 38.h,width: 38.h,),
                    ],
                  ),
                ),
                const NegotiationHeaderWidget(isMobile: true),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Finance2CustomTextField(),
                        Expanded(child: Finance2MobileCustomListView()),
                      ],
                    ),
                  ),
                ),
              ]
        ),
      ),
    );
  }
}
