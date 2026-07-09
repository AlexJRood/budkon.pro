import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/automation_studio_config.dart';
import '../providers/automation_api_provider.dart';
import '../providers/automation_new_features_provider.dart';
import '../services/automation_api_service_new_features.dart';
import '../widgets/common/automation_status_badges.dart';
import 'automation_builder_screen.dart';

class AutomationTemplatesScreen extends ConsumerWidget {
  final int? companyId;
  const AutomationTemplatesScreen({super.key, this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(automationTemplatesProvider(companyId));

    return automationShell(
      context,
      ref: ref,
      title: 'Automation templates',
      screenKey: 'automation.templates',
      child: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
        data: (items) => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 360,
            mainAxisExtent: 210,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (_, index) {
            final item = items[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 8),
                    Text(item.description, maxLines: 3, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      children: [
                        AutomationRiskBadge(riskLevel: item.riskLevel),
                        const Spacer(),
                        FilledButton(
                          onPressed: () async {
                            final workflow = await ref.read(automationApiServiceProvider)
                                .createWorkflowFromTemplate(item.id, companyId: companyId);
                            if (context.mounted) {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => AutomationBuilderScreen(workflowId: workflow.id),
                              ));
                            }
                          },
                          child: const Text('Use'),
                        ),
                      ],
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
}
