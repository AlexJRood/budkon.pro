// notification/notification_screen.dart (keep as is - no changes needed)
import 'dart:ui' as ui;
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification/emma/anchors/notification_emma_anchors.dart';
import 'package:notification/notification_mobile_screen.dart';
import 'package:notification/notification_pc_screen.dart';
import 'package:notification/notification_service.dart';
import 'package:core/platform/navigation_service.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await ref.read(notificationProvider.notifier).refreshAllData(ref: ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final Widget notificationContent = screenWidth > 800
        ? const NotificationPcScreen()
        : const NotificationMobileScreen();

    return EmmaUiAnchorTarget(
      anchorKey: NotificationEmmaAnchors.screenRoot.anchorKey,

      spec: NotificationEmmaAnchors.screenRoot,
      runtimeMode: NotificationEmmaAnchors.screenRoot.runtimeMode,
      tapMode: NotificationEmmaAnchors.screenRoot.tapMode,
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
            EmmaUiAnchorTarget(
              anchorKey: NotificationEmmaAnchors.dismissArea.anchorKey,

              spec: NotificationEmmaAnchors.dismissArea,
              runtimeMode: NotificationEmmaAnchors.dismissArea.runtimeMode,
              tapMode: NotificationEmmaAnchors.dismissArea.tapMode,
              child: GestureDetector(
                onTap: () => ref.read(navigationService).beamPop(),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                ),
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: EmmaUiAnchorTarget(
                anchorKey: NotificationEmmaAnchors.content.anchorKey,

                spec: NotificationEmmaAnchors.content,
                runtimeMode: NotificationEmmaAnchors.content.runtimeMode,
                tapMode: NotificationEmmaAnchors.content.tapMode,
                child: notificationContent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}