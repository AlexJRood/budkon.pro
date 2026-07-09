import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/shell/keyboard_shortcuts.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/design.dart';
import 'package:crm_agent/crm/agent_financial_plans_mobile.dart';
import 'package:crm_agent/crm/agent_financial_plans_pc.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:pie_menu/pie_menu.dart';

class AgentFinancialPlansPage extends ConsumerStatefulWidget {
  const AgentFinancialPlansPage({super.key});

  @override
  ConsumerState<AgentFinancialPlansPage> createState() =>
      _AgentFinancialPlansPageState();
}

class _AgentFinancialPlansPageState
    extends ConsumerState<AgentFinancialPlansPage>
    with AutomaticKeepAliveClientMixin {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        // Check if the pressed key matches the stored pop key
        KeyBoardShortcuts().handleKeyNavigation(event, ref, context);
        final Set<LogicalKeyboardKey> pressedKeys =
            HardwareKeyboard.instance.logicalKeysPressed;
        final LogicalKeyboardKey? shiftKey = ref.watch(togglesidemenu1);
        if (pressedKeys.contains(ref.watch(adclientprovider)) &&
            !pressedKeys.contains(shiftKey)) {
          ref
              .read(navigationService)
              .pushNamedScreen(Routes.proFinanceRevenueAdd);
        }
      },
      child: PieCanvas(
        theme: const PieTheme(
          rightClickShowsMenu: true,
          leftClickShowsMenu: false,
          buttonTheme: PieButtonTheme(
            backgroundColor: AppColors.buttonGradient1,
            iconColor: Colors.white,
          ),
          buttonThemeHovered: PieButtonTheme(
            backgroundColor: Color.fromARGB(96, 58, 58, 58),
            iconColor: Colors.white,
          ),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth > 1080) {
              return const AgentFinancialPlanspc();
            } else {
              return AgentFinancialPlansMobile();
            }
          },
        ),
      ),
    );
  }
}
