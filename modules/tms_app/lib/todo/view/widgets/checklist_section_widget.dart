import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:tms_app/todo/models/tasks_model.dart';
import 'package:tms_app/todo/provider/task_checklist_provider.dart';
import 'package:tms_app/todo/provider/todo_provider.dart';
import 'package:core/user/user/user_provider.dart';

final addRowOpenProvider = StateProvider.family<bool, String>(
  (ref, checklistId) => false,
);

class ChecklistSection extends ConsumerStatefulWidget {
  final TaskChecklist checklist;
  final Function(List<ChecklistItem>) onChecklistUpdated;
  final String taskId;

  const ChecklistSection({
    super.key,
    required this.checklist,
    required this.onChecklistUpdated,
    required this.taskId,
  });

  @override
  ConsumerState<ChecklistSection> createState() => _ChecklistSectionState();
}

class _ChecklistSectionState extends ConsumerState<ChecklistSection> {
  late final TextEditingController controller;
  final FocusNode _addFocusNode = FocusNode();

  // --- Subskrypcje Riverpoda przeniesione do initState
  ProviderSubscription<bool>? _addOpenSub;
  ProviderSubscription<dynamic>? _checklistSub;
  final GlobalKey _addItemKey = GlobalKey();

  // trzymamy ID jako string, żeby nie powtarzać konwersji
  late final String _id;

  void _scrollToField(GlobalKey key) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      final ctx = key.currentContext;
      if (ctx == null) return;

      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: 0.2,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    _id = widget.checklist.id.toString();

