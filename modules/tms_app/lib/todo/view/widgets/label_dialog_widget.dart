import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';
import 'package:tms_app/todo/provider/task_labels_provider.dart';
import 'package:tms_app/todo/provider/todo_provider.dart';
import 'package:tms_app/todo/view/widgets/label_selector_widget.dart';
import 'create_label_dialog_widget.dart';
import 'package:tms_app/todo/view/model/task_label_model.dart';

class LabelDialogWidget extends ConsumerStatefulWidget {
  final String taskId;
  const LabelDialogWidget({super.key, required this.taskId});

  @override
  ConsumerState<LabelDialogWidget> createState() => _LabelDialogWidgetState();
}

class _LabelDialogWidgetState extends ConsumerState<LabelDialogWidget> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final allTasks = ref.read(taskDetailsProvider);
      final task = allTasks.firstWhereOrNull(
        (t) => t.id.toString() == widget.taskId,
      );
      final labelIds =
          task?.labels
              ?.map((e) => int.tryParse(e.toString()))
              .whereType<int>()
              .toList() ??
          <int>[];
      ref.read(selectedLabelIdsProvider(widget.taskId).notifier).state = labelIds;

    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final labels = ref.watch(filteredLabelsProvider);
   final selectedIds = ref.watch(selectedLabelIdsProvider(widget.taskId));


    return Dialog(
      backgroundColor: theme.adPopBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              cursorColor: theme.textColor,
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.textFieldColor,
                hintText: 'Search labels...'.tr,
                hintStyle: TextStyle(color: theme.textColor),
                prefixIcon: Icon(Icons.search, color: theme.textColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              style: TextStyle(color: theme.textColor),
              onChanged:
                  (val) =>
                      ref.read(searchLabelQueryProvider.notifier).state = val,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: labels.isEmpty
                  ? Center(
                child: AppLottie.noResults(),
              )
                  :ListView.builder(
                addAutomaticKeepAlives: false,
                cacheExtent: 300.0,
                itemCount: labels.length,
                itemBuilder: (_, index) {
                  final label = labels[index];
                  final isSelected = selectedIds.contains(label.id);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: InkWell(
                      onTap: () async {
                        final updated = [...selectedIds];
                        if (isSelected) {
                          updated.remove(label.id);
                        } else {
                          updated.add(label.id);
                        }

                      ref.read(selectedLabelIdsProvider(widget.taskId).notifier).state =updated;


                        await ref
                            .read(taskProvider.notifier)
                            .editTask(context, widget.taskId, 'labels', updated);

                        ref
                            .read(taskDetailsProvider.notifier)
                            .updateTask(widget.taskId, 'labels', updated);
                      },
                      child: Row(
                        children: [
                          Checkbox(
                            activeColor: theme.themeColor,
                            checkColor: theme.themeTextColor,
                            value: isSelected,
                            onChanged: (val) async {
                              final updated = [...selectedIds];
                              if (val == true) {
                                updated.add(label.id);
                              } else {
                                updated.remove(label.id);
                              }

                            ref.read(selectedLabelIdsProvider(widget.taskId).notifier).state = updated;
                              await ref
                                  .read(taskProvider.notifier)
                                  .editTask(
                                    context,
                                    widget.taskId,
                                    'label',
                                    updated,
                                  );
                              ref
                                  .read(taskDetailsProvider.notifier)
                                  .updateTask(widget.taskId, 'labels', updated);
                            },
                          ),
                          Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Color(
                                  int.parse(
                                    label.color.replaceFirst('#', '0xff'),
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    label.name,
                                    style: TextStyle(color: theme.textColor),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: theme.textColor,
                              size: 18,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder:
                                    (_) => CreateLabelDialogWidget(
                                      editLabel: label,
                                      isEditMode: true,
                                    ),
                              ).then((_) {
                                // refresh list after editing
                                ref
                                    .read(taskLabelsProvider.notifier)
                                    .fetchLabels();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            InkWell(
              onTap: () async {
                ref.read(labelColorProvider.notifier).state = null;
                ref.read(labelNameProvider.notifier).state = '';

                final result = await showDialog(
                  context: context,
                  builder: (_) => const CreateLabelDialogWidget(),
                );

                TaskLabel? created;
                if (result is TaskLabel) {
                  created = result;
                } else if (result == true) {
                  await ref.read(taskLabelsProvider.notifier).fetchLabels();
                  final all =
                      ref.read(taskLabelsProvider)?.results ?? <TaskLabel>[];
                  final createdName = ref.read(labelNameProvider);
                  final createdColor = ref.read(labelColorProvider);
                  created = all.firstWhereOrNull(
                    (l) =>
                        l.name == createdName &&
                        l.color.toLowerCase() ==
                            (createdColor ?? '').toLowerCase(),
                  );
                }

                if (created != null) {
                  final current = ref.read(selectedLabelIdsProvider(widget.taskId));
                  final updated = {...current, created.id}.toList();
                 ref.read(selectedLabelIdsProvider(widget.taskId).notifier).state = updated;
                  await ref
                      .read(taskProvider.notifier)
                      .editTask(context, widget.taskId, 'label', updated);

                  ref
                      .read(taskDetailsProvider.notifier)
                      .updateTask(widget.taskId, 'label', updated);

                  await ref.read(taskLabelsProvider.notifier).fetchLabels();
                }
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: theme.themeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    'Create a new label'.tr,
                    style: TextStyle(color: theme.themeTextColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
