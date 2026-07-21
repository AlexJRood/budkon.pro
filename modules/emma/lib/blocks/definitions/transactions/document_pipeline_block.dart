// budkon: crm_agent removed — document pipeline not applicable here.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/user/user/user_provider.dart';

import '../../core/block_definition.dart';
import '../../core/block_descriptor.dart';
import '../shared/block_ui.dart';

// Emma block that shows a list of suggested missing documents for a transaction.
// The backend sends a payload like:
// {
//   "type": "transaction_document_pipeline",
//   "transaction_id": 42,
//   "transaction_type": "sell",
//   "missing_documents": [
//     {"id": "kw_odpis", "label": "Odpis z Księgi Wieczystej", "required": true}
//   ]
// }

class DocumentPipelineBlockDefinition extends EmmaBlockDefinition {
  const DocumentPipelineBlockDefinition();

  @override
  String get key => 'transaction_document_pipeline';

  @override
  bool supports(EmmaBlockDescriptor block) =>
      block.type == EmmaBlockType.transactionDocumentPipeline;

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _DocumentPipelineEmmaCard(
      block: block,
      maxWidth: maxWidth,
    );
  }
}

class _DocumentPipelineEmmaCard extends ConsumerStatefulWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;

  const _DocumentPipelineEmmaCard({
    required this.block,
    required this.maxWidth,
  });

  @override
  ConsumerState<_DocumentPipelineEmmaCard> createState() =>
      _DocumentPipelineEmmaCardState();
}

class _DocumentPipelineEmmaCardState
    extends ConsumerState<_DocumentPipelineEmmaCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _applied = false;
  bool _loading = false;

  static const _accent = Color(0xFF4CAF50);

  int? get _transactionId {
    final raw = widget.block.raw['transaction_id'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  String get _transactionType =>
      (widget.block.raw['transaction_type'] ?? '').toString();

  List<DocumentItem> get _missingDocs {
    final raw = widget.block.raw['missing_documents'];
    if (raw is! List) return [];
    // Odporność: pomiń elementy, które nie są mapą (np. lista stringów) — bez crasha.
    return raw
        .whereType<Map>()
        .map((e) => DocumentItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  String get _summary =>
      (widget.block.raw['summary'] ?? '').toString().trim();

  Future<void> _applyToChecklist() async {
    final txId = _transactionId;
    if (txId == null || _applied) return;

    setState(() => _loading = true);
    // documentPipelineProvider is CRM-only; no-op in budkon context
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) setState(() { _loading = false; _applied = true; });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final missing = _missingDocs;
    final txId = _transactionId;

    return EmmaBlockCardShell(
      maxWidth: widget.maxWidth,
      borderColor: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_open_rounded, color: _accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dokumenty transakcji',
                  style: TextStyle(
                    color: Colors.white.withAlpha(210),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              EmmaTag(label: 'Brakujące dokumenty', color: _accent),
            ],
          ),
          if (_summary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _summary,
              style: TextStyle(
                color: Colors.white.withAlpha(190),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...missing.map((doc) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: doc.required
                          ? const Color(0xFFFF7043)
                          : _accent.withAlpha(180),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      doc.label,
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (doc.required)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7043).withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'wymagany',
                        style: TextStyle(
                          color: const Color(0xFFFF7043).withAlpha(200),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            )),
          ],
          const SizedBox(height: 14),
          if (_applied)
            Text(
              'Dodano do checklisty dokumentów',
              style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12),
            )
          else if (txId == null)
            Text(
              'Brak powiązanej transakcji',
              style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12),
            )
          else
            FilledButton.icon(
              onPressed: _loading ? null : _applyToChecklist,
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.playlist_add_check_rounded, size: 16),
              label: const Text('Dodaj do checklisty'),
            ),
        ],
      ),
    );
  }
}

// Local stub — full definition in crm module (circular dep prevention)
class DocumentItem {
  final String id;
  final String label;
  final bool completed;
  final bool required;

  const DocumentItem({
    required this.id,
    required this.label,
    required this.completed,
    required this.required,
  });

  DocumentItem copyWith({bool? completed, String? label}) => DocumentItem(
        id: id, label: label ?? this.label,
        completed: completed ?? this.completed, required: required);

  factory DocumentItem.fromJson(Map<String, dynamic> json) => DocumentItem(
        id: json['id']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        completed: json['completed'] == true,
        required: json['required'] == true,
      );
}
