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

  const PipelineState({
    this.isUploading = false,
    this.status,
    this.uploadError,
  });

  bool get isActive => status != null && !status!.isDone && !status!.isFailed;
  bool get isDone   => status?.isDone ?? false;
  bool get isFailed => (status?.isFailed ?? false) || uploadError != null;

  PipelineState copyWith({bool? isUploading, PipelineStatusModel? status, String? uploadError}) =>
      PipelineState(
        isUploading: isUploading ?? this.isUploading,
        status:      status      ?? this.status,
        uploadError: uploadError ?? this.uploadError,
      );

  PipelineState withError(String err) =>
      PipelineState(isUploading: false, status: status, uploadError: err);
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class PipelineNotifier extends StateNotifier<PipelineState> {
  PipelineNotifier(this._api) : super(const PipelineState());

  final ProjektyApi _api;

  void updateFromLive(Map<String, dynamic> payload) {
    final incoming = PipelineStatusModel.fromLivePayload(payload);
    if (state.status == null || incoming.pipelineId != state.status!.pipelineId) return;
    state = state.copyWith(status: incoming);
  }

  Future<int?> startUpload(List<int> bytes, String name) async {
    state = const PipelineState(isUploading: true);
    try {
      final result = await _api.startPipeline(Uint8List.fromList(bytes), name);
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
