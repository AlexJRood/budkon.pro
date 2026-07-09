import 'package:flutter/material.dart';
import 'package:reports/reports_urls.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

class _ShareState {
  final bool loading;
  final String? shareUrl;
  final String? token;
  final DateTime? expiresAt;
  final int? viewCount;
  final String? error;

  const _ShareState({
    this.loading = false,
    this.shareUrl,
    this.token,
    this.expiresAt,
    this.viewCount,
    this.error,
  });

  _ShareState copyWith({
    bool? loading,
    String? shareUrl,
    String? token,
    DateTime? expiresAt,
    int? viewCount,
    String? error,
    bool clearError = false,
  }) {
    return _ShareState(
      loading: loading ?? this.loading,
      shareUrl: shareUrl ?? this.shareUrl,
      token: token ?? this.token,
      expiresAt: expiresAt ?? this.expiresAt,
      viewCount: viewCount ?? this.viewCount,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final _shareProvider =
    StateNotifierProvider.family<_ShareNotifier, _ShareState, int>(
  (ref, reportId) => _ShareNotifier(ref, reportId),
);

class _ShareNotifier extends StateNotifier<_ShareState> {
  final Ref _ref;
  final int _reportId;

  _ShareNotifier(this._ref, this._reportId) : super(const _ShareState());

  Future<void> createLink({int expiresDays = 30}) async {
    state = state.copyWith(loading: true, clearError: true);
    final response = await ApiServices.post(
      ReportsUrls.reportShare(_reportId),
      data: {'expires_days': expiresDays},
      hasToken: true,
      ref: _ref,
    );
    if (response == null || response.statusCode != 201) {
      state = state.copyWith(loading: false, error: 'share_link_error'.tr);
      return;
    }
    final data = response.data as Map<String, dynamic>;
    state = state.copyWith(
      loading: false,
      shareUrl: data['share_url'] as String?,
      token: data['token'] as String?,
      expiresAt: data['expires_at'] != null
          ? DateTime.tryParse(data['expires_at'] as String)
          : null,
    );
  }

  Future<void> revoke() async {
    state = state.copyWith(loading: true, clearError: true);
    await ApiServices.delete(
      ReportsUrls.reportShare(_reportId),
      hasToken: true,
    );
    state = const _ShareState();
  }
}

// ── Dialog ────────────────────────────────────────────────────────────────────

class ReportShareDialog extends ConsumerStatefulWidget {
  final int reportId;

  const ReportShareDialog({super.key, required this.reportId});

  static Future<void> show(BuildContext context, int reportId) {
    return showDialog(
      context: context,
      builder: (_) => ReportShareDialog(reportId: reportId),
    );
  }

  @override
  ConsumerState<ReportShareDialog> createState() => _ReportShareDialogState();
}

class _ReportShareDialogState extends ConsumerState<ReportShareDialog> {
  int _expireDays = 30;

  @override
  Widget build(BuildContext context) {
    final textColor = CustomColors.secondaryWidgetTextColor(context, ref);
    final bgColor   = CustomColors.secondaryWidgetColor(context, ref);
    final share     = ref.watch(_shareProvider(widget.reportId));
    final notifier  = ref.read(_shareProvider(widget.reportId).notifier);
    const accent    = Color(0xFF5FCDD9);

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Icon(Icons.share_outlined, color: accent, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'share_report_title'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textColor.withValues(alpha: 0.5)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (share.shareUrl == null && !share.loading) ...[
                // Expiry selector
                Text(
                  'share_expires_label'.tr,
                  style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [7, 14, 30, 90].map((days) {
                    final selected = _expireDays == days;
                    return ChoiceChip(
                      label: Text('$days ${'days'.tr}'),
                      selected: selected,
                      selectedColor: accent,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : textColor,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _expireDays = days),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => notifier.createLink(expiresDays: _expireDays),
                    icon: const Icon(Icons.link, size: 18),
                    label: Text('generate_share_link'.tr),
                    style: FilledButton.styleFrom(backgroundColor: accent),
                  ),
                ),
              ],

              if (share.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),

              if (share.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    share.error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),

              if (share.shareUrl != null) ...[
                // Link display
                Text(
                  'share_link_ready'.tr,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          share.shareUrl!,
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        color: accent,
                        tooltip: 'copy_link'.tr,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: share.shareUrl!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('link_copied'.tr)),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new, size: 18),
                        color: accent,
                        tooltip: 'open_link'.tr,
                        onPressed: () => launchUrl(
                          Uri.parse(share.shareUrl!),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (share.expiresAt != null)
                  Text(
                    '${'expires_on'.tr}: ${_formatDate(share.expiresAt!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => notifier.revoke(),
                        icon: const Icon(Icons.link_off, size: 16),
                        label: Text('revoke_link'.tr),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => notifier.createLink(expiresDays: _expireDays),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: Text('renew_link'.tr),
                        style: FilledButton.styleFrom(backgroundColor: accent),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}
