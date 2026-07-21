import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import '../../data/providers/projekt_provider.dart';
import '../projekt_review/projekt_review_screen.dart';

class ProjektUploadScreen extends ConsumerStatefulWidget {
  final int? kosztorysId;
  const ProjektUploadScreen({super.key, this.kosztorysId});

  @override
  ConsumerState<ProjektUploadScreen> createState() => _ProjektUploadScreenState();
}

class _ProjektUploadScreenState extends ConsumerState<ProjektUploadScreen> {
  final _sideMenuKey = GlobalKey<SideMenuState>();
  PlatformFile? _pickedFile;
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final parseState = ref.watch(parseProvider);

    return BarManager(
      sideMenuKey: _sideMenuKey,
      appModule: AppModule.budkon,
      childPc: Column(
        children: [
          _buildHeader(theme),
          Expanded(child: _buildBody(theme, parseState)),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeColors theme) {
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
          Text(
            'PDF lub obraz (JPG, PNG)',
            style: TextStyle(color: theme.textColor.withAlpha(120), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeColors theme, ParseState parseState) {
    if (parseState.isLoading) {
      return _buildLoadingView(theme, parseState.progress ?? 0);
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDropZone(theme),
          if (_pickedFile != null) ...[
            const SizedBox(height: 24),
            _buildFileInfo(theme),
            const SizedBox(height: 24),
            _buildParseButton(theme),
          ],
          if (parseState.error != null) ...[
            const SizedBox(height: 16),
            _buildError(theme, parseState.error!),
          ],
          const SizedBox(height: 32),
          _buildInfoCards(theme),
        ],
      ),
    );
  }

  Widget _buildDropZone(ThemeColors theme) {
    return DragTarget<Object>(
      onWillAcceptWithDetails: (d) {
        setState(() => _isDragOver = true);
        return true;
      },
      onLeave: (_) => setState(() => _isDragOver = false),
      onAcceptWithDetails: (_) {
        setState(() => _isDragOver = false);
        _pickFile();
      },
      builder: (context, _, __) {
        return GestureDetector(
          onTap: _pickFile,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
            decoration: BoxDecoration(
              color: _isDragOver
                  ? theme.themeColor.withAlpha(30)
                  : theme.userTile.withAlpha(80),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isDragOver
                    ? theme.themeColor
                    : theme.bordercolor.withAlpha(80),
                width: _isDragOver ? 2 : 1,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _pickedFile != null
                      ? Icons.check_circle_outline
                      : Icons.upload_file_outlined,
                  size: 56,
                  color: _pickedFile != null
                      ? theme.themeColor
                      : theme.textColor.withAlpha(100),
                ),
                const SizedBox(height: 16),
                Text(
                  _pickedFile != null
                      ? 'Zmień plik'
                      : 'Przeciągnij plik lub kliknij',
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Obsługiwane formaty: PDF, JPG, PNG',
                  style: TextStyle(
                      color: theme.textColor.withAlpha(120), fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFileInfo(ThemeColors theme) {
    final file = _pickedFile!;
    final sizeKb = (file.size / 1024).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.userTile,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.bordercolor.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(_fileIcon(file.name), color: theme.themeColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.name,
                    style: TextStyle(
                        color: theme.textColor, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
                Text('$sizeKb KB',
                    style: TextStyle(
                        color: theme.textColor.withAlpha(120), fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: theme.textColor.withAlpha(120), size: 18),
            onPressed: () => setState(() => _pickedFile = null),
          ),
        ],
      ),
    );
  }

  Widget _buildParseButton(ThemeColors theme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Analizuj projekt'),
        onPressed: _startParsing,
        style: FilledButton.styleFrom(
          backgroundColor: theme.themeColor,
          foregroundColor: theme.buttonTextColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildLoadingView(ThemeColors theme, double progress) {
    final steps = [
      'Przesyłanie pliku...',
      'Analiza struktury dokumentu...',
      'Rozpoznawanie pomieszczeń...',
      'Generowanie pozycji kosztorysowych...',
    ];
    final stepIdx = (progress * steps.length).floor().clamp(0, steps.length - 1);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                value: progress > 0 ? progress : null,
                strokeWidth: 4,
                color: theme.themeColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Analizowanie projektu',
              style: TextStyle(
                  color: theme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              steps[stepIdx],
              style:
                  TextStyle(color: theme.textColor.withAlpha(150), fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 300,
              child: LinearProgressIndicator(
                value: progress > 0 ? progress : null,
                color: theme.themeColor,
                backgroundColor: theme.bordercolor.withAlpha(60),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ThemeColors theme, String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Błąd analizy: $error',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(ThemeColors theme) {
    final items = [
      (Icons.search, 'Rozpoznaje pomieszczenia', 'Nazwy, powierzchnie i układ'),
      (Icons.calculate, 'Generuje kosztorys', 'Szacunkowe pozycje i ceny'),
      (Icons.map, 'Rysuje floor plan', 'Interaktywny rzut kondygnacji'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items
          .map((e) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _InfoCard(icon: e.$1, title: e.$2, desc: e.$3, theme: theme),
                ),
              ))
          .toList(),
    );
  }

  IconData _fileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => Icons.picture_as_pdf,
      'jpg' || 'jpeg' || 'png' => Icons.image_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: kIsWeb,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _startParsing() async {
    final file = _pickedFile;
    if (file == null) return;

    ParsedProjekt? result;
    if (kIsWeb || file.bytes != null) {
      result = await ref
          .read(parseProvider.notifier)
          .parseBytes(file.bytes!, file.name);
    } else {
      result = await ref
          .read(parseProvider.notifier)
          .parseFile(file.path!, file.name);
    }

    if (result != null && mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProjektReviewScreen(
          projekt: result!,
          kosztorysId: widget.kosztorysId,
        ),
      ));
    }
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final ThemeColors theme;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.theme,
  });

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
