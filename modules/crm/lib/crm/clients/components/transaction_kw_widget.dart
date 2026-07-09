import 'dart:async';

import 'package:crm/crm/clients/components/transaction_document_pipeline_widget.dart';
import 'package:crm/crm_urls.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:core/user/user/user_provider.dart';

// ignore_for_file: deprecated_member_use

// ---------------------------------------------------------------------------
// Provider dla stanu KW konkretnej transakcji
// ---------------------------------------------------------------------------

class KwState {
  final String number;
  final String status; // idle | pending | downloading | ready | error
  final Map<String, dynamic>? document;

  const KwState({
    this.number = '',
    this.status = 'idle',
    this.document,
  });

  bool get isLoading => status == 'pending' || status == 'downloading';
  bool get isReady => status == 'ready';
  bool get hasError => status == 'error';

  KwState copyWith({String? number, String? status, Map<String, dynamic>? document}) => KwState(
        number: number ?? this.number,
        status: status ?? this.status,
        document: document ?? this.document,
      );
}

class KwNotifier extends StateNotifier<KwState> {
  final Ref ref;
  final int transactionId;
  Timer? _pollTimer;

  KwNotifier(this.ref, this.transactionId, AgentTransactionModel tx)
      : super(KwState(
          number: tx.landAndMortgageRegister ?? '',
          status: tx.kwDownloadStatus,
        )) {
    // Jeśli po wznowieniu sesji status to downloading — wznów polling
    if (state.isLoading) _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> trigger(String kwNumber) async {
    final trimmed = kwNumber.trim();
    if (trimmed.isEmpty) return;

    state = state.copyWith(number: trimmed, status: 'pending');

    final resp = await ApiServices.post(
      CrmUrls.agentKwTrigger(transactionId),
      ref: ref,
      hasToken: true,
      data: {'kw_number': trimmed},
    );

    if (resp == null || resp.statusCode != 202) {
      state = state.copyWith(status: 'error');
      return;
    }

    state = state.copyWith(status: 'downloading');
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _poll());
  }

  Future<void> _poll() async {
    final resp = await ApiServices.get(
      CrmUrls.agentKwStatus(transactionId),
      ref: ref,
      hasToken: true,
    );

    if (resp == null || resp.statusCode != 200) return;

    final data = resp.data as Map<String, dynamic>;
    final newStatus = data['kw_download_status'] as String? ?? state.status;
    final doc = data['kw_document'] as Map<String, dynamic>?;

    state = state.copyWith(status: newStatus, document: doc ?? state.document);

    if (!state.isLoading) {
      _pollTimer?.cancel();

      // Auto-odhacz "Odpis z KW" w pipeline dokumentów
      if (state.isReady) {
        final userId = ref.read(userProvider).value?.idInt ?? 0;
        if (userId != 0) {
          final pipelineNotifier = ref.read(
            documentPipelineProvider(transactionId).notifier,
          );
          await pipelineNotifier.markKwDone(userId);
        }
      }
    }
  }
}

final kwProvider = StateNotifierProvider.family<KwNotifier, KwState, (int, AgentTransactionModel)>(
  (ref, args) => KwNotifier(ref, args.$1, args.$2),
);

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class TransactionKwWidget extends ConsumerStatefulWidget {
  final AgentTransactionModel transaction;

  const TransactionKwWidget({super.key, required this.transaction});

  @override
  ConsumerState<TransactionKwWidget> createState() => _TransactionKwWidgetState();
}

class _TransactionKwWidgetState extends ConsumerState<TransactionKwWidget> {
  late final TextEditingController _wydzialCtrl;
  late final TextEditingController _numerCtrl;
  late final TextEditingController _cyfraCtrl;
  final _numerFocus = FocusNode();
  final _cyfraFocus = FocusNode();

  String get _fullKwNumber =>
      '${_wydzialCtrl.text}/${_numerCtrl.text}/${_cyfraCtrl.text}';

  @override
  void initState() {
    super.initState();
    final raw = widget.transaction.landAndMortgageRegister ?? '';
    final parts = raw.split('/');
    _wydzialCtrl = TextEditingController(text: parts.isNotEmpty ? parts[0] : '');
    _numerCtrl   = TextEditingController(text: parts.length > 1 ? parts[1] : '');
    _cyfraCtrl   = TextEditingController(text: parts.length > 2 ? parts[2] : '');
  }

