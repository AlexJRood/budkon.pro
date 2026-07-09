import 'package:core/shell/manager/bar_manager.dart';
import 'package:flutter/material.dart';
import 'package:crm_fliper/finance/finance2/widget/finance_2_pc_custom_list_view.dart';
import 'package:crm_fliper/finance/finance2/widget/finance_2_custom_text_field.dart';
import 'package:crm_fliper/selection_and_negotiations/widgets/nigotiation_header_widget.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Finance2PcScreen extends StatelessWidget {
  const Finance2PcScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sideMenuKey = GlobalKey<SideMenuState>();

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.portal,
      isTopAppBarOff: true,
      childPc: Container(
        color: Colors.black,
        child: Column(
          spacing: 20.h,
          children: [
            const SizedBox(),
            const NegotiationHeaderWidget(),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 160.0.w),
                child: SingleChildScrollView(
                  child: Column(
                    spacing: 12.h,
                    children: const [
                      Finance2CustomTextField(),
                      Finance2PcCustomListView(),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
