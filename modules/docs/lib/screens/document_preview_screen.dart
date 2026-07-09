import 'dart:convert';

import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/common/chrome/back_button.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:docs/api/cloud_docs_service.dart';
import 'package:docs/models/document.dart';
import 'package:docs/provider/cloud_doc_provider.dart';
import 'package:docs/provider/document_page_setup_provider.dart';
import 'package:docs/widgets/document_exporter.dart';
import 'package:docs/widgets/document_page_break.dart';
import 'package:docs/widgets/paged_quill_document_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';
import 'package:universal_platform/universal_platform.dart';

class DocumentPreviewScreen extends ConsumerStatefulWidget {
  final dynamic routeData;
  final String? routeDocumentId;

  const DocumentPreviewScreen({
    super.key,
    this.routeData,
    this.routeDocumentId,
  });

  @override
  ConsumerState<DocumentPreviewScreen> createState() =>
      _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends ConsumerState<DocumentPreviewScreen> {
  final sideMenuKey = GlobalKey<SideMenuState>();
  final _scrollController = ScrollController();
  final _previewFocusNode = FocusNode(debugLabel: 'docs_preview_focus');

  late final QuillController _previewController;

  Future<Documents?>? _loadFuture;

  bool _disposed = false;
  String? _appliedDocumentSignature;

  @override
  void initState() {
    super.initState();

    _previewFocusNode.canRequestFocus = false;

    _previewController = QuillController(
      document: Document()..insert(0, '\n'),
      selection: const TextSelection.collapsed(offset: 0),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _disposed) return;

      setState(() {
        _loadFuture = _loadDocument();
      });
    });
  }

  @override
  void dispose() {
    _disposed = true;

    _scrollController.dispose();
    _previewFocusNode.dispose();
    _previewController.dispose();

    super.dispose();
  }

  String? _argString(dynamic data, String key) {
    if (data is Map) {
      final value = data[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return null;
  }

  String? _extractDocumentIdFromArgs(dynamic args) {
    if (widget.routeDocumentId != null &&
        widget.routeDocumentId!.trim().isNotEmpty) {
      return widget.routeDocumentId!.trim();
    }

    if (args == null) return null;

    if (args is String && args.trim().isNotEmpty) {
      return args.trim();
    }

    if (args is Documents) {
      return args.id.toString();
    }

    if (args is Map) {
      final directId = _argString(args, 'documentId') ??
          _argString(args, 'document_id') ??
          _argString(args, 'docId') ??
          _argString(args, 'doc_id') ??
          _argString(args, 'id');

      if (directId != null) return directId;

      final documentValue = args['document'];

      if (documentValue is Documents) {
        return documentValue.id.toString();
      }

      if (documentValue is String && documentValue.trim().isNotEmpty) {
        return documentValue.trim();
      }

      if (documentValue is Map) {
        final documentMap = Map<String, dynamic>.from(documentValue);

        final nestedId = documentMap['id'] ??
            documentMap['documentId'] ??
            documentMap['document_id'] ??
            documentMap['docId'] ??
            documentMap['doc_id'];

        if (nestedId != null && nestedId.toString().trim().isNotEmpty) {
          return nestedId.toString().trim();
        }
      }
    }

    return null;
  }

  List<dynamic> _normalizePageBreakOps(List<dynamic> ops) {
    final normalized = <dynamic>[];

    Map<String, dynamic> textOp(
      String text,
      dynamic attributes,
    ) {
      final op = <String, dynamic>{
        'insert': text,
      };

      if (attributes != null) {
        op['attributes'] = attributes;
      }

      return op;
    }

    Map<String, dynamic> pageBreakEmbedOp() {
      return {
        'insert': {
          'custom': {
            'type': DocumentPageBreakTools.embedType,
            'data': '',
          },
        },
      };
    }

    for (final rawOp in ops) {
      if (rawOp is! Map) {
        normalized.add(rawOp);
        continue;
      }

      final op = Map<String, dynamic>.from(rawOp);
      final insert = op['insert'];

      if (insert is! String) {
        normalized.add(op);
        continue;
      }

      final matches =
          DocumentPageBreakTools.legacyTextRegex.allMatches(insert).toList();

      if (matches.isEmpty) {
        normalized.add(op);
        continue;
      }

      final attributes = op['attributes'];
      var cursor = 0;

      for (final match in matches) {
        final before = insert.substring(cursor, match.start);

        if (before.isNotEmpty) {
          normalized.add(textOp(before, attributes));
        }

        normalized.add({'insert': '\n'});
        normalized.add(pageBreakEmbedOp());
        normalized.add({'insert': '\n\n'});

        cursor = match.end;
      }

      final after = insert.substring(cursor);

      if (after.isNotEmpty) {
        normalized.add(textOp(after, attributes));
      }
    }

    return normalized;
  }

  Delta _deltaFromMap(Map<String, dynamic>? deltaJson) {
    try {
      final ops = deltaJson?['ops'];

      if (ops is List<dynamic>) {
        return Delta.fromJson(_normalizePageBreakOps(ops));
      }

      if (ops is List) {
        return Delta.fromJson(_normalizePageBreakOps(ops.toList()));
      }
    } catch (e) {
      debugPrint('Preview delta parsing failed: $e');
    }

    return Delta()..insert('\n');
  }

  String _documentSignature(Documents document) {
    final deltaJson = jsonEncode(document.currentDelta ?? {});
    final styleJson = jsonEncode(document.currentStyle ?? {});

    return '${document.id}|${document.revision}|$deltaJson|$styleJson';
  }

  void _applyDocumentToPreview(Documents document) {
    final signature = _documentSignature(document);

    if (_appliedDocumentSignature == signature) {
      return;
    }

    _appliedDocumentSignature = signature;

    final delta = _deltaFromMap(document.currentDelta);
    final previewDocument = Document.fromDelta(delta);

    _previewController.document = previewDocument;
    _previewController.updateSelection(
      const TextSelection.collapsed(offset: 0),
      ChangeSource.remote,
    );
  }

  Future<Documents?> _loadDocument() async {
    final modalArgs = ModalRoute.of(context)?.settings.arguments;
    final args = widget.routeData ?? modalArgs;

    final documentId = _extractDocumentIdFromArgs(args);

    if (documentId == null || documentId.trim().isEmpty) {
      throw Exception('Brak documentId dla podglądu dokumentu.');
    }

    await ref.read(documentProvider.notifier).fetchDocument(
          documentId.trim(),
          ref,
        );

    final document = ref.read(documentProvider).valueOrNull;

    if (document == null) {
      throw Exception('Nie udało się pobrać dokumentu.');
    }

    _applyDocumentToPreview(document);

    return document;
  }

  Future<void> _reload() async {
    if (!mounted || _disposed) return;

    setState(() {
      _loadFuture = _loadDocument();
    });
  }

  Future<void> _exportPdf(Documents document) async {
    final pageSetup = ref.read(documentPageSetupProvider);

    final filePath = await DocumentExporter.exportToPdfFromController(
      controller: _previewController,
      title: document.title,
      pageSetup: pageSetup,
    );

    if (!mounted || _disposed) return;

    if (UniversalPlatform.isWeb) {
      _showSnackBar(
        message: "PDF '${document.title}' pobrany.",
        backgroundColor: Colors.green,
      );
      return;
    }

    if (filePath == null) {
      _showSnackBar(
        message: 'Nie udało się wygenerować PDF.',
        backgroundColor: Colors.red,
      );
      return;
    }

    _showSnackBar(
      message: 'PDF wygenerowany: $filePath',
      backgroundColor: Colors.green,
    );
  }

  Future<void> _printDocument(Documents document) async {
    try {
      final pageSetup = ref.read(documentPageSetupProvider);

      await DocumentExporter.printFromController(
        controller: _previewController,
        title: document.title,
        pageSetup: pageSetup,
      );

      if (!mounted || _disposed) return;

      _showSnackBar(
        message: 'Otworzono drukowanie.',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      if (!mounted || _disposed) return;

      _showSnackBar(
        message: 'Nie udało się wydrukować dokumentu: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  void _openEditor(Documents document) {
    ref.read(navigationService).pushNamedScreen(
      Routes.docs,
      data: {
        'documentId': document.id,
      },
    );
  }

  void _showSnackBar({
    required String message,
    required Color backgroundColor,
  }) {
    if (!mounted || _disposed) return;

    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
        ),
      );
  }

  Widget _buildLoading(ThemeColors theme) {
    return Center(
      child: AppLottie.loading(size: 420),
    );
  }

  Widget _buildError({
    required ThemeColors theme,
    required Object error,
  }) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.withAlpha(220),
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(
              'Nie udało się otworzyć podglądu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor.withAlpha(170),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('Spróbuj ponownie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.themeColor,
                foregroundColor: theme.themeColorText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewTopBar({
    required ThemeColors theme,
    required Documents document,
    required bool isMobile,
  }) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        isMobile ? 12 : 72,
        isMobile ? 10 : 0,
        isMobile ? 12 : 72,
        14,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 18,
        vertical: isMobile ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: theme.dashboardContainer.withAlpha(235),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dashboardBoarder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BackButtonHously(),
              const SizedBox(width: 10),
              Icon(
                Icons.visibility_outlined,
                color: theme.textColor.withAlpha(190),
                size: 20,
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? 220 : 480,
                ),
                child: Text(
                  document.title.trim().isEmpty
                      ? 'Dokument bez tytułu'
                      : document.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: isMobile ? 15 : 17,
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _PreviewPill(
                theme: theme,
                icon: Icons.remove_red_eye_outlined,
                label: 'Podgląd',
              ),
              _PreviewPill(
                theme: theme,
                icon: Icons.history_outlined,
                label: 'Rev. ${document.revision}',
              ),
              _PreviewIconButton(
                theme: theme,
                icon: Icons.refresh,
                tooltip: 'Odśwież',
                onTap: _reload,
              ),
              _PreviewIconButton(
                theme: theme,
                icon: Icons.print_outlined,
                tooltip: 'Drukuj',
                onTap: () => _printDocument(document),
              ),
              _PreviewIconButton(
                theme: theme,
                icon: Icons.picture_as_pdf_outlined,
                tooltip: 'Generuj PDF',
                onTap: () => _exportPdf(document),
              ),
              _PreviewPrimaryButton(
                theme: theme,
                icon: Icons.edit_outlined,
                label: 'Edytuj',
                onTap: () => _openEditor(document),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreview({
    required ThemeColors theme,
    required Documents document,
    required bool isMobile,
  }) {
    final pageSetup = ref.watch(documentPageSetupProvider);
    final paperPreviewMode = ref.watch(documentPaperPreviewModeProvider);
    final whitePaperMode = paperPreviewMode.isWhitePaper;

    _applyDocumentToPreview(document);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPreviewTopBar(
          theme: theme,
          document: document,
          isMobile: isMobile,
        ),
        Expanded(
          child: IgnorePointer(
            ignoring: true,
            child: PagedQuillDocumentEditor(
              masterController: _previewController,
              outerScrollController: _scrollController,
              pageSetup: pageSetup,
              resolvedTheme: theme,
              whitePaperMode: whitePaperMode,
              placeholder: '',
              focusNode: _previewFocusNode,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody({
    required bool isMobile,
  }) {
    final theme = ref.watch(themeColorsProvider);
    final future = _loadFuture;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: future == null
            ? _buildLoading(theme)
            : FutureBuilder<Documents?>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return _buildLoading(theme);
                  }

                  if (snapshot.hasError) {
                    return _buildError(
                      theme: theme,
                      error: snapshot.error!,
                    );
                  }

                  final document = snapshot.data;

                  if (document == null) {
                    return _buildError(
                      theme: theme,
                      error: 'Brak dokumentu.',
                    );
                  }

                  return _buildPreview(
                    theme: theme,
                    document: document,
                    isMobile: isMobile,
                  );
                },
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.agentCrm,
      isTopAppBarOff: true,
      enableScrool: false,
      childPc: _buildBody(isMobile: false),
      childMobile: _buildBody(isMobile: true),
    );
  }
}

class _PreviewPill extends StatelessWidget {
  final ThemeColors theme;
  final IconData icon;
  final String label;

  const _PreviewPill({
    required this.theme,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.textColor.withAlpha(170),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor.withAlpha(185),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewIconButton extends StatelessWidget {
  final ThemeColors theme;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _PreviewIconButton({
    required this.theme,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: theme.dashboardBoarder),
            ),
            child: Icon(
              icon,
              size: 18,
              color: theme.textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewPrimaryButton extends StatelessWidget {
  final ThemeColors theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PreviewPrimaryButton({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.themeColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: theme.themeColorText,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: theme.themeColorText,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}