import 'dart:ui' as ui;

import 'package:core/common/chrome/appbar_logo_only.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'edit_offer_mobile_page.dart';
import 'package:crm/contact_panel/tabs/Draft/edit_sell_offer_pc.dart';
import 'package:core/common/chrome/side_menu_manager.dart';

import 'package:core/ui/side_menu/slide_rotate_menu.dart';

class CrmEditSellOfferPage extends ConsumerWidget {
  final int? offerId;

  const CrmEditSellOfferPage({super.key, required this.offerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SideMenuManager.sideMenuSettings(
        menuKey: sideMenuKey,
        child: Stack(
          children: [
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withAlpha((255 * 0.85).toInt()),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth > 1200) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 40, right: 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const TopAppBarLogoOnly(),
                            CrmEditSellOfferPc(offerId: offerId),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return CrmEditOfferMobilePage(offerId: offerId);
              }
            }),
          ],
        ),
      ),
    );
  }
}