  @override
  void dispose() {
    _wydzialCtrl.dispose();
    _numerCtrl.dispose();
    _cyfraCtrl.dispose();
    _numerFocus.dispose();
    _cyfraFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final kw = ref.watch(kwProvider((widget.transaction.id, widget.transaction)));
    final userId = ref.watch(userProvider).value?.idInt ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.menu_book_outlined, size: 18, color: theme.themeColor),
              const SizedBox(width: 8),
              Text(
                'Księga Wieczysta',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              const Spacer(),
              if (kw.isReady)
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: Colors.green.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Pobrano',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade600),
                    ),
                  ],
                ),
              if (kw.hasError)
                Row(
                  children: [
                    Icon(Icons.error_outline_rounded, size: 14, color: Colors.red.shade400),
                    const SizedBox(width: 4),
                    Text(
                      'Błąd',
                      style: TextStyle(fontSize: 12, color: Colors.red.shade400),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 3-częściowy input KW
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Wydział
              Expanded(
                flex: 3,
                child: _KwField(
                  controller: _wydzialCtrl,
                  label: 'Wydział',
                  hint: 'WA1M',
                  enabled: !kw.isLoading,
                  theme: theme,
                  maxLength: 8,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    _UpperCaseFormatter(),
                  ],
                  onChanged: (v) {
                    if (v.contains('/')) {
                      _wydzialCtrl.text = v.replaceAll('/', '');
                      _numerFocus.requestFocus();
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(' / ', style: TextStyle(color: theme.textColor.withAlpha(120), fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              // Numer
              Expanded(
                flex: 4,
                child: _KwField(
                  controller: _numerCtrl,
                  label: 'Numer',
                  hint: '00123456',
                  enabled: !kw.isLoading,
                  focusNode: _numerFocus,
                  theme: theme,
                  maxLength: 8,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) {
                    if (v.contains('/') || v.length == 8) {
                      _numerCtrl.text = v.replaceAll('/', '');
                      _cyfraFocus.requestFocus();
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(' / ', style: TextStyle(color: theme.textColor.withAlpha(120), fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              // Cyfra kontrolna
              Expanded(
                flex: 2,
                child: _KwField(
                  controller: _cyfraCtrl,
                  label: 'Cyfra',
                  hint: '7',
                  enabled: !kw.isLoading,
                  focusNode: _cyfraFocus,
                  theme: theme,
                  maxLength: 1,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: _TriggerButton(
                  isLoading: kw.isLoading,
                  onPressed: userId == 0
                      ? null
                      : () {
                          ref
                              .read(kwProvider((widget.transaction.id, widget.transaction)).notifier)
                              .trigger(_fullKwNumber);
                        },
                  theme: theme,
                ),
              ),
            ],
          ),

          // Status downloading
          if (kw.isLoading) ...[
            const SizedBox(height: 12),
            _LoadingIndicator(theme: theme),
          ],

          // Dokument gotowy
          if (kw.isReady && kw.document != null) ...[
            const SizedBox(height: 12),
            _KwDocumentCard(document: kw.document!, theme: theme),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Przycisk triggerowania
// ---------------------------------------------------------------------------

class _TriggerButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final ThemeColors theme;

  const _TriggerButton({
    required this.isLoading,
    required this.onPressed,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.themeColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Pobierz KW', style: TextStyle(fontSize: 13)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wskaźnik pobierania
// ---------------------------------------------------------------------------

class _LoadingIndicator extends StatelessWidget {
  final ThemeColors theme;

  const _LoadingIndicator({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.themeColor,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Pobieranie Księgi Wieczystej z EKW...',
            style: TextStyle(fontSize: 12, color: theme.themeColor),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Karta pobranego dokumentu
// ---------------------------------------------------------------------------

class _KwDocumentCard extends StatelessWidget {
  final Map<String, dynamic> document;
  final ThemeColors theme;

  const _KwDocumentCard({required this.document, required this.theme});

  @override
  Widget build(BuildContext context) {
    final name = document['name'] as String? ?? 'Księga Wieczysta';
    final url = document['url'] as String? ?? '';
    final htmlContent = document['content_html'] as String? ?? '';
    final hasUrl = url.isNotEmpty;
    final hasHtml = htmlContent.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, size: 16, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
          if (hasUrl || hasHtml) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (hasUrl)
                  _ActionChip(
                    icon: Icons.open_in_new_rounded,
                    label: 'Otwórz',
                    onTap: () => launchUrl(Uri.parse(url)),
                    color: Colors.green.shade700,
                  ),
                if (hasUrl && hasHtml) const SizedBox(width: 8),
                if (hasHtml)
                  _ActionChip(
                    icon: Icons.visibility_outlined,
                    label: 'Podgląd',
                    onTap: () => _showHtmlPreview(context, name, htmlContent),
                    color: Colors.green.shade700,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showHtmlPreview(BuildContext context, String title, String html) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _KwHtmlPreviewSheet(title: title, html: html),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HTML preview bottom sheet
// ---------------------------------------------------------------------------

class _KwHtmlPreviewSheet extends StatelessWidget {
  final String title;
  final String html;

  const _KwHtmlPreviewSheet({required this.title, required this.html});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined, size: 18, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content — scrollable text (flutter_html lub SelectableText)
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  _stripHtmlTags(html),
                  style: const TextStyle(fontSize: 13, height: 1.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Proste usunięcie tagów HTML dla czytelnego podglądu
  String _stripHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

// ---------------------------------------------------------------------------
// Formatter dla numeru KW
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Reusable pole KW z etykietą
// ---------------------------------------------------------------------------

class _KwField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool enabled;
  final FocusNode? focusNode;
  final ThemeColors theme;
  final int maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  const _KwField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.enabled,
    required this.theme,
    required this.maxLength,
    this.focusNode,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: theme.dashboardBoarder),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.textColor.withAlpha(140),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          maxLength: maxLength,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: TextStyle(fontSize: 13, color: theme.textColor, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: theme.textColor.withAlpha(70), fontSize: 13),
            counterText: '',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            filled: true,
            fillColor: theme.textFieldColor,
            border: border,
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.themeColor, width: 1.5),
            ),
            disabledBorder: border,
          ),
        ),
      ],
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class _KwNumberFormatter extends TextInputFormatter {
  // Przepuszcza tylko litery, cyfry i /
  // Nie wymusza formatu — tylko czyści niedozwolone znaki
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9/]'), '');
    return newValue.copyWith(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
  }
}
