// lib/emma/tools/cards/docs.dart

import 'package:flutter/material.dart';
import 'package:emma/tools/tool_type.dart';

class DocsToolCard extends StatelessWidget {
  final AiToolDescriptor tool;
  final double maxWidth;

  const DocsToolCard({
    super.key,
    required this.tool,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final r = tool.result;

    final title = r['title']?.toString() ??
        r['name']?.toString() ??
        'Dokument';
    final template = r['template_name']?.toString();
    final number = r['number']?.toString();

    final lines = <String>[];
    if (template != null && template.isNotEmpty) {
      lines.add('Szablon: $template');
    }
    if (number != null && number.isNotEmpty) {
      lines.add('Numer: $number');
    }

    final subtitle = lines.join(' • ');

    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
      padding: const EdgeInsets.all(10),
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(115),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: tool.ok
              ? Colors.greenAccent.withAlpha(153)
              : Colors.redAccent,
          width: 0.7,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.description_outlined,
            size: 18,
            color: tool.ok ? Colors.greenAccent : Colors.redAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
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
