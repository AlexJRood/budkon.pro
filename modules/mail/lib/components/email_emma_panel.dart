import 'dart:async';
import 'dart:convert';

import 'package:emma/blocks/blocks.dart';
import 'package:emma/blocks/core/block_descriptor.dart';
import 'package:emma/provider/urls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

enum _PanelStatus { idle, loading, ready, nothingDetected, error }

class EmailEmmaPanel extends ConsumerStatefulWidget {
  final int emailId;

  /// When true: no collapsible header, always fully visible (for bottom sheets).
  final bool standalone;

  const EmailEmmaPanel({
    super.key,
    required this.emailId,
    this.standalone = false,
  });

  @override
  ConsumerState<EmailEmmaPanel> createState() => _EmailEmmaPanelState();
}

class _EmailEmmaPanelState extends ConsumerState<EmailEmmaPanel> {
  static const _accent = Color(0xFF37B6FF);
  static const _maxPolls = 22;
  static const _carouselHeight = 260.0;

  // In-process cache: email IDs for which analysis has been triggered in this
  // app session.  Prevents re-queuing on every panel rebuild.
  static final Set<int> _triggeredThisSession = {};

  _PanelStatus _status = _PanelStatus.idle;
  List<EmmaBlockDescriptor> _blocks = const [];
  late bool _expanded;
  bool _polling = false;

  Timer? _pollTimer;
  int? _sessionId;
  int _pollCount = 0;

  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _expanded = widget.standalone;
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// Step 1 — check DB for existing structured suggestions.
  /// Only triggers LLM analysis if nothing exists yet AND we haven't
  /// already triggered for this email_id in this session.
  Future<void> _init() async {
    if (!mounted) return;
    setState(() => _status = _PanelStatus.loading);

    try {
      final res = await ApiServices.get(
        URLsEmma.emmaEmailSuggestions(widget.emailId),
        hasToken: true,
        ref: ref,
      );
      if (!mounted) return;

      if (res != null && res.statusCode == 200) {
        final body = _decode(res.data);
        if (body is Map) {
          final analyzed = body['analyzed'] == true;
          final suggestions = (body['suggestions'] as List?) ?? [];
          final inquiries  = (body['inquiries']  as List?) ?? [];

          if (suggestions.isNotEmpty || inquiries.isNotEmpty) {
            // Already has structured results — no LLM needed
            if (mounted) setState(() => _status = _PanelStatus.nothingDetected);
            // Note: structured suggestions are shown in the global pending dashboard.
            // The per-email panel acknowledges them but doesn't re-render them here.
            return;
          }

          if (analyzed) {
            // Analyzed but nothing actionable detected
            if (mounted) setState(() => _status = _PanelStatus.nothingDetected);
            return;
          }
        }
      }
    } catch (_) {
      // If the check fails, fall through to LLM trigger
    }

    // Not yet analyzed — trigger LLM once per email per session
    if (!_triggeredThisSession.contains(widget.emailId)) {
      _triggeredThisSession.add(widget.emailId);
      await _triggerLlm();
    } else {
      // Already triggered but panel was rebuilt — resume polling if needed
      if (_sessionId != null) {
        _startPolling();
      } else {
        if (mounted) setState(() => _status = _PanelStatus.nothingDetected);
      }
    }
  }

  Future<void> _triggerLlm() async {
    if (!mounted) return;
    setState(() => _status = _PanelStatus.loading);
    try {
      final response = await ApiServices.post(
        URLsEmma.emmaProactiveEmail(widget.emailId),
        data: <String, dynamic>{},
        hasToken: true,
        ref: ref,
      );
      if (!mounted) return;

      final data = _decode(response?.data);
      final Map<String, dynamic> dataMap =
          data is Map ? Map<String, dynamic>.from(data) : {};

      final sessionId = int.tryParse((dataMap['session_id'] ?? '').toString());
      if (sessionId == null) {
        setState(() => _status = _PanelStatus.error);
        return;
      }
      _sessionId = sessionId;
      _pollCount = 0;
      _startPolling();
    } catch (_) {
      if (mounted) setState(() => _status = _PanelStatus.error);
    }
  }

