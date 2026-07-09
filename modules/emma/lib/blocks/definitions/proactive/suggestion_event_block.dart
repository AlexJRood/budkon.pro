import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

import '../../core/block_definition.dart';
import '../../core/block_descriptor.dart';
import '../shared/block_ui.dart';
import 'package:emma/provider/urls.dart';

class SuggestionEventBlockDefinition extends EmmaBlockDefinition {
  const SuggestionEventBlockDefinition();

  @override
  String get key => 'suggestion_event';

  @override
  bool supports(EmmaBlockDescriptor block) =>
      block.type == EmmaBlockType.suggestionEvent;

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _SuggestionEventCard(
      block: block,
      maxWidth: maxWidth,
      messageId: messageId,
    );
  }
}

class _SuggestionEventCard extends ConsumerStatefulWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;
  final String messageId;

  const _SuggestionEventCard({
    required this.block,
    required this.maxWidth,
    required this.messageId,
  });

  @override
  ConsumerState<_SuggestionEventCard> createState() =>
      _SuggestionEventCardState();
}

class _SuggestionEventCardState extends ConsumerState<_SuggestionEventCard>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  bool _loading = true;
  bool _done = false;
  bool _draftError = false;
  int? _eventId;

  // Extract email_id from messageId convention: 'email_<emailId>_<index>'
  int? get _emailId {
    final parts = widget.messageId.split('_');
    if (parts.length >= 2 && parts[0] == 'email') return int.tryParse(parts[1]);
    return null;
  }

  static const _accent = Color(0xFF4CAF50);

  String get _summary =>
      (widget.block.raw['summary'] ?? '').toString().trim();
  String get _title =>
      (widget.block.raw['title'] ?? '').toString().trim();
  String get _start =>
      (widget.block.raw['start_datetime'] ?? '').toString().trim();
  String get _end =>
      (widget.block.raw['end_datetime'] ?? '').toString().trim();
  String get _location =>
      (widget.block.raw['location'] ?? '').toString().trim();

  String get _dateRange {
    if (_start.isEmpty) return '';
    if (_end.isEmpty) return _start;
    final s = _start.replaceAll('T', ' ');
    final e = _end.replaceAll('T', ' ');
    final sDate = s.length > 10 ? s.substring(0, 10) : s;
    final eDate = e.length > 10 ? e.substring(0, 10) : e;
    if (sDate == eDate) {
      final sTime = s.length > 10 ? s.substring(11, 16) : '';
      final eTime = e.length > 10 ? e.substring(11, 16) : '';
      return '$sDate $sTime – $eTime';
    }
    return '$s – $e';
  }

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
          'type': 'suggestion_event',
          'mode': 'auto_draft',
          'data': {
            ...widget.block.raw,
            if (_emailId != null) '_email_id': _emailId,
          },
        },
        hasToken: true,
      );
      final id = resp?.data?['event_id'];
      if (!mounted) return;
      setState(() {
        _eventId = id is int ? id : int.tryParse(id?.toString() ?? '');
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
          'type': 'suggestion_event',
          'mode': 'confirm',
          'data': {'event_id': _eventId, ...widget.block.raw},
        },
        hasToken: true,
      );
      if (!mounted) return;
      setState(() => _done = true);
      _showMsg('Wydarzenie zatwierdzone w kalendarzu');
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
        data: {'type': 'suggestion_event', 'data': widget.block.raw},
        hasToken: true,
      );
      if (!mounted) return;
      setState(() => _done = true);
      _showMsg('Dodano do kalendarza');
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
          'type': 'suggestion_event',
          if (_eventId != null) 'event_id': _eventId,
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
              Icon(Icons.event_rounded, color: _accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sugerowane wydarzenie',
                  style: TextStyle(
                    color: Colors.white.withAlpha(210),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_loading && _eventId == null)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                )
              else
                EmmaTag(
                  label: _eventId != null ? 'Wersja robocza' : 'Kalendarz',
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
          if (_dateRange.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 13, color: Colors.white.withAlpha(140)),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    _dateRange,
                    style: TextStyle(
                        color: Colors.white.withAlpha(170), fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          if (_location.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.place_rounded,
                    size: 13, color: Colors.white.withAlpha(140)),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    _location,
                    style: TextStyle(
                        color: Colors.white.withAlpha(170), fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          if (_done)
            Text(
              'Wydarzenie zatwierdzone',
              style:
                  TextStyle(color: Colors.white.withAlpha(150), fontSize: 12),
            )
          else if (_loading && _eventId == null)
            Text(
              'Dodawanie do kalendarza…',
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
                      ? 'Dodaj do kalendarza'
                      : 'Zatwierdź w kalendarzu'),
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
