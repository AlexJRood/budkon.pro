// lib/emma/tools/cards/generic.dart

import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';

import '../tool_type.dart';

class GenericToolCard extends StatelessWidget {
  final AiToolDescriptor tool;
  final double maxWidth;

  const GenericToolCard({
    super.key,
    required this.tool,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
      padding: const EdgeInsets.all(10),
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(115),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: tool.ok ? Colors.greenAccent.withAlpha(153) : Colors.redAccent,
          width: 0.7,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.extension, // puzzle vibe
            size: 18,
            color: tool.ok ? Colors.greenAccent : Colors.redAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${'emma_used_tool'.tr}: ${tool.name}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
