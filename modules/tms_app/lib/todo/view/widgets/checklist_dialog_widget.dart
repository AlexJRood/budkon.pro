import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:tms_app/todo/provider/task_checklist_provider.dart';
import 'package:tms_app/todo/provider/todo_provider.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ChecklistDialogWidget extends ConsumerStatefulWidget {
  final String taskId;
  const ChecklistDialogWidget({super.key, required this.taskId});

  @override
  ConsumerState<ChecklistDialogWidget> createState() => _ChecklistDialogWidgetState();
}

class _ChecklistDialogWidgetState extends ConsumerState<ChecklistDialogWidget> {
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Autofocus after the dialog is laid out
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final payload = {
      "title": title,
      "description": "Checklist created from UI",
      "checklist": []
    };

    await ref.read(taskChecklistProvider.notifier).createChecklist(widget.taskId, payload);
    await ref.read(taskDetailsProvider.notifier).fetchTask(widget.taskId);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    return Dialog(
      backgroundColor: theme.dashboardContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          // Enter keys submit the form
          LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
          LogicalKeySet(LogicalKeyboardKey.numpadEnter): const ActivateIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (intent) {
              _submit();
              return null;
            }),
          },
          child: Focus(
            autofocus: true,
            child: Container(
              width: 400,
              height: 260,

              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Checklist'.tr,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Title'.tr, style: TextStyle(color: theme.textColor)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    focusNode: _focusNode,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(), 
                    cursorColor: theme.textColor,
                    decoration: InputDecoration(
                      hintText: 'Enter checklist title'.tr,
                      hintStyle: TextStyle(color: theme.textColor.withAlpha(153)),
                      filled: true,
                      fillColor: theme.adPopBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(color: theme.textColor),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.themeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: _submit,
                      child: Text(
                        'Add'.tr,
                        style: TextStyle(
                          color: theme.themeTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
