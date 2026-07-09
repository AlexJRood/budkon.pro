import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import '../../models/tasks_model.dart';
import 'package:tms_app/todo/provider/todo_provider.dart';

/// Are we editing the task name? (per task id)
final isEditingTaskNameProvider = StateProvider.family<bool, String>(
  (ref, taskId) => false,
);

/// Draft input while editing (per task id)
final taskNameDraftProvider = StateProvider.family<String, String>(
  (ref, taskId) => '',
);

/// Optimistic override shown immediately after submit (per task id)
/// If null, fall back to the server value from `task.name`.
final taskTitleOverrideProvider = StateProvider.family<String?, String>(
  (ref, taskId) => null,
);

class DialogHeader extends ConsumerStatefulWidget {
  final Tasks task;
  final VoidCallback? onClose;

  const DialogHeader({
    super.key,
    required this.task,
    this.onClose,
  });

  @override
  ConsumerState<DialogHeader> createState() => _DialogHeaderState();
}

class _DialogHeaderState extends ConsumerState<DialogHeader> {
   late final FocusNode _titleFocus;

  @override
  void initState() {
    super.initState();
    _titleFocus = FocusNode();
  }

  @override
  void dispose() {
    _titleFocus.dispose();
    super.dispose();
  }

  void _postFrame(VoidCallback action) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    action();
  });
}


  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final taskId = (widget.task.id ?? 0).toString();

    final isEditing = ref.watch(isEditingTaskNameProvider(taskId));
    final draft = ref.watch(taskNameDraftProvider(taskId));
    final override = ref.watch(taskTitleOverrideProvider(taskId));

    final shownName = (override ?? widget.task.name ?? '').trim();

    Future<void> submit(String value) async {
      _titleFocus.unfocus();
      final previous = shownName;
      final newName = value.trim();
      ref.read(isEditingTaskNameProvider(taskId).notifier).state = false;

      if (newName.isEmpty || newName == previous) return;

      ref.read(taskTitleOverrideProvider(taskId).notifier).state = newName;

      try {
        await ref.read(taskProvider.notifier).editTask(context, taskId, 'name', newName);
      } catch (e) {
        ref.read(taskTitleOverrideProvider(taskId).notifier).state = previous;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to rename task: $e')),
        );
      }
    }

    Widget title;
    if (isEditing) {
      title = TextFormField(
        focusNode: _titleFocus,
        key: ValueKey('editing_$taskId'),
        autofocus: true,
        maxLines: 1,
        initialValue: draft.isEmpty ? shownName : draft,
        onTapOutside: (_) {
        _titleFocus.unfocus();
        _postFrame(() {
         ref.read(isEditingTaskNameProvider(taskId).notifier).state = false;
        });
      },
        style: AppTextStyles.interMedium22.copyWith(
          fontWeight: FontWeight.w900,
          color: theme.textColor,
          height: 1.1,
        ),
        cursorColor: theme.themeColor,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: theme.adPopBackground,
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          hintText: 'Task title',
          hintStyle: TextStyle(color: theme.textColor.withValues(alpha: .5)),
          border: const UnderlineInputBorder(),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: theme.themeColor, width: 2),
          ),
        ),
        onChanged: (v) => ref.read(taskNameDraftProvider(taskId).notifier).state = v,
        onFieldSubmitted: submit,
      );
    } else {
      title = InkWell(
        onTap: () {
        ref.read(taskNameDraftProvider(taskId).notifier).state = shownName;
        ref.read(isEditingTaskNameProvider(taskId).notifier).state = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
          _titleFocus.requestFocus();
       });
    },
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Text(
          shownName,
            maxLines: 3,                 
            overflow: TextOverflow.visible, 
          style: AppTextStyles.interMedium22.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.textColor,
            height: 1.1,
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.table_rows_rounded, color: theme.textColor),
        ),
        Expanded(child: title),
        IconButton(
          color: theme.textColor,
          icon: const Icon(Icons.close_rounded, size: 30),
        onPressed: () {
         FocusManager.instance.primaryFocus?.unfocus();
         _postFrame(() {
          ref.read(isEditingTaskNameProvider(taskId).notifier).state = false;
          widget.onClose?.call();
         });
         },
        ),
      ],
    );
  }
}
