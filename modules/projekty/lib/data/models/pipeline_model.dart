// ── PageEntry — accumulated per-page OCR result ───────────────────────────────

// Public so UI can enumerate all kinds for the reclassify dropdown
const kindLabels = {
  'rzut_parteru':           'Rzut parteru',
  'rzut_pietra':            'Rzut piętra',
  'rzut_poddasza':          'Rzut poddasza',
  'rzut_fundamentow':       'Rzut fundamentów',
  'rzut_garazu':            'Rzut garażu',
  'rzut_dachu':             'Rzut dachu',
  'przekroj':               'Przekrój',
  'elewacja':               'Elewacja',
  'opis_techniczny':        'Opis techniczny',
  'schemat_elektryczny':    'Schemat elektryczny',
  'schemat_sanitarny':      'Schemat sanitarny',
  'zestawienie_stolarki':   'Zestawienie stolarki',
  'zestawienie_materialow': 'Zestawienie materiałów',
  'warunki_przylaczenia':   'Warunki przyłączenia',
  'obliczenia_techniczne':  'Obliczenia techniczne',
  'uzgodnienie':               'Uzgodnienie / Decyzja',
  'pozwolenie_na_budowe':      'Pozwolenie na budowę',
  'uprawnienia_projektanta':   'Uprawnienia projektanta',
  'oswiadczenie':              'Oświadczenie',
  'projekt_zagospodarowania':  'Projekt zagospodarowania',
  'mapa_sytuacyjna':           'Mapa sytuacyjna',
  'opis_sanitarny':            'Opis sanitarny',
  'strona_tytulowa':           'Strona tytułowa',
  'strona_pusta':              'Strona pusta',
  'inny':                      'Pominięta',
};

class PageEntry {
  final int globalPage;
  final int docIdx;
  final int pageInDoc;
  final String? url;
  final String? ocrText;
  final String? kind;
  final bool isSkipped;
  final bool isProcessing;
  final Map<String, dynamic>? extractedData;

  const PageEntry({
    required this.globalPage,
    required this.docIdx,
    required this.pageInDoc,
    this.url,
    this.ocrText,
    this.kind,
    this.isSkipped = false,
    this.isProcessing = false,
    this.extractedData,
  });

  String get kindLabel => kindLabels[kind] ?? (isProcessing ? 'Przetwarzanie…' : kind ?? '');

  PageEntry copyWith({
    String? url,
    String? ocrText,
    String? kind,
    bool? isSkipped,
    bool? isProcessing,
    int? docIdx,
    Map<String, dynamic>? extractedData,
  }) => PageEntry(
    globalPage:    globalPage,
    docIdx:        docIdx        ?? this.docIdx,
    pageInDoc:     pageInDoc,
    url:           url           ?? this.url,
    ocrText:       ocrText       ?? this.ocrText,
    kind:          kind          ?? this.kind,
    isSkipped:     isSkipped     ?? this.isSkipped,
    isProcessing:  isProcessing  ?? this.isProcessing,
    extractedData: extractedData ?? this.extractedData,
  );
}

// ─────────────────────────────────────────────────────────────────────────────

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
  final String? progressMsg;
  final String? pagePreviewUrl;
  final double? mbDone;
  final String? ocrTextPreview;
  final List<String>? fileNames;

  const PipelineStatusModel({
    required this.pipelineId,
    required this.status,
    required this.currentStep,
    this.projektId,
    this.error,
    this.progressMsg,
    this.pagePreviewUrl,
    this.mbDone,
    this.ocrTextPreview,
    this.fileNames,
  });

  bool get isDone    => status == 'done';
  bool get isFailed  => status == 'failed';
  bool get isPending => status == 'pending';
  bool get isRunning => status == 'running';

  factory PipelineStatusModel.fromJson(Map<String, dynamic> j) =>
      PipelineStatusModel(
        pipelineId:      j['pipeline_id'] as int? ?? 0,
        status:          j['status'] as String? ?? 'pending',
        currentStep:     j['current_step'] as String? ?? 'upload',
        projektId:       j['projekt_id'] as String?,
        error:           j['error'] as String?,
        progressMsg:     j['progress_msg'] as String?,
        pagePreviewUrl:  j['page_preview_url'] as String?,
        mbDone:          (j['mb_done'] as num?)?.toDouble(),
        ocrTextPreview:  j['ocr_text_preview'] as String?,
        fileNames:       (j['file_names'] as List?)?.cast<String>(),
      );

  factory PipelineStatusModel.fromLivePayload(Map<String, dynamic> p) =>
      PipelineStatusModel.fromJson(p);

  PipelineStatusModel copyWith({
    String? status, String? currentStep, String? projektId,
    String? error, String? progressMsg, String? pagePreviewUrl,
    double? mbDone, String? ocrTextPreview, List<String>? fileNames,
  }) => PipelineStatusModel(
    pipelineId:      pipelineId,
    status:          status         ?? this.status,
    currentStep:     currentStep    ?? this.currentStep,
    projektId:       projektId      ?? this.projektId,
    error:           error          ?? this.error,
    progressMsg:     progressMsg    ?? this.progressMsg,
    pagePreviewUrl:  pagePreviewUrl ?? this.pagePreviewUrl,
    mbDone:          mbDone         ?? this.mbDone,
    ocrTextPreview:  ocrTextPreview ?? this.ocrTextPreview,
    fileNames:       fileNames      ?? this.fileNames,
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
