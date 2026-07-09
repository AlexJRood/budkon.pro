import 'package:crm/data/clients/client_provider.dart';
import 'package:reports/reports_urls.dart';
import 'package:crm_agent/models/clients_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:mail/send_mail/send_mail.dart';
import 'package:reports/reports/report_pdf_page/models/pdf_report_model.dart';

// ── color palette matching report_preview_widget.dart ──────────────────────
const _primaryText = Color(0xFF171A1F);
const _secondaryText = Color(0xFF667085);
const _lightText = Color(0xFF98A2B3);
const _accent = Color(0xFF5FCDD9);
const _accentStrong = Color(0xFF2FB8C6);
const _background = Color(0xFFF6F7F9);
const _card = Colors.white;
const _border = Color(0xFFE7ECF2);
const _green = Color(0xFF16A34A);

// ── entry point ─────────────────────────────────────────────────────────────

void showReportShareSheet(
  BuildContext context,
  WidgetRef ref, {
  required int reportId,
  required PdfReportModel reportData,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: _ReportShareSheet(
        reportId: reportId,
        reportData: reportData,
        ref: ref,
      ),
    ),
  );
}

// ── main sheet widget ────────────────────────────────────────────────────────

class _ReportShareSheet extends ConsumerStatefulWidget {
  final int reportId;
  final PdfReportModel reportData;
  final WidgetRef ref;

  const _ReportShareSheet({
    required this.reportId,
    required this.reportData,
    required this.ref,
  });

  @override
  ConsumerState<_ReportShareSheet> createState() => _ReportShareSheetState();
}

class _ReportShareSheetState extends ConsumerState<_ReportShareSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _linkCopied = false;

  String get _reportUrl =>
      ReportsUrls.singlePdfReport(widget.reportId);

  String get _reportAddress =>
      widget.reportData.report?.streetAddress ??
      widget.reportData.location?.address ??
      'report #${widget.reportId}';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _reportUrl));
    if (!mounted) return;
    setState(() => _linkCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _linkCopied = false);
    });
  }

  void _sendToClient(UserContactModel client) {
    if (client.email == null || client.email!.isEmpty) return;
    Navigator.of(context).pop();

    final clientName =
        [client.name, client.lastName].where((s) => s != null && s.isNotEmpty).join(' ');
    final subject = '${'share_report_email_subject'.tr}: $_reportAddress';
    final body = '${'share_report_email_body'.tr} $clientName,\n\n'
        '${'share_report_email_intro'.tr}\n\n'
        '$_reportAddress\n\n'
        '${'share_report_email_link'.tr}:\n$_reportUrl\n\n'
        '${'share_report_email_regards'.tr}';

    showEmailOverlay(
      context,
      widget.ref,
      leadId: client.id,
      initialSubject: subject,
      initialBody: body,
      initialEmails: [client.email!],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          const Divider(height: 1, color: _border),
          _buildLinkSection(),
          const Divider(height: 1, color: _border),
          _buildClientsSection(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: _border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 16, 16),
      child: Row(
        children: [
          const Icon(Icons.share_outlined, color: _accentStrong, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'share_report'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _primaryText,
                  ),
                ),
                Text(
                  _reportAddress,
                  style: const TextStyle(fontSize: 13, color: _secondaryText),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: _secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'share_report_link'.tr,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _secondaryText,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Text(
                    _reportUrl,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _lightText,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _copyLink,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _linkCopied
                        ? _green.withOpacity(0.12)
                        : _accentStrong.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _linkCopied
                          ? _green.withOpacity(0.3)
                          : _accentStrong.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _linkCopied
                            ? Icons.check_rounded
                            : Icons.copy_rounded,
                        size: 16,
                        color: _linkCopied ? _green : _accentStrong,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _linkCopied
                            ? 'copied'.tr
                            : 'copy_link'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _linkCopied ? _green : _accentStrong,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientsSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'share_report_send_to_client'.tr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _secondaryText,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  style: const TextStyle(fontSize: 14, color: _primaryText),
                  decoration: InputDecoration(
                    hintText: 'search_client'.tr,
                    hintStyle:
                        const TextStyle(fontSize: 14, color: _lightText),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: _lightText, size: 20),
                    filled: true,
                    fillColor: _background,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _accentStrong, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _ClientsList(
              searchQuery: _searchQuery,
              onSelect: _sendToClient,
            ),
          ),
        ],
      ),
    );
  }
}

// ── clients list ─────────────────────────────────────────────────────────────

class _ClientsList extends ConsumerWidget {
  final String searchQuery;
  final void Function(UserContactModel) onSelect;

  const _ClientsList({required this.searchQuery, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientProvider);

    return clientsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _accentStrong,
        ),
      ),
      error: (_, __) => Center(
        child: Text(
          'failed_to_load_clients'.tr,
          style: const TextStyle(fontSize: 13, color: _lightText),
        ),
      ),
      data: (clients) {
        final q = searchQuery.toLowerCase();
        final filtered = q.isEmpty
            ? clients
            : clients.where((c) {
                final fullName =
                    '${c.name} ${c.lastName ?? ''}'.toLowerCase();
                final email = (c.email ?? '').toLowerCase();
                return fullName.contains(q) || email.contains(q);
              }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              'no_clients_found'.tr,
              style: const TextStyle(fontSize: 13, color: _lightText),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: filtered.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: _border, indent: 56),
          itemBuilder: (_, i) => _ClientTile(
            client: filtered[i],
            onTap: () => onSelect(filtered[i]),
          ),
        );
      },
    );
  }
}

// ── single client tile ────────────────────────────────────────────────────────

class _ClientTile extends StatelessWidget {
  final UserContactModel client;
  final VoidCallback onTap;

  const _ClientTile({required this.client, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasEmail = client.email != null && client.email!.isNotEmpty;
    final fullName =
        [client.name, client.lastName].where((s) => s != null && s.isNotEmpty).join(' ');
    final initials = _initials(fullName);

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: _accent.withOpacity(0.15),
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _accentStrong,
          ),
        ),
      ),
      title: Text(
        fullName,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _primaryText,
        ),
      ),
      subtitle: Text(
        hasEmail ? client.email! : 'no_email'.tr,
        style: TextStyle(
          fontSize: 12,
          color: hasEmail ? _secondaryText : _lightText,
        ),
      ),
      trailing: hasEmail
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _accentStrong.withOpacity(0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mail_outline_rounded,
                      size: 14, color: _accentStrong),
                  const SizedBox(width: 5),
                  Text(
                    'send'.tr,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _accentStrong,
                    ),
                  ),
                ],
              ),
            )
          : null,
      onTap: hasEmail ? onTap : null,
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
