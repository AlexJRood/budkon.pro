import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:emma/blocks/core/block_definition.dart';
import 'package:emma/blocks/core/block_descriptor.dart';
import 'package:emma/blocks/definitions/shared/block_ui.dart';
import 'package:get/get_utils/get_utils.dart';

class TmsTaskDeleteResultBlockDefinition extends EmmaBlockDefinition {
  const TmsTaskDeleteResultBlockDefinition();

  @override
  String get key => 'tms_task_delete_result';

  @override
  bool supports(EmmaBlockDescriptor block) {
    return block.type == EmmaBlockType.tmsTaskDeleteResult;
  }

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _TmsTaskDeleteResultBlockCard(
      block: block,
      maxWidth: maxWidth,
    );
  }
}

class _DeleteTaskItem {
  final int? id;
  final String name;
  final String projectName;
  final String progressName;

  const _DeleteTaskItem({
    required this.id,
    required this.name,
    required this.projectName,
    required this.progressName,
  });

  factory _DeleteTaskItem.fromRaw(Map<String, dynamic> raw) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return _DeleteTaskItem(
      id: parseInt(raw['id']),
      name: (raw['name'] ?? 'Task').toString(),
      projectName: (raw['project_name'] ?? '').toString(),
      progressName: (raw['progress_name'] ?? '').toString(),
    );
  }
}

class _DeletePayload {
  final String title;
  final int deletedCount;
  final _DeleteTaskItem? deletedTask;
  final List<_DeleteTaskItem> deletedTasks;

  const _DeletePayload({
    required this.title,
    required this.deletedCount,
    required this.deletedTask,
    required this.deletedTasks,
  });

  factory _DeletePayload.fromBlock(EmmaBlockDescriptor block) {
    int parseInt(dynamic value, int fallback) {
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? fallback;
    }

    final oneRaw = block.raw['deleted_task'];
    final manyRaw = block.raw['deleted_tasks'];

    final deletedTask = oneRaw is Map
        ? _DeleteTaskItem.fromRaw(Map<String, dynamic>.from(oneRaw))
        : null;

    final deletedTasks = manyRaw is List
        ? manyRaw
            .whereType<Map>()
            .map((e) => _DeleteTaskItem.fromRaw(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <_DeleteTaskItem>[];

    return _DeletePayload(
      title: (block.raw['title'] ?? 'Deleted task').toString(),
      deletedCount: parseInt(block.raw['deleted_count'], deletedTasks.length),
      deletedTask: deletedTask,
      deletedTasks: deletedTasks,
    );
  }
}

class _TmsTaskDeleteResultBlockCard extends ConsumerWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;

  const _TmsTaskDeleteResultBlockCard({
    required this.block,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payload = _DeletePayload.fromBlock(block);
    final items = payload.deletedTasks.isNotEmpty
        ? payload.deletedTasks
        : (payload.deletedTask != null ? [payload.deletedTask!] : const <_DeleteTaskItem>[]);

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: Colors.redAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'emma_deleted_tasks'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
          '${'deleted'.tr}: ${payload.deletedCount}',
            style: TextStyle(
              color: Colors.white.withAlpha(190),
              fontSize: 12,
            ),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...items.take(8).map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withAlpha(14)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
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
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}