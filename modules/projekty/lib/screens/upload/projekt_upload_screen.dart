import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/platform/navigation_service.dart';
import '../../data/models/pipeline_model.dart';
import '../../data/providers/pipeline_provider.dart';
import '../../data/services/projekty_api.dart';
import '../../ui/pipeline_bubble.dart';

class ProjektUploadScreen extends ConsumerStatefulWidget {
  const ProjektUploadScreen({super.key});

  @override
  ConsumerState<ProjektUploadScreen> createState() => _ProjektUploadScreenState();
}

class _ProjektUploadScreenState extends ConsumerState<ProjektUploadScreen> {
  final _sideMenuKey = GlobalKey<SideMenuState>();
  final List<PlatformFile> _pickedFiles = [];
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final state = ref.watch(pipelineProvider);

    // WS live subscription
    ref.watch(pipelineLiveProvider);

    // Navigate on success
    ref.listen(pipelineProvider, (_, next) {
      if (!next.isDone) return;
      final projektId = next.status?.projektId;
      if (projektId != null && mounted) {
        ref.read(navigationService).pushNamedScreen('/projekty/$projektId');
      }
    });

    final isProcessing = state.isUploading || state.isActive;

    return BarManager(
      sideMenuKey: _sideMenuKey,
      appModule: AppModule.budkon,
      childPc: Column(
        children: [
          _Header(
            theme: theme,
            canMinimize: isProcessing,
            onMinimize: () {
              showPipelineBubble(context, ref);
              Navigator.of(context).maybePop();
            },
          ),
          Expanded(
            child: isProcessing || state.isDone || state.isFailed
                ? _PipelineView(state: state, theme: theme,
                    onReset: () => ref.read(pipelineProvider.notifier).reset())
                : _PickerBody(
                    theme: theme,
                    pickedFiles: _pickedFiles,
                    isDragOver: _isDragOver,
                    onDragEnter: () => setState(() => _isDragOver = true),
                    onDragExit:  () => setState(() => _isDragOver = false),
                    onDragDone:  _onDragDone,
                    onPick:      _pickFiles,
                    onRemove:    (i) => setState(() => _pickedFiles.removeAt(i)),
                    onStart:     _startPipeline,
                  ),
          ),
        ],
      ),
    );
  }

  void _onDragDone(DropDoneDetails details) {
    setState(() => _isDragOver = false);
    const allowed = ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'];
    final files = details.files
        .where((f) => allowed.contains(f.name.split('.').last.toLowerCase()))
        .map((f) => PlatformFile(name: f.name, path: f.path, size: 0))
        .toList();
    if (files.isNotEmpty) setState(() => _pickedFiles.addAll(files));
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      allowMultiple: true,
      withData: kIsWeb,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFiles.addAll(result.files));
    }
  }

  Future<void> _startPipeline() async {
    if (_pickedFiles.isEmpty) return;

    // Read bytes for all picked files.
    final files = <(Uint8List, String)>[];
    for (final file in _pickedFiles) {
      List<int>? bytes = file.bytes;
      if (bytes == null && file.path != null && !kIsWeb) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes != null) files.add((Uint8List.fromList(bytes), file.name));
    }

    if (files.isEmpty) return;
    await ref.read(pipelineProvider.notifier).startUpload(files);
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.theme,
    this.canMinimize = false,
    this.onMinimize,
  });
  final ThemeColors theme;
  final bool canMinimize;
  final VoidCallback? onMinimize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.bordercolor.withAlpha(40)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.architecture, color: theme.themeColor, size: 22),
          const SizedBox(width: 10),
          Text(
            'Wczytaj projekt architektoniczny',
            style: TextStyle(
              color: theme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (canMinimize)
            TextButton.icon(
              icon: Icon(Icons.minimize_rounded,
                  size: 16, color: theme.themeColor),
              label: Text('Minimalizuj',
                  style: TextStyle(fontSize: 12, color: theme.themeColor)),
              onPressed: onMinimize,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            )
          else
            Text(
              'PDF, DOC, DOCX, JPG, PNG',
              style: TextStyle(
                  color: theme.textColor.withAlpha(120), fontSize: 12),
            ),
        ],
      ),
    );
  }
}

// ── Picker body (idle state) ──────────────────────────────────────────────────

class _PickerBody extends StatelessWidget {
  const _PickerBody({
    required this.theme,
    required this.pickedFiles,
    required this.isDragOver,
    required this.onDragEnter,
    required this.onDragExit,
    required this.onDragDone,
    required this.onPick,
    required this.onRemove,
    required this.onStart,
  });

