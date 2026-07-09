import 'package:core/shell/manager/bar_manager.dart';
import 'package:crm/crm/finance/features/transactions/columns_transactions.dart';
import 'package:crm/contact_panel/components/buy_vertical_buttons.dart';
import 'package:crm/contact_panel/components/appbar_transaction_mobile.dart';
import 'package:crm/contact_panel/tabs/dashboard/new_clients_view_full.dart';
import 'package:crm/contact_panel/tabs/transactions/transactions_section_mobile.dart';
import 'package:crm/contact_panel/tabs/transactions/tx_client_provider.dart';
import 'package:crm/contact_panel/view_changer.dart';
import 'package:crm/contact_panel/navigation/bottombar_client_panel.dart';
import 'package:crm/shared/models/clients_model.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:crm/crm/clients/components/vertical_buttons_client_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/navigation_history_provider.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';

import 'package:core/platform/platforms/html_utils_stub.dart'
    if (dart.library.html) 'package:core/platform/platforms/html_utils_web.dart';
import 'package:crm/contact_panel/navigation/enum.dart';

class NewClientTablet extends ConsumerStatefulWidget {
  final UserContactModel clientViewPop;
  final String tagClientViewPop;
  final String activeSection;
  final String activeAd;
  final ContactType contactType;

  const NewClientTablet({
    super.key,
    this.contactType = ContactType.client,
    required this.clientViewPop,
    required this.tagClientViewPop,
    required this.activeSection,
    required this.activeAd,
  });

  @override
  ConsumerState<NewClientTablet> createState() => _NewClientTabletState();
}

class _NewClientTabletState extends ConsumerState<NewClientTablet> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final shouldNavigate =
          ref.read(isNavigateFromFinanceDraggableProvider).triggered;

      final initial = shouldNavigate ? 'transakcje' : widget.activeSection;

      ref.read(activeSectionProvider.notifier).state = initial;
    });
  }

  void openTransactionSection(
    String section,
    AgentTransactionModel transaction,
  ) {
    ref.read(activeSectionProvider.notifier).state = section;
    ref.read(openTransactionIdProvider.notifier).state =
        transaction.id.toString();
    updateUrl(
      '/pro/clients/${widget.clientViewPop.id}/transakcje/${transaction.id}',
    );
  }

  // Changing section
  void _changeSection(String section) {
    ref.read(activeSectionProvider.notifier).state = section;
    ref.read(navigationHistoryProvider.notifier).addPage(section);
    updateUrl('/pro/clients/${widget.clientViewPop.id}/$section');
  }

  @override
  void didUpdateWidget(covariant NewClientTablet oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldId = oldWidget.clientViewPop.id;
    final newId = widget.clientViewPop.id;

    if (oldId != newId) {
      Future.microtask(() {
        ref.read(activeSectionProvider.notifier).state = 'dashboard';
        ref.read(openTransactionIdProvider.notifier).state = null;
      });
    }
  }

  // String _selectedSegment = '/transakcje';
  // void updateSelected(Set<String> selected) {
  //   setState(() {
  //     _selectedSegment = selected.first;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final activeSection = ref.watch(activeSectionProvider);
    final openTransaction = ref.watch(openTransactionIdProvider);

    return ClientViewContent(
      isTablet: true,
      isMobile: false,
      activeSection: activeSection,
      clientViewPop: widget.clientViewPop,
      activeAd: widget.activeAd,
      openTransaction: openTransaction,
      contactType: widget.contactType,
    );
  }
}