    // 🔔 focus na polu dodawania, gdy otworzymy "Add row"
    _addOpenSub = ref.listenManual<bool>(
      addRowOpenProvider(_id),
      (prev, next) {
        if (next == true && prev != true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            FocusScope.of(context).requestFocus(_addFocusNode);
            _scrollToField(_addItemKey);
          });
        }
      },
    );

    // 🔄 informuj parenta o zmianach checklisty (zamiast robić to w build)
    _checklistSub = ref.listenManual(
      checklistProvider(widget.checklist.checklist),
      (prev, next) {
        // next ma .items – aktualizujemy parenta
        widget.onChecklistUpdated(next.items);
      },
    );
  }

  @override
  void dispose() {
    _addOpenSub?.close();
    _checklistSub?.close();
    controller.dispose();
    _addFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    final userAsync = ref.watch(userProvider);

    final int? currentUserId = userAsync.maybeWhen(
      data: (u) {
        final dynamic raw = u?.userId ?? u?.userId;
        if (raw == null) return null;
        if (raw is int) return raw;
        return int.tryParse(raw.toString());
      },
      orElse: () => null,
    );

    final state = ref.watch(checklistProvider(widget.checklist.checklist));
    final notifier = ref.read(checklistProvider(widget.checklist.checklist).notifier);
    final taskChecklistNotifier = ref.read(taskChecklistProvider.notifier);

    final addOpen = ref.watch(addRowOpenProvider(_id));

    final progress = state.items.isEmpty
        ? 0.0
        : state.items.where((e) => e.completed).length / state.items.length;

    Future<void> submit() async {
      final text = controller.text.trim();

      if (text.isEmpty) {
        controller.clear();

        if (mounted) {
          FocusScope.of(context).unfocus();
        }

        ref.read(addRowOpenProvider(_id).notifier).state = false;
        return;
      }

      // Keep field open and keyboard focused
      controller.clear();
      _addFocusNode.requestFocus();

      // Add locally first
      notifier.addItem(text);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToField(_addItemKey);
        _addFocusNode.requestFocus();
      });

      // Save in background, do not change focus after this
      await taskChecklistNotifier.editChecklist(
        widget.checklist.id,
        {
          "title": widget.checklist.title,
          "description": widget.checklist.description,
          "checklist": notifier.state.items.map((e) => e.toJson()).toList(),
        },
        isAddingItem: true,
      );

      if (mounted && !_addFocusNode.hasFocus) {
        _addFocusNode.requestFocus();
      }
    }

    Widget memberChip({
      required String titlePrefix,
      required dynamic member,
      DateTime? when,
    }) {
      final String first = (member?.firstName ?? '').toString();
      final String last = (member?.lastName ?? '').toString();
      final String name = [first, last].where((s) => s.isNotEmpty).join(' ').trim();
      final String? avatar = (member?.avatar as String?);
      final String initials = [
        if (first.isNotEmpty) first[0],
        if (last.isNotEmpty) last[0],
      ].join().toUpperCase();

      final timeStr = when != null ? DateFormat('d MMM, HH:mm').format(when.toLocal()) : null;
      final tooltip = timeStr == null ? '$titlePrefix $name' : '$titlePrefix $name • $timeStr';

      return Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 300),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: Colors.grey[700],
              backgroundImage: (avatar != null && avatar.isNotEmpty) ? NetworkImage(avatar) : null,
              child: (avatar == null || avatar.isEmpty)
                  ? Text(
                      initials.isEmpty ? '?' : initials,
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 6),
          ],
        ),
      );
    }

    dynamic findMemberById(dynamic uid) {
      final int? parsed = uid is int ? uid : int.tryParse(uid?.toString() ?? '');
      if (parsed == null) return null;
      return userAsync.maybeWhen(
        data: (u) {
          final members = (u?.companyMembers ?? const <dynamic>[]);
          return members.firstWhereOrNull((m) => m.id == parsed);
        },
        orElse: () => null,
      );
    }

    final creatorMember = findMemberById(widget.checklist.createdBy);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (creatorMember != null)
              memberChip(titlePrefix: 'Created by'.tr, member: creatorMember)
            else
              const CircleAvatar(radius: 10, child: Icon(Icons.person, size: 12)),
            const SizedBox(width: 8),
            Text(
              widget.checklist.title,
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.textColor),
            ),
            const Spacer(),
            InkWell(
              onTap: () async {
                await ref.read(taskChecklistProvider.notifier).deleteCheckList(widget.checklist.id.toString());
                await ref.read(taskDetailsProvider.notifier).fetchTask(widget.taskId);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: theme.themeColor),
                child: Text('Delete'.tr, style: AppTextStyles.interBold.copyWith(color: theme.themeTextColor)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[800],
          color: theme.themeColor,
        ),
        const SizedBox(height: 12),

        // Items
        Column(
          children: List.generate(state.items.length, (index) {
            final item = state.items[index];
            final checkerMember = findMemberById(item.checkedBy);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: item.completed,
                  onChanged: (val) async {
                    final bool newVal = val ?? false;
                    final DateTime now = DateTime.now();

                    final updated = state.items.asMap().entries.map((entry) {
                      if (entry.key != index) return entry.value;
                      return entry.value.copyWith(
                        completed: newVal,
                        checkedBy: newVal ? currentUserId : null,
                        checkedAt: newVal ? now : null,
                      );
                    }).toList();

                    notifier.state = notifier.state.copyWith(items: updated);

                    await taskChecklistNotifier.editChecklist(
                      widget.checklist.id,
                      {
                        "title": widget.checklist.title,
                        "description": widget.checklist.description,
                        "checklist": updated.map((e) => e.toJson()).toList(),
                      },
                      toggledIndex: index,
                      toggledValue: newVal,
                    );
                  },
                  activeColor: theme.themeColor,
                  checkColor: theme.themeTextColor,
                ),

                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      color: theme.textColor,
                      decoration: item.completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),

                if (item.completed && checkerMember != null)
                  memberChip(titlePrefix: 'Checked by'.tr, member: checkerMember, when: item.checkedAt),
              ],
            );
          }),
        ),

        const SizedBox(height: 10),

        if (addOpen) ...[
          Container(
            key: _addItemKey,
            child: TextField(
              controller: controller,
              focusNode: _addFocusNode,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) async => await submit(),
              cursorColor: theme.textColor,
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.textFieldColor,
                hintText: 'Add an item...'.tr,
                hintStyle: TextStyle(color: theme.textColor),
                prefixIcon: Icon(Icons.search, color: theme.textColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              ),
              style: TextStyle(color: theme.textColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              InkWell(
                onTap: () async => await submit(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: theme.themeColor),
                  child: Text('Add'.tr, style: AppTextStyles.interBold.copyWith(color: theme.themeTextColor)),
                ),
              ),
              TextButton(
                onPressed: () {
                  controller.clear();
                  if (mounted) FocusScope.of(context).unfocus();
                  ref.read(addRowOpenProvider(_id).notifier).state = false;
                },
                child: Text('Cancel'.tr, style: AppTextStyles.interBold.copyWith(color: theme.themeTextColor)),
              ),
            ],
          ),
        ] else ...[
          InkWell(
            onTap: () {
              ref.read(addRowOpenProvider(_id).notifier).state = true;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: theme.themeColor),
              child: Text('Add an item'.tr, style: AppTextStyles.interBold.copyWith(color: theme.themeTextColor)),
            ),
          ),
        ],
      ],
    );
  }
}
