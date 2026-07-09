import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

import '../import_state.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:importer/emma/anchors/anchors_importer.dart';


class ImportTabUpload extends ConsumerStatefulWidget {
  final AsyncValue<ImportOptions> optionsAsync;
  final ImportFormState formState;
  final ImportFormNotifier formNotifier;
  final bool isTablet;

  const ImportTabUpload({
    super.key,
    required this.optionsAsync,
    required this.formState,
    required this.formNotifier,
    this.isTablet = false,
  });

  @override
  ConsumerState<ImportTabUpload> createState() => _ImportTabUploadState();
}

class _ImportTabUploadState extends ConsumerState<ImportTabUpload> {
  bool _isUploading = false;
  bool _isDragging = false;

  Future<void> _pickFile() async {
    if (_isUploading) return;

    final res = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['csv', 'tsv', 'json', 'xlsx', 'xls', 'xml'],
    );

    if (res == null || res.files.isEmpty) return;

    setState(() => _isUploading = true);
    try {
      await widget.formNotifier.setFile(res.files.first);
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _handleDrop(DropDoneDetails details) async {
    if (_isUploading || details.files.isEmpty) return;
    final xFile = details.files.first;
    setState(() {
      _isUploading = true;
      _isDragging = false;
    });
    try {
      final bytes = await xFile.readAsBytes();
      final name = xFile.name;
      final file = PlatformFile(name: name, bytes: bytes, size: bytes.length);
      await widget.formNotifier.setFile(file);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final optionsAsync = widget.optionsAsync;
    final formState = widget.formState;
    final formNotifier = widget.formNotifier;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 750;
    final isTablet = screenWidth >= 750 && screenWidth < 1100;

    return EmmaUiAnchorTarget(
      // @emma-backend: ImporterEmmaAnchors.importUploadRoot
      anchorKey: 'importer.upload.root',
      // child: Padding(
        // padding: const EdgeInsets.all(16),
        child: isCompact
            ? SingleChildScrollView(
                child: Column(
                  children: [
                    _buildUploadCard(
                      theme: theme,
                      formState: formState,
                      formNotifier: formNotifier,
                      compact: true,
                      isTablet:false
                  ),
                    const SizedBox(height: 16),
                    _buildHelpCard(theme, optionsAsync, formState),
                  ],
                ),
              )
      :isTablet
          ? Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: _buildUploadCard(
              theme: theme,
              formState: formState,
              formNotifier: formNotifier,
              compact: false,
              isTablet: true
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _buildHelpCard(theme, optionsAsync, formState),
          ),
        ],
      )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: _buildUploadCard(
                      theme: theme,
                      formState: formState,
                      formNotifier: formNotifier,
                      compact: false,
                      isTablet: false
                  ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: _buildHelpCard(theme, optionsAsync, formState),
                  ),
                ],
              ),
      // ),
    );
  }

  Widget _buildUploadCard({
    required ThemeColors theme,
    required ImportFormState formState,
    required ImportFormNotifier formNotifier,
    required bool compact,
    required bool isTablet,

  }) {
    final file = formState.file;

    return Card(
      elevation: 0,
      color: theme.dashboardContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dashboardBoarder.withAlpha(150)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EmmaUiAnchorTarget(
                    // @emma-backend: ImporterEmmaAnchors.importUploadDropzone
                    anchorKey: 'importer.upload.dropzone',
                    child: DropTarget(
                      onDragDone: _handleDrop,
                      onDragEntered: (_) => setState(() => _isDragging = true),
                      onDragExited: (_) => setState(() => _isDragging = false),
                      child: _UploadHero(
                        theme: theme,
                        isUploading: _isUploading,
                        isDragging: _isDragging,
                        onPickFile: _pickFile,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  EmmaUiAnchorTarget(
                    // @emma-backend: ImporterEmmaAnchors.importUploadSelectedFile
                    anchorKey: 'importer.upload.selected_file',
                    child: _SelectedFileInfo(
                      theme: theme,
                      file: file,
                      onClear: _isUploading
                          ? null
                          : () {
                              formNotifier.setFile(null);
                            },
                    ),
                  ),
                  if (_isUploading) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: theme.textColor.withAlpha(38),
                    ),
                  ],
                  if (formState.largeFileWarning != null)
                    _LargeFileWarningBanner(
                      theme: theme,
                      message: formState.largeFileWarning!,
                    ),
                  if (formState.xlsxSheetNames.length > 1)
                    _XlsxSheetSelector(
                      theme: theme,
                      sheets: formState.xlsxSheetNames,
                      selected: formState.xlsxSelectedSheet ??
                          formState.xlsxSheetNames.first,
                      onChanged: (s) => formNotifier.selectXlsxSheet(s),
                    ),
                  _EncodingSelector(
                    theme: theme,
                    encoding: formState.fileEncoding,
                    onChanged: (enc) => formNotifier.setEncoding(enc),
                  ),
                  const SizedBox(height: 16),
                  _SupportedFormatsRow(theme: theme),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 330,
                    child: EmmaUiAnchorTarget(
                      // @emma-backend: ImporterEmmaAnchors.importUploadPreview
                      anchorKey: 'importer.upload.preview',
                      child: _FilePreviewMini(
                        theme: theme,
                        formState: formState,
                        isLoading: _isUploading,
                      ),
                    ),
                  ),
                ],
              )
            : isTablet
                ? SingleChildScrollView(
                    child: SizedBox(
                      height: 620,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropTarget(
                            onDragDone: _handleDrop,
                            onDragEntered: (_) =>
                                setState(() => _isDragging = true),
                            onDragExited: (_) =>
                                setState(() => _isDragging = false),
                            child: _UploadHero(
                              theme: theme,
                              isUploading: _isUploading,
                              isDragging: _isDragging,
                              onPickFile: _pickFile,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _SelectedFileInfo(
                            theme: theme,
                            file: file,
                            onClear: _isUploading
                                ? null
                                : () => formNotifier.setFile(null),
                          ),
                          if (_isUploading) ...[
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              minHeight: 2,
                              backgroundColor: theme.textColor.withAlpha(38),
                            ),
                          ],
                          if (formState.largeFileWarning != null)
                            _LargeFileWarningBanner(
                              theme: theme,
                              message: formState.largeFileWarning!,
                            ),
                          if (formState.xlsxSheetNames.length > 1)
                            _XlsxSheetSelector(
                              theme: theme,
                              sheets: formState.xlsxSheetNames,
                              selected: formState.xlsxSelectedSheet ??
                                  formState.xlsxSheetNames.first,
                              onChanged: (s) => formNotifier.selectXlsxSheet(s),
                            ),
                          _EncodingSelector(
                            theme: theme,
                            encoding: formState.fileEncoding,
                            onChanged: (enc) => formNotifier.setEncoding(enc),
                          ),
                          const SizedBox(height: 6),
                          _SupportedFormatsRow(theme: theme),
                          const SizedBox(height: 6),
                          Expanded(
                            child: _FilePreviewMini(
                              theme: theme,
                              formState: formState,
                              isLoading: _isUploading,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SizedBox(
                    height: 620,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropTarget(
                          onDragDone: _handleDrop,
                          onDragEntered: (_) =>
                              setState(() => _isDragging = true),
                          onDragExited: (_) =>
                              setState(() => _isDragging = false),
                          child: _UploadHero(
                            theme: theme,
                            isUploading: _isUploading,
                            isDragging: _isDragging,
                            onPickFile: _pickFile,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SelectedFileInfo(
                          theme: theme,
                          file: file,
                          onClear: _isUploading
                              ? null
                              : () => formNotifier.setFile(null),
                        ),
                        if (_isUploading) ...[
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            minHeight: 4,
                            backgroundColor: theme.textColor.withAlpha(38),
                          ),
                        ],
                        if (formState.largeFileWarning != null)
                          _LargeFileWarningBanner(
                            theme: theme,
                            message: formState.largeFileWarning!,
                          ),
                        if (formState.xlsxSheetNames.length > 1)
                          _XlsxSheetSelector(
                            theme: theme,
                            sheets: formState.xlsxSheetNames,
                            selected: formState.xlsxSelectedSheet ??
                                formState.xlsxSheetNames.first,
                            onChanged: (s) => formNotifier.selectXlsxSheet(s),
                          ),
                        _EncodingSelector(
                          theme: theme,
                          encoding: formState.fileEncoding,
                          onChanged: (enc) => formNotifier.setEncoding(enc),
                        ),
                        const SizedBox(height: 16),
                        _SupportedFormatsRow(theme: theme),
                        const SizedBox(height: 18),
                        Expanded(
                          child: _FilePreviewMini(
                            theme: theme,
                            formState: formState,
                            isLoading: _isUploading,
                          ),
                        ),
                      ],
                    ),
                  ))
    );
  }

  Widget _buildHelpCard(
    ThemeColors theme,
    AsyncValue<ImportOptions> optionsAsync,
    ImportFormState formState,
  ) {
    return Card(
      elevation: 0,
      color: theme.dashboardContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.dashboardBoarder.withAlpha(150)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: optionsAsync.when(
          data: (options) {
            final modelCount = options.targetModels.keys.length;
            final selectedFile = formState.file?.name;
            final previewCols = formState.previewColumns.length;
            final previewRows = formState.previewData.length;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jak to działa?'.tr,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _bullet(
                    theme,
                    '1. Wrzucasz plik i od razu widzisz szybki podgląd kolumn oraz pierwszych wierszy.',
                  ),
                  _bullet(
                    theme,
                    '2. W edytorze poprawiasz i rozbijasz dane tak, żeby były gotowe do importu.',
                  ),
                  _bullet(
                    theme,
                    '3. W mapperze łączysz kolumny z polami modelu.',
                  ),
                  _bullet(
                    theme,
                    '4. Uruchamiasz import i sprawdzasz wyniki lub błędy w ostatnich importach.',
                  ),
                  const SizedBox(height: 14),
                  _InfoTile(
                    theme: theme,
                    icon: Icons.widgets_outlined,
                    title: 'Modele docelowe'.tr,
                    value: '$modelCount',
                  ),
                  const SizedBox(height: 10),
                  _InfoTile(
                    theme: theme,
                    icon: Icons.table_rows_outlined,
                    title: 'Podgląd danych'.tr,
                    value: previewCols == 0
                        ? 'Jeszcze niegotowy'.tr
                        : '$previewRows wierszy • $previewCols kolumn'.tr,
                  ),
                  const SizedBox(height: 10),
                  _InfoTile(
                    theme: theme,
                    icon: Icons.insert_drive_file_outlined,
                    title: 'Wybrany plik'.tr,
                    value: selectedFile?.isNotEmpty == true
                        ? selectedFile!
                        : 'Brak wybranego pliku'.tr,
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (err, _) => Text(
            'Błąd pobierania opcji importu: $err'.tr,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }

  Widget _bullet(ThemeColors theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.themeColor.withAlpha(16),
              shape: BoxShape.circle,
            ),
            child: Text(
              '•',
              style: TextStyle(
                color: theme.themeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text.tr,
              style: TextStyle(
                color: theme.textColor.withAlpha(210),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadHero extends StatelessWidget {
  final ThemeColors theme;
  final bool isUploading;
  final bool isDragging;
  final VoidCallback onPickFile;

  const _UploadHero({
    required this.theme,
    required this.isUploading,
    required this.isDragging,
    required this.onPickFile,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: isUploading ? null : onPickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDragging
                ? theme.themeColor
                : theme.themeColor.withAlpha(110),
            width: isDragging ? 2 : 1,
          ),
          gradient: LinearGradient(
            colors: isDragging
                ? [
                    theme.themeColor.withAlpha(40),
                    theme.themeColor.withAlpha(18),
                  ]
                : [
                    theme.themeColor.withAlpha(18),
                    theme.themeColor.withAlpha(6),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: theme.themeColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.upload_file_rounded,
                size: 30,
                color: theme.themeColor,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isUploading
                  ? 'Wczytywanie pliku...'.tr
                  : isDragging
                      ? 'Upuść plik tutaj'.tr
                      : 'Kliknij, aby wybrać plik'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'CSV, TSV, JSON, XLSX, XML. Po wybraniu od razu przygotujemy podgląd.'
                  .tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor.withAlpha(178),
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: isUploading ? null : onPickFile,
              icon: Icon(
                Icons.folder_open_rounded,
                color: theme.textColor,
              ),
              label: Text(
                isUploading ? 'Wczytywanie...'.tr : 'Wybierz plik'.tr,
                style: TextStyle(color: theme.textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedFileInfo extends StatelessWidget {
  final ThemeColors theme;
  final PlatformFile? file;
  final VoidCallback? onClear;

  const _SelectedFileInfo({
    required this.theme,
    required this.file,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (file == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dashboardBoarder.withAlpha(140)),
          color: Colors.black.withAlpha(8),
        ),
        child: Text(
          'Nie wybrano jeszcze pliku. Zacznij od źródła danych.'.tr,
          style: TextStyle(
            color: theme.textColor.withAlpha(178),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(140)),
        color: Colors.black.withAlpha(8),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.themeColor.withAlpha(18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.description_outlined,
              color: theme.themeColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${file!.name} • ${(file!.size / 1024).toStringAsFixed(1)} KB',
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportedFormatsRow extends StatelessWidget {
  final ThemeColors theme;

  const _SupportedFormatsRow({
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    const activeFormats = ['CSV', 'TSV', 'JSON', 'XLSX', 'XLS', 'XML'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final format in activeFormats)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: theme.dashboardBoarder.withAlpha(120)),
            ),
            child: Text(
              format,
              style: TextStyle(
                color: theme.textColor.withAlpha(210),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _FilePreviewMini extends StatelessWidget {
  final ThemeColors theme;
  final ImportFormState formState;
  final bool isLoading;

  const _FilePreviewMini({
    required this.theme,
    required this.formState,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _PreviewShell(
        theme: theme,
        child: Center(
          child: Text(
            'Wczytywanie i analizowanie pliku...'.tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(178),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (formState.file == null) {
      return _PreviewShell(
        theme: theme,
        child: Center(
          child: Text(
            'Po wybraniu pliku pokażemy tutaj szybki podgląd danych.'.tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(178),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (formState.previewColumns.isEmpty) {
      return _PreviewShell(
        theme: theme,
        child: Center(
          child: Text(
            'Plik został wybrany, ale nie udało się jeszcze zbudować podglądu kolumn.'
                .tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(178),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final cols = formState.previewColumns;
    final rows = formState.previewData.take(5).toList(growable: false);

    return _PreviewShell(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Szybki podgląd'.tr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pierwsze ${rows.length} wierszy i ${cols.length} kolumn'.tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(170),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: cols
                  .map(
                    (c) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: theme.themeColor.withAlpha(16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: theme.themeColor.withAlpha(55),
                        ),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Text(
                      'Kolumny zostały wykryte, ale brak danych do podglądu.'.tr,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(178),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowHeight: 34,
                      dataRowMinHeight: 32,
                      dataRowMaxHeight: 46,
                      columns: [
                        for (final c in cols)
                          DataColumn(
                            label: Text(
                              c,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: theme.textColor,
                              ),
                            ),
                          ),
                      ],
                      rows: [
                        for (final row in rows)
                          DataRow(
                            cells: [
                              for (var i = 0; i < cols.length; i++)
                                DataCell(
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 220),
                                    child: Text(
                                      i < row.length ? row[i] : '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: theme.textColor.withAlpha(230),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PreviewShell extends StatelessWidget {
  final ThemeColors theme;
  final Widget child;

  const _PreviewShell({
    required this.theme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(140)),
        color: Colors.black.withAlpha(10),
      ),
      child: child,
    );
  }
}

class _LargeFileWarningBanner extends StatelessWidget {
  final ThemeColors theme;
  final String message;

  const _LargeFileWarningBanner({
    required this.theme,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withAlpha(18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orangeAccent.withAlpha(100)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.orangeAccent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message.tr,
                style: TextStyle(
                  color: theme.textColor.withAlpha(220),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _XlsxSheetSelector extends StatelessWidget {
  final ThemeColors theme;
  final List<String> sheets;
  final String selected;
  final ValueChanged<String> onChanged;

  const _XlsxSheetSelector({
    required this.theme,
    required this.sheets,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(Icons.table_chart_outlined,
              size: 16, color: theme.themeColor),
          const SizedBox(width: 8),
          Text(
            'Arkusz:'.tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(200),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: sheets.contains(selected) ? selected : sheets.first,
                isDense: true,
                dropdownColor: theme.dashboardContainer,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                items: sheets
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EncodingSelector extends StatelessWidget {
  final ThemeColors theme;
  final String encoding;
  final ValueChanged<String> onChanged;

  static const _encodings = [
    ('utf-8', 'UTF-8 (domyślne)'),
    ('utf-16', 'UTF-16'),
    ('windows-1250', 'Windows-1250 (PL)'),
    ('iso-8859-2', 'ISO-8859-2 / Latin-2'),
  ];

  const _EncodingSelector({
    required this.theme,
    required this.encoding,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.translate_rounded, size: 15,
              color: theme.textColor.withAlpha(160)),
          const SizedBox(width: 8),
          Text(
            'Kodowanie:'.tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(180),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _encodings.any((e) => e.$1 == encoding)
                    ? encoding
                    : 'utf-8',
                isDense: true,
                dropdownColor: theme.dashboardContainer,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                items: _encodings
                    .map((e) => DropdownMenuItem(
                          value: e.$1,
                          child: Text(e.$2),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final ThemeColors theme;
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.theme,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(130)),
        color: Colors.black.withAlpha(10),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.themeColor.withAlpha(16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: theme.themeColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.tr,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(170),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}