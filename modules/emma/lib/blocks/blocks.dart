import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/block_descriptor.dart';
import 'core/block_registry.dart';

int? _tryParseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

String _asText(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _asListOfMaps(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];

  return value
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);
}

Map<String, dynamic>? _tryDecodeBlockPayload({
  required String type,
  required String jsonRaw,
}) {
  final normalizedType = type.trim().toLowerCase();
  if (normalizedType.isEmpty || jsonRaw.trim().isEmpty) return null;

  try {
    final decoded = jsonDecode(jsonRaw.trim());
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      map['type'] ??= normalizedType;
      return map;
    }
  } catch (_) {
    // ignore invalid inline block
  }

  return null;
}

List<Map<String, dynamic>> _extractInlineBlocksFromContent(String? content) {
  if (content == null || content.trim().isEmpty) {
    return const <Map<String, dynamic>>[];
  }

  final results = <Map<String, dynamic>>[];

  final genericBlockRegex = RegExp(
    r'<emma_block\s+type="(?<type>[a-zA-Z0-9_\-:.]+)"\s*>\s*(?<payload>[\s\S]*?)\s*</emma_block>',
    caseSensitive: false,
  );

  for (final match in genericBlockRegex.allMatches(content)) {
    final type = (match.namedGroup('type') ?? '').trim().toLowerCase();
    final jsonRaw = (match.namedGroup('payload') ?? '').trim();

    final block = _tryDecodeBlockPayload(
      type: type,
      jsonRaw: jsonRaw,
    );

    if (block != null) {
      results.add(block);
    }
  }

  final legacyRegex = RegExp(
    r'<([a-zA-Z0-9_\-:.]+)>\s*([\s\S]*?)\s*</\1>',
    caseSensitive: false,
  );

  for (final match in legacyRegex.allMatches(content)) {
    final tag = (match.group(1) ?? '').trim().toLowerCase();
    final jsonRaw = (match.group(2) ?? '').trim();

    if (tag == 'emma_block') continue;
    if (tag == 'emma_tool_result') continue;

    final block = _tryDecodeBlockPayload(
      type: tag,
      jsonRaw: jsonRaw,
    );

    if (block != null) {
      results.add(block);
    }
  }

  return results;
}

List<Map<String, dynamic>> _extractRenderBlocksFromLegacyTool(
  Map<String, dynamic> rawTool,
) {
  final out = <Map<String, dynamic>>[];

  final directRenderBlocks = rawTool['render_blocks'];
  if (directRenderBlocks is List) {
    for (final raw in directRenderBlocks.whereType<Map>()) {
      out.add(Map<String, dynamic>.from(raw));
    }
    return out;
  }

  final directBlocks = rawTool['blocks'];
  if (directBlocks is List) {
    for (final raw in directBlocks.whereType<Map>()) {
      out.add(Map<String, dynamic>.from(raw));
    }
    return out;
  }

  final resultRaw = rawTool['result'];
  if (resultRaw is! Map) {
    final llmRaw = rawTool['llm_result'];
    if (llmRaw is Map) {
      return _extractRenderBlocksFromLegacyTool({
        ...rawTool,
        'result': llmRaw,
      });
    }

    return out;
  }

  final result = Map<String, dynamic>.from(resultRaw);

  final renderBlocks = result['render_blocks'];
  if (renderBlocks is List) {
    for (final raw in renderBlocks.whereType<Map>()) {
      final enriched = Map<String, dynamic>.from(raw);

      final resultMetaRaw = result['meta'];
      final resultMeta = resultMetaRaw is Map
          ? Map<String, dynamic>.from(resultMetaRaw)
          : <String, dynamic>{};

      enriched['summary_count'] ??=
          _tryParseInt(result['count']) ??
          ((result['items'] is List) ? (result['items'] as List).length : null);

      enriched['summary_total_count'] ??= _tryParseInt(result['total_count']);
      enriched['summary_limit'] ??= _tryParseInt(result['limit']);
      enriched['summary_marked_seen_by_emma'] ??=
          resultMeta['marked_seen_by_emma'] == true;
      enriched['summary_source'] ??= (resultMeta['source'] ?? '').toString();
      enriched['summary_tool_name'] ??=
          (rawTool['name'] ?? rawTool['tool_name'] ?? '').toString();

      out.add(enriched);
    }
    return out;
  }

  final blocks = result['blocks'];
  if (blocks is List) {
    for (final raw in blocks.whereType<Map>()) {
      out.add(Map<String, dynamic>.from(raw));
    }
    return out;
  }

  final toolName = (rawTool['name'] ?? rawTool['tool_name'] ?? '').toString();
  final ok = rawTool['ok'] == true || result['ok'] == true;

  if (!ok) {
    final error = (result['error'] ?? rawTool['error'] ?? '').toString().trim();
    if (error.isNotEmpty) {
      out.add({
        'type': 'info',
        'variant': 'error',
        'title': 'Błąd narzędzia',
        'text': error,
      });
    }
    return out;
  }

  switch (toolName) {
    case 'calendar_create_event':
      out.add({
        'type': 'calendar_event',
        'event_id': result['event_id'],
        'calendar_id': result['calendar_id'],
        'calendar_name': result['calendar_name'],
        'calendar_color': result['calendar_color'],
        'title': result['title'],
        'start_time': result['start_time'],
        'end_time': result['end_time'],
        'location': result['location'],
        'available_calendars': result['available_calendars'],
      });
      break;

    case 'tms_create_task':
    case 'tms_update_task':
      final taskRaw = result['task'];
      if (taskRaw is Map) {
        final task = Map<String, dynamic>.from(taskRaw);
        out.add({
          'type': 'tms_task',
          'operation': toolName == 'tms_create_task' ? 'create' : 'update',
          'task': task,
          ...task,
        });
      }
      break;

    case 'tms_delete_task':
      final deletedTaskRaw = result['deleted_task'];
      if (deletedTaskRaw is Map) {
        final deletedTask = Map<String, dynamic>.from(deletedTaskRaw);
        out.add({
          'type': 'tms_task_delete_result',
          'operation': 'delete',
          'deleted': true,
          'task': deletedTask,
          ...deletedTask,
        });
      } else {
        out.add({
          'type': 'info',
          'variant': 'success',
          'title': 'Usunięto zadanie',
          'text': (result['message'] ?? 'Zadanie zostało usunięte.').toString(),
        });
      }
      break;

    default:
      final message = (result['message'] ??
              rawTool['message'] ??
              rawTool['assistant_message'] ??
              '')
          .toString()
          .trim();

      if (message.isNotEmpty) {
        out.add({
          'type': 'info',
          'variant': 'success',
          'title': toolName.isEmpty ? 'Wykonano akcję' : toolName,
          'text': message,
          'tool_name': toolName,
        });
      }
      break;
  }

  return out;
}

