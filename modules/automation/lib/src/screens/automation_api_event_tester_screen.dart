import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/automation_studio_config.dart';
import '../providers/automation_api_provider.dart';
import '../services/automation_api_service_new_features.dart';
import '../widgets/forms/automation_json_field.dart';

class AutomationApiEventTesterScreen extends ConsumerStatefulWidget {
  const AutomationApiEventTesterScreen({super.key});

  @override
  ConsumerState<AutomationApiEventTesterScreen> createState() => _AutomationApiEventTesterScreenState();
}

class _AutomationApiEventTesterScreenState extends ConsumerState<AutomationApiEventTesterScreen> {
  final signalController = TextEditingController(text: 'api.invoice.updated');
  Map<String, dynamic> payload = const {'id': 123, 'status': 'paid'};
  Map<String, dynamic>? result;

  @override
  Widget build(BuildContext context) {
    return automationShell(
      context,
      ref: ref,
      title: 'API event tester',
      screenKey: 'automation.api_event_tester',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: signalController,
            decoration: const InputDecoration(labelText: 'Signal key', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          AutomationJsonField(
            label: 'Payload',
            value: payload,
            onChanged: (value) => payload = value,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _send,
            icon: const Icon(Icons.send_rounded),
            label: const Text('Emit event'),
          ),
          if (result != null) ...[
            const SizedBox(height: 12),
            AutomationJsonField(label: 'Result', value: result!, onChanged: (_) {}),
          ],
        ],
      ),
    );
  }

  Future<void> _send() async {
    final data = await ref.read(automationApiServiceProvider).emitApiEvent(
          signalKey: signalController.text.trim(),
          body: payload,
        );
    if (mounted) setState(() => result = data);
  }
}
