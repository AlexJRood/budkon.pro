class PipelineStartResult {
  final int pipelineId;
  final String status;

  const PipelineStartResult({required this.pipelineId, required this.status});

  factory PipelineStartResult.fromJson(Map<String, dynamic> j) =>
      PipelineStartResult(
        pipelineId: j['pipeline_id'] as int,
        status: j['status'] as String? ?? 'pending',
      );
}

class PipelineStatusModel {
  final int pipelineId;
  final String status;        // pending | running | done | failed
  final String currentStep;  // upload | parse | rooms | kosztorys | save
  final String? projektId;
  final String? error;

  const PipelineStatusModel({
    required this.pipelineId,
    required this.status,
    required this.currentStep,
    this.projektId,
    this.error,
  });

  bool get isDone    => status == 'done';
  bool get isFailed  => status == 'failed';
  bool get isPending => status == 'pending';
  bool get isRunning => status == 'running';

  factory PipelineStatusModel.fromJson(Map<String, dynamic> j) =>
      PipelineStatusModel(
        pipelineId:  j['pipeline_id'] as int? ?? 0,
        status:      j['status'] as String? ?? 'pending',
        currentStep: j['current_step'] as String? ?? 'upload',
        projektId:   j['projekt_id'] as String?,
        error:       j['error'] as String?,
      );

  factory PipelineStatusModel.fromLivePayload(Map<String, dynamic> p) =>
      PipelineStatusModel.fromJson(p);

  PipelineStatusModel copyWith({String? status, String? currentStep, String? projektId, String? error}) =>
      PipelineStatusModel(
        pipelineId:  pipelineId,
        status:      status ?? this.status,
        currentStep: currentStep ?? this.currentStep,
        projektId:   projektId ?? this.projektId,
        error:       error ?? this.error,
      );
}

/// Labels for each pipeline step shown in the UI.
const pipelineSteps = [
  ('upload',    'Przesyłanie pliku'),
  ('parse',     'Analiza dokumentu'),
  ('rooms',     'Rozpoznawanie pomieszczeń'),
  ('kosztorys', 'Generowanie kosztorysu'),
  ('save',      'Zapis projektu'),
];

int pipelineStepIndex(String step) {
  final idx = pipelineSteps.indexWhere((s) => s.$1 == step);
  return idx < 0 ? 0 : idx;
}