  final ThemeColors theme;
  final List<PlatformFile> pickedFiles;
  final bool isDragOver;
  final VoidCallback onDragEnter;
  final VoidCallback onDragExit;
  final void Function(DropDoneDetails) onDragDone;
  final VoidCallback onPick;
  final void Function(int) onRemove;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DropZone(
            theme: theme,
            hasFiles: pickedFiles.isNotEmpty,
            isDragOver: isDragOver,
            onDragEnter: onDragEnter,
            onDragExit: onDragExit,
            onDragDone: onDragDone,
            onTap: onPick,
          ),
          if (pickedFiles.isNotEmpty) ...[
            const SizedBox(height: 24),
            _FileList(files: pickedFiles, theme: theme, onRemove: onRemove),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Analizuj projekt'),
              onPressed: onStart,
              style: FilledButton.styleFrom(
                backgroundColor: theme.themeColor,
                foregroundColor: theme.buttonTextColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const SizedBox(height: 32),
          _InfoCards(theme: theme),
        ],
      ),
    );
  }
}

// ── Drop zone ─────────────────────────────────────────────────────────────────

class _DropZone extends StatelessWidget {
  const _DropZone({
    required this.theme,
    required this.hasFiles,
    required this.isDragOver,
    required this.onDragEnter,
    required this.onDragExit,
    required this.onDragDone,
    required this.onTap,
  });

  final ThemeColors theme;
  final bool hasFiles, isDragOver;
  final VoidCallback onDragEnter, onDragExit, onTap;
  final void Function(DropDoneDetails) onDragDone;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => onDragEnter(),
      onDragExited:  (_) => onDragExit(),
      onDragDone: onDragDone,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
          decoration: BoxDecoration(
            color: isDragOver
                ? theme.themeColor.withAlpha(30)
                : theme.userTile.withAlpha(80),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDragOver ? theme.themeColor : theme.bordercolor.withAlpha(80),
              width: isDragOver ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasFiles
                    ? Icons.check_circle_outline
                    : Icons.upload_file_outlined,
                size: 56,
                color: hasFiles
                    ? theme.themeColor
                    : theme.textColor.withAlpha(100),
              ),
              const SizedBox(height: 16),
              Text(
                hasFiles ? 'Dodaj kolejne pliki' : 'Przeciągnij pliki lub kliknij',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'PDF, DOC, DOCX, JPG, PNG — możesz dodać wiele plików naraz',
                style: TextStyle(
                    color: theme.textColor.withAlpha(120), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── File list ─────────────────────────────────────────────────────────────────

class _FileList extends StatelessWidget {
  const _FileList({required this.files, required this.theme, required this.onRemove});
  final List<PlatformFile> files;
  final ThemeColors theme;
  final void Function(int) onRemove;

  static IconData _icon(String name) {
    return switch (name.split('.').last.toLowerCase()) {
      'pdf'                    => Icons.picture_as_pdf,
      'jpg' || 'jpeg' || 'png' => Icons.image_outlined,
      'doc' || 'docx'          => Icons.description_outlined,
      _                        => Icons.insert_drive_file_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: files.asMap().entries.map((e) {
        final i = e.key;
        final f = e.value;
        final sizeKb = f.size > 0 ? '${(f.size / 1024).toStringAsFixed(0)} KB' : '';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.userTile,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.bordercolor.withAlpha(60)),
          ),
          child: Row(
            children: [
              Icon(_icon(f.name), color: theme.themeColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.name,
                        style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis),
                    if (sizeKb.isNotEmpty)
                      Text(sizeKb,
                          style: TextStyle(
                              color: theme.textColor.withAlpha(120),
                              fontSize: 11)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close,
                    color: theme.textColor.withAlpha(120), size: 18),
                onPressed: () => onRemove(i),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Info cards ────────────────────────────────────────────────────────────────

class _InfoCards extends StatelessWidget {
  const _InfoCards({required this.theme});
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.search,    'Rozpoznaje pomieszczenia', 'Nazwy, powierzchnie i układ'),
      (Icons.calculate, 'Generuje kosztorys',       'Szacunkowe pozycje i ceny'),
      (Icons.map,       'Rysuje floor plan',        'Interaktywny rzut kondygnacji'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.map((e) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _InfoCard(icon: e.$1, title: e.$2, desc: e.$3, theme: theme),
        ),
      )).toList(),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.desc, required this.theme});
  final IconData icon;
  final String title, desc;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.userTile.withAlpha(60),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.bordercolor.withAlpha(40)),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.themeColor, size: 28),
          const SizedBox(height: 8),
          Text(title,
              style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(desc,
              style: TextStyle(
                  color: theme.textColor.withAlpha(120), fontSize: 11),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Pipeline progress view ────────────────────────────────────────────────────

/// Parsuje [X/Y] z progressMsg (licznik stron). Zwraca (current, total) lub null.
({int current, int total})? _parsePageProgress(String? msg) {
  if (msg == null) return null;
  // ignoruj [doc X/Y] — szukamy tylko głównego licznika stron
  final clean = msg.replaceAll(RegExp(r'\[doc \d+/\d+\]'), '');
  final m = RegExp(r'\[(\d+)/(\d+)\]').firstMatch(clean);
  if (m == null) return null;
  return (current: int.parse(m.group(1)!), total: int.parse(m.group(2)!));
}

/// Parsuje "OCR N/M stron gotowe" — podpostęp równoległego OCR bieżącego
/// dokumentu (Faza 1). Główny licznik [X/Y] stoi w miejscu przez cały czas
/// trwania tej fazy (rusza dopiero w Fazie 2, klasyfikacja/ekstrakcja), więc
/// bez tego UI wygląda na zawieszone mimo że backend cały czas pracuje.
({int current, int total})? _parseOcrSubProgress(String? msg) {
  if (msg == null) return null;
  final m = RegExp(r'OCR (\d+)/(\d+) stron gotowe').firstMatch(msg);
  if (m == null) return null;
  return (current: int.parse(m.group(1)!), total: int.parse(m.group(2)!));
}

/// Parsuje [doc X/Y] z progressMsg. Zwraca (current, total) lub null.
({int current, int total})? _parseDocProgress(String? msg) {
  if (msg == null) return null;
  final m = RegExp(r'\[doc (\d+)/(\d+)\]').firstMatch(msg);
  if (m == null) return null;
  return (current: int.parse(m.group(1)!), total: int.parse(m.group(2)!));
}

void _showFullscreenImage(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 6,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Center(
                child: Icon(Icons.broken_image_outlined,
                    color: Colors.white38, size: 64),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 28),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Zamknij',
            ),
          ),
        ],
      ),
    ),
  );
}

