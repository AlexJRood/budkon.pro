import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:crm/crm/clients/clients_list.dart';
import 'package:crm/crm/clients/search_buttons.dart';
import 'package:crm_agent/add_client_form/add_client_form_mobile.dart';
import 'package:crm_agent/screens/filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

import 'package:core/ui/side_menu/slide_rotate_menu.dart';

import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';

class ClientsPage extends ConsumerWidget {
  const ClientsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.read(themeColorsProvider);

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.agentCrm,
      isTopAppBarHoveroverUI: false,
      paddingPc: 20,
      paddingMobile: 10,
      verticalButtons: Column(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: theme.textFieldColor,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            child: ElevatedButton(
              style: elevatedButtonStyleRounded10,
              onPressed:
                  () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: theme.dashboardContainer,
                    builder: (_) {
                      return DraggableScrollableSheet(
                        initialChildSize: 0.85,
                        minChildSize: 0.4,
                        maxChildSize: 0.95,
                        expand: false,
                        builder: (ctx, scrollController) {
                          return AddClientFormMobile(
                            isClientView: false,
                            sheetScrollController: scrollController,
                          );
                        },
                      );
                    },
                  ),
              child: AppIcons.add(
                color: theme.textColor,
                height: 25,
                width: 25,
              ),
            ),
          ),

          const SizedBox(height: 5),

          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: theme.textFieldColor,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            child: ElevatedButton(
              style: elevatedButtonStyleRounded10,
              onPressed:
                  () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) {
                      return DraggableScrollableSheet(
                        initialChildSize: 0.85,
                        minChildSize: 0.4,
                        maxChildSize: 0.95,
                        expand: false,
                        builder: (ctx, scrollController) {
                          return FilterSheet(
                            scrollController: scrollController,
                          );
                        },
                      );
                    },
                  ),
              child: AppIcons.filterAlt(color: theme.textColor),
            ),
          ),
          SizedBox(height: 4),
        ],
      ),

      childrenPc: [
        Align(
          alignment: Alignment.topLeft,
          child: Text(
            'My Clients'.tr,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 10),
        StatusFilterWidget(),
        SizedBox(height: 10),
        Expanded(child: ClientList()),
      ],

      // verticalButtons: ,
      childrenMobile: [
        SizedBox(height: TopAppBarSize.resolve(context) + 5),
        // SizedBox(height: 70, child: StatusFilterWidgetMobile()),
        const Expanded(child: ClientList(isMobile: true)),
      ],
    );
  }
}
