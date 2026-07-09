import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';

import 'package:emma/blocks/core/block_definition.dart';
import 'package:emma/blocks/core/block_descriptor.dart';
import 'package:emma/blocks/definitions/shared/block_ui.dart';

class TmsTaskListBlockDefinition extends EmmaBlockDefinition {
  const TmsTaskListBlockDefinition();

  @override
  String get key => 'tms_task_list';

  @override
  bool supports(EmmaBlockDescriptor block) {
    return block.type == EmmaBlockType.tmsTaskList;
  }

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _TmsTaskListBlockCard(
      block: block,
      maxWidth: maxWidth,
    );
  }
}

class _TaskListItem {
  final int? id;
  final String name;
  final String projectName;
  final String progressName;
  final String? priority;
  final String? deadline;
  final bool isCompleted;

  const _TaskListItem({
    required this.id,
    required this.name,
    required this.projectName,
    required this.progressName,
    required this.priority,
    required this.deadline,
    required this.isCompleted,
  });

  factory _TaskListItem.fromRaw(Map<String, dynamic> raw) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return _TaskListItem(
      id: parseInt(raw['id']),
      name: (raw['name'] ?? 'Task').toString(),
      projectName: (raw['project_name'] ?? '').toString(),
      progressName: (raw['progress_name'] ?? '').toString(),
      priority: raw['priority']?.toString(),
      deadline: raw['deadline']?.toString(),
      isCompleted: raw['is_completed'] == true,
    );
  }
}

class _TmsTaskListPayload {
  final String title;
  final int count;
  final int totalCount;
  final List<_TaskListItem> items;
  final Map<String, dynamic> filters;

  const _TmsTaskListPayload({
    required this.title,
    required this.count,
    required this.totalCount,
    required this.items,
    required this.filters,
  });

  factory _TmsTaskListPayload.fromBlock(EmmaBlockDescriptor block) {
    final rawItems = block.raw['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((e) => _TaskListItem.fromRaw(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <_TaskListItem>[];

    int parseInt(dynamic value, int fallback) {
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? fallback;
    }

    final filtersRaw = block.raw['filters'];
    final filters = filtersRaw is Map
        ? Map<String, dynamic>.from(filtersRaw)
        : <String, dynamic>{};

    return _TmsTaskListPayload(
      title: (block.raw['title'] ?? 'Tasks').toString(),
      count: parseInt(block.raw['count'], items.length),
      totalCount: parseInt(block.raw['total_count'], items.length),
      items: items,
      filters: filters,
    );
  }
}

class _TmsTaskListBlockCard extends ConsumerWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;

  const _TmsTaskListBlockCard({
    required this.block,
    required this.maxWidth,
  });

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd.MM.yyyy HH:mm').format(dt);
    } catch (_) {
      return iso;
    }
  }

  Color _priorityColor(String? priority) {
    switch ((priority ?? '').toUpperCase()) {
      case 'L':
        return Colors.lightBlueAccent;
      case 'M':
        return Colors.orangeAccent;
      case 'H':
        return Colors.deepOrangeAccent;
      default:
        return Colors.white54;
    }
  }

  Future<void> _openTms(BuildContext context, WidgetRef ref) async {
    ref.read(navigationService).pushNamedScreen(Routes.proTodo);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payload = _TmsTaskListPayload.fromBlock(block);
    final includeCompleted = payload.filters['include_completed'] == true;

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: const Color(0xFF37B6FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_rounded, color: Color(0xFF37B6FF), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  payload.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              EmmaTag(
                label: '${payload.count}/${payload.totalCount}',
                color: const Color(0xFF37B6FF),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            includeCompleted
                ? 'showing_completed_tasks'.tr
                : 'showing_active_tasks'.tr,
            style: TextStyle(
              color: Colors.white.withAlpha(155),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          if (payload.items.isEmpty)
            Text(
              'no_tasks_to_display'.tr,
              style: TextStyle(
                color: Colors.white.withAlpha(170),
                fontSize: 12,
              ),
            )
          else
            Column(
              children: payload.items.map((item) {
                final deadline = _formatDate(item.deadline);
                final accent = item.isCompleted
                    ? Colors.greenAccent
                    : _priorityColor(item.priority);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(14)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        item.isCompleted
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                        size: 18,
                        color: accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (item.projectName.isNotEmpty) item.projectName,
                                if (item.progressName.isNotEmpty) item.progressName,
                              ].join(' · '),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                            if (deadline.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${'deadline'.tr}: $deadline',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(growable: false),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              EmmaActionPill(
                label: 'open_tms'.tr,
                icon: Icons.open_in_new,
                onTap: () => _openTms(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}