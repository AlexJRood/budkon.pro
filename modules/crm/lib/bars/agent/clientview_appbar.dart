import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/common/chrome/side_menu_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';

class ClientviewAppbar extends ConsumerWidget {
  final GlobalKey<SideMenuState> sideMenuKey;
  const ClientviewAppbar({super.key, required this.sideMenuKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ApiServices.isUserLoggedIn();

    double screenWidth = MediaQuery.of(context).size.width;
    const double maxWidth = 1920;
    const double minWidth = 480;
    const double maxLogoSize = 30;
    const double minLogoSize = 22;
    double logoSize = (screenWidth - minWidth) /
            (maxWidth - minWidth) *
            (maxLogoSize - minLogoSize) +
        minLogoSize;
    logoSize = logoSize.clamp(minLogoSize, maxLogoSize);
    final color = Theme.of(context).iconTheme.color;

    final currentthememode = ref.watch(themeProvider);

    return Container(
      height: TopAppBarSize.resolve(context),
      decoration: BoxDecoration(
          color: currentthememode == ThemeMode.system ||
                  currentthememode == ThemeMode.light
              ? Colors.black.withAlpha((255 * 0.1).toInt())
              : Colors.white.withAlpha((255 * 0.1).toInt())),
      padding: const EdgeInsets.only(left: 0, right: 5, top: 5, bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            height: 60,
            child: ElevatedButton(
              style: elevatedButtonStyleRounded10,
              onPressed: () {
                SideMenuManager.toggleMenu(ref: ref, menuKey: sideMenuKey);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  AppIcons.menu(color: color, height: 30.0,width: 30,),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
