import 'package:flutter/material.dart';
import 'package:emma/widgets/appbar_chat.dart';
import 'package:emma/widgets/message_list.dart';
import 'package:emma/widgets/sidebar_chat.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../widgets/send_message_box.dart';
import 'dart:ui' as ui;

class ChatAiMobile extends ConsumerWidget {
  ChatAiMobile({super.key});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      key: _scaffoldKey,
      endDrawer:  Drawer(
        backgroundColor:theme.adPopBackground.withAlpha((255 * 0.4).toInt()),
        child: ChatAiSideBar(
          scaffoldKey: _scaffoldKey,
          isMobile: true,
        ),
      ),
      body: Stack(
        children: [
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.black.withAlpha((255 * 0.35).toInt()),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              color: theme.adPopBackground.withAlpha((255 * 0.25).toInt()),
              width: double.infinity,
              height: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        AiAppBar(
                          isMobile: true,
                          scaffoldKey: _scaffoldKey,
                        ),
                        const Expanded(
                          child: Stack(
                            children: [
                              MessageListView(isMobile: true),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: SendMessageBox(
                                  isMobile: true,
                                ),
                              ),
                            ],
                          ),
                        ),

                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
