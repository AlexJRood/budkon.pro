import 'package:crm/shared/models/clients_model.dart';
import 'package:crm/contact_panel/data/client_view_db_calendar_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:crm/contact_panel/components/custom_containers.dart';
import 'package:intl/intl.dart';
import 'package:core/theme/lottie.dart';
import 'package:tms_app/todo/models/tasks_model.dart';

import 'package:tms_app/todo/view/task_pup_up.dart';

class TodoListMobile extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> todo;
  final UserContactModel clientViewPop;

  const TodoListMobile({
    super.key,
    required this.todo,
    required this.clientViewPop,
  });

  @override
  ConsumerState<TodoListMobile> createState() => _TodoListMobileState();
}

class _TodoListMobileState extends ConsumerState<TodoListMobile> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ref
          .read(filterTaskByClientProvider.notifier)
          .filterTaskByClient(widget.clientViewPop.id.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final todoData = ref.watch(filterTaskByClientProvider);
    return todoData.isEmpty
        ? Center(child: AppLottie.noResults(size: 450))
        : ListView.builder(
      addAutomaticKeepAlives: false,
      cacheExtent: 300.0,
          itemCount: todoData.length,
          itemBuilder: (context, index) {
            final item = todoData[index];
            final task = Tasks(
              id: item.id,
              description: item.description,
              name: item.name,
              isCompleted: item.isCompleted,
              progressId: item.project,
              projectId: item.project,
              priority: item.priority,
              timestamp: item.timestamp.toString(),
              assignedToUser: item.assignedTo,
              ordering: item.ordering,
            );
            String formattedDate = DateFormat(
              'MMM d, y',
            ).format(item.timestamp);
            return InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) {
                    return TaskDetailsPopup(task: task,isMobile: true,);
                  },
                );
              },
              child: Card(
                color: theme.dashboardContainer,
                margin: const EdgeInsets.all(5),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          SizedBox(
                            child: Prioritycontainer(
                              isPC: true,
                              priority: item.priority,
                            ),
                          ),
                          const SizedBox(width: 5),
                          DateContainer(date: formattedDate, isPc: true),
                          Spacer(),
                          IconButton(
                            highlightColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            padding: const EdgeInsets.all(0),
                            onPressed: () {},
                            icon: Icon(
                              Icons.more_vert_rounded,
                              size: 14,
                              color: theme.textColor,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Checkbox(
                            side: BorderSide(color: theme.textColor),
                            value: false,
                            onChanged: (val) {},
                          ),
                          const SizedBox(width: 5),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                item.description,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
  }
}
