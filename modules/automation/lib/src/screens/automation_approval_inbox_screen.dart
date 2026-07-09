import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/automation_studio_config.dart';
import '../providers/automation_api_provider.dart';
import '../providers/automation_history_provider.dart';

class AutomationApprovalInboxScreen extends ConsumerWidget {
  const AutomationApprovalInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalsAsync = ref.watch(automationApprovalsProvider);

    return automationShell(
      context,
      ref: ref,
      title: 'Automation approvals',
      screenKey: 'automation.approvals',
      child: approvalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
        data: (items) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  title: Text(item['title']?.toString() ?? 'Approval required'),
                  subtitle: Text(item['message']?.toString() ?? ''),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => _respond(context, ref, item['id'].toString(), false),
                        child: const Text('Reject'),
                      ),
                      FilledButton(
                        onPressed: () => _respond(context, ref, item['id'].toString(), true),
                        child: const Text('Approve'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _respond(BuildContext context, WidgetRef ref, String id, bool approved) async {
    await ref.read(automationApiServiceProvider).respondApproval(
          approvalId: id,
          approved: approved,
        );
    ref.invalidate(automationApprovalsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approved ? 'Approved' : 'Rejected')),
      );
    }
  }
}
