import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/automation_studio_config.dart';
import '../models/automation_governance.dart';
import '../providers/automation_api_provider.dart';
import '../providers/automation_new_features_provider.dart';
import '../services/automation_api_service_new_features.dart';

class AutomationPolicyScreen extends ConsumerStatefulWidget {
  final int companyId;
  const AutomationPolicyScreen({super.key, required this.companyId});

  @override
  ConsumerState<AutomationPolicyScreen> createState() => _AutomationPolicyScreenState();
}

class _AutomationPolicyScreenState extends ConsumerState<AutomationPolicyScreen> {
  AutomationCompanyPolicy? editing;

  @override
  Widget build(BuildContext context) {
    final policiesAsync = ref.watch(automationCompanyPoliciesProvider(widget.companyId));

    return automationShell(
      context,
      ref: ref,
      title: 'Automation policy',
      screenKey: 'automation.policy',
      actions: [
        IconButton(onPressed: editing == null ? null : _save, icon: const Icon(Icons.save_rounded)),
      ],
      child: policiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
        data: (items) {
          editing ??= items.isEmpty
              ? AutomationCompanyPolicy(id: '', companyId: widget.companyId)
              : items.first;

          final p = editing!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('Emma can create workflows'),
                value: p.allowEmmaCreate,
                onChanged: (v) => setState(() => editing = AutomationCompanyPolicy(
                  id: p.id,
                  companyId: p.companyId,
                  allowEmmaCreate: v,
                  allowEmmaUpdate: p.allowEmmaUpdate,
                  allowEmmaActivate: p.allowEmmaActivate,
                  requireReviewForEmma: p.requireReviewForEmma,
                  requireReviewRiskLevels: p.requireReviewRiskLevels,
                  blockedActionKeys: p.blockedActionKeys,
                )),
              ),
              SwitchListTile(
                title: const Text('Emma can update workflows'),
                value: p.allowEmmaUpdate,
                onChanged: (v) => setState(() => editing = AutomationCompanyPolicy(
                  id: p.id,
                  companyId: p.companyId,
                  allowEmmaCreate: p.allowEmmaCreate,
                  allowEmmaUpdate: v,
                  allowEmmaActivate: p.allowEmmaActivate,
                  requireReviewForEmma: p.requireReviewForEmma,
                  requireReviewRiskLevels: p.requireReviewRiskLevels,
                  blockedActionKeys: p.blockedActionKeys,
                )),
              ),
              SwitchListTile(
                title: const Text('Emma can activate workflows'),
                value: p.allowEmmaActivate,
                onChanged: (v) => setState(() => editing = AutomationCompanyPolicy(
                  id: p.id,
                  companyId: p.companyId,
                  allowEmmaCreate: p.allowEmmaCreate,
                  allowEmmaUpdate: p.allowEmmaUpdate,
                  allowEmmaActivate: v,
                  requireReviewForEmma: p.requireReviewForEmma,
                  requireReviewRiskLevels: p.requireReviewRiskLevels,
                  blockedActionKeys: p.blockedActionKeys,
                )),
              ),
              SwitchListTile(
                title: const Text('Require review for Emma'),
                value: p.requireReviewForEmma,
                onChanged: (v) => setState(() => editing = AutomationCompanyPolicy(
                  id: p.id,
                  companyId: p.companyId,
                  allowEmmaCreate: p.allowEmmaCreate,
                  allowEmmaUpdate: p.allowEmmaUpdate,
                  allowEmmaActivate: p.allowEmmaActivate,
                  requireReviewForEmma: v,
                  requireReviewRiskLevels: p.requireReviewRiskLevels,
                  blockedActionKeys: p.blockedActionKeys,
                )),
              ),
              const SizedBox(height: 12),
              Text('Review risk levels: ${p.requireReviewRiskLevels.join(', ')}'),
              Text('Blocked actions: ${p.blockedActionKeys.join(', ')}'),
            ],
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    final p = editing;
    if (p == null) return;
    await ref.read(automationApiServiceProvider).saveCompanyPolicy(p);
    ref.invalidate(automationCompanyPoliciesProvider(widget.companyId));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Policy saved')));
  }
}
