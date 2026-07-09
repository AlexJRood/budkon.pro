import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';

import 'package:emma/blocks/core/block_definition.dart';
import 'package:emma/blocks/core/block_descriptor.dart';
import 'package:emma/blocks/definitions/shared/block_ui.dart';

class TmsBoardListBlockDefinition extends EmmaBlockDefinition {
  const TmsBoardListBlockDefinition();

  @override
  String get key => 'tms_board_list';

  @override
  bool supports(EmmaBlockDescriptor block) {
    return block.type == EmmaBlockType.tmsBoardList;
  }

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _TmsBoardListBlockCard(
      block: block,
      maxWidth: maxWidth,
    );
  }
}

class _BoardColumn {
  final String name;
  final int taskCount;

  const _BoardColumn({
    required this.name,
    required this.taskCount,
  });

  factory _BoardColumn.fromRaw(Map<String, dynamic> raw) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return _BoardColumn(
      name: (raw['name'] ?? '').toString(),
      taskCount: parseInt(raw['task_count']),
    );
  }
}

class _BoardItem {
  final int? id;
  final String name;
  final int totalTasks;
  final int openTasks;
  final List<_BoardColumn> columns;

  const _BoardItem({
    required this.id,
    required this.name,
    required this.totalTasks,
    required this.openTasks,
    required this.columns,
  });

  factory _BoardItem.fromRaw(Map<String, dynamic> raw) {
    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    final rawColumns = raw['columns'];
    final columns = rawColumns is List
        ? rawColumns
            .whereType<Map>()
            .map((e) => _BoardColumn.fromRaw(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <_BoardColumn>[];

    return _BoardItem(
      id: parseNullableInt(raw['id']),
      name: (raw['name'] ?? 'Board').toString(),
      totalTasks: parseInt(raw['total_tasks']),
      openTasks: parseInt(raw['open_tasks']),
      columns: columns,
    );
  }
}

class _BoardListPayload {
  final String title;
  final int count;
  final List<_BoardItem> items;

  const _BoardListPayload({
    required this.title,
    required this.count,
    required this.items,
  });

  factory _BoardListPayload.fromBlock(EmmaBlockDescriptor block) {
    int parseInt(dynamic value, int fallback) {
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? fallback;
    }

    final rawItems = block.raw['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((e) => _BoardItem.fromRaw(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <_BoardItem>[];

    return _BoardListPayload(
      title: (block.raw['title'] ?? 'Boards').toString(),
      count: parseInt(block.raw['count'], items.length),
      items: items,
    );
  }
}

class _TmsBoardListBlockCard extends ConsumerWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;

  const _TmsBoardListBlockCard({
    required this.block,
    required this.maxWidth,
  });

  Future<void> _openTms(BuildContext context, WidgetRef ref) async {
    ref.read(navigationService).pushNamedScreen(Routes.proTodo);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payload = _BoardListPayload.fromBlock(block);

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: const Color(0xFF8B5CF6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard_customize_rounded, color: Color(0xFF8B5CF6), size: 18),
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
                label: '${payload.count}',
                color: const Color(0xFF8B5CF6),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (payload.items.isEmpty)
            Text(
              'no_boards_to_display'.tr,
              style: TextStyle(
                color: Colors.white.withAlpha(170),
                fontSize: 12,
              ),
            )
          else
            Column(
              children: payload.items.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(14)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${'open_tasks'.tr}: ${item.openTasks} · ${'all_tasks'.tr}: ${item.totalTasks}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      if (item.columns.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: item.columns.map((col) {
                            return EmmaTag(
                              label: '${col.name} (${col.taskCount})',
                              color: const Color(0xFF8B5CF6),
                            );
                          }).toList(growable: false),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(growable: false),
            ),
          const SizedBox(height: 8),
          EmmaActionPill(
            label: 'open_tms'.tr,
            icon: Icons.open_in_new,
            onTap: () => _openTms(context, ref),
          ),
        ],
      ),
    );
  }
}