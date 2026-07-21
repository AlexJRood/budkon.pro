// emma/screens/pc.dart

import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emma/widgets/sidebar_chat.dart';
import 'package:core/shell/manager/bar_manager.dart'
    show SidebarManagerRail, AppModule;
import 'dart:ui' as ui;
import 'package:core/theme/apptheme.dart';
import 'package:emma/widgets/chat_conversation_pane.dart';



class ChatAiPc extends ConsumerWidget {
  const ChatAiPc({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final sideMenuKey = GlobalKey<SideMenuState>();

    double screenWidth = MediaQuery.of(context).size.width;
    double maxWidth = 1500;
    double minWidth = 1000;
    double maxDynamicContainerSize = 400;
    double minDynamicContainerSize = 0;
    double dynamicContainerSize = (screenWidth - minWidth) /
            (maxWidth - minWidth) *
            (maxDynamicContainerSize - minDynamicContainerSize) +
        minDynamicContainerSize;
    dynamicContainerSize = dynamicContainerSize.clamp(
        minDynamicContainerSize, maxDynamicContainerSize);

    return Scaffold(
      backgroundColor: Colors.transparent,
      // PieCanvas ancestor for the SidebarManagerRail's PieMenu buttons below.
      // Without it pie_menu throws "Could not find any PieCanvas".
      body: Stack(
        children: [
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: theme.adPopBackground.withAlpha((255 * 0.15).toInt()),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          GestureDetector(onTap: () {
            Navigator.of(context).pop();
          }),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        child: Stack(
                          children: [                          
                          BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                            child: Container(
                              color: theme.adPopBackground.withAlpha((255 * 0.35).toInt()),
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Row(
                              children: [
                                SidebarManagerRail(
                                  appModule: AppModule.chat,
                                  sideMenuKey: sideMenuKey,
                                  legacyChild: const SizedBox.shrink(),
                                  onSidebarTap: () => Navigator.maybeOf(context)?.pop(),
                                ),
                                ChatAiSideBar(),
                                Expanded(
                                    child: ChatConversationPane(isMobile: false),
                                  ),
                                ],
                              ),
                            ],
                        ),
                      ),
                    ),
                    SizedBox(width: dynamicContainerSize),
                  ],
                ),
              )
            ],
          ),
        ],
        ),
    );
  }
}
//
