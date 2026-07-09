import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/automation_api_provider.dart';
import '../../services/automation_api_service_new_features.dart';

class AutomationGovernanceToolbar extends ConsumerWidget {
  final String workflowId;
  final VoidCallback? onChanged;

  const AutomationGovernanceToolbar({
    super.key,
    required this.workflowId,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            await ref.read(automationApiServiceProvider).assessWorkflowRisk(workflowId);
            onChanged?.call();
          },
          icon: const Icon(Icons.health_and_safety_rounded),
          label: const Text('Assess risk'),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final plan = await ref.read(automationApiServiceProvider).dryRunWorkflow(workflowId);
            if (!context.mounted) return;
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Dry-run'),
                content: SingleChildScrollView(child: Text(plan.raw.toString())),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
                ],
              ),
            );
          },
          icon: const Icon(Icons.science_rounded),
          label: const Text('Dry-run'),
        ),
        FilledButton.icon(
          onPressed: () async {
            await ref.read(automationApiServiceProvider).requestWorkflowReview(workflowId);
            onChanged?.call();
          },
          icon: const Icon(Icons.verified_user_rounded),
          label: const Text('Request review'),
        ),
      ],
    );
  }
}
