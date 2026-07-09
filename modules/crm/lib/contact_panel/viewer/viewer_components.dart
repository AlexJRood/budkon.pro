import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/apptheme.dart';
import 'package:crm/contact_panel/viewer/viewer_list.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';
import 'package:crm/contact_panel/viewer/viewer_provider.dart';

class ViewerClientView extends ConsumerWidget {
  final int clientId;
  final AgentTransactionModel transaction;
  final bool isMobile;

  const ViewerClientView({
    super.key,
    required this.clientId,
    required this.transaction,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Column(
      children: [
        // Górny pasek z akcjami
        Row(
          children: [
            ElevatedButton(
              style: elevatedButtonStyleRounded10,
              onPressed: () async {
                // Dialog wyboru kontaktu spośród nieprzypiętych do tej transakcji
                final added = await showDialog<bool>(
                  context: context,
                  builder: (_) => _AddViewerDialog(transactionId: transaction.id),
                );
                if (added == true) {
                  ref.invalidate(viewersForTransactionProvider(transaction.id));
                }
              },
              child: Text('add_viewer_button'.tr, style: TextStyle(color: theme.textColor)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ViewerListClientTable(transactionId: transaction.id, clientId: clientId, isMobile: isMobile),
        ),
      ],
    );
  }
}

class _AddViewerDialog extends ConsumerStatefulWidget {
  final int transactionId;
  const _AddViewerDialog({required this.transactionId});

  @override
  ConsumerState<_AddViewerDialog> createState() => _AddViewerDialogState();
}

class _AddViewerDialogState extends ConsumerState<_AddViewerDialog> {
  final _controller = TextEditingController();
  int? _selectedContactId;
  List<Map<String, dynamic>> _items = [];
  bool _loading = false;

  Future<void> _loadCandidates() async {
    setState(() => _loading = true);
    try {
      final r = await ApiServices.get(
        ref:ref,
        URLs.userContacts,
        hasToken: true,
        queryParameters: {
          'viewer_transaction': widget.transactionId,
          'viewer_is_assigned': 'false',
          if (_controller.text.trim().isNotEmpty) 'search': _controller.text.trim(),
        },
      );
      final data = r?.data;
      final results = (data is Map && data['results'] is List) ? (data['results'] as List).cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
      setState(() => _items = results);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    
    return Dialog(
      backgroundColor: theme.dashboardContainer,
      child: SizedBox(
        width: 560,
        height: 560,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(labelText: 'search_contact_hint'.tr),
                onSubmitted: (_) => _loadCandidates(),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final it = _items[i];
                          final id = it['id'] as int;
                          final name = [it['name'], it['last_name']].where((e) => (e ?? '').toString().isNotEmpty).join(' ');
                          final email = it['email'] ?? '';
                          return RadioListTile<int>(
                            value: id,
                            groupValue: _selectedContactId,
                            onChanged: (v) => setState(() => _selectedContactId = v),
                            title: Text(name),
                            subtitle: Text(email),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child:Text('cancel_button'.tr)),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selectedContactId == null
                        ? null
                        : () async {
                            await addViewerToTx(txId: widget.transactionId, contactId: _selectedContactId!);
                            if (context.mounted) Navigator.pop(context, true);
                          },
                    child: Text('add_button'.tr),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
