import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';

import 'published_ad_network_link.dart';
import 'published_ad_network_links_provider.dart';

class PublishedAdNetworkLinksOverlay extends ConsumerStatefulWidget {
  const PublishedAdNetworkLinksOverlay({
    super.key,
    required this.scope,
  });

  final PublishedAdNetworkLinksScope scope;

  static Future<void> show({
    required BuildContext context,
    required PublishedAdNetworkLinksScope scope,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => PublishedAdNetworkLinksOverlay(scope: scope),
    );
  }

  @override
  ConsumerState<PublishedAdNetworkLinksOverlay> createState() =>
      _PublishedAdNetworkLinksOverlayState();
}

class _PublishedAdNetworkLinksOverlayState
    extends ConsumerState<PublishedAdNetworkLinksOverlay> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await ref
          .read(publishedAdNetworkLinksProvider(widget.scope).notifier)
          .loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final state = ref.watch(publishedAdNetworkLinksProvider(widget.scope));
    final notifier =
        ref.read(publishedAdNetworkLinksProvider(widget.scope).notifier);

    final visibleLinks = state.links.where((item) => !item.isRejected).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 920,
          maxHeight: 820,
        ),
        child: Material(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _Header(
                theme: theme,
                isLoading: state.isFinding || state.isLoading,
                onClose: () => Navigator.of(context).maybePop(),
                onRefresh: () => notifier.findCandidates(force: true),
              ),
              if (state.error != null)
                _ErrorBox(
                  theme: theme,
                  message: state.error!,
                ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (visibleLinks.isEmpty) {
                      return _EmptyState(
                        theme: theme,
                        isFinding: state.isFinding,
                        onFind: () => notifier.findCandidates(force: true),
                        onAddManual: () => _openManualDialog(context),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SettingsCard(
                            theme: theme,
                            settings: state.settings,
                            isSaving: state.isActionRunning,
                            onChanged: (settings) {
                              notifier.saveSettings(settings);
                            },
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Found possible publication links'.tr,
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: state.isFinding
                                    ? null
                                    : () => notifier.findCandidates(force: true),
                                icon: const Icon(Icons.search),
                                label: Text('Find again'.tr),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                style: elevatedButtonStyleRounded10,
                                onPressed: () => _openManualDialog(context),
                                icon: const Icon(Icons.add_link),
                                label: Text('Add link'.tr),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          for (final link in visibleLinks) ...[
                            _LinkCandidateCard(
                              theme: theme,
                              link: link,
                              isActionRunning: state.isActionRunning,
                              onConfirm: () => notifier.confirm(link.id),
                              onReject: () => notifier.reject(link.id),
                              onCheckActive: () {
                                notifier.checkActive(linkId: link.id);
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openManualDialog(BuildContext context) async {
    final result = await showDialog<_ManualLinkInput>(
      context: context,
      builder: (_) => _ManualLinkDialog(),
    );

    if (result == null) return;

    await ref
        .read(publishedAdNetworkLinksProvider(widget.scope).notifier)
        .addManualLink(
          url: result.url,
          portalCode: result.portalCode,
          portalName: result.portalName,
        );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.theme,
    required this.isLoading,
    required this.onClose,
    required this.onRefresh,
  });

  final ThemeColors theme;
  final bool isLoading;
  final VoidCallback onClose;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: theme.themeColor,
      child: Row(
        children: [
          Icon(Icons.hub_outlined, color: theme.themeTextColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Network Monitoring links'.tr,
              style: TextStyle(
                color: theme.themeTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (isLoading) ...[
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.themeTextColor,
              ),
            ),
            const SizedBox(width: 10),
          ],
          IconButton(
            onPressed: isLoading ? null : onRefresh,
            icon: Icon(Icons.refresh, color: theme.themeTextColor),
            tooltip: 'Refresh'.tr,
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close, color: theme.themeTextColor),
            tooltip: 'Close'.tr,
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({
    required this.theme,
    required this.message,
  });

  final ThemeColors theme;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withAlpha(90)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: theme.textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.theme,
    required this.isFinding,
    required this.onFind,
    required this.onAddManual,
  });

  final ThemeColors theme;
  final bool isFinding;
  final VoidCallback onFind;
  final VoidCallback onAddManual;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.textFieldColor.withAlpha(100),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.textColor.withAlpha(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.link_off_outlined,
              size: 48,
              color: theme.themeColor,
            ),
            const SizedBox(height: 12),
            Text(
              'No publication links found yet'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can search Network Monitoring again or add a publication link manually.'
                  .tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textColor.withAlpha(170)),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: elevatedButtonStyleRounded10,
                  onPressed: isFinding ? null : onFind,
                  icon: isFinding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text('Find candidates'.tr),
                ),
                TextButton.icon(
                  onPressed: onAddManual,
                  icon: const Icon(Icons.add_link),
                  label: Text('Add link manually'.tr),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.theme,
    required this.settings,
    required this.isSaving,
    required this.onChanged,
  });

  final ThemeColors theme;
  final PublishedAdMatchingSettings? settings;
  final bool isSaving;
  final ValueChanged<PublishedAdMatchingSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = settings;

    if (current == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.textFieldColor.withAlpha(80),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.textColor.withAlpha(26)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.settings_outlined, color: theme.textColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Published ad matching settings'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isSaving)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: current.enabled,
            title: Text(
              'Enable NM matching'.tr,
              style: TextStyle(color: theme.textColor),
            ),
            onChanged: (value) {
              onChanged(current.copyWith(enabled: value));
            },
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: current.showOverlay,
            title: Text(
              'Show overlay with candidates'.tr,
              style: TextStyle(color: theme.textColor),
            ),
            onChanged: (value) {
              onChanged(current.copyWith(showOverlay: value));
            },
          ),
        ],
      ),
    );
  }
}

