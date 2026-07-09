// emma/lib/blocks/definitions/docs/docs_create_from_contact_block.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/platform/navigation_service.dart' show navigationService;
import 'package:core/platform/route_constant.dart' show Routes;

import '../../core/block_definition.dart';
import '../../core/block_descriptor.dart';
import '../../../provider/docs_emma_state.dart';

class DocsCreateFromContactBlockDefinition extends EmmaBlockDefinition {
  const DocsCreateFromContactBlockDefinition();

  @override
  String get key => 'docs_create_from_contact';

  @override
  bool supports(EmmaBlockDescriptor block) {
    return block.type == EmmaBlockType.docsCreateFromContact;
  }

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _DocsCreateFromContactCard(
      block: block,
      maxWidth: maxWidth,
    );
  }
}

class _DocsCreateFromContactCard extends ConsumerStatefulWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;

  const _DocsCreateFromContactCard({
    required this.block,
    required this.maxWidth,
  });

  @override
  ConsumerState<_DocsCreateFromContactCard> createState() =>
      _DocsCreateFromContactCardState();
}

class _DocsCreateFromContactCardState
    extends ConsumerState<_DocsCreateFromContactCard> {
  bool _confirmed = false;
  bool _cancelled = false;

  int? get _templateId {
    final raw = widget.block.raw['template_id'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  String get _templateName =>
      (widget.block.raw['template_name'] ?? '').toString().trim();
  String get _contactId =>
      (widget.block.raw['contact_id'] ?? '').toString().trim();
  String get _contactType =>
      (widget.block.raw['contact_type'] ?? 'contact').toString().trim();

  List<String> get _actions {
    final raw = widget.block.raw['actions'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const ['create_and_fill', 'cancel'];
  }

  String _localizeContactType(String type) {
    switch (type) {
      case 'lead':
        return 'lead';
      case 'client':
        return 'klient';
      case 'owner':
        return 'właściciel';
      default:
        return 'kontakt';
    }
  }

  void _createAndFill() {
    if (_confirmed || _cancelled) return;
    final tid = _templateId;
    if (tid == null || _contactId.isEmpty) return;

    ref.read(docsEmmaProvider.notifier).requestCreateFromContact(
          DocsCreateFromContactRequest(
            templateId: tid,
            templateName: _templateName,
            contactId: _contactId,
            contactType: _contactType,
          ),
        );

    setState(() => _confirmed = true);

    ref.read(navigationService).pushNamedScreen(
      Routes.docs,
      data: {
        'templateId': tid.toString(),
        'contactId': _contactId,
        'contactType': _contactType,
      },
    );
  }

  void _cancel() {
    if (_confirmed || _cancelled) return;
    setState(() => _cancelled = true);
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF37B6FF);
    final isDone = _confirmed || _cancelled;

    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 8),
      padding: const EdgeInsets.all(14),
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(90),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withAlpha(isDone ? 50 : 110),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'create_document_for_contact'.tr,
                  style: TextStyle(
                    color: Colors.white.withAlpha(210),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_confirmed)
                _statusChip('creating'.tr, Colors.greenAccent)
              else if (_cancelled)
                _statusChip('cancelled'.tr, Colors.white38),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.article_outlined,
            'template'.tr,
            _templateName.isNotEmpty ? _templateName : _templateId?.toString() ?? '—',
            accent,
          ),
          const SizedBox(height: 6),
          _infoRow(
            Icons.person_outline_rounded,
            'contact_type'.tr,
            _localizeContactType(_contactType),
            Colors.white60,
          ),
          if (!isDone) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_actions.contains('create_and_fill'))
                  FilledButton.icon(
                    onPressed: _createAndFill,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 15),
                    label: Text('create_and_fill'.tr),
                  ),
                if (_actions.contains('cancel'))
                  OutlinedButton(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white60,
                      side: BorderSide(color: Colors.white.withAlpha(30)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text('cancel'.tr),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withAlpha(120),
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