class _PipelineView extends StatelessWidget {
  const _PipelineView({
    required this.state,
    required this.theme,
    required this.onReset,
  });

  final PipelineState state;
  final ThemeColors theme;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final st = state.status;
    final currentIdx = st != null ? pipelineStepIndex(st.currentStep) : 0;
    final failed = state.isFailed;
    final pageProgress = _parsePageProgress(st?.progressMsg);
    final ocrSubProgress = _parseOcrSubProgress(st?.progressMsg);

    const aiPerPage = 4;
    final pagesTotal   = pageProgress?.total;
    final pagesCurrent = pageProgress?.current;
    final aiTotal = pagesTotal != null ? pagesTotal * aiPerPage : null;
    final aiDone  = pagesCurrent != null
        ? (pagesCurrent.clamp(1, pagesTotal ?? 1) - 1) * aiPerPage
        : null;
    final mbDone = st?.mbDone;
    final docs   = _parseDocProgress(st?.progressMsg);

    final progressPanel = _ProgressPanel(
      state:        state,
      theme:        theme,
      currentIdx:   currentIdx,
      failed:       failed,
      pagesTotal:   pagesTotal,
      pagesCurrent: pagesCurrent,
      ocrSubProgress: ocrSubProgress,
      aiTotal:      aiTotal,
      aiDone:       aiDone,
      mbDone:       mbDone,
      docs:         docs,
      onReset:      onReset,
    );

    final accPages = state.pages;

    if (accPages.isNotEmpty) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: _DocBrowser(
              pages:         accPages,
              fileNames:     st?.fileNames,
              currentDocIdx: docs?.current ?? 1,
              theme:         theme,
              pipelineId:    st?.pipelineId ?? 0,
            ),
          ),
          Container(width: 1, color: theme.bordercolor.withAlpha(40)),
          SizedBox(
            width: 300,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: progressPanel,
            ),
          ),
        ],
      );
    }

    final pagePreviewUrl = st?.pagePreviewUrl;
    final ocrText        = st?.ocrTextPreview;
    final hasPreview     = !state.isDone && !failed && pagePreviewUrl != null;

    if (hasPreview) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 340,
            child: _PagePreviewColumn(
              url:          pagePreviewUrl,
              ocrText:      ocrText,
              theme:        theme,
              onFullscreen: () => _showFullscreenImage(context, pagePreviewUrl),
            ),
          ),
          Container(width: 1, color: theme.bordercolor.withAlpha(40)),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: progressPanel,
              ),
            ),
          ),
        ],
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(48),
        child: progressPanel,
      ),
    );
  }
}

// ── Page preview column ───────────────────────────────────────────────────────

class _PagePreviewColumn extends StatelessWidget {
  const _PagePreviewColumn({
    required this.url,
    required this.ocrText,
    required this.theme,
    required this.onFullscreen,
  });

