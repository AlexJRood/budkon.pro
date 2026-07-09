import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';

import 'package:emma/blocks/core/block_definition.dart';
import 'package:emma/blocks/core/block_descriptor.dart';
import 'package:emma/blocks/definitions/shared/block_ui.dart';

class TmsProgressColumnBlockDefinition extends EmmaBlockDefinition {
  const TmsProgressColumnBlockDefinition();

  @override
  String get key => 'tms_progress_column';

  @override
  bool supports(EmmaBlockDescriptor block) {
    return block.type == EmmaBlockType.tmsProgressColumn;
  }

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _TmsProgressColumnBlockCard(
      block: block,
      maxWidth: maxWidth,
    );
  }
}

class _ProgressColumnPayload {
  final int? id;
  final int? projectId;
  final String title;
  final String name;
  final String projectName;

  const _ProgressColumnPayload({
    required this.id,
    required this.projectId,
    required this.title,
    required this.name,
    required this.projectName,
  });

  factory _ProgressColumnPayload.fromBlock(EmmaBlockDescriptor block) {
    final rawColumn = block.raw['column'] is Map
        ? Map<String, dynamic>.from(block.raw['column'] as Map)
        : <String, dynamic>{};

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return _ProgressColumnPayload(
      id: parseInt(rawColumn['id']),
      projectId: parseInt(rawColumn['project_id']),
      title: (block.raw['title'] ?? 'Column created').toString(),
      name: (rawColumn['name'] ?? 'Kolumna').toString(),
      projectName: (rawColumn['project_name'] ?? '').toString(),
    );
  }
}

class _TmsProgressColumnBlockCard extends ConsumerWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;

  const _TmsProgressColumnBlockCard({
    required this.block,
    required this.maxWidth,
  });

  Future<void> _openBoard(
    BuildContext context,
    WidgetRef ref,
    _ProgressColumnPayload payload,
  ) async {
    ref.read(navigationService).pushNamedScreen(Routes.proTodo);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          payload.projectName.isEmpty
              ? 'tms_opened'.tr
              : '${'board_opened'.tr}: ${payload.projectName}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payload = _ProgressColumnPayload.fromBlock(block);

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: const Color(0xFFF59E0B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(
            children: [
              Icon(Icons.vertical_split_rounded, color: Color(0xFFF59E0B), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'emma_created_column'.tr,
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
          if (payload.projectName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${'board'.tr}: ${payload.projectName}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
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