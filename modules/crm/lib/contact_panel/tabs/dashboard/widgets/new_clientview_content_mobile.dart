import 'package:crm/shared/models/clients_model.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:calendar/widgets/save_event_widget.dart';
import 'package:crm/contact_panel/components/const.dart';
import 'package:crm/contact_panel/components/no_todo_widget.dart';
import 'package:crm/contact_panel/mobile/event_mobile.dart';
import 'package:crm/contact_panel/mobile/todo_mobile.dart';
import 'package:crm/contact_panel/mobile/new_client_card_mobile.dart';
import 'package:crm/contact_panel/mobile/new_client_details_mobile.dart';
import 'package:crm/widget/add_task_dialog_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:crm/contact_panel/tabs/dashboard/widgets/new_client_transaction.dart';
import 'package:crm/contact_panel/data/client_view_db_calendar_provider.dart';

class ClientDashboardContentMobile extends ConsumerStatefulWidget {
  final UserContactModel clientViewPop;
  const ClientDashboardContentMobile({super.key, required this.clientViewPop});

  @override
  ConsumerState<ClientDashboardContentMobile> createState() =>
      _ClientDashboardContentMobileState();
}

class _ClientDashboardContentMobileState
    extends ConsumerState<ClientDashboardContentMobile> {
  // ✅ Keep controller in State (do NOT create it in build)
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  @override
  void dispose() {
    // ✅ Always dispose controllers
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    final screenHeight = MediaQuery.of(context).size.height;
    if (kDebugMode) {
      debugPrint('ClientDashboardContentMobile height: $screenHeight');
    }

    final double bottomInset = BottomBarSize.resolve(context) + 10;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: SingleChildScrollView(
          controller: _scrollController,
          // ✅ Important: when you pass your own controller, primary should be false
          primary: false,
          padding: const EdgeInsets.only(left: 12, right: 12),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: TopAppBarSize.resolve(context)),

              // ===== HEADER CARD =====
              NewClientCardMobile(
                onTap: () {},
                id: widget.clientViewPop.id,
                avatar: widget.clientViewPop.avatar ?? '',
                name: widget.clientViewPop.name ?? '',
                lastName: widget.clientViewPop.lastName ?? '',
                email: widget.clientViewPop.email ?? '',
                phoneNumber: widget.clientViewPop.phoneNumber ?? '',
              ),

              const SizedBox(height: 15),

              NewClientDetailsMobile(clientId: widget.clientViewPop.id),

              const SizedBox(height: 20),

              // ===== EVENTS =====
              Row(
                children: [
                  Text(
                    "Planned Events".tr,
                    style: TextStyle(color: theme.textColor, fontSize: 18),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: theme.dashboardContainer,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        builder: (context) {
                          return DraggableScrollableSheet(
                            initialChildSize: 0.85,
                            minChildSize: 0.4,
                            maxChildSize: 0.95,
                            expand: false,
                            builder:
                                (ctx, scrollController) => SaveEventWidget(
                                  index: 0,
                                  isMobile: true,
                                  clientId: widget.clientViewPop.id.toString(),
                                  scrollController: scrollController,
                                ),
                          );
                        },
                      );
                    },
                    icon: Icon(Icons.add, size: 20, color: theme.textColor),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: NewClientEventMobile(
                  clientId: widget.clientViewPop.id.toString(),
                ),
              ),

              const SizedBox(height: 20),

              // ===== TODO =====
              if (todo.isNotEmpty) ...[
                Row(
                  children: [
                    Text(
                      "To-Do".tr,
                      style: TextStyle(color: theme.textColor, fontSize: 18),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder:
                              (ctx) => AddTaskDialogWidget(
                                clientId: widget.clientViewPop.id.toString(),
                              ),
                        );
                      },
                      icon: Icon(Icons.add, size: 20, color: theme.textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 400,
                  child: TodoListMobile(
                    todo: todo,
                    clientViewPop: widget.clientViewPop,
                  ),
                ),
                const SizedBox(height: 15),
              ] else ...[
                const SizedBox(height: 10),
                const SizedBox(height: 400, child: TodoNoclient(isPc: false)),
                const SizedBox(height: 15),
              ],

              // ===== TRANSACTIONS =====
              Container(
                height: 500,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: theme.dashboardBoarder),
                  color: theme.dashboardContainer,
                ),
                child: NewClientTransaction(
                  // ✅ This is now stable and correct
                  scrollController: _scrollController,
                  isMobile: true,
                  clientId: widget.clientViewPop.id.toString(),
                ),
              ),

              SizedBox(height: bottomInset),
            ],
          ),
        ),
      ),
    );
  }
}
