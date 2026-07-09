import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';

import 'package:emma/blocks/core/block_definition.dart';
import 'package:emma/blocks/core/block_descriptor.dart';
import 'package:emma/blocks/definitions/shared/block_ui.dart';

class TmsProjectBlockDefinition extends EmmaBlockDefinition {
  const TmsProjectBlockDefinition();

  @override
  String get key => 'tms_project';

  @override
  bool supports(EmmaBlockDescriptor block) {
    return block.type == EmmaBlockType.tmsProject;
  }

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _TmsProjectBlockCard(
      block: block,
      maxWidth: maxWidth,
    );
  }
}

class _ProjectColumn {
  final int? id;
  final String name;
  final int? ordering;

  const _ProjectColumn({
    required this.id,
    required this.name,
    required this.ordering,
  });

  factory _ProjectColumn.fromRaw(Map<String, dynamic> raw) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return _ProjectColumn(
      id: parseInt(raw['id']),
      name: (raw['name'] ?? '').toString(),
      ordering: parseInt(raw['ordering']),
    );
  }
}

class _ProjectPayload {
  final int? id;
  final String title;
  final String name;
  final String description;
  final List<_ProjectColumn> columns;

  const _ProjectPayload({
    required this.id,
    required this.title,
    required this.name,
    required this.description,
    required this.columns,
  });

  factory _ProjectPayload.fromBlock(EmmaBlockDescriptor block) {
    final rawProject = block.raw['project'] is Map
        ? Map<String, dynamic>.from(block.raw['project'] as Map)
        : <String, dynamic>{};

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    final rawColumns = rawProject['columns'];
    final columns = rawColumns is List
        ? rawColumns
            .whereType<Map>()
            .map((e) => _ProjectColumn.fromRaw(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <_ProjectColumn>[];

    return _ProjectPayload(
      id: parseInt(rawProject['id']),
      title: (block.raw['title'] ?? 'Board created').toString(),
      name: (rawProject['name'] ?? 'Board').toString(),
      description: (rawProject['description'] ?? '').toString(),
      columns: columns,
    );
  }
}

class _TmsProjectBlockCard extends ConsumerWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;

  const _TmsProjectBlockCard({
    required this.block,
    required this.maxWidth,
  });

  Future<void> _openBoard(
    BuildContext context,
    WidgetRef ref,
    _ProjectPayload payload,
  ) async {
    ref.read(navigationService).pushNamedScreen(Routes.proTodo);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${'board_opened'.tr}: ${payload.name}')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payload = _ProjectPayload.fromBlock(block);

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: const Color(0xFF8B5CF6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.view_kanban_rounded, color: Color(0xFF8B5CF6), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'emma_created_board'.tr,
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
            payload.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          if (payload.description.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              payload.description,
              style: TextStyle(
                color: Colors.white.withAlpha(185),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
          if (payload.columns.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: payload.columns.map((column) {
                return EmmaTag(
                  label: column.name,
                  color: const Color(0xFF8B5CF6),
                );
              }).toList(growable: false),
            ),
          ],
          const SizedBox(height: 12),
          EmmaActionPill(
            label: 'open_board'.tr,
            icon: Icons.open_in_new,
            onTap: () => _openBoard(context, ref, payload),
          ),
        ],
      ),
    );
  }
}