List<EmmaBlockDescriptor> parseBlocksFromMeta(
  Map<String, dynamic>? meta, {
  String? messageContent,
}) {
  final descriptors = <EmmaBlockDescriptor>[];
  final seen = <String>{};




void pushRawMap(Map<String, dynamic> raw) {
  final normalizedType = (raw['type'] ?? '').toString().trim();

  if (normalizedType.isEmpty) {
    return;
  }

  final descriptor = EmmaBlockDescriptor.fromRaw(raw);

  // Text nie jest blokiem renderowanym jako card.
  // Unknown zostawiamy, bo ma iść do GenericBlockDefinition.
  if (descriptor.type == EmmaBlockType.text) {
    return;
  }

  final dedupeKey = jsonEncode(raw);
  if (!seen.add(dedupeKey)) return;

  descriptors.add(descriptor);
}

  final rawBlocks = meta?['blocks'];
  final hasMetaBlocks = rawBlocks is List && rawBlocks.isNotEmpty;

  if (rawBlocks is List) {
    for (final raw in rawBlocks.whereType<Map>()) {
      pushRawMap(Map<String, dynamic>.from(raw));
    }
  }

  final rawRenderBlocks = meta?['render_blocks'];
  if (rawRenderBlocks is List) {
    for (final raw in rawRenderBlocks.whereType<Map>()) {
      pushRawMap(Map<String, dynamic>.from(raw));
    }
  }

  if (!hasMetaBlocks) {
    final rawTools = meta?['tools'];
    if (rawTools is List) {
      for (final rawTool in rawTools.whereType<Map>()) {
        final tool = Map<String, dynamic>.from(rawTool);

        for (final rawBlock in _extractRenderBlocksFromLegacyTool(tool)) {
          pushRawMap(rawBlock);
        }
      }
    }
  }

  final localToolRaw = meta?['local_llm_tools'];
  final localTool = _asMap(localToolRaw);
  final localToolBlocks = _asListOfMaps(localTool['blocks']);
  for (final raw in localToolBlocks) {
    pushRawMap(raw);
  }

  final pendingBlocks = meta?['pending_blocks'];
  if (pendingBlocks is List) {
    for (final raw in pendingBlocks.whereType<Map>()) {
      final map = Map<String, dynamic>.from(raw);
      map['type'] = (map['type'] ?? 'loading').toString();
      map['state'] ??= 'loading';
      pushRawMap(map);
    }
  }

  for (final inlineBlock in _extractInlineBlocksFromContent(messageContent)) {
    pushRawMap(inlineBlock);
  }

  return descriptors;
}

class EmmaBlocksSection extends ConsumerWidget {
  final List<EmmaBlockDescriptor> blocks;
  final double maxWidth;
  final String messageId;

  const EmmaBlocksSection({
    super.key,
    required this.blocks,
    required this.maxWidth,
    required this.messageId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (blocks.isEmpty) return const SizedBox.shrink();

    final registry = ref.watch(emmaBlockRegistryProvider);

    final resolved = blocks
        .map(
          (block) => ResolvedEmmaBlock(
            block: block,
            definition: registry.resolve(block),
          ),
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: resolved
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: entry.definition.buildBlock(
                context: context,
                ref: ref,
                block: entry.block,
                maxWidth: maxWidth,
                messageId: messageId,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}