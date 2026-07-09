import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:emma/widgets/chat_conversation_pane.dart';
import 'package:emma/widgets/message_list.dart';
import 'package:emma/widgets/send_message_box.dart';
import 'package:emma/widgets/sidebar_chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:emma/widgets/appbar_chat.dart';



class EmmaChatScreen extends ConsumerStatefulWidget {
  const EmmaChatScreen({super.key});

  @override
  ConsumerState<EmmaChatScreen> createState() => _EmmaChatScreenState();
}

class _EmmaChatScreenState extends ConsumerState<EmmaChatScreen> {
  final GlobalKey<SideMenuState> _sideMenuKey = GlobalKey<SideMenuState>();

  @override
  Widget build(BuildContext context) {
    return BarManager(
      sideMenuKey: _sideMenuKey,

      // Jeżeli u Ciebie enum ma inną nazwę modułu, np. AppModule.emma,
      // podmień tylko tę wartość.
      appModule: AppModule.agentCrm,
      isBottomBarOff: true,

      isChildExpanded: true,
      enableScrool: false,

      paddingPc: 0,
      paddingTablet: 0,
      paddingMobile: 0,
      spacing: 0,

      tabletScaffoldMode: TabletScaffoldMode.pc,

      layoutTypePc: LayoutTypePc.stack,
      childPc: const _EmmaChatPcContent(isPc: true),
      childTablet: const _EmmaChatPcContent(isPc: false),

      layoutTypeMobile: LayoutTypeMobile.stack,
      childrenMobile: const [
        _EmmaChatMobileConversation(),
      ],

      // Swipe w prawo na mobile pokaże listę czatów.
      childrenMobileSwipeLeft: const [
        _EmmaChatMobileSessions(),
      ],
    );
  }
}

class _EmmaChatPcContent extends ConsumerWidget {
  final bool isPc;
  const _EmmaChatPcContent({Key? key, this.isPc = true}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final sidebarWidth = constraints.maxWidth < 1100 ? 280.0 : 340.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: theme.adPopBackground.withAlpha((255 * 0.18).toInt()),
            child: Row(
              children: [
                SizedBox(
                  width: sidebarWidth,
                    child: const _HoverRevealChatSidebar(
                      idleOpacity: 0.05,
                      hoverOpacity: 1.0,
                      child: ChatAiSideBar(),
                    ),
                ),

                const Expanded(
                  child: ChatConversationPane(
                    isMobile: false,
                    isAppBar: false
                  ),
                ),
                if(isPc)
                
                SizedBox(
                  width: sidebarWidth,
                    child: _HoverRevealChatSidebar(
                      idleOpacity: 0.05,
                      hoverOpacity: 1.0,
                      child: AiVerticalSidebar(width: sidebarWidth, showCloseButton: false),
                    ),
                ),
                
                 
                if(!isPc)
                 AiVerticalSidebar(width: 72, showCloseButton: false),
              ],

            ),
          ),
        );
      },
    );
  }
}

class _HoverRevealChatSidebar extends StatefulWidget {
  const _HoverRevealChatSidebar({
    required this.child,
    this.idleOpacity = 0.38,
    this.hoverOpacity = 1.0,
  });

  final Widget child;
  final double idleOpacity;
  final double hoverOpacity;

  @override
  State<_HoverRevealChatSidebar> createState() =>
      _HoverRevealChatSidebarState();
}

class _HoverRevealChatSidebarState extends State<_HoverRevealChatSidebar> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (_isHovered) return;
        setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (!_isHovered) return;
        setState(() => _isHovered = false);
      },
      child: AnimatedOpacity(
        opacity: _isHovered ? widget.hoverOpacity : widget.idleOpacity,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _EmmaChatMobileConversation extends ConsumerWidget {
  const _EmmaChatMobileConversation();

  static const double _topBarSpace = 68;
  static const double _bottomBarSpace = 0;
  static const double _inputHeightSpace = 92;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = MediaQuery.of(context);
    final keyboardVisible = media.viewInsets.bottom > 0;

    final topPadding = media.padding.top + _topBarSpace;

    final inputBottomPadding = keyboardVisible
        ? 8.0
        : media.padding.bottom + _bottomBarSpace;

    final listBottomPadding = inputBottomPadding;

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.only(
              top: topPadding,
              bottom: listBottomPadding,
            ),
            child: const MessageListView(
              isMobile: true,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: inputBottomPadding,
          child: const SendMessageBox(
            isMobile: true,
          ),
        ),
      ],
    );
  }
}

class _EmmaChatMobileSessions extends ConsumerWidget {
  const _EmmaChatMobileSessions();

  static const double _topBarSpace = 68;
  static const double _bottomBarSpace = 78;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(
        top: media.padding.top + _topBarSpace,
        bottom: media.padding.bottom + _bottomBarSpace,
        left: 8,
        right: 8,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.adPopBackground.withAlpha((255 * 0.35).toInt()),
            border: Border.all(
              color: Colors.white.withAlpha(22),
              width: 1,
            ),
          ),
          child: const ChatAiSideBar(
            isMobile: true,
          ),
        ),
      ),
    );
  }
}