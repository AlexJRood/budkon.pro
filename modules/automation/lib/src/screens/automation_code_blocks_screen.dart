import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/automation_studio_config.dart';
import '../models/automation_code_block.dart';
import '../models/automation_common.dart';
import '../providers/automation_api_provider.dart';
import '../providers/automation_new_features_provider.dart';
import '../services/automation_api_service_new_features.dart';
import '../widgets/common/automation_badge.dart';
import 'automation_code_block_editor_screen.dart';

class AutomationCodeBlocksScreen extends ConsumerWidget {
  final String? workflowId;
  final int? companyId;

  const AutomationCodeBlocksScreen({
    super.key,
    this.workflowId,
    this.companyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = AutomationCodeBlockQuery(workflowId: workflowId, companyId: companyId);
    final blocksAsync = ref.watch(automationCodeBlocksProvider(query));

    return automationShell(
      context,
      ref: ref,
      title: 'Code blocks',
      screenKey: 'automation.code_blocks',
      actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded),
          onPressed: () => _openEditor(context),
        ),
      ],
      child: blocksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, index) {
            final block = items[index];
            return Card(
              child: ListTile(
                onTap: () => _openEditor(context, block),
                leading: const Icon(Icons.code_rounded),
                title: Text(block.name.isEmpty ? 'Untitled code block' : block.name),
                subtitle: Text('${enumName(block.language)} • ${enumName(block.riskLevel)}'),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    AutomationBadge(
                      label: enumName(block.status),
                      color: block.status == AutomationCodeBlockStatus.approved
                          ? automationColors(context, ref).success
                          : automationColors(context, ref).warning,
                    ),
                    IconButton(
                      tooltip: 'Validate',
                      icon: const Icon(Icons.fact_check_rounded),
                      onPressed: () async {
                        await ref.read(automationApiServiceProvider).validateCodeBlock(block.id);
                        ref.invalidate(automationCodeBlocksProvider(query));
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, [AutomationCodeBlock? block]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AutomationCodeBlockEditorScreen(
          block: block,
          workflowId: workflowId,
          companyId: companyId,
        ),
      ),
    );
  }
}
