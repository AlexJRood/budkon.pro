import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../core/block_definition.dart';
import '../core/block_descriptor.dart';
import 'shared/block_ui.dart';

// budkon: mail package removed — email draft block shows read-only preview.

class EmailDraftBlockDefinition extends EmmaBlockDefinition {
  const EmailDraftBlockDefinition();

  @override
  String get key => 'email_draft';

  @override
  bool supports(EmmaBlockDescriptor block) =>
      block.type == EmmaBlockType.emailDraft;

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    final raw = block.raw;
    final subject = raw['subject']?.toString() ?? '';
    final body = raw['body']?.toString() ?? raw['content']?.toString() ?? '';
    final to = raw['to']?.toString() ?? raw['recipient']?.toString() ?? '';

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.mail_outline, size: 14, color: Colors.white60),
            const SizedBox(width: 6),
            Text('email_draft'.tr,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Colors.white70)),
          ]),
          if (to.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Do: $to',
                style: const TextStyle(fontSize: 12, color: Colors.white60)),
          ],
          if (subject.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subject,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ],
          if (body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(body,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ],
      ),
    );
  }
}
