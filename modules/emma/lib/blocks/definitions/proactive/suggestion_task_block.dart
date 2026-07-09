import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

import '../../core/block_definition.dart';
import '../../core/block_descriptor.dart';
import '../shared/block_ui.dart';
import 'package:emma/provider/urls.dart';

class SuggestionTaskBlockDefinition extends EmmaBlockDefinition {
  const SuggestionTaskBlockDefinition();

  @override
  String get key => 'suggestion_task';

  @override
  bool supports(EmmaBlockDescriptor block) =>
      block.type == EmmaBlockType.suggestionTask;

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _SuggestionTaskCard(
      block: block,
      maxWidth: maxWidth,
      messageId: messageId,
    );
  }
}

class _SuggestionTaskCard extends ConsumerStatefulWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;
  final String messageId;

  const _SuggestionTaskCard({
    required this.block,
    required this.maxWidth,
    required this.messageId,
  });

  @override
  ConsumerState<_SuggestionTaskCard> createState() =>
      _SuggestionTaskCardState();
}

class _SuggestionTaskCardState extends ConsumerState<_SuggestionTaskCard>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  bool _loading = true;
  bool _done = false;
  bool _draftError = false;
  int? _taskId;

  int? get _emailId {
    final parts = widget.messageId.split('_');
    if (parts.length >= 2 && parts[0] == 'email') return int.tryParse(parts[1]);
    return null;
  }

  static const _accent = Color(0xFFFF9800);

  String get _summary =>
      (widget.block.raw['summary'] ?? '').toString().trim();
  String get _title =>
      (widget.block.raw['title'] ?? '').toString().trim();
  String get _description =>
      (widget.block.raw['description'] ?? '').toString().trim();
  String get _dueDate =>
      (widget.block.raw['due_date'] ?? '').toString().trim();

  @override
  void initState() {
    super.initState();
    _autoDraft();
  }

  Future<void> _autoDraft() async {
    try {
      final resp = await ApiServices.post(
        URLsEmma.emmaProactiveAccept,
        data: {
          'type': 'suggestion_task',
          'mode': 'auto_draft',
          'data': {
            ...widget.block.raw,
            if (_emailId != null) '_email_id': _emailId,
          },
        },
        hasToken: true,
      );
      final id = resp?.data?['task_id'];
      if (!mounted) return;
      setState(() {
        _taskId = id is int ? id : int.tryParse(id?.toString() ?? '');
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _draftError = true;
        _loading = false;
      });
    }
  }

  void _showMsg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _confirm() async {
    if (_loading || _done) return;
    setState(() => _loading = true);
    try {
      await ApiServices.post(
        URLsEmma.emmaProactiveAccept,
        data: {
          'type': 'suggestion_task',
          'mode': 'confirm',
          'data': {'task_id': _taskId, ...widget.block.raw},
        },
        hasToken: true,
      );
      if (!mounted) return;
      setState(() => _done = true);
      _showMsg('Zadanie zatwierdzone');
    } catch (e) {
      if (!mounted) return;
      _showMsg('Błąd: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Fallback: legacy create (when auto-draft failed)
  Future<void> _legacyCreate() async {
    if (_loading || _done) return;
    setState(() => _loading = true);
    try {
      await ApiServices.post(
        URLsEmma.emmaProactiveAccept,
        data: {'type': 'suggestion_task', 'data': widget.block.raw},
        hasToken: true,
      );
      if (!mounted) return;
      setState(() => _done = true);
      _showMsg('Zadanie utworzone');
    } catch (e) {
      if (!mounted) return;
      _showMsg('Błąd: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _dismiss() async {
    setState(() => _loading = true);
    try {
      await ApiServices.post(
        URLsEmma.emmaProactiveDismiss,
        data: {
          'type': 'suggestion_task',
          if (_taskId != null) 'task_id': _taskId,
        },
        hasToken: true,
      );
    } catch (_) {}
    if (mounted) setState(() {_done = true; _loading = false;});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return EmmaBlockCardShell(
      maxWidth: widget.maxWidth,
      borderColor: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.task_alt_rounded, color: _accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sugerowane zadanie',
                  style: TextStyle(
                    color: Colors.white.withAlpha(210),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_loading && _taskId == null)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                )
              else
                EmmaTag(
                  label: _taskId != null ? 'Wersja robocza' : 'Zadanie',
                  color: _accent,
                ),
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
          const SizedBox(height: 10),
          if (_title.isNotEmpty)
            Text(
              _title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          if (_description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withAlpha(170),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
          if (_dueDate.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 13, color: Colors.white.withAlpha(140)),
                const SizedBox(width: 5),
                Text(
                  'Termin: $_dueDate',
                  style: TextStyle(
                      color: Colors.white.withAlpha(170), fontSize: 12),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          if (_done)
            Text(
              'Zadanie zatwierdzone',
              style:
                  TextStyle(color: Colors.white.withAlpha(150), fontSize: 12),
            )
          else if (_loading && _taskId == null)
            Text(
              'Dodawanie do TMS…',
              style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _loading
                      ? null
                      : (_draftError ? _legacyCreate : _confirm),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                  ),
                  icon: _loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check_rounded, size: 16),
                  label: Text(_draftError
                      ? 'Utwórz zadanie'
                      : 'Zatwierdź zadanie'),
                ),
                TextButton(
                  onPressed: _loading ? null : _dismiss,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withAlpha(140),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                  ),
                  child: const Text('Odrzuć'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