class _LinkCandidateCard extends StatelessWidget {
  const _LinkCandidateCard({
    required this.theme,
    required this.link,
    required this.isActionRunning,
    required this.onConfirm,
    required this.onReject,
    required this.onCheckActive,
  });

  final ThemeColors theme;
  final PublishedAdNetworkLink link;
  final bool isActionRunning;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final VoidCallback onCheckActive;

  @override
  Widget build(BuildContext context) {
    final local = link.matchReasons['local'];
    final nm = link.matchReasons['nm'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: link.isConfirmed || link.isManual
              ? Colors.green.withAlpha(120)
              : theme.textColor.withAlpha(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _ConfidenceBadge(
                theme: theme,
                confidence: link.confidence,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  link.displayPortal,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusPill(
                theme: theme,
                status: link.matchStatus,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            link.displayTitle,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            link.url,
            style: TextStyle(
              color: theme.themeColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          _ScoresRow(theme: theme, link: link),
          if (local is Map || nm is Map) ...[
            const SizedBox(height: 12),
            _ComparisonBox(
              theme: theme,
              local: local is Map ? Map<String, dynamic>.from(local) : const {},
              nm: nm is Map ? Map<String, dynamic>.from(nm) : const {},
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                style: elevatedButtonStyleRounded10,
                onPressed: isActionRunning || link.isConfirmed
                    ? null
                    : onConfirm,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  link.isConfirmed ? 'Confirmed'.tr : 'This is my ad'.tr,
                ),
              ),
              TextButton.icon(
                onPressed: isActionRunning || link.isRejected
                    ? null
                    : onReject,
                icon: const Icon(Icons.block),
                label: Text('Not this ad'.tr),
              ),
              TextButton.icon(
                onPressed: isActionRunning ? null : onCheckActive,
                icon: const Icon(Icons.radar_outlined),
                label: Text('Check active'.tr),
              ),
              TextButton.icon(
                onPressed: () {
                  // Replace with url_launcher if you already use it in project.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(link.url)),
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: Text('Copy/open link'.tr),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({
    required this.theme,
    required this.confidence,
  });

  final ThemeColors theme;
  final double confidence;

  @override
  Widget build(BuildContext context) {
    final percent = (confidence * 100).round().clamp(0, 100);

    Color color = Colors.orange;
    if (confidence >= 0.92) color = Colors.green;
    if (confidence < 0.8) color = Colors.red;

    return Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withAlpha(28),
        border: Border.all(color: color.withAlpha(120), width: 2),
      ),
      child: Text(
        '$percent%',
        style: TextStyle(
          color: theme.textColor,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.theme,
    required this.status,
  });

  final ThemeColors theme;
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color = theme.themeColor;

    if (status == 'confirmed' || status == 'manual') {
      color = Colors.green;
    } else if (status == 'rejected') {
      color = Colors.red;
    } else if (status == 'suggested') {
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        status.tr,
        style: TextStyle(
          color: theme.textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ScoresRow extends StatelessWidget {
  const _ScoresRow({
    required this.theme,
    required this.link,
  });

  final ThemeColors theme;
  final PublishedAdNetworkLink link;

  @override
  Widget build(BuildContext context) {
    final reasons = link.matchReasons;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ScoreChip(
          theme: theme,
          label: 'Title'.tr,
          score: reasons['title_score'],
        ),
        _ScoreChip(
          theme: theme,
          label: 'Price'.tr,
          score: reasons['price_score'],
        ),
        _ScoreChip(
          theme: theme,
          label: 'Area'.tr,
          score: reasons['area_score'],
        ),
        _ScoreChip(
          theme: theme,
          label: 'Location'.tr,
          score: reasons['location_score'],
        ),
        _ScoreChip(
          theme: theme,
          label: 'Description'.tr,
          score: reasons['description_score'],
        ),
        _ScoreChip(
          theme: theme,
          label: 'Rooms'.tr,
          score: reasons['rooms_score'],
        ),
      ],
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.theme,
    required this.label,
    required this.score,
  });

  final ThemeColors theme;
  final String label;
  final dynamic score;

  @override
  Widget build(BuildContext context) {
    final value = _asDouble(score);
    final percent = (value * 100).round().clamp(0, 100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: theme.textFieldColor.withAlpha(120),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$label: $percent%',
        style: TextStyle(
          color: theme.textColor.withAlpha(200),
          fontSize: 12,
        ),
      ),
    );
  }

  double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _ComparisonBox extends StatelessWidget {
  const _ComparisonBox({
    required this.theme,
    required this.local,
    required this.nm,
  });

  final ThemeColors theme;
  final Map<String, dynamic> local;
  final Map<String, dynamic> nm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.textFieldColor.withAlpha(90),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.textColor.withAlpha(20)),
      ),
      child: Column(
        children: [
          _ComparisonRow(
            theme: theme,
            label: 'Price'.tr,
            local: local['price'],
            nm: nm['price'],
          ),
          _ComparisonRow(
            theme: theme,
            label: 'Area'.tr,
            local: local['area'],
            nm: nm['area'],
          ),
          _ComparisonRow(
            theme: theme,
            label: 'City'.tr,
            local: local['city'],
            nm: nm['city'],
          ),
          _ComparisonRow(
            theme: theme,
            label: 'District'.tr,
            local: local['district'],
            nm: nm['district'],
          ),
          _ComparisonRow(
            theme: theme,
            label: 'Rooms'.tr,
            local: local['rooms'],
            nm: nm['rooms'],
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.theme,
    required this.label,
    required this.local,
    required this.nm,
  });

  final ThemeColors theme;
  final String label;
  final dynamic local;
  final dynamic nm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: theme.textColor.withAlpha(150),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${local ?? '-'}',
              style: TextStyle(color: theme.textColor, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.compare_arrows,
            size: 16,
            color: theme.textColor.withAlpha(130),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${nm ?? '-'}',
              style: TextStyle(color: theme.textColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualLinkInput {
  const _ManualLinkInput({
    required this.url,
    required this.portalCode,
    required this.portalName,
  });

  final String url;
  final String portalCode;
  final String portalName;
}

class _ManualLinkDialog extends StatefulWidget {
  @override
  State<_ManualLinkDialog> createState() => _ManualLinkDialogState();
}

class _ManualLinkDialogState extends State<_ManualLinkDialog> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _portalCodeController = TextEditingController();
  final TextEditingController _portalNameController = TextEditingController();

  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    _portalCodeController.dispose();
    _portalNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final theme = ref.watch(themeColorsProvider);

        return AlertDialog(
          backgroundColor: theme.dashboardContainer,
          title: Text(
            'Add publication link manually'.tr,
            style: TextStyle(color: theme.textColor),
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: _urlController,
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    labelText: 'URL'.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _portalCodeController,
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    labelText: 'Portal code'.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _portalNameController,
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    labelText: 'Portal name'.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'.tr),
            ),
            ElevatedButton(
              style: elevatedButtonStyleRounded10,
              onPressed: _submit,
              child: Text('Add link'.tr),
            ),
          ],
        );
      },
    );
  }

  void _submit() {
    final url = _urlController.text.trim();

    if (url.isEmpty || Uri.tryParse(url)?.hasAbsolutePath != true) {
      setState(() {
        _error = 'Provide valid URL'.tr;
      });
      return;
    }

    Navigator.of(context).pop(
      _ManualLinkInput(
        url: url,
        portalCode: _portalCodeController.text.trim(),
        portalName: _portalNameController.text.trim(),
      ),
    );
  }
}