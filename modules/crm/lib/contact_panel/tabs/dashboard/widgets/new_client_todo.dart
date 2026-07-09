import 'package:crm/contact_panel/components/custom_containers.dart';
import 'package:crm/contact_panel/data/client_view_db_calendar_provider.dart';
import 'package:crm/widget/add_task_dialog_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';
import 'package:tms_app/todo/board/provider/board_provider.dart';
import 'package:tms_app/todo/models/tasks_model.dart';
import 'package:tms_app/todo/provider/todo_provider.dart';
import 'package:tms_app/todo/view/task_pup_up.dart';

final showAllClientTodoProvider = StateProvider<bool>((ref) => false);

class NewClientTodo extends ConsumerStatefulWidget {
  final String clientId;
  const NewClientTodo({super.key, required this.clientId});

  @override
  ConsumerState<NewClientTodo> createState() => _NewClientTodoState();
}

class _NewClientTodoState extends ConsumerState<NewClientTodo> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref.read(boardManagementProvider.notifier).fetchBoards(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final todoData = ref.watch(filterTaskByClientProvider);
    final showAllTasks = ref.watch(showAllClientTodoProvider);

    final visibleTodoData =
    showAllTasks
        ? todoData
        : todoData.where((task) => task.isCompleted != true).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Column below relies on Expanded to bound the task list; if a
        // caller ever hosts this widget in an unbounded-height context
        // (e.g. a plain Column/ScrollView without a fixed size), fall
        // back to a sane height so the list scrolls instead of overflowing.
        final maxHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 400.0;

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: _buildBody(theme, visibleTodoData, showAllTasks),
        );
      },
    );
  }

  Widget _buildBody(
    ThemeColors theme,
    List<dynamic> visibleTodoData,
    bool showAllTasks,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: theme.dashboardBoarder),
        color: theme.dashboardContainer,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'task_list_title'.tr,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        theme.clientbuttoncolor,
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      minimumSize: WidgetStateProperty.all(const Size(0, 32)),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      ref.read(showAllClientTodoProvider.notifier).state =
                      !showAllTasks;
                    },
                    child: Text(
                      showAllTasks
                          ? 'show_unfinished_button'.tr
                          : 'show_all_button'.tr,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(fontSize: 10, color: theme.textColor),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        theme.clientbuttoncolor,
                      ),
                      shape: WidgetStatePropertyAll(
                        (RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        )),
                      ),
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      minimumSize: WidgetStateProperty.all(const Size(0, 32)),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(Icons.add, color: theme.textColor, size: 14),
                    label: Text(
                      'add_task_button'.tr,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(fontSize: 10, color: theme.textColor),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) =>
                            AddTaskDialogWidget(clientId: widget.clientId),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
          const SizedBox(height: 15),
          visibleTodoData.isEmpty
              ? Center(child: AppLottie.noResults(size: 350))
              : Expanded(
            child: ListView.builder(
              addAutomaticKeepAlives: false,
              cacheExtent: 300.0,
              itemCount: visibleTodoData.length,
              itemBuilder: (context, index) {
                final item = visibleTodoData[index];
                final isCompleted = item.isCompleted;

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
                    showDialog(
                      context: context,
                      builder: (_) => TaskDetailsPopup(task: task),
                    ).whenComplete(() {
                      ref
                          .read(filterTaskByClientProvider.notifier)
                          .filterTaskByClient(widget.clientId);
                    });
                  },
                  child: Card(
                    color: theme.adPopBackground,
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
                              DateContainer(
                                date: formattedDate,
                                isPc: true,
                              ),
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

                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth:
                              MediaQuery.of(context).size.width - 40,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Checkbox(
                                  side: BorderSide(color: theme.textColor),
                                  activeColor: theme.themeColor,
                                  value: isCompleted,
                                  onChanged: (val) async {
                                    if (val == null) return;

                                    final newValue = !isCompleted;

                                    ref
                                        .read(taskDetailsProvider.notifier)
                                        .updateTask(item.id.toString(), 'is_completed', newValue);

                                    try {
                                      await ref
                                          .read(taskProvider.notifier)
                                          .editTask(context, item.id.toString(), 'is_completed', newValue).whenComplete(() {
                                        ref
                                            .read(filterTaskByClientProvider.notifier)
                                            .filterTaskByClient(widget.clientId);
                                      },);
                                    } catch (e) {
                                      ref
                                          .read(taskDetailsProvider.notifier)
                                          .updateTask(item.id.toString(), 'is_completed', isCompleted);

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('failed_to_update_task_status'.tr)),
                                      );
                                    }
                                  },
                                ),

                                const SizedBox(width: 5),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: theme.textColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        item.description,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style: TextStyle(
                                          color: theme.textColor,
                                          fontSize: 12,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
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
              },
            ),
          ),
        ],
      ),
    );
  }
}