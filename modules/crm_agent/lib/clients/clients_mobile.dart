import 'package:core/shell/manager/bar_manager.dart';
import 'package:crm/crm/clients/clients_list.dart';
import 'package:crm/crm/clients/search_buttons_mobile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/common/install_popup.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';

import 'package:get/get_utils/get_utils.dart';

class ClientsMobile extends ConsumerWidget {
  const ClientsMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();

    return PopupListener(
      child: BarManager(
        sideMenuKey: sideMenuKey,
        appModule: AppModule.agentCrm,
        childMobile: Container(
          color: const Color.fromRGBO(19, 19, 19, 1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Clients'.tr,
                      style: const TextStyle(
                          color: Color.fromRGBO(255, 255, 255, 1),
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 70, child: StatusFilterWidgetMobile()),
                  ],
                ),
              ),
              const Flexible(child: ClientList(isMobile: true)),
            ],
          ),
        ),
      ),
    );
  }
}
