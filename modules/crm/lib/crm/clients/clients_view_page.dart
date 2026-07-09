import 'dart:ui' as ui;

import 'package:crm/contact_panel/tabs/dashboard/new_client_mobile.dart';
import 'package:crm/contact_panel/tabs/dashboard/new_client_tablet.dart';
import 'package:crm/contact_panel/tabs/dashboard/new_clients_view_full.dart';
import 'package:crm/contact_panel/data/client_view_db_calendar_provider.dart';
import 'package:crm/contact_panel/tabs/transactions/transactions_section_mobile.dart';
import 'package:crm/contact_panel/tabs/transactions/tx_client_provider.dart';
import 'package:crm/shared/models/clients_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm/contact_panel/navigation/enum.dart';
import 'package:crm/contact_panel/components/appbar_transaction_mobile.dart';
import 'package:crm/contact_panel/components/buy_vertical_buttons.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:crm/contact_panel/navigation/bottombar_client_panel.dart';
import 'package:crm/crm/clients/components/vertical_buttons_client_list.dart';
import 'package:core/platform/navigation_history_provider.dart';
import 'package:core/platform/platforms/html_utils_stub.dart'
    if (dart.library.html) 'package:core/platform/platforms/html_utils_web.dart';
import 'package:core/theme/apptheme.dart';

class ClientsViewPop extends ConsumerStatefulWidget {
  final UserContactModel clientViewPop;
  final String tagClientViewPop;
  final String activeSection;
  final String activeAd;
  final ContactType contactType;

  const ClientsViewPop({
    super.key,
    required this.clientViewPop,
    required this.tagClientViewPop,
    required this.activeSection,
    required this.activeAd,
    this.contactType = ContactType.client,
  });

  @override
  ConsumerState<ClientsViewPop> createState() => _ClientsViewPopState();
}

class _ClientsViewPopState extends ConsumerState<ClientsViewPop> {
  @override
  void initState() {
    super.initState();
    if (widget.contactType != ContactType.crmUser) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (!mounted) return;
        if (kDebugMode) {
          debugPrint('Fetching transactions...');
        }
        ref
            .read(calendarTransActionByClientProvider.notifier)
            .getTransActionByClient(widget.clientViewPop.id.toString());
        ref
            .read(filterTaskByClientProvider.notifier)
            .filterTaskByClient(widget.clientViewPop.id.toString());
      });
    }

    // debugPrint('Mahdi: initState: ');
    // html.window.onPopState.listen((event) {
    //   Prevent the default back action (navigating to the previous page)
    //   html.window.history.pushState(null, '', html.window.location.href);
    //   debugPrint('Mahdi: initState: back pressed');

    //   final lastPage = ref.read(navigationHistoryProvider.notifier).lastPage;
    //   ref.read(navigationService).replaceNamedScreen(lastPage);
    // });
  }

  void _changeSection(String section) {
    ref.read(activeSectionProvider.notifier).state = section;
    ref.read(navigationHistoryProvider.notifier).addPage(section);
    updateUrl('/pro/clients/${widget.clientViewPop.id}/$section');
  }

  @override
  Widget build(BuildContext context) {
    final activeSection = ref.watch(activeSectionProvider);
    final selectedTx = widget.contactType != ContactType.crmUser
        ? ref.watch(selectedTransactionProvider(widget.clientViewPop.id))
        : null;
    final int? selectedTxId = selectedTx?.id;
    final String? selectedTxIdStr = selectedTx?.id.toString();
    final theme = ref.watch(themeColorsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1020) {
          return NewClientsViewFull(
            clientViewPop: widget.clientViewPop,
            tagClientViewPop: widget.tagClientViewPop,
            activeSection: widget.activeSection,
            activeAd: widget.activeAd,
            contactType: widget.contactType,
          );
        }

        final floatingButtons = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedTxIdStr != null &&
                selectedTx != null &&
                selectedTx.isSeller &&
                activeSection == 'transakcje')
              AdActionsPanel(offerId: selectedTxId),
            if (selectedTx != null &&
                !selectedTx.isSeller &&
                activeSection == 'transakcje')
              ClientPanelVerticalButtons(
                transactionId: selectedTxId,
                clientId: widget.clientViewPop.id,
              ),
            if (activeSection == 'mail')
              MailVerticalBar(onPressed: () {}, showActionList: true),
          ],
        );

        final bottomBar = BottombarClientPanel(
          onTabSelected: _changeSection,
          activeSection: activeSection,
          contactType: widget.contactType,
        );

        final topBar = AppBarMobileTransaction(
          clientId: widget.clientViewPop.id,
          isTransactionSection: activeSection == 'transakcje',
          showTransactions: widget.contactType != ContactType.crmUser,
        );

        final blurBackground = Stack(
          children: [
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: theme.adPopBackground.withAlpha((255 * 0.85).toInt()),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ],
        );

        if (constraints.maxWidth >= 600) {
          return PieCanvas(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  blurBackground,
                  NewClientTablet(
                    clientViewPop: widget.clientViewPop,
                    tagClientViewPop: widget.tagClientViewPop,
                    activeSection: widget.activeSection,
                    activeAd: widget.activeAd,
                    contactType: widget.contactType,
                  ),
                  Positioned(top: 0, left: 0, right: 0, child: topBar),
                  Positioned(bottom: 0, left: 0, right: 0, child: bottomBar),
                  Positioned(bottom: 80, right: 5, child: floatingButtons),
                ],
              ),
            ),
          );
        }

        return PieCanvas(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                blurBackground,
                NewClientMobile(
                  clientViewPop: widget.clientViewPop,
                  tagClientViewPop: widget.tagClientViewPop,
                  activeSection: widget.activeSection,
                  activeAd: widget.activeAd,
                  contactType: widget.contactType,
                ),
                Positioned(top: 0, left: 0, right: 0, child: topBar),
                Positioned(bottom: 0, left: 0, right: 0, child: bottomBar),
                Positioned(bottom: 80, right: 5, child: floatingButtons),
              ],
            ),
          ),
        );
      },
    );
  }
}