  final String url;
  final String? ocrText;
  final ThemeColors theme;
  final VoidCallback onFullscreen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onFullscreen,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: theme.textColor.withAlpha(40), size: 48),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Tooltip(
                    message: 'Pełny ekran',
                    child: Material(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: onFullscreen,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(7),
                          child: Icon(Icons.fullscreen,
                              color: Colors.white70, size: 20),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (ocrText != null) ...[
          Container(height: 1, color: theme.bordercolor.withAlpha(40)),
          SizedBox(
            height: 180,
            child: Scrollbar(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Text(
                  ocrText!,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(130),
                    fontSize: 10,
                    fontFamily: 'monospace',
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Progress panel ────────────────────────────────────────────────────────────

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({
    required this.state,
    required this.theme,
    required this.currentIdx,
    required this.failed,
    required this.pagesTotal,
    required this.pagesCurrent,
    this.ocrSubProgress,
    required this.aiTotal,
    required this.aiDone,
    required this.mbDone,
    required this.docs,
    required this.onReset,
  });

  final PipelineState state;
  final ThemeColors theme;
  final int currentIdx;
  final bool failed;
  final int? pagesTotal, pagesCurrent, aiTotal, aiDone;
  final ({int current, int total})? ocrSubProgress;
  final double? mbDone;
  final ({int current, int total})? docs;
  final VoidCallback onReset;


  @override
  Widget build(BuildContext context) {
    final st = state.status;

    final fileNames = state.status?.fileNames;
    final currentDocIdx = (docs?.current ?? 1) - 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Lista dokumentów (kolejka)
        if (fileNames != null && fileNames.isNotEmpty && !state.isDone) ...[
          _DocQueuePanel(
            fileNames: fileNames,
            currentDocIdx: failed ? -1 : currentDocIdx,
            failed: failed,
            theme: theme,
          ),
          const SizedBox(height: 24),
        ],

        // Spinner / ikona
        if (state.isDone)
          Icon(Icons.check_circle_rounded, color: Colors.green.shade400, size: 64)
        else if (failed)
          Icon(Icons.error_rounded, color: Colors.red.shade400, size: 64)
        else
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(strokeWidth: 3, color: theme.themeColor),
          ),
        const SizedBox(height: 20),

        Text(
          state.isUploading
              ? 'Przesyłanie pliku…'
              : state.isDone
                  ? 'Projekt wczytany!'
                  : failed
                      ? 'Błąd przetwarzania'
                      : 'Analizowanie projektu',
          style: TextStyle(
              color: theme.textColor, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),

        if (!state.isUploading)
          Text(
            state.isDone
                ? 'Przechodzę do projektu…'
                : failed
                    ? (state.uploadError ?? state.status?.error ?? 'Nieznany błąd')
                    : pipelineSteps[currentIdx].$2,
            style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 13),
            textAlign: TextAlign.center,
          ),

        if (!state.isUploading && !state.isDone && !failed &&
            st?.progressMsg != null) ...[
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: theme.userTile.withAlpha(80),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              st!.progressMsg!,
              style: TextStyle(
                  color: theme.textColor.withAlpha(80),
                  fontSize: 11,
                  fontFamily: 'monospace'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],

        const SizedBox(height: 24),

        if (!state.isUploading) ...[
          if (!state.isDone && !failed && pagesTotal != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  if (docs != null)
                    _CounterBadge(
                      icon: Icons.folder_copy_outlined,
                      label: 'Dokument',
                      current: docs!.current,
                      total: docs!.total,
                      color: theme.themeColor.withRed(200),
                      theme: theme,
                    ),
                  _CounterBadge(
                    icon: Icons.description_outlined,
                    // Podczas równoległego OCR (Faza 1) globalny licznik stron
                    // stoi w miejscu aż do końca tej fazy — pokaż zamiast niego
                    // żywy podpostęp OCR bieżącego dokumentu, żeby było widać,
                    // że backend faktycznie pracuje.
                    label: ocrSubProgress != null ? 'Strona (OCR dok.)' : 'Strona',
                    current: ocrSubProgress?.current ?? (pagesCurrent ?? 0),
                    total: ocrSubProgress?.total ?? pagesTotal!,
                    color: theme.themeColor,
                    theme: theme,
                  ),
                  _CounterBadge(
                    icon: Icons.psychology_outlined,
                    label: 'Zapytań AI',
                    current: aiDone ?? 0,
                    total: aiTotal!,
                    color: theme.themeColor.withBlue(200),
                    theme: theme,
                  ),
                  if (mbDone != null && mbDone! > 0)
                    _MbBadge(mb: mbDone!, theme: theme),
                ],
              ),
            ),

          SizedBox(
            width: 380,
            child: LinearProgressIndicator(
              value: state.isDone
                  ? 1.0
                  : failed
                      ? null
                      : pagesTotal != null && pagesTotal! > 0
                          ? (pagesCurrent ?? 0) / pagesTotal!
                          : (currentIdx + 1) / pipelineSteps.length,
              color: failed ? Colors.red.shade400 : theme.themeColor,
              backgroundColor: theme.bordercolor.withAlpha(60),
              borderRadius: BorderRadius.circular(4),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 24),

          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(pipelineSteps.length, (i) {
              final step = pipelineSteps[i];
              final isDone  = state.isDone || i < currentIdx;
              final isCurr  = !state.isDone && i == currentIdx && !failed;
              final isErr   = failed && i == currentIdx;
              final color = isErr
                  ? Colors.red.shade400
                  : isDone
                      ? Colors.green.shade400
                      : isCurr
                          ? theme.themeColor
                          : theme.textColor.withAlpha(60);
              return _StepChip(
                label: step.$2, color: color,
                isDone: isDone, isCurrent: isCurr, isError: isErr,
              );
            }),
          ),

          if (!state.isDone && !failed && pagesTotal != null) ...[
            const SizedBox(height: 20),
            _AiPlanRow(pagesTotal: pagesTotal!, aiTotal: aiTotal!, theme: theme),
          ],
        ],

        if (failed) ...[
          const SizedBox(height: 28),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Spróbuj ponownie'),
            onPressed: onReset,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.themeColor,
              side: BorderSide(color: theme.themeColor),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
        if (!failed && !state.isDone && !state.isUploading && state.isActive) ...[
          const SizedBox(height: 20),
          TextButton.icon(
            icon: Icon(Icons.cancel_outlined,
                size: 16, color: theme.textColor.withAlpha(80)),
            label: Text('Porzuć przetwarzanie',
                style: TextStyle(
                    color: theme.textColor.withAlpha(80), fontSize: 12)),
            onPressed: onReset,
          ),
        ],
      ],
    );
  }
}

// ── Counter badge ─────────────────────────────────────────────────────────────

class _CounterBadge extends StatelessWidget {
  const _CounterBadge({
    required this.icon,
    required this.label,
    required this.current,
    required this.total,
    required this.color,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final int current, total;
  final Color color;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$current / $total',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: theme.textColor.withAlpha(100),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── MB badge ──────────────────────────────────────────────────────────────────

class _MbBadge extends StatelessWidget {
  const _MbBadge({required this.mb, required this.theme});

  final double mb;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    final color = theme.themeColor.withGreen(160);
    final label = mb >= 1024 ? '${(mb / 1024).toStringAsFixed(1)} GB' : '${mb.toStringAsFixed(1)} MB';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.download_done_outlined, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
              Text('pobrano', style: TextStyle(color: theme.textColor.withAlpha(100), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── AI plan row ───────────────────────────────────────────────────────────────

class _AiPlanRow extends StatelessWidget {
  const _AiPlanRow({
    required this.pagesTotal,
    required this.aiTotal,
    required this.theme,
  });

  final int pagesTotal, aiTotal;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    final dim = theme.textColor.withAlpha(70);
    final items = [
      (Icons.image_search, '$pagesTotal × OCR (vision)'),
      (Icons.label_outline, '$pagesTotal × klasyfikacja'),
      (Icons.data_object, '${pagesTotal * 2} × ekstrakcja JSON'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.userTile.withAlpha(60),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.bordercolor.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.map((e) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(e.$1, size: 12, color: dim),
              const SizedBox(width: 4),
              Text(e.$2, style: TextStyle(color: dim, fontSize: 11)),
            ],
          ),
        )).toList(),
      ),
    );
  }
}


// ── Doc queue panel ───────────────────────────────────────────────────────────

class _DocQueuePanel extends StatelessWidget {
  const _DocQueuePanel({
    required this.fileNames,
    required this.currentDocIdx,
    required this.failed,
    required this.theme,
  });

  final List<String> fileNames;
  final int currentDocIdx; // -1 = error
  final bool failed;
  final ThemeColors theme;

  static IconData _icon(String name) {
    return switch (name.split('.').last.toLowerCase()) {
      'pdf'                    => Icons.picture_as_pdf,
      'jpg' || 'jpeg' || 'png' => Icons.image_outlined,
      'doc' || 'docx'          => Icons.description_outlined,
      _                        => Icons.insert_drive_file_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: theme.userTile.withAlpha(60),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.bordercolor.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Text(
              '${fileNames.length} dokumentów do przetworzenia',
              style: TextStyle(
                color: theme.textColor.withAlpha(100),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Container(height: 1, color: theme.bordercolor.withAlpha(40)),
          ...fileNames.asMap().entries.map((e) {
            final i = e.key;
            final name = e.value;
            final isDone    = i < currentDocIdx;
            final isCurrent = i == currentDocIdx && !failed;
            final isErr     = failed && i == currentDocIdx;
            final isPending = i > currentDocIdx && !failed;

            final color = isErr
                ? Colors.red.shade400
                : isDone
                    ? Colors.green.shade400
                    : isCurrent
                        ? theme.themeColor
                        : theme.textColor.withAlpha(50);

            return Container(
              decoration: BoxDecoration(
                color: isCurrent
                    ? theme.themeColor.withAlpha(12)
                    : null,
                border: i < fileNames.length - 1
                    ? Border(bottom: BorderSide(
                        color: theme.bordercolor.withAlpha(30)))
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                children: [
                  Icon(_icon(name), size: 16, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        color: isCurrent
                            ? theme.textColor
                            : isPending
                                ? theme.textColor.withAlpha(60)
                                : color,
                        fontSize: 12,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isDone)
                    Icon(Icons.check_circle_outline, size: 14, color: color)
                  else if (isErr)
                    Icon(Icons.error_outline, size: 14, color: color)
                  else if (isCurrent)
                    SizedBox(
                      width: 12, height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: color),
                    )
                  else
                    Icon(Icons.schedule_outlined,
                        size: 14, color: theme.textColor.withAlpha(40)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Doc browser (pages gallery) ───────────────────────────────────────────────

class _DocBrowser extends StatefulWidget {
  const _DocBrowser({
    required this.pages,
    required this.fileNames,
    required this.currentDocIdx,
    required this.theme,
    required this.pipelineId,
  });

  final List<PageEntry> pages;
  final List<String>? fileNames;
  final int currentDocIdx; // 1-based, currently processing
  final ThemeColors theme;
  final int pipelineId;

  @override
  State<_DocBrowser> createState() => _DocBrowserState();
}

class _DocBrowserState extends State<_DocBrowser> {
  int _selectedDocIdx = 1; // 1-based

  @override
  void didUpdateWidget(_DocBrowser old) {
    super.didUpdateWidget(old);
    // auto-follow current doc until user taps a tab
    if (!_userSelectedTab && widget.currentDocIdx != old.currentDocIdx) {
      setState(() => _selectedDocIdx = widget.currentDocIdx);
    }
  }

  bool _userSelectedTab = false;

  Map<int, List<PageEntry>> get _groups {
    final m = <int, List<PageEntry>>{};
    for (final p in widget.pages) {
      m.putIfAbsent(p.docIdx, () => []).add(p);
    }
    return m;
  }

  String _docName(int docIdx) {
    final names = widget.fileNames;
    if (names != null && docIdx - 1 < names.length) {
      final n = names[docIdx - 1];
      return n.length > 28 ? '${n.substring(0, 25)}…' : n;
    }
    return 'Dokument $docIdx';
  }

  Color _kindColor(PageEntry p, ThemeColors t) {
    if (p.isSkipped) return t.textColor.withAlpha(60);
    return switch (p.kind) {
      String k when k.startsWith('rzut') => const Color(0xFFE67E22),
      'przekroj' || 'elewacja'           => const Color(0xFF9B59B6),
      'opis_techniczny' || 'strona_tytulowa' => const Color(0xFF3498DB),
      'schemat_elektryczny'              => const Color(0xFFE74C3C),
      'schemat_sanitarny'                => const Color(0xFF1ABC9C),
      'warunki_przylaczenia'             => const Color(0xFFE91E63),
      'obliczenia_techniczne'            => const Color(0xFF795548),
      'uzgodnienie'                      => const Color(0xFF607D8B),
      'pozwolenie_na_budowe'             => const Color(0xFFD32F2F),
      'uprawnienia_projektanta'          => const Color(0xFF5C6BC0),
      'oswiadczenie'                     => const Color(0xFF8D6E63),
      'projekt_zagospodarowania'         => const Color(0xFF2E7D32),
      'zestawienie_materialow' || 'zestawienie_stolarki' => const Color(0xFF00BCD4),
      'mapa_sytuacyjna'                  => const Color(0xFF4CAF50),
      'opis_sanitarny'                   => const Color(0xFF009688),
      'strona_pusta'                     => t.textColor.withAlpha(30),
      _                                  => t.themeColor,
    };
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    final allDocIdxs = groups.keys.toList()..sort();
    // include docs that are pending (have names but no pages yet)
    final totalDocs = widget.fileNames?.length ?? allDocIdxs.length;

    if (!allDocIdxs.contains(_selectedDocIdx) && allDocIdxs.isNotEmpty) {
      _selectedDocIdx = allDocIdxs.first;
    }

    final selectedPages = groups[_selectedDocIdx] ?? [];
    final t = widget.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Doc tabs ──────────────────────────────────────────────────────────
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: totalDocs,
            itemBuilder: (ctx, i) {
              final docIdx   = i + 1;
              final isActive = docIdx == _selectedDocIdx;
              final isProc   = docIdx == widget.currentDocIdx;
              final docPages = groups[docIdx] ?? [];
              final doneCount = docPages.where((p) => p.kind != null).length;

              return GestureDetector(
                onTap: () => setState(() {
                  _selectedDocIdx = docIdx;
                  _userSelectedTab = true;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? t.themeColor.withAlpha(25)
                        : t.userTile.withAlpha(60),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive ? t.themeColor.withAlpha(120) : t.bordercolor.withAlpha(50),
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isProc)
                        Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: SizedBox(
                            width: 10, height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: t.themeColor),
                          ),
                        ),
                      Text(
                        _docName(docIdx),
                        style: TextStyle(
                          color: isActive ? t.textColor : t.textColor.withAlpha(130),
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (doneCount > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: t.themeColor.withAlpha(40),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$doneCount',
                            style: TextStyle(
                                color: t.themeColor, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        Container(height: 1, color: t.bordercolor.withAlpha(30)),

        // ── Page grid ─────────────────────────────────────────────────────────
        Expanded(
          child: selectedPages.isEmpty
              ? Center(
                  child: Text(
                    'Oczekiwanie na strony…',
                    style: TextStyle(color: t.textColor.withAlpha(60), fontSize: 13),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(14),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 130,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: selectedPages.length,
                  itemBuilder: (ctx, i) {
                    final p = selectedPages[i];
                    return _PageThumb(
                      entry:     p,
                      kindColor: _kindColor(p, t),
                      theme:     t,
                      onTap: p.url != null || p.ocrText != null
                          ? () => _openDetail(ctx, p)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openDetail(BuildContext context, PageEntry p) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withAlpha(180),
      builder: (_) => _PageDetailDialog(
        entry: p,
        theme: widget.theme,
        pipelineId: widget.pipelineId,  // _DocBrowserState has access to widget.pipelineId
      ),
    );
  }
}

// ── Page thumbnail ────────────────────────────────────────────────────────────

class _PageThumb extends StatelessWidget {
  const _PageThumb({
    required this.entry,
    required this.kindColor,
    required this.theme,
    this.onTap,
  });

  final PageEntry entry;
  final Color kindColor;
  final ThemeColors theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final p = entry;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: t.userTile,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: t.bordercolor.withAlpha(60)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // image area
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (p.url != null)
                    Image.network(
                      p.url!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(Icons.broken_image_outlined,
                            size: 28, color: t.textColor.withAlpha(40)),
                      ),
                    )
                  else
                    Center(
                      child: p.isProcessing
                          ? SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5, color: t.themeColor.withAlpha(120)))
                          : Icon(Icons.hourglass_empty_rounded,
                              size: 24, color: t.textColor.withAlpha(40)),
                    ),

                  // skipped overlay
                  if (p.isSkipped)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: Icon(Icons.do_not_disturb_outlined,
                            color: Colors.white54, size: 24),
                      ),
                    ),

                  // page number badge
                  Positioned(
                    top: 4, left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        's.${p.pageInDoc}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // kind label bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              color: kindColor.withAlpha(p.isSkipped ? 20 : 30),
              child: Text(
                p.kindLabel.isEmpty ? '…' : p.kindLabel,
                style: TextStyle(
                  color: kindColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page detail dialog ────────────────────────────────────────────────────────

// ── Right panel in page detail dialog: tabs Dane / OCR ───────────────────────
class _PageRightPanel extends StatefulWidget {
  const _PageRightPanel({required this.entry, required this.theme});
  final PageEntry entry;
  final ThemeColors theme;
  @override
  State<_PageRightPanel> createState() => _PageRightPanelState();
}

class _PageRightPanelState extends State<_PageRightPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    final hasData = (widget.entry.extractedData?.isNotEmpty ?? false);
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: hasData ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.entry;
    final t = widget.theme;
    final hasData = (p.extractedData?.isNotEmpty ?? false);
    final dim = t.textColor.withAlpha(110);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── tab bar ─────────────────────────────────────────────────────────
        TabBar(
          controller: _tabs,
          labelColor: t.themeColor,
          unselectedLabelColor: dim,
          indicatorColor: t.themeColor,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: const [Tab(text: 'Dane'), Tab(text: 'Tekst OCR')],
        ),
        Container(height: 1, color: t.bordercolor.withAlpha(30)),

        // ── tab views ────────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              // ── tab 0: Dane wyekstraktowane ────────────────────────────
              hasData
                  ? Scrollbar(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                        children: [
                          ..._buildDataRows(p.extractedData!, t),
                        ],
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hourglass_empty,
                              color: t.textColor.withAlpha(40), size: 32),
                          const SizedBox(height: 8),
                          Text(
                            p.isProcessing
                                ? 'Trwa ekstrakcja…'
                                : p.isSkipped
                                    ? 'Strona pominięta'
                                    : 'Brak danych',
                            style: TextStyle(
                                color: t.textColor.withAlpha(60), fontSize: 12),
                          ),
                        ],
                      ),
                    ),

              // ── tab 1: Tekst OCR ────────────────────────────────────────
              p.ocrText != null
                  ? Scrollbar(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                        child: Text(
                          p.ocrText!,
                          style: TextStyle(
                            color: t.textColor.withAlpha(160),
                            fontSize: 11,
                            fontFamily: 'monospace',
                            height: 1.65,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text('Brak tekstu OCR',
                          style: TextStyle(
                              color: t.textColor.withAlpha(60), fontSize: 12)),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDataRows(Map<String, dynamic> data, ThemeColors t) {
    final rows = <Widget>[];
    for (final entry in data.entries) {
      final key = entry.key;
      final val = entry.value;
      if (val == null || val == '' || (val is List && val.isEmpty)) continue;

      final label = key
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');

      if (val is List) {
        rows.add(_DataSection(label: label, theme: t));
        for (int i = 0; i < val.length; i++) {
          final item = val[i];
          if (item is Map<String, dynamic>) {
            final sub = item.entries
                .where((e) => e.value != null && e.value != '')
                .map((e) => '${e.key}: ${e.value}')
                .join('  •  ');
            if (sub.isNotEmpty) {
              rows.add(_DataRow(
                  label: '${i + 1}.',
                  value: sub,
                  theme: t,
                  indent: true));
            }
          } else {
            rows.add(_DataRow(
                label: '${i + 1}.', value: '$item', theme: t, indent: true));
          }
        }
      } else {
        rows.add(_DataRow(label: label, value: '$val', theme: t));
      }
      rows.add(const SizedBox(height: 2));
    }
    return rows;
  }
}

class _DataSection extends StatelessWidget {
  const _DataSection({required this.label, required this.theme});
  final String label;
  final ThemeColors theme;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
              color: theme.themeColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6),
        ),
      );
}

class _DataRow extends StatelessWidget {
  const _DataRow(
      {required this.label,
      required this.value,
      required this.theme,
      this.indent = false});
  final String label;
  final String value;
  final ThemeColors theme;
  final bool indent;
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(left: indent ? 10 : 0, bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: indent ? 24 : 130,
              child: Text(
                label,
                style: TextStyle(
                    color: theme.textColor.withAlpha(100),
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                    color: theme.textColor.withAlpha(200), fontSize: 11),
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
class _PageDetailDialog extends StatefulWidget {
  const _PageDetailDialog({required this.entry, required this.theme, required this.pipelineId});
  final PageEntry entry;
  final ThemeColors theme;
  final int pipelineId;
  @override
  State<_PageDetailDialog> createState() => _PageDetailDialogState();
}

class _PageDetailDialogState extends State<_PageDetailDialog> {
  late String _selectedKind;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _selectedKind = widget.entry.kind ?? 'inny';
  }

  Future<void> _retry() async {
    setState(() => _isRetrying = true);
    try {
      final api = ProjektyApi();
      await api.reclassifyPage(
        pipelineId: widget.pipelineId,
        pageGlobal: widget.entry.globalPage,
        kind: _selectedKind,
        ocrText: widget.entry.ocrText ?? '',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.entry;
    final t = widget.theme;
    final w = MediaQuery.of(context).size.width * 0.82;
    final h = MediaQuery.of(context).size.height * 0.82;

    return Dialog(
      backgroundColor: t.userTile,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.all(32),
      child: SizedBox(
        width: w,
        height: h,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
              child: Row(
                children: [
                  Text(
                    'Strona ${p.pageInDoc}',
                    style: TextStyle(
                        color: t.textColor, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(width: 10),
                  // Kind dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: t.themeColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: t.themeColor.withAlpha(60)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: kindLabels.containsKey(_selectedKind) ? _selectedKind : 'inny',
                        isDense: true,
                        style: TextStyle(
                            color: t.themeColor, fontSize: 11, fontWeight: FontWeight.w600),
                        dropdownColor: t.userTile,
                        icon: Icon(Icons.arrow_drop_down, size: 16, color: t.themeColor),
                        items: kindLabels.entries.map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value,
                              style: TextStyle(
                                  color: t.textColor, fontSize: 12)),
                        )).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedKind = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Ponów button
                  if (_selectedKind != (p.kind ?? 'inny') || p.extractedData == null)
                    _isRetrying
                        ? SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 1.5, color: t.themeColor))
                        : TextButton.icon(
                            onPressed: _retry,
                            icon: Icon(Icons.refresh, size: 14, color: t.themeColor),
                            label: Text('Ponów',
                                style: TextStyle(
                                    color: t.themeColor, fontSize: 12)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                            ),
                          ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: t.textColor.withAlpha(120), size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Zamknij',
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            Container(height: 1, color: t.bordercolor.withAlpha(40)),

            // ── body ─────────────────────────────────────────────────────────
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // image panel
                  if (p.url != null)
                    Expanded(
                      flex: 3,
                      child: Container(
                        color: Colors.black12,
                        child: InteractiveViewer(
                          minScale: 0.3,
                          maxScale: 8,
                          child: Image.network(
                            p.url!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(Icons.broken_image_outlined,
                                  color: t.textColor.withAlpha(40), size: 56),
                            ),
                          ),
                        ),
                      ),
                    ),

                  if (p.url != null && (p.ocrText != null || p.extractedData != null))
                    Container(width: 1, color: t.bordercolor.withAlpha(40)),

                  // right panel: extracted data + OCR text
                  if (p.ocrText != null || p.extractedData != null)
                    Expanded(
                      flex: 2,
                      child: _PageRightPanel(entry: p, theme: t),
                    ),

                  // fallback if no content
                  if (p.url == null && p.ocrText == null && p.extractedData == null)
                    Expanded(
                      child: Center(
                        child: Text(
                          'Brak podglądu',
                          style: TextStyle(color: t.textColor.withAlpha(60)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.label,
    required this.color,
    required this.isDone,
    required this.isCurrent,
    required this.isError,
  });

  final String label;
  final Color color;
  final bool isDone, isCurrent, isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(isCurrent || isDone ? 30 : 15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withAlpha(isCurrent || isDone ? 120 : 40),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDone)
            Icon(Icons.check, size: 12, color: color)
          else if (isError)
            Icon(Icons.close, size: 12, color: color)
          else if (isCurrent)
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: color),
            )
          else
            SizedBox(
              width: 8,
              height: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
