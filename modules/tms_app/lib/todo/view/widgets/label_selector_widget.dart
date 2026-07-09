import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:tms_app/todo/provider/task_labels_provider.dart';
import 'package:tms_app/todo/provider/todo_provider.dart';
import 'package:tms_app/todo/view/widgets/quick_access_option.dart';
import 'label_dialog_widget.dart';
import 'package:core/theme/apptheme.dart';

/// ✅ Per-task selected labels
final selectedLabelIdsProvider =
StateProvider.autoDispose.family<List<int>, String>((ref, taskId) => const []);

class LabelSelectorWidget extends ConsumerStatefulWidget {
  final String taskId;
  const LabelSelectorWidget({super.key, required this.taskId});

  @override
  ConsumerState<LabelSelectorWidget> createState() => _LabelSelectorWidgetState();
}

class _LabelSelectorWidgetState extends ConsumerState<LabelSelectorWidget> {
  ProviderSubscription<List<dynamic>>? _taskDetailsSub;

  /// ✅ Converts ANY list-ish input into List<int>
  List<int> _toIntList(Iterable<dynamic>? input) {
    if (input == null) return const [];
    return input
        .map((e) => e is int ? e : int.tryParse(e.toString()))
        .whereType<int>()
        .toList();
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();

    // ✅ Keep selection synced with latest taskDetails
    _taskDetailsSub = ref.listenManual<List<dynamic>>(
      taskDetailsProvider,
          (prev, next) {
        Future(() {
          if (!mounted) return;

          final task = next.firstWhereOrNull(
                (t) => t.id.toString() == widget.taskId,
          );
          final ids = _toIntList(task?.labels);

          final current = ref.read(selectedLabelIdsProvider(widget.taskId));

          if (!_listEquals(current, ids)) {
            ref.read(selectedLabelIdsProvider(widget.taskId).notifier).state = ids;
          }
        });
      },
      fireImmediately: true,
    );
  }

  @override
  void didUpdateWidget(covariant LabelSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.taskId != widget.taskId) {
      Future(() {
        if (!mounted) return;

        final allTasks = ref.read(taskDetailsProvider);
        final task = allTasks.firstWhereOrNull(
              (t) => t.id.toString() == widget.taskId,
        );
        final ids = _toIntList(task?.labels);

        final current = ref.read(selectedLabelIdsProvider(widget.taskId));

        if (!_listEquals(current, ids)) {
          ref.read(selectedLabelIdsProvider(widget.taskId).notifier).state = ids;
        }
      });
    }
  }

  @override
  void dispose() {
    _taskDetailsSub?.close();
    super.dispose();
  }

  Color _parseHexColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    return Color(int.parse(value, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final labelsResp = ref.watch(taskLabelsProvider);

    final selectedIds = ref.watch(selectedLabelIdsProvider(widget.taskId));

    final allLabels = labelsResp?.results ?? const [];
    final selected = allLabels.where((l) => selectedIds.contains(l.id)).toList();

    final hasSelection = selected.isNotEmpty;

    final chips = hasSelection
        ? Wrap(
      spacing: 6,
      runSpacing: 6,
      children: selected.map((label) {
        final color = _parseHexColor(label.color);
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.black.withAlpha(38),
              width: 1,
            ),
          ),
        );
      }).toList(),
    )
        : Text(
      'Select Label'.tr,
      style: TextStyle(color: theme.textColor),
    );

    return QuickAccessOption(
      'Label'.tr,
      InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => LabelDialogWidget(taskId: widget.taskId),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.adPopBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.textFieldColor),
          ),
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: chips,
          ),
        ),
      ),
    );
  }
}
