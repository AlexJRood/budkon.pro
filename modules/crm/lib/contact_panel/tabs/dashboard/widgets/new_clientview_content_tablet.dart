import 'package:crm/shared/models/clients_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core/theme/apptheme.dart';
import 'package:crm/contact_panel/tabs/dashboard/widgets/new_client_details.dart';
import 'package:crm/contact_panel/tabs/dashboard/widgets/new_client_event.dart';
import 'package:crm/contact_panel/tabs/dashboard/widgets/new_client_photo_card.dart';
import 'package:crm/contact_panel/tabs/dashboard/widgets/new_client_todo.dart';
import 'package:crm/contact_panel/tabs/dashboard/widgets/new_client_transaction.dart';
import 'package:crm/contact_panel/data/client_view_db_calendar_provider.dart';

class ClientDashboardContentTablet extends ConsumerStatefulWidget {
  final UserContactModel clientViewPop;
  const ClientDashboardContentTablet({super.key, required this.clientViewPop});

  @override
  ConsumerState<ClientDashboardContentTablet> createState() =>
      _ClientDashboardContentTabletState();
}

class _ClientDashboardContentTabletState
    extends ConsumerState<ClientDashboardContentTablet> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (kDebugMode) {
        debugPrint('Fetching transactions for tablet...');
      }
      ref
          .read(calendarTransActionByClientProvider.notifier)
          .getTransActionByClient(widget.clientViewPop.id.toString());
      ref
          .read(filterTaskByClientProvider.notifier)
          .filterTaskByClient(widget.clientViewPop.id.toString());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    GlobalKey showMenukey = GlobalKey();
    double dynamicSpacer = 15.0;

    return NotificationListener<OverscrollNotification>(
      // Pozwala listom wewnątrz kart dashboardu (todo, wydarzenia,
      // transakcje) przekazać scroll dalej do tej strony, gdy same
      // dojadą do granicy — tak samo jak w dynamic_dashboard_page.dart.
      onNotification: (notification) {
        if (notification.depth > 0 && _scrollController.hasClients) {
          final pos = _scrollController.position;
          final target = (pos.pixels + notification.overscroll).clamp(
            pos.minScrollExtent,
            pos.maxScrollExtent,
          );
          if (target != pos.pixels) _scrollController.jumpTo(target);
        }
        return false;
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.only(
          left: dynamicSpacer,
          right: dynamicSpacer,
          bottom: 15,
          top: 15, // added top padding for tablet
        ),
        child: Column(
          spacing: dynamicSpacer,
          children: [
            // Row 1: Photo
            ClientPhotowidget(clientViewPop: widget.clientViewPop),

            // Row 2: Details and Todo
            Row(
              spacing: dynamicSpacer,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: NewClientDetails(clientId: widget.clientViewPop.id),
                ),
                Expanded(
                  child: Container(
                    height: 348, // Match height of NewClientDetails
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: theme.dashboardBoarder),
                      color: theme.dashboardContainer,
                    ),
                    child: NewClientTodo(
                      clientId: widget.clientViewPop.id.toString(),
                    ),
                  ),
                ),
              ],
            ),

            // Row 3: Events (Full width)
            NewClientEvent(clientId: widget.clientViewPop.id.toString()),

            // Row 4: Transactions (Full width)
            Container(
              height: 400, // Fixed height or min height for transactions
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: theme.dashboardBoarder),
                color: theme.dashboardContainer,
              ),
              child: NewClientTransaction(
                key: showMenukey,
                clientId: widget.clientViewPop.id.toString(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
