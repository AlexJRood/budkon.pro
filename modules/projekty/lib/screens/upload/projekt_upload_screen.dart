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
    final file = _pickedFiles.first;

    List<int>? bytes = file.bytes;

    // On desktop FilePicker returns path but no bytes — read from disk.
    if (bytes == null && file.path != null && !kIsWeb) {
      bytes = await File(file.path!).readAsBytes();
    }

    if (bytes == null) return;
    await ref.read(pipelineProvider.notifier).startUpload(bytes, file.name);
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Big icon / spinner
            if (state.isDone)
              Icon(Icons.check_circle_rounded,
                  color: Colors.green.shade400, size: 72)
            else if (failed)
              Icon(Icons.error_rounded, color: Colors.red.shade400, size: 72)
            else
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                    strokeWidth: 4, color: theme.themeColor),
              ),
            const SizedBox(height: 24),
            Text(
              state.isUploading
                  ? 'Przesyłanie pliku…'
                  : state.isDone
                      ? 'Projekt wczytany!'
                      : failed
                          ? 'Błąd przetwarzania'
                          : 'Analizowanie projektu',
              style: TextStyle(
                  color: theme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            if (!state.isUploading) ...[
              const SizedBox(height: 8),
              Text(
                state.isDone
                    ? 'Przechodzę do projektu…'
                    : failed
                        ? (state.uploadError ?? 'Nieznany błąd')
                        : pipelineSteps[currentIdx].$2,
                style: TextStyle(
                    color: theme.textColor.withAlpha(150), fontSize: 13),
              ),
            ],
            const SizedBox(height: 32),
            if (!state.isUploading) ...[
              // Linear progress bar
              SizedBox(
                width: 360,
                child: LinearProgressIndicator(
                  value: state.isDone
                      ? 1.0
                      : failed
                          ? null
                          : (currentIdx + 1) / pipelineSteps.length,
                  color: failed ? Colors.red.shade400 : theme.themeColor,
                  backgroundColor: theme.bordercolor.withAlpha(60),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 32),
              // Step chips
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: List.generate(pipelineSteps.length, (i) {
                  final step = pipelineSteps[i];
                  final isDone = state.isDone || i < currentIdx;
                  final isCurrent = !state.isDone && i == currentIdx && !failed;
                  final isErr = failed && i == currentIdx;

                  final color = isErr
                      ? Colors.red.shade400
                      : isDone
                          ? Colors.green.shade400
                          : isCurrent
                              ? theme.themeColor
                              : theme.textColor.withAlpha(60);

                  return _StepChip(
                    label: step.$2,
                    color: color,
                    isDone: isDone,
                    isCurrent: isCurrent,
                    isError: isErr,
                  );
                }),
              ),
            ],
            if (failed) ...[
              const SizedBox(height: 32),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Spróbuj ponownie'),
                onPressed: onReset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.themeColor,
                  side: BorderSide(color: theme.themeColor),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
