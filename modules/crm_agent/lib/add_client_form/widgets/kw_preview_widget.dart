import 'package:flutter/material.dart';
import 'package:crm_agent/crm_agent_urls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/theme/apptheme.dart';

// ---------------------------------------------------------------------------
// Local parser — runs on device, sensitive data never leaves the app
// ---------------------------------------------------------------------------

Map<String, dynamic> _parseKwHtml(String html) {
  // Strip HTML tags → plain text
  final text = html
      .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true, caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true, caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll(RegExp(r'&nbsp;'), ' ')
      .replaceAll(RegExp(r'&amp;'), '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  final result = <String, dynamic>{};

  // Kod pocztowy + miasto
  final zipMatch = RegExp(r'(\d{2}-\d{3})\s+([A-ZŁŚŻŹĆĄĘÓŃ][a-złśżźćąęóń\s\-]{2,40}?)(?=\s|,|$)').firstMatch(text);
  if (zipMatch != null) {
    result['zipcode'] = zipMatch.group(1);
    result['city'] = zipMatch.group(2)!.trim();
  }

  // Ulica
  final streetMatch = RegExp(
    r'(?:ul\.|ulica|al\.|aleja|pl\.|plac)\s+([A-ZŁŚŻŹĆĄĘÓŃ][^\n,<]{2,60}?)(?=\s*\d|\s*,|\s*\n|$)',
    caseSensitive: false,
  ).firstMatch(text);
  if (streetMatch != null) {
    result['street'] = streetMatch.group(0)!.trim().replaceAll(RegExp(r',\s*$'), '');
  }

  // Powierzchnia (m², m2)
  final areaMatch = RegExp(r'(\d[\d\s]*[,.]?\d*)\s*(?:m²|m2|mkw\.?)', caseSensitive: false).firstMatch(text);
  if (areaMatch != null) {
    final raw = areaMatch.group(1)!.replaceAll(' ', '').replaceAll(',', '.');
    final val = double.tryParse(raw);
    if (val != null) result['square_footage'] = val;
  }

  // Typ nieruchomości
  const estateKeywords = {
    'lokal mieszkalny': 'apartment',
    'mieszkanie': 'apartment',
    'dom jednorodzinny': 'house',
    'dom': 'house',
    'działka': 'plot',
    'grunt': 'plot',
    'lokal użytkowy': 'commercial',
    'garaż': 'garage',
  };
  final textLower = text.toLowerCase();
  for (final entry in estateKeywords.entries) {
    if (textLower.contains(entry.key)) {
      result['estate_type'] = entry.value;
      break;
    }
  }

  // Województwo
  final wojMatch = RegExp(r'woj(?:ewództwo)?\.?\s+([A-ZŁŚŻŹĆĄĘÓŃ][a-złśżźćąęóń\s\-]{2,30})', caseSensitive: false).firstMatch(text);
  if (wojMatch != null) {
    final woj = wojMatch.group(1)!.trim();
    result['state'] = woj[0].toUpperCase() + woj.substring(1).toLowerCase();
  }

  return result;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum KwPreviewStatus { idle, loading, done, error }

class KwPreviewState {
  final KwPreviewStatus status;
  final String? errorMessage;
  final Map<String, dynamic> structured;

  const KwPreviewState({
    this.status = KwPreviewStatus.idle,
    this.errorMessage,
    this.structured = const {},
  });

  KwPreviewState copyWith({
    KwPreviewStatus? status,
    String? errorMessage,
    Map<String, dynamic>? structured,
  }) =>
      KwPreviewState(
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
        structured: structured ?? this.structured,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class KwPreviewNotifier extends StateNotifier<KwPreviewState> {
  KwPreviewNotifier() : super(const KwPreviewState());

  Future<Map<String, dynamic>?> fetch(String kwNumber) async {
    state = state.copyWith(status: KwPreviewStatus.loading, errorMessage: null);
    try {
      final response = await ApiServices.post(
        CrmAgentUrls.agentKwPreview,
        hasToken: true,
        data: {'kw_number': kwNumber.trim().toUpperCase()},
      );
      if (response == null || (response.statusCode != 200 && response.statusCode != 201)) {
        final raw = response?.data;
        final msg = (raw is Map ? raw['detail'] : null) ?? 'Błąd serwera (${response?.statusCode})';
        state = state.copyWith(status: KwPreviewStatus.error, errorMessage: msg.toString());
        return null;
      }
      // Parse HTML locally — sensitive data stays on device
      final raw = response.data;
      final dataMap = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      final html = (dataMap['kw_html'] as String?) ?? '';
      final s = html.isNotEmpty ? _parseKwHtml(html) : <String, dynamic>{};
      state = state.copyWith(status: KwPreviewStatus.done, structured: s);
      return s;
    } catch (e) {
      state = state.copyWith(status: KwPreviewStatus.error, errorMessage: e.toString());
      return null;
    }
  }

  void reset() => state = const KwPreviewState();

  void setError(String msg) =>
      state = state.copyWith(status: KwPreviewStatus.error, errorMessage: msg);
}

final kwPreviewProvider =
    StateNotifierProvider.autoDispose<KwPreviewNotifier, KwPreviewState>(
  (_) => KwPreviewNotifier(),
);

// ---------------------------------------------------------------------------
// Callback signature – called with field-map when preview succeeds
// ---------------------------------------------------------------------------
typedef KwPreviewCallback = void Function(Map<String, dynamic> fields);

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class KwPreviewButton extends ConsumerWidget {
  final TextEditingController kwController;
  final KwPreviewCallback onAutofill;

  const KwPreviewButton({
    super.key,
    required this.kwController,
    required this.onAutofill,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(kwPreviewProvider);
    final theme = ref.watch(themeColorsProvider);
    final isLoading = st.status == KwPreviewStatus.loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.themeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: isLoading
                ? null
                : () async {
                    final kw = kwController.text.trim().toUpperCase();
                    if (kw.isEmpty) return;
                    final parts = kw.split('/');
                    if (parts.length != 3 || parts[0].length < 2 || parts[1].length != 8 || parts[2].length != 1) {
                      ref.read(kwPreviewProvider.notifier).setError('Nieprawidłowy format. Wymagany: XXXX/NNNNNNNN/C (np. WA1M/00123456/7)');
                      return;
                    }
                    final fields = await ref.read(kwPreviewProvider.notifier).fetch(kw);
                    if (fields != null && fields.isNotEmpty) {
                      onAutofill(fields);
                    }
                  },
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download_rounded, size: 18),
            label: Text(isLoading ? 'Pobieranie KW...' : 'Pobierz KW'),
          ),
        ),
        if (st.status == KwPreviewStatus.error)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              st.errorMessage ?? 'Błąd pobierania KW',
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
        if (st.status == KwPreviewStatus.done && st.structured.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Dane uzupełnione z KW: ${_summaryText(st.structured)}',
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _summaryText(Map<String, dynamic> fields) {
    final parts = <String>[];
    if (fields['city'] != null) parts.add(fields['city'].toString());
    if (fields['street'] != null) parts.add(fields['street'].toString());
    if (fields['square_footage'] != null) parts.add('${fields['square_footage']} m²');
    return parts.join(', ');
  }
}
