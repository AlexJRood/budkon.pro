// tms_app/todo/provider/task_filters_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Quick ranges for timestamp/deadline selection
enum QuickRange {
  any,
  today,
  yesterday,
  last7Days,
  last30Days,
  next7Days,
  next30Days,
  custom,
}

@immutable
class DateRangeValue {
  final QuickRange preset;
  final DateTime? from;
  final DateTime? to;

  const DateRangeValue({
    this.preset = QuickRange.any,
    this.from,
    this.to,
  });

  DateRangeValue copyWith({
    QuickRange? preset,
    DateTime? from,
    bool clearFrom = false,
    DateTime? to,
    bool clearTo = false,
  }) {
    return DateRangeValue(
      preset: preset ?? this.preset,
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
    );
  }
}

@immutable
class TaskFiltersState {
  final String name; // ?name= (icontains)

  // ✅ keep your existing single assignedTo (if your backend supports it)
  final int? assignedTo; // ?assigned_to=

  // ✅ NEW: assigned-to CLIENTS multi-select
  final List<int> assignedClientIds; // ?assigned_to= or ?assigned_to__in=

  final List<int> memberIds; // ?members=1&members=2...
  final DateRangeValue timestampRange; // timestamp__gte/lte
  final DateRangeValue deadlineRange; // deadline__gte/lte

  // ✅ NEW:
  final String? priority; // ?priority= (H/M/L)
  final bool? isCompleted; // ?is_completed=true/false

  /// ✅ Labels multi-select
  /// Backend expects: label=1,2,3
  final List<int> labelIds;

  const TaskFiltersState({
    this.name = '',
    this.assignedTo,
    this.assignedClientIds = const [],
    this.memberIds = const [],
    this.timestampRange = const DateRangeValue(preset: QuickRange.any),
    this.deadlineRange = const DateRangeValue(preset: QuickRange.any),
    this.priority,
    this.isCompleted,
    this.labelIds = const [],
  });

  TaskFiltersState copyWith({
    String? name,
    int? assignedTo,
    bool clearAssignedTo = false,
    List<int>? assignedClientIds,
    List<int>? memberIds,
    DateRangeValue? timestampRange,
    DateRangeValue? deadlineRange,

    // ✅ NEW:
    String? priority,
    bool clearPriority = false,
    bool? isCompleted,
    bool clearIsCompleted = false,

    // ✅ labels
    List<int>? labelIds,
  }) {
    return TaskFiltersState(
      name: name ?? this.name,
      assignedTo: clearAssignedTo ? null : (assignedTo ?? this.assignedTo),
      assignedClientIds: assignedClientIds ?? this.assignedClientIds,
      memberIds: memberIds ?? this.memberIds,
      timestampRange: timestampRange ?? this.timestampRange,
      deadlineRange: deadlineRange ?? this.deadlineRange,

      // ✅ NEW:
      priority: clearPriority ? null : (priority ?? this.priority),
      isCompleted: clearIsCompleted ? null : (isCompleted ?? this.isCompleted),

      // ✅ labels
      labelIds: labelIds ?? this.labelIds,
    );
  }

  /// Convert UI ranges into concrete DateTimes
  static DateRangeValue resolvePreset(QuickRange preset) {
    final now = DateTime.now();

    DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 0, 0, 0);
    DateTime endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);

    switch (preset) {
      case QuickRange.any:
        return const DateRangeValue(preset: QuickRange.any);
      case QuickRange.today:
        final from = startOfDay(now);
        final to = endOfDay(now);
        return DateRangeValue(preset: preset, from: from, to: to);
      case QuickRange.yesterday:
        final y = now.subtract(const Duration(days: 1));
        return DateRangeValue(preset: preset, from: startOfDay(y), to: endOfDay(y));
      case QuickRange.last7Days:
        final from = startOfDay(now.subtract(const Duration(days: 6)));
        final to = endOfDay(now);
        return DateRangeValue(preset: preset, from: from, to: to);
      case QuickRange.last30Days:
        final from = startOfDay(now.subtract(const Duration(days: 29)));
        final to = endOfDay(now);
        return DateRangeValue(preset: preset, from: from, to: to);
      case QuickRange.next7Days:
        final from = startOfDay(now);
        final to = endOfDay(now.add(const Duration(days: 6)));
        return DateRangeValue(preset: preset, from: from, to: to);
      case QuickRange.next30Days:
        final from = startOfDay(now);
        final to = endOfDay(now.add(const Duration(days: 29)));
        return DateRangeValue(preset: preset, from: from, to: to);
      case QuickRange.custom:
        return const DateRangeValue(preset: QuickRange.custom);
    }
  }

  Map<String, dynamic> toQueryParams(dynamic ref) {
    debugPrint('Younis queryParams called');
    final qp = <String, dynamic>{};

    final n = name.trim();
    if (n.isNotEmpty) qp['name'] = n;

    // ✅ keep single assignedTo if you still use it
    if (assignedTo != null) qp['assigned_to'] = assignedTo;

    if (memberIds.isNotEmpty) qp['members'] = memberIds;

    // timestamp
    final ts = timestampRange;
    if (ts.from != null) qp['timestamp__gte'] = ts.from!.toIso8601String();
    if (ts.to != null) qp['timestamp__lte'] = ts.to!.toIso8601String();

    // deadline
    final dl = deadlineRange;
    if (dl.from != null) qp['deadline__gte'] = dl.from!.toIso8601String();
    if (dl.to != null) qp['deadline__lte'] = dl.to!.toIso8601String();

    // ✅ NEW: assigned-to CLIENT(S) filtering
    if (assignedClientIds.length == 1) {
      qp['assigned_to'] = assignedClientIds.first;
    }
    if (assignedClientIds.length > 1) {
      qp['assigned_to__in'] = assignedClientIds.join(',');
    }

    // ✅ NEW: priority
    if (priority != null && priority!.trim().isNotEmpty) {
      qp['priority'] = priority!.trim();
    }

    // ✅ NEW: is_completed
    if (isCompleted != null) {
      qp['is_completed'] = isCompleted;
    }

    // ✅ FIXED: labels multi-select format => label=1,2,3
    if (labelIds.isNotEmpty) {
      qp['label'] = labelIds.join(',');
    }

    if (kDebugMode) {
      debugPrint('✅ TASK FILTER QUERY PARAMS => $qp');
    }
    debugPrint('🧪 RAW FILTER STATE => priority=${priority} labelIds=$labelIds isCompleted=$isCompleted');
    debugPrint('🧪 FINAL QUERY PARAMS => $qp');

    return qp;
  }
}

