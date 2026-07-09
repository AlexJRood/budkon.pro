import 'package:core/shell/manager/bar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/common/install_popup.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';

class AgentFinancialPlansMobile extends ConsumerStatefulWidget {
  const AgentFinancialPlansMobile({super.key});

  @override
  _AgentFinancialPlansMobileState createState() =>
      _AgentFinancialPlansMobileState();
}

// Listy widgetów dla PageView

class _AgentFinancialPlansMobileState
    extends ConsumerState<AgentFinancialPlansMobile> {
  final sideMenuKey = GlobalKey<SideMenuState>();

  @override
  Widget build(BuildContext context) {
    return PopupListener(
      child: BarManager(
        sideMenuKey: sideMenuKey,
        appModule: AppModule.agentCrm,
        childMobile: const SizedBox(height: 20),
      ),
    );
  }

  // Future<void> _checkForToken() async {
  //   if (ApiServices.token != null) {
  //     // Usunięcie stron logowania i rejestracji z historii nawigacji
  //     ref
  //         .read(navigationHistoryProvider.notifier)
  //         .removeSpecificPages(['/login', '/register']);

  //     // Przekierowanie na ostatnią stronę w historii nawigacji
  //     final lastPage = ref.read(navigationHistoryProvider.notifier).lastPage;
  //     ref.read(navigationService).pushNamedReplacementScreen(lastPage);
  //   }
  // }
}
