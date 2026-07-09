// lib/emma/tools/cards/notes.dart
import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import '../tool_type.dart';

/// Rejestr tekstów dla modułu notatek.
String noteToolHeader(AiToolDescriptor tool) {
  final kind = tool.noteKind ?? NoteToolKind.unknown;

  switch (kind) {
    case NoteToolKind.createNote:
      return 'emma_created_note'.tr;
    case NoteToolKind.updateNote:
      return 'emma_updated_note'.tr;
    case NoteToolKind.deleteNote:
      return 'emma_deleted_note'.tr;
    case NoteToolKind.listNotes:
      return 'emma_listed_notes'.tr;
    case NoteToolKind.unknown:
    default:
      return 'emma_handled_note'.tr;
  }
}

class NoteToolCard extends StatelessWidget {
  final AiToolDescriptor tool;
  final double maxWidth;

  const NoteToolCard({
    super.key,
    required this.tool,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final r = tool.result;

    final title = r['title'] as String? ?? 'Note'.tr;
    final content = r['content'] as String? ?? r['body'] as String? ?? '';

    final success = tool.ok && tool.status == 'success';

    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
      padding: const EdgeInsets.all(10),
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(115),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              success ? Colors.greenAccent.withAlpha(153) : Colors.redAccent,
          width: 0.7,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.sticky_note_2_outlined,
            size: 18,
            color: success ? Colors.greenAccent : Colors.redAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  noteToolHeader(tool),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                if (content.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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
  }
}
