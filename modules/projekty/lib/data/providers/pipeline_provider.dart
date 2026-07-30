import 'dart:typed_data';
import 'package:core/platform/live/live.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pipeline_model.dart';
import '../services/projekty_api.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class PipelineState {
  final bool isUploading;
  final PipelineStatusModel? status;
  final String? uploadError;
  final List<PageEntry> pages;

  const PipelineState({
    this.isUploading = false,
    this.status,
    this.uploadError,
    this.pages = const [],
  });

  bool get isActive => status != null && !status!.isDone && !status!.isFailed;
  bool get isDone   => status?.isDone ?? false;
  bool get isFailed => (status?.isFailed ?? false) || uploadError != null;

  PipelineState copyWith({
    bool? isUploading,
    PipelineStatusModel? status,
    String? uploadError,
    List<PageEntry>? pages,
  }) => PipelineState(
    isUploading: isUploading ?? this.isUploading,
    status:      status      ?? this.status,
    uploadError: uploadError ?? this.uploadError,
    pages:       pages       ?? this.pages,
  );

  PipelineState withError(String err) =>
      PipelineState(isUploading: false, status: status, uploadError: err, pages: pages);
}

// ── Page accumulation ─────────────────────────────────────────────────────────

final _rGlobal  = RegExp(r'\[(\d+)/\d+\]');
final _rDoc     = RegExp(r'\[doc (\d+)/\d+\]');
final _rPageInDoc = RegExp(r's\.(\d+)[:\s]');
final _rKind    = RegExp(r'ekstrakcja \((\w+)\)');
final _rOcrDone = RegExp(r's\.(\d+): OCR done');

List<PageEntry> _accumulateFromLive(
  List<PageEntry> existing,
  PipelineStatusModel st,
) {
  final msg = st.progressMsg;
  if (msg == null) return existing;

  final globalM = _rGlobal.firstMatch(msg);
  if (globalM == null) return existing;
  final globalPage = int.parse(globalM.group(1)!);

  final docM      = _rDoc.firstMatch(msg);
  final docIdx    = docM != null ? int.parse(docM.group(1)!) : null;
  final pidM      = _rPageInDoc.firstMatch(msg);
  final pageInDoc = pidM != null ? int.parse(pidM.group(1)!) : globalPage;

  final kindM     = _rKind.firstMatch(msg);
  final kind      = kindM?.group(1);
  final isSkipped = msg.contains('pominieta (inny)');
  final hasUrl    = st.pagePreviewUrl != null && st.pagePreviewUrl!.isNotEmpty;
  final isOcrDone = _rOcrDone.hasMatch(msg) || hasUrl;

  // Wiadomości Fazy 1 ("OCR N/M stron gotowe") niosą globalPage zamrożony na
  // wartości sprzed rozpoczęcia tej fazy (patrz _parseOcrSubProgress) oraz
  // rotujący, nie-strono-specyficzny podgląd tekstu/miniaturki bieżąco
  // przetwarzanej strony. Jeśli ten zamrożony globalPage trafi w numer już
  // istniejącego, dawno ukończonego wpisu, zwykły update nadpisałby JEGO
  // ocrText/url tym rotującym podglądem — wygląda to jak pomieszanie treści
  // między stronami/dokumentami. W Fazie 1 aktualizujemy więc tylko docIdx,
  // nigdy ocrText/url istniejącego wpisu.
  final isPhase1 = RegExp(r'OCR \d+/\d+ stron gotowe').hasMatch(msg);

  final idx = existing.indexWhere((p) => p.globalPage == globalPage);

  if (idx >= 0) {
    final old = existing[idx];
    final updated = old.copyWith(
      docIdx:       docIdx ?? old.docIdx,
      url:          isPhase1 ? old.url : ((hasUrl ? st.pagePreviewUrl : null) ?? old.url),
      ocrText:      isPhase1 ? old.ocrText
                    : ((st.ocrTextPreview?.isNotEmpty == true ? st.ocrTextPreview : null) ?? old.ocrText),
      kind:         kind ?? (isSkipped ? 'inny' : old.kind),
      isSkipped:    isSkipped ? true : old.isSkipped,
      isProcessing: !isSkipped && kind == null && isOcrDone,
    );
    return [...existing.sublist(0, idx), updated, ...existing.sublist(idx + 1)];
  }

  if (!isOcrDone && !isSkipped && kind == null) return existing;

  return [
    ...existing,
    PageEntry(
      globalPage:   globalPage,
      docIdx:       docIdx ?? 1,
      pageInDoc:    pageInDoc,
      url:          hasUrl ? st.pagePreviewUrl : null,
      ocrText:      st.ocrTextPreview?.isNotEmpty == true ? st.ocrTextPreview : null,
      kind:         kind ?? (isSkipped ? 'inny' : null),
      isSkipped:    isSkipped,
      isProcessing: !isSkipped && kind == null,
    ),
  ];
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class PipelineNotifier extends StateNotifier<PipelineState> {
  PipelineNotifier(this._api) : super(const PipelineState());

  final ProjektyApi _api;

  void updateFromLive(Map<String, dynamic> payload) {
    final incoming = PipelineStatusModel.fromLivePayload(payload);
    if (state.status != null && incoming.pipelineId != state.status!.pipelineId) return;

    // page_extracted — wyekstraktowane dane JSON dla konkretnej strony
    final pe = payload['page_extracted'];
    if (pe != null && pe is Map<String, dynamic>) {
      final globalPage = pe['page_global'] as int?;
      final data = pe['data'];
      if (globalPage != null && data is Map<String, dynamic> && data.isNotEmpty) {
        final updated = state.pages.map((p) {
          if (p.globalPage == globalPage) {
            return p.copyWith(extractedData: data);
          }
          return p;
        }).toList();
        state = state.copyWith(status: incoming, pages: updated);
        return;
      }
    }

    final pages = _accumulateFromLive(state.pages, incoming);
    state = state.copyWith(status: incoming, pages: pages);
  }

  Future<int?> startUpload(List<(Uint8List, String)> files) async {
    state = const PipelineState(isUploading: true);
    try {
      final result = await _api.startPipeline(files);
      final initStatus = PipelineStatusModel(
        pipelineId:  result.pipelineId,
        status:      result.status,
        currentStep: 'upload',
      );
      state = PipelineState(isUploading: false, status: initStatus);
      return result.pipelineId;
    } catch (e) {
      state = state.withError(e.toString());
      return null;
    }
  }

  Future<void> pollStatus() async {
    final id = state.status?.pipelineId;
    if (id == null) return;
    try {
      final s = await _api.fetchPipelineStatus(id);
      state = state.copyWith(status: s);
    } catch (_) {}
  }

  void reset() => state = const PipelineState();
}

final pipelineProvider =
    StateNotifierProvider.autoDispose<PipelineNotifier, PipelineState>(
  (ref) => PipelineNotifier(ref.read(projektyApiProvider)),
);

// ── Live subscription ─────────────────────────────────────────────────────────

/// Watch this in the upload screen to receive WS pipeline signals.
final pipelineLiveProvider = Provider.autoDispose<void>((ref) {
  const topic = 'projekty:pipeline';
  liveSubscribe(ref, topic);
  liveOn(ref, topic, (sig) {
    if (sig.payload == null) return;
    ref.read(pipelineProvider.notifier).updateFromLive(sig.payload!);
  });
});
