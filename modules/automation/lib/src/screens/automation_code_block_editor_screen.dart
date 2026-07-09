import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/automation_studio_config.dart';
import '../models/automation_code_block.dart';
import '../models/automation_common.dart';
import '../providers/automation_api_provider.dart';
import '../services/automation_api_service_new_features.dart';
import '../widgets/forms/automation_json_field.dart';

class AutomationCodeBlockEditorScreen extends ConsumerStatefulWidget {
  final AutomationCodeBlock? block;
  final String? workflowId;
  final int? companyId;

  const AutomationCodeBlockEditorScreen({
    super.key,
    this.block,
    this.workflowId,
    this.companyId,
  });

  @override
  ConsumerState<AutomationCodeBlockEditorScreen> createState() => _AutomationCodeBlockEditorScreenState();
}

class _AutomationCodeBlockEditorScreenState extends ConsumerState<AutomationCodeBlockEditorScreen> {
  late final nameController = TextEditingController(text: widget.block?.name ?? '');
  late final descriptionController = TextEditingController(text: widget.block?.description ?? '');
  late final codeController = TextEditingController(
    text: widget.block?.code ?? '{\n  "result": "ok"\n}',
  );

  late AutomationCodeLanguage language = widget.block?.language ?? AutomationCodeLanguage.safeExpression;
  Map<String, dynamic> input = const {'payload': {'status': 'paid'}};
  bool busy = false;

  @override
  Widget build(BuildContext context) {
    return automationShell(
      context,
      ref: ref,
      title: widget.block == null ? 'New code block' : 'Edit code block',
      screenKey: 'automation.code_block_editor',
      actions: [
        IconButton(onPressed: busy ? null : _save, icon: const Icon(Icons.save_rounded)),
        if (widget.block?.id.isNotEmpty == true) ...[
          IconButton(onPressed: busy ? null : _validate, icon: const Icon(Icons.fact_check_rounded)),
          IconButton(onPressed: busy ? null : _dryRun, icon: const Icon(Icons.science_rounded)),
          IconButton(onPressed: busy ? null : _requestReview, icon: const Icon(Icons.verified_user_rounded)),
        ],
      ],
      child: Row(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AutomationCodeLanguage>(
                  value: language,
                  decoration: const InputDecoration(labelText: 'Language', border: OutlineInputBorder()),
                  items: AutomationCodeLanguage.values
                      .map((item) => DropdownMenuItem(value: item, child: Text(enumName(item))))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => language = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeController,
                  minLines: 18,
                  maxLines: 32,
                  style: const TextStyle(fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    labelText: 'Code / safe expression',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 380,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AutomationJsonField(
                  label: 'Dry-run input',
                  value: input,
                  onChanged: (value) => input = value,
                ),
                const SizedBox(height: 12),
                const Text('Safety', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text(
                  'Python powinien działać tylko na osobnym sandbox workerze. '
                  'Safe expression jest domyślnym, najbezpieczniejszym trybem.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AutomationCodeBlock _block() => AutomationCodeBlock(
        id: widget.block?.id ?? '',
        workflowId: widget.workflowId ?? widget.block?.workflowId,
        companyId: widget.companyId ?? widget.block?.companyId,
        name: nameController.text.trim().isEmpty ? 'Untitled code block' : nameController.text.trim(),
        description: descriptionController.text.trim(),
        language: language,
        code: codeController.text,
      );

  Future<void> _save() async {
    setState(() => busy = true);
    try {
      final saved = await ref.read(automationApiServiceProvider).saveCodeBlock(_block());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code block saved')));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AutomationCodeBlockEditorScreen(
              block: saved,
              workflowId: widget.workflowId,
              companyId: widget.companyId,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _validate() async {
    final id = widget.block?.id;
    if (id == null) return;
    await ref.read(automationApiServiceProvider).validateCodeBlock(id);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Validated')));
  }

  Future<void> _requestReview() async {
    final id = widget.block?.id;
    if (id == null) return;
    await ref.read(automationApiServiceProvider).requestCodeBlockReview(id);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review requested')));
  }

  Future<void> _dryRun() async {
    final id = widget.block?.id;
    if (id == null) return;
    final result = await ref.read(automationApiServiceProvider).dryRunCodeBlock(id, input: input);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Dry run: ${enumName(result.status)}'),
        content: SingleChildScrollView(
          child: Text('stdout:\n${result.stdout}\n\nstderr:\n${result.stderr}\n\noutput:\n${result.outputData}'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }
}