  void _startPolling() {
    if (_polling) return;
    _polling = true;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  Future<void> _poll() async {
    if (!mounted || _sessionId == null) return;
    _pollCount++;
    if (_pollCount > _maxPolls) {
      _pollTimer?.cancel();
      _polling = false;
      // Analysis finished but nothing actionable — not an error
      if (mounted) setState(() => _status = _PanelStatus.nothingDetected);
      return;
    }
    try {
      final res = await ApiServices.getJson(
        '${URLsEmma.baseUrl}chat/messages/',
        ref: ref,
        queryParameters: {
          'session': _sessionId.toString(),
          'role': 'assistant',
          'ordering': '-created_at',
          'limit': '10',
        },
      );
      if (!mounted) return;

      final results = res['results'];
      if (results is! List) return;

      for (final msg in results) {
        if (msg is! Map) continue;
        final meta = msg['meta'];
        if (meta is! Map) continue;

        // Filter: only accept blocks generated for THIS email
        final msgEmailId = meta['email_id']?.toString();
        if (msgEmailId != null && msgEmailId != widget.emailId.toString()) continue;

        final blocks = parseBlocksFromMeta(Map<String, dynamic>.from(meta));
        if (blocks.isNotEmpty) {
          _pollTimer?.cancel();
          _polling = false;
          if (mounted) {
            setState(() {
              _blocks = blocks;
              _status = _PanelStatus.ready;
              _expanded = true;
            });
          }
          return;
        }
      }
    } catch (_) {}
  }

  void _goTo(int index) {
    if (index < 0 || index >= _blocks.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final blockCount = _blocks.length;

    if (widget.standalone) {
      return _buildStandaloneBody(blockCount);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ──
        InkWell(
          onTap: _status == _PanelStatus.ready
              ? () => setState(() => _expanded = !_expanded)
              : _status == _PanelStatus.error
                  ? _init
                  : null,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: _accent.withAlpha(35)),
                bottom: _expanded && _status == _PanelStatus.ready
                    ? BorderSide(color: _accent.withAlpha(20))
                    : BorderSide.none,
              ),
              color: _accent.withAlpha(8),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: _accent, size: 14),
                const SizedBox(width: 7),
                Text(
                  'Sugestie Emmy',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
                const Spacer(),
                _buildHeaderTrailing(blockCount),
              ],
            ),
          ),
        ),

        // ── Carousel ──
        if (_expanded && _status == _PanelStatus.ready && blockCount > 0)
          SizedBox(
            height: _carouselHeight,
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: blockCount,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, index) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: EmmaBlocksSection(
                          blocks: [_blocks[index]],
                          maxWidth: double.infinity,
                          messageId: 'email_${widget.emailId}_$index',
                        ),
                      );
                    },
                  ),
                ),
                if (blockCount > 1) _buildCarouselFooter(blockCount),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStandaloneBody(int blockCount) {
    switch (_status) {
      case _PanelStatus.idle:
      case _PanelStatus.loading:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _accent.withAlpha(180),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Analizuję email…',
                  style: TextStyle(
                    color: _accent.withAlpha(160),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );

      case _PanelStatus.nothingDetected:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded,
                    color: _accent.withAlpha(60), size: 36),
                const SizedBox(height: 12),
                Text(
                  'Brak sugestii dla tej wiadomości',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _accent.withAlpha(140),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );

      case _PanelStatus.error:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    color: Colors.redAccent.withAlpha(180), size: 32),
                const SizedBox(height: 12),
                Text(
                  'Błąd analizy',
                  style: TextStyle(
                    color: Colors.redAccent.withAlpha(180),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _init,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Spróbuj ponownie'),
                ),
              ],
            ),
          ),
        );

      case _PanelStatus.ready:
        if (blockCount == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'Brak sugestii',
                style: TextStyle(
                  color: _accent.withAlpha(120),
                  fontSize: 13,
                ),
              ),
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 430,
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: blockCount,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemBuilder: (context, index) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                          child: EmmaBlocksSection(
                            blocks: [_blocks[index]],
                            maxWidth: double.infinity,
                            messageId: 'email_${widget.emailId}_$index',
                          ),
                        );
                      },
                    ),
                  ),
                  if (blockCount > 1) _buildCarouselFooter(blockCount),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildCarouselFooter(int blockCount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NavArrow(
            icon: Icons.chevron_left_rounded,
            onTap: _currentPage > 0 ? () => _goTo(_currentPage - 1) : null,
            accent: _accent,
          ),
          const SizedBox(width: 6),
          ...List.generate(blockCount, (i) {
            final active = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? _accent : _accent.withAlpha(60),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
          const SizedBox(width: 6),
          _NavArrow(
            icon: Icons.chevron_right_rounded,
            onTap: _currentPage < blockCount - 1
                ? () => _goTo(_currentPage + 1)
                : null,
            accent: _accent,
          ),
          const SizedBox(width: 14),
          Text(
            '${_currentPage + 1} / $blockCount',
            style: TextStyle(
              color: _accent.withAlpha(140),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTrailing(int blockCount) {
    switch (_status) {
      case _PanelStatus.idle:
      case _PanelStatus.loading:
        return SizedBox(
          width: 13,
          height: 13,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: _accent.withAlpha(150),
          ),
        );
      case _PanelStatus.nothingDetected:
        return Text(
          'brak sugestii',
          style: TextStyle(
            color: _accent.withAlpha(120),
            fontSize: 11,
          ),
        );
      case _PanelStatus.error:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Spróbuj ponownie',
              style: TextStyle(
                color: Colors.redAccent.withAlpha(200),
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.refresh_rounded, color: Colors.redAccent, size: 14),
          ],
        );
      case _PanelStatus.ready:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (blockCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _accent.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$blockCount',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(
              _expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: _accent.withAlpha(180),
              size: 16,
            ),
          ],
        );
    }
  }

  static dynamic _decode(dynamic data) {
    if (data is List<int>) return jsonDecode(utf8.decode(data));
    if (data is String) {
      final v = data.trim();
      return v.isEmpty ? null : jsonDecode(v);
    }
    return data;
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color accent;

  const _NavArrow({
    required this.icon,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          icon,
          size: 20,
          color: onTap != null ? accent : accent.withAlpha(40),
        ),
      ),
    );
  }
}
