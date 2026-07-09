import 'dart:ui' as ui;
import 'package:core/common/chrome/side_menu_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:docs/provider/cloud_doc_provider.dart';
import 'package:docs/widgets/document_title_editor_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';

class TopAppBarMobileDocs extends ConsumerWidget {
  const TopAppBarMobileDocs({super.key, required this.sideMenuKey});

  final GlobalKey<SideMenuState> sideMenuKey;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final documentAsync = ref.watch(documentProvider);
    final isConnected = ref.watch(documentWebSocketProvider).isConnected;
    double screenWidth = MediaQuery.of(context).size.width;

    final color = theme.textColor;
    return Container(
      height: TopAppBarSize.resolve(context),
      width: screenWidth,
      color: Colors.transparent,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 35, sigmaY: 35),
          child: Container(
            color: theme.sidebar,
            child: Row(
              children: [
                SizedBox(
                  height: 60,
                  width: 60,
                  child: ElevatedButton(
                    style: elevatedButtonStyleRounded10,
                    onPressed: () {
                      SideMenuManager.toggleMenu(
                        ref: ref,
                        menuKey: sideMenuKey,
                      );
                    },
                    child: Center(
                      child: AppIcons.menu(
                        color: color,
                        height: 25.0,
                        width: 25,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                Expanded(
                  child: documentAsync.when(
                    data: (doc) {
                      if (doc == null) return const SizedBox.shrink();
                      return DocumentTitleEditor(documentId: doc.id);
                    },
                    loading: () => const SizedBox.shrink(),
                    error:
                        (_, __) => Text(
                          "Error loading title",
                          style: TextStyle(color: theme.textColor),
                        ),
                  ),
                ),

                const SizedBox(width: 8),
                _ConnectionChip(isConnected: isConnected),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
}

class _ConnectionChip extends StatelessWidget {
  const _ConnectionChip({required this.isConnected});
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color:
            isConnected
                ? Colors.green.withAlpha(51)
                : Colors.orange.withAlpha(51),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.cloud_done : Icons.cloud_off,
            size: 14,
            color: isConnected ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 10),
          Text(
            isConnected ? "Saved" : "Connecting...",
            style: TextStyle(
              fontSize: 12,
              color: isConnected ? Colors.green[700] : Colors.orange[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