final taskFiltersProvider =
StateNotifierProvider<TaskFiltersNotifier, TaskFiltersState>((ref) {
  return TaskFiltersNotifier();
});

class TaskFiltersNotifier extends StateNotifier<TaskFiltersState> {
  TaskFiltersNotifier() : super(const TaskFiltersState());

  void setName(String v) => state = state.copyWith(name: v);

  void setAssignedTo(int? userId) {
    state = state.copyWith(
      assignedTo: userId,
      clearAssignedTo: userId == null,
    );
  }

  // ✅ NEW: set selected client ids (multi select)
  void setAssignedToClientIds(List<int> ids) {
    state = state.copyWith(assignedClientIds: ids);
  }

  void toggleMember(int id) {
    final current = [...state.memberIds];
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    state = state.copyWith(memberIds: current);
  }

  void setMembers(List<int> ids) => state = state.copyWith(memberIds: ids);

  void setTimestampPreset(QuickRange preset) {
    if (preset == QuickRange.custom) {
      state = state.copyWith(
        timestampRange: state.timestampRange.copyWith(preset: QuickRange.custom),
      );
      return;
    }
    state = state.copyWith(timestampRange: TaskFiltersState.resolvePreset(preset));
  }

  void setDeadlinePreset(QuickRange preset) {
    if (preset == QuickRange.custom) {
      state = state.copyWith(
        deadlineRange: state.deadlineRange.copyWith(preset: QuickRange.custom),
      );
      return;
    }
    state = state.copyWith(deadlineRange: TaskFiltersState.resolvePreset(preset));
  }

  void setTimestampCustom(DateTime? from, DateTime? to) {
    state = state.copyWith(
      timestampRange: DateRangeValue(preset: QuickRange.custom, from: from, to: to),
    );
  }

  void setDeadlineCustom(DateTime? from, DateTime? to) {
    state = state.copyWith(
      deadlineRange: DateRangeValue(preset: QuickRange.custom, from: from, to: to),
    );
  }

  void clearTimestamp() {
    state = state.copyWith(timestampRange: const DateRangeValue(preset: QuickRange.any));
  }

  void clearDeadline() {
    state = state.copyWith(deadlineRange: const DateRangeValue(preset: QuickRange.any));
  }

  // ✅ NEW: priority
  void setPriority(String? v) {
    state = state.copyWith(
      priority: v,
      clearPriority: v == null || v.trim().isEmpty,
    );
  }

  // ✅ NEW: is_completed
  void setIsCompleted(bool? v) {
    state = state.copyWith(
      isCompleted: v,
      clearIsCompleted: v == null,
    );
  }

  // ✅ labels (multi-select)
  void setLabelIds(List<int> ids) {
    state = state.copyWith(labelIds: ids);
  }

  void toggleLabel(int id) {
    final current = [...state.labelIds];
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    state = state.copyWith(labelIds: current);
  }

  void reset() => state = const TaskFiltersState();
}

/// show/hide the sheet under the button
final showAssignedClientSheetProvider = StateProvider<bool>((ref) => false);

/// selected client IDs (multi-select)
final selectedAssignedClientIdsProvider = StateProvider<List<int>>((ref) => []);

/// search query inside the sheet
final assignedClientSearchQueryProvider = StateProvider<String>((ref) => '');

/// helper to toggle selection
final assignedClientFilterControllerProvider =
Provider<AssignedClientFilterController>((ref) {
  return AssignedClientFilterController(ref);
});

class AssignedClientFilterController {
  AssignedClientFilterController(this.ref);
  final Ref ref;

  void toggleSheet() {
    final isOpen = ref.read(showAssignedClientSheetProvider);
    ref.read(showAssignedClientSheetProvider.notifier).state = !isOpen;
  }

  void closeSheet() {
    ref.read(showAssignedClientSheetProvider.notifier).state = false;
  }

  void clear() {
    ref.read(selectedAssignedClientIdsProvider.notifier).state = [];
    ref.read(assignedClientSearchQueryProvider.notifier).state = '';
  }

  void toggleClient(int clientId) {
    final current = ref.read(selectedAssignedClientIdsProvider);
    final next = [...current];
    if (next.contains(clientId)) {
      next.remove(clientId);
    } else {
      next.add(clientId);
    }
    ref.read(selectedAssignedClientIdsProvider.notifier).state = next;
  }
}

/// ✅ Labels filter UI state (same style as Assigned To / Members)
final showLabelsSheetProvider = StateProvider<bool>((ref) => false);
final labelsSearchQueryProvider = StateProvider<String>((ref) => '');

final appliedTaskFiltersProvider =
StateProvider<TaskFiltersState>((ref) => const TaskFiltersState());