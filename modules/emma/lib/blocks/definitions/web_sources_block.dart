import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/block_definition.dart';
import '../core/block_descriptor.dart';
import 'shared/block_ui.dart';

/// Lista źródeł, które Emma przeszukała (web_search / web_latest).
/// Każde źródło: domena + tytuł + fragment; tap = kopiuj URL do schowka.
class WebSourcesBlockDefinition extends EmmaBlockDefinition {
  const WebSourcesBlockDefinition();

  @override
  String get key => 'web_sources';

  @override
  bool supports(EmmaBlockDescriptor block) =>
      block.type == EmmaBlockType.webSources;

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _WebSourcesCard(block: block, maxWidth: maxWidth);
  }
}

class _WebSourcesCard extends StatelessWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;

  const _WebSourcesCard({required this.block, required this.maxWidth});

  static const _accent = Color(0xFF37B6FF);

  List<Map<String, dynamic>> get _sources {
    final raw = block.raw['sources'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }

  String get _query => (block.raw['query'] ?? '').toString().trim();

  int? get _total {
    final t = block.raw['total'];
    if (t is int) return t;
    return int.tryParse('${t ?? ''}');
  }

  void _copy(BuildContext context, String url) {
    if (url.isEmpty) return;
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Skopiowano link'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sources = _sources;
    if (sources.isEmpty) return const SizedBox.shrink();

    final totalLabel = (_total != null && _total! > sources.length)
        ? ' · z ${_total!}'
        : '';

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.travel_explore_rounded, color: _accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _query.isEmpty ? 'Źródła' : 'Źródła: $_query',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withAlpha(210),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              EmmaTag(label: '${sources.length}$totalLabel', color: _accent),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < sources.length; i++) ...[
            if (i > 0)
              Divider(color: Colors.white.withAlpha(15), height: 14),
            _SourceRow(
              source: sources[i],
              accent: _accent,
              onTap: () => _copy(context, (sources[i]['url'] ?? '').toString()),
            ),
          ],
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  final Map<String, dynamic> source;
  final Color accent;
  final VoidCallback onTap;

  const _SourceRow({
    required this.source,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = (source['title'] ?? '').toString().trim();
    final domain = (source['domain'] ?? '').toString().trim();
    final snippet = (source['snippet'] ?? '').toString().trim();
    final url = (source['url'] ?? '').toString().trim();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (domain.isNotEmpty) ...[
                  Flexible(
                    child: Text(
                      domain,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent.withAlpha(220),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Icon(Icons.copy_rounded, size: 12, color: Colors.white.withAlpha(90)),
              ],
            ),
            if (title.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withAlpha(220),
                  fontSize: 12.5,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (snippet.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                snippet,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withAlpha(150),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
            if (title.isEmpty && snippet.isEmpty && url.isNotEmpty)
              Text(
                url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
