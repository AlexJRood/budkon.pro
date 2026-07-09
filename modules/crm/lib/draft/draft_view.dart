import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:crm/contact_panel/tabs/transactions/transaction_docs_view.dart';
import 'package:crm/contact_panel/tabs/transactions/transaction_view.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DraftView extends ConsumerStatefulWidget {
  final int id;
  final AgentTransactionModel? ad;

  const DraftView({super.key, required this.id, required this.ad});

  @override
  ConsumerState<DraftView> createState() => _DraftListState();
}

class _DraftListState extends ConsumerState<DraftView> {

  @override
  Widget build(BuildContext context) {
    final sideMenuKey = GlobalKey<SideMenuState>();

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.agentCrm,
      isTopAppBarOff: true,
      childPc: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
        // WAŻNE: przekaż ten sam 'type' do TransactionView,
        // żeby i przyciski, i content słuchały TEGO SAMEGO providera
        child: TransactionView(
          clientId: widget.id,
          transaction: widget.ad,
          type: TransactionType.create, // <--- DODAJ ten argument w TransactionView
        ),
      ),
    );
  }
}
