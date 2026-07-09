import 'package:crm/bars/top_app_bar_crm.dart';
import 'package:crm/bars/agent/sidebar.dart';
import 'package:core/shell/keyboard_shortcuts.dart';
import 'package:core/common/chrome/side_menu_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:crm/crm/finance/financial_plans/financal_plan_expenses.dart';
import 'package:crm/crm/finance/financial_plans/financal_plan_revenue.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';

class AgentFinancialPlanspc extends ConsumerStatefulWidget {
  const AgentFinancialPlanspc({super.key});

  @override
  _AgentFinancalPlansState createState() => _AgentFinancalPlansState();
}

class _AgentFinancalPlansState extends ConsumerState<AgentFinancialPlanspc>
    with AutomaticKeepAliveClientMixin {
  bool showExpenses = true; // Przechowuje stan dla przełączania widoków
  final sideMenuKey = GlobalKey<SideMenuState>();
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
    double screenWidth = MediaQuery.of(context).size.width;
    double screenPadding = screenWidth / 10;
    final theme = ref.watch(themeColorsProvider);
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
      child: Scaffold(
        body: SideMenuManager.sideMenuSettings(
          menuKey: sideMenuKey,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SidebarAgentCrm(sideMenuKey: sideMenuKey),
              Expanded(
                child: Column(
                  children: [
                    const TopAppBarCRM(),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        SizedBox(width: screenPadding),
                        // Dwa przyciski typu ChoiceChip
                        Container(
                          height: 50,
                          padding: const EdgeInsets.all(5),
                          child: ChoiceChip(
                            checkmarkColor: Theme.of(context).iconTheme.color,
                            selectedColor: Theme.of(context).primaryColor,
                            // Color when selected
                            backgroundColor: theme.fillColor,
                            // selectedColor: Theme.of(context).colorScheme.primary,
                            label: Text(
                              'Show Expenses'.tr,
                              style: TextStyle(
                                color:
                                    showExpenses
                                        ? Theme.of(context).iconTheme.color
                                        : theme.textFieldColor,
                              ),
                            ),
                            selected: showExpenses,
                            onSelected: (selected) {
                              setState(() {
                                showExpenses = true; // Wybierz wydatki
                              });
                            },
                            // backgroundColor: AppColors.light,
                            // selectedColor: AppColors.superbee,
                            labelStyle: const TextStyle(
                              color: // showExpenses ? Colors.white :
                                  Colors.black,
                            ),
                          ),
                        ),
                        Container(
                          height: 50,
                          padding: const EdgeInsets.all(5),
                          child: ChoiceChip(
                            checkmarkColor: Theme.of(context).iconTheme.color,
                            selectedColor: Theme.of(context).primaryColor,
                            // Color when selected
                            backgroundColor: theme.fillColor,
                            label: Text(
                              'Show Revenue'.tr,
                              style: TextStyle(
                                color:
                                    !showExpenses
                                        ? Theme.of(context).iconTheme.color
                                        : theme.textFieldColor,
                              ),
                            ),
                            selected: !showExpenses,
                            onSelected: (selected) {
                              setState(() {
                                showExpenses = false; // Wybierz przychody
                              });
                            },
                            // backgroundColor: AppColors.light,
                            // selectedColor: AppColors.superbee,
                            labelStyle: TextStyle(
                              color: // showExpenses ? Colors.white :
                                  Theme.of(context).iconTheme.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Center(
                        child:
                            showExpenses
                                ? const FinancialPlansExpenses()
                                : const FinancialPlansRevenue(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
