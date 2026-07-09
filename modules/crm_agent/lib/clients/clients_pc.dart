import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:crm/crm/clients/clients_list.dart';
import 'package:crm/crm/clients/search_buttons.dart';
import 'package:crm/crm/clients/search_buttons_mobile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:crm/invoice_pdf_generator/model/invoise_model.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';

import 'package:get/get_utils/get_utils.dart';

class ClientsPc extends ConsumerWidget {
  const ClientsPc({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    ref.watch(invoicetoggleProvider);
    final theme = ref.read(themeColorsProvider);

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.agentCrm,
      isTopAppBarHoveroverUI: false,
      paddingPc: 20,

      childrenPc: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'My Clients'.tr,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [StatusFilterWidget()],
        ),
        SizedBox(height: 10),
        Expanded(child: ClientList()),
      ],

      childrenMobile: [
        SizedBox(height: TopAppBarSize.resolve(context)),
        Text(
          'My Clients'.tr,
          style: TextStyle(
            color: Color.fromRGBO(255, 255, 255, 1),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 70, child: StatusFilterWidgetMobile()),
        const Flexible(child: ClientList(isMobile: true)),

        SizedBox(height: TopAppBarSize.withTopAppBar(context)),
      ],
    );
  }
}
