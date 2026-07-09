import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tms_app/todo/provider/task_filters_provider.dart';
import 'package:tms_app/todo/view/widgets/task_filters/quick_range_chips_widget.dart';

class TimestampRangeSection extends ConsumerWidget {
  final dynamic theme;
  final Future<DateTime?> Function(BuildContext, DateTime?) pickDateTime;
  final String Function(DateTime?) fmt;

  const TimestampRangeSection({
    super.key,
    required this.theme,
    required this.pickDateTime,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(taskFiltersProvider);

    return Column(
      children: [
        QuickRangeChips(
          theme: theme,
          current: filters.timestampRange.preset,
          onSelected:
              (r) =>
                  ref.read(taskFiltersProvider.notifier).setTimestampPreset(r),
        ),
        if (filters.timestampRange.preset == QuickRange.custom) ...[
          const SizedBox(height: 10),
          CustomRangeRow(
            theme: theme,
            from: filters.timestampRange.from,
            to: filters.timestampRange.to,
            fmt: fmt,
            onPickFrom: () async {
              final dt = await pickDateTime(
                context,
                filters.timestampRange.from,
              );
              ref
                  .read(taskFiltersProvider.notifier)
                  .setTimestampCustom(dt, filters.timestampRange.to);
            },
            onPickTo: () async {
              final dt = await pickDateTime(context, filters.timestampRange.to);
              ref
                  .read(taskFiltersProvider.notifier)
                  .setTimestampCustom(filters.timestampRange.from, dt);
            },
            onClear:
                () => ref.read(taskFiltersProvider.notifier).clearTimestamp(),
          ),
        ],
      ],
    );
  }
}

class DeadlineRangeSection extends ConsumerWidget {
  final dynamic theme;
  final Future<DateTime?> Function(BuildContext, DateTime?) pickDateTime;
  final String Function(DateTime?) fmt;

  const DeadlineRangeSection({
    super.key,
    required this.theme,
    required this.pickDateTime,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(taskFiltersProvider);

    return Column(
      children: [
        QuickRangeChips(
          theme: theme,
          current: filters.deadlineRange.preset,
          onSelected:
              (r) =>
                  ref.read(taskFiltersProvider.notifier).setDeadlinePreset(r),
        ),
        if (filters.deadlineRange.preset == QuickRange.custom) ...[
          const SizedBox(height: 10),
          CustomRangeRow(
            theme: theme,
            from: filters.deadlineRange.from,
            to: filters.deadlineRange.to,
            fmt: fmt,
            onPickFrom: () async {
              final dt = await pickDateTime(
                context,
                filters.deadlineRange.from,
              );
              ref
                  .read(taskFiltersProvider.notifier)
                  .setDeadlineCustom(dt, filters.deadlineRange.to);
            },
            onPickTo: () async {
              final dt = await pickDateTime(context, filters.deadlineRange.to);
              ref
                  .read(taskFiltersProvider.notifier)
                  .setDeadlineCustom(filters.deadlineRange.from, dt);
            },
            onClear:
                () => ref.read(taskFiltersProvider.notifier).clearDeadline(),
          ),
        ],
      ],
    );
  }
}
