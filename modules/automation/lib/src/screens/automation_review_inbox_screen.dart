import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/automation_studio_config.dart';
import '../providers/automation_api_provider.dart';
import '../providers/automation_new_features_provider.dart';
import '../services/automation_api_service_new_features.dart';
import '../widgets/common/automation_status_badges.dart';

class AutomationReviewInboxScreen extends ConsumerWidget {
  final int? companyId;
  const AutomationReviewInboxScreen({super.key, this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(automationWorkflowReviewsProvider(companyId));

    return automationShell(
      context,
      ref: ref,
      title: 'Workflow reviews',
      screenKey: 'automation.workflow_reviews',
      child: reviewsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, index) {
            final item = items[index];
            return Card(
              child: ListTile(
                leading: AutomationRiskBadge(riskLevel: item.riskLevel),
                title: Text(item.title.isEmpty ? 'Workflow review required' : item.title),
                subtitle: Text(item.message),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => _respond(context, ref, item.id, false),
                      child: const Text('Reject'),
                    ),
                    FilledButton(
                      onPressed: () => _respond(context, ref, item.id, true),
                      child: const Text('Approve'),
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

  Future<void> _respond(BuildContext context, WidgetRef ref, String id, bool approved) async {
    await ref.read(automationApiServiceProvider).respondWorkflowReview(
          reviewId: id,
          approved: approved,
        );
    ref.invalidate(automationWorkflowReviewsProvider(companyId));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approved ? 'Review approved' : 'Review rejected')),
      );
    }
  }
}
