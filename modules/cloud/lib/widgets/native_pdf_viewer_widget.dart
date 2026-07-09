import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:printing/printing.dart';


class NativePdfViewerController extends ChangeNotifier {
  VoidCallback? _onPreviousPage;
  VoidCallback? _onNextPage;
  VoidCallback? _onZoomIn;
  VoidCallback? _onZoomOut;
  VoidCallback? _onResetZoom;
  VoidCallback? _onFitWidth;
  VoidCallback? _onRotateLeft;
  VoidCallback? _onRotateRight;
  Future<void> Function()? _onPrintPdf;
  Future<void> Function()? _onOpenExternal;

  bool _isAttached = false;
  bool _isReady = false;
  bool _supportsAdvancedControls = false;
  String? _filePath;
  int _pagesCount = 0;
  int _currentPage = 1;
  int _rotationTurns = 0;
  double _zoom = 1.0;

  bool get isAttached => _isAttached;
  bool get isReady => _isReady;
  bool get supportsAdvancedControls => _supportsAdvancedControls;
  String? get filePath => _filePath;
  int get pagesCount => _pagesCount;
  int get currentPage => _currentPage;
  int get rotationTurns => _rotationTurns;
  double get zoom => _zoom;

  bool get canNavigate => _isAttached && _supportsAdvancedControls && _isReady;
  bool get canZoom => _isAttached && _supportsAdvancedControls && _isReady;
  bool get canRotate => _isAttached && _supportsAdvancedControls && _isReady;
  bool get canPrint => _isAttached && _onPrintPdf != null;
  bool get canOpenExternal => _isAttached && _onOpenExternal != null;

  String get pagesLabel {
    if (_pagesCount <= 0) return 'Strona $_currentPage';
    return 'Strona $_currentPage / $_pagesCount';
  }

  String get zoomLabel => '${(_zoom * 100).round()}%';

  void previousPage() => _onPreviousPage?.call();
  void nextPage() => _onNextPage?.call();
  void zoomIn() => _onZoomIn?.call();
  void zoomOut() => _onZoomOut?.call();
  void resetZoom() => _onResetZoom?.call();
  void fitWidth() => _onFitWidth?.call();
  void rotateLeft() => _onRotateLeft?.call();
  void rotateRight() => _onRotateRight?.call();

  Future<void> printPdf() async {
    final action = _onPrintPdf;
    if (action == null) return;
    await action();
  }

  Future<void> openExternal() async {
    final action = _onOpenExternal;
    if (action == null) return;
    await action();
  }

  void _attach({
    required String filePath,
    required bool supportsAdvancedControls,
    required VoidCallback onPreviousPage,
    required VoidCallback onNextPage,
    required VoidCallback onZoomIn,
    required VoidCallback onZoomOut,
    required VoidCallback onResetZoom,
    required VoidCallback onFitWidth,
    required VoidCallback onRotateLeft,
    required VoidCallback onRotateRight,
    required Future<void> Function() onPrintPdf,
    required Future<void> Function() onOpenExternal,
  }) {
    _isAttached = true;
    _filePath = filePath;
    _supportsAdvancedControls = supportsAdvancedControls;
    _onPreviousPage = onPreviousPage;
    _onNextPage = onNextPage;
    _onZoomIn = onZoomIn;
    _onZoomOut = onZoomOut;
    _onResetZoom = onResetZoom;
    _onFitWidth = onFitWidth;
    _onRotateLeft = onRotateLeft;
    _onRotateRight = onRotateRight;
    _onPrintPdf = onPrintPdf;
    _onOpenExternal = onOpenExternal;
    notifyListeners();
  }

  void _updateState({
    required String filePath,
    required bool isReady,
    required bool supportsAdvancedControls,
    required int pagesCount,
    required int currentPage,
    required int rotationTurns,
    required double zoom,
  }) {
    final didChange = _filePath != filePath ||
        _isReady != isReady ||
        _supportsAdvancedControls != supportsAdvancedControls ||
        _pagesCount != pagesCount ||
        _currentPage != currentPage ||
        _rotationTurns != rotationTurns ||
        (_zoom - zoom).abs() > 0.001;

    _filePath = filePath;
    _isReady = isReady;
    _supportsAdvancedControls = supportsAdvancedControls;
    _pagesCount = pagesCount;
    _currentPage = currentPage;
    _rotationTurns = rotationTurns;
    _zoom = zoom;

    if (didChange) notifyListeners();
  }

  void _detach() {
    final wasAttached = _isAttached;

    _isAttached = false;
    _isReady = false;
    _supportsAdvancedControls = false;
    _filePath = null;
    _pagesCount = 0;
    _currentPage = 1;
    _rotationTurns = 0;
    _zoom = 1.0;

    _onPreviousPage = null;
    _onNextPage = null;
    _onZoomIn = null;
    _onZoomOut = null;
    _onResetZoom = null;
    _onFitWidth = null;
    _onRotateLeft = null;
    _onRotateRight = null;
    _onPrintPdf = null;
    _onOpenExternal = null;

    if (wasAttached) notifyListeners();
  }
}

class NativePdfViewer extends StatefulWidget {
  final String filePath;
  final NativePdfViewerController? controller;
  final bool showToolbar;

  const NativePdfViewer({
    required this.filePath,
    this.controller,
    this.showToolbar = true,
    super.key,
  });

  @override
  State<NativePdfViewer> createState() => _NativePdfViewerState();
}

class _NativePdfViewerState extends State<NativePdfViewer> {
  static const double _minZoom = 0.35;
  static const double _maxZoom = 4.0;
  static const double _zoomStep = 0.15;

  PdfControllerPinch? _pinchController;

  PdfDocument? _desktopDocument;
  Future<PdfDocument>? _desktopDocumentFuture;

  final ScrollController _scrollController = ScrollController();
  final Map<int, Future<_RenderedPdfPage>> _desktopPageFutures =
      <int, Future<_RenderedPdfPage>>{};

  int _pagesCount = 0;
  int _currentPageEstimate = 1;
  int _rotationTurns = 0;

  double _zoom = 1.0;
  double _lastViewportWidth = 900;
  double _lastViewportHeight = 700;

  bool get _useDesktopRenderer {
    if (kIsWeb) return false;

    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_handleScrollChanged);
    _attachController();
    _initPdf();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      debugPrint(
        '[NativePdfViewer] firstFrame '
        'filePath=${widget.filePath} '
        'platform=$defaultTargetPlatform '
        'desktopRenderer=$_useDesktopRenderer',
      );
    });
  }

  @override
  void didUpdateWidget(covariant NativePdfViewer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      _attachController();
    }

    if (oldWidget.filePath != widget.filePath) {
      debugPrint(
        '[NativePdfViewer] didUpdateWidget filePath changed '
        'old=${oldWidget.filePath} '
        'new=${widget.filePath}',
      );

      _disposePdf();
      _attachController();
      _initPdf();

      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    debugPrint('[NativePdfViewer] dispose filePath=${widget.filePath}');

    _scrollController.removeListener(_handleScrollChanged);
    widget.controller?._detach();
    _disposePdf();
    _scrollController.dispose();

    super.dispose();
  }

  void _attachController() {
    widget.controller?._attach(
      filePath: widget.filePath,
      supportsAdvancedControls: _useDesktopRenderer,
      onPreviousPage: _scrollToPreviousPage,
      onNextPage: _scrollToNextPage,
      onZoomIn: _zoomIn,
      onZoomOut: _zoomOut,
      onResetZoom: _resetZoom,
      onFitWidth: _fitWidth,
      onRotateLeft: _rotateLeft,
      onRotateRight: _rotateRight,
      onPrintPdf: _printPdf,
      onOpenExternal: _openExternal,
    );

    _syncController();
  }

  void _syncController() {
    widget.controller?._updateState(
      filePath: widget.filePath,
      isReady: _pagesCount > 0,
      supportsAdvancedControls: _useDesktopRenderer,
      pagesCount: _pagesCount,
      currentPage: _currentPageEstimate,
      rotationTurns: _rotationTurns,
      zoom: _zoom,
    );
  }

  void _initPdf() {
    debugPrint(
      '[NativePdfViewer] initPdf '
      'filePath=${widget.filePath} '
      'platform=$defaultTargetPlatform '
      'desktopRenderer=$_useDesktopRenderer',
    );

    _pagesCount = 0;
    _currentPageEstimate = 1;
    _rotationTurns = 0;
    _zoom = 1.0;
    _syncController();

    if (_useDesktopRenderer) {
      _pinchController = null;
      _desktopPageFutures.clear();

      _desktopDocumentFuture = PdfDocument.openFile(widget.filePath).then(
        (document) {
          _desktopDocument = document;
          _pagesCount = document.pagesCount;

          debugPrint(
            '[NativePdfViewer] desktop document loaded '
            'pages=${document.pagesCount} '
            'filePath=${widget.filePath}',
          );

          if (mounted) {
            setState(() {});
            _syncController();
          }

          return document;
        },
      );

      return;
    }

    _desktopDocumentFuture = null;
    _desktopDocument = null;
    _desktopPageFutures.clear();

    _pinchController = PdfControllerPinch(
      document: PdfDocument.openFile(widget.filePath),
    );
  }

  void _disposePdf() {
    debugPrint('[NativePdfViewer] disposePdf filePath=${widget.filePath}');

    _pinchController?.dispose();
    _pinchController = null;

    try {
      _desktopDocument?.close();
    } catch (e) {
      debugPrint('[NativePdfViewer] desktop document close error=$e');
    }

    _desktopDocument = null;
    _desktopDocumentFuture = null;
    _desktopPageFutures.clear();
  }

  void _handleScrollChanged() {
    if (!_scrollController.hasClients) return;

    final estimatedExtent = (842.0 * _zoom) + 34.0;
    if (estimatedExtent <= 0) return;

    final next = (_scrollController.offset / estimatedExtent).floor() + 1;
    final clamped = next.clamp(1, _pagesCount <= 0 ? 1 : _pagesCount).toInt();

    if (clamped == _currentPageEstimate) return;

    setState(() {
      _currentPageEstimate = clamped;
    });
    _syncController();
  }

  void _setZoom(double value) {
    final next = value.clamp(_minZoom, _maxZoom).toDouble();

    if ((next - _zoom).abs() < 0.001) return;

    debugPrint(
      '[NativePdfViewer] setZoom old=$_zoom next=$next '
      'filePath=${widget.filePath}',
    );

    setState(() {
      _zoom = next;
    });
    _syncController();
  }

  void _zoomIn() {
    _setZoom(_zoom + _zoomStep);
  }

  void _zoomOut() {
    _setZoom(_zoom - _zoomStep);
  }

  void _resetZoom() {
    _setZoom(1.0);
  }

  void _fitWidth() {
    final safeWidth = (_lastViewportWidth - 96).clamp(320.0, 2400.0);

    // Most A4 PDFs have width around 595 PDF points.
    // This keeps the viewer predictable even before all pages are rendered.
    final nextZoom = safeWidth / 595.0;

    _setZoom(nextZoom);
  }

  void _rotateLeft() {
    setState(() {
      _rotationTurns = (_rotationTurns - 1) % 4;
    });
    _syncController();
  }

  void _rotateRight() {
    setState(() {
      _rotationTurns = (_rotationTurns + 1) % 4;
    });
    _syncController();
  }

  Future<void> _printPdf() async {
    try {
      debugPrint('[NativePdfViewer] print.start filePath=${widget.filePath}');

      final file = File(widget.filePath);

      if (!await file.exists()) {
        throw Exception('PDF file does not exist: ${widget.filePath}');
      }

      await Printing.layoutPdf(
        name: widget.filePath.split(Platform.pathSeparator).last,
        onLayout: (_) async => file.readAsBytes(),
      );

      debugPrint('[NativePdfViewer] print.done filePath=${widget.filePath}');
    } catch (e) {
      debugPrint('[NativePdfViewer] print.error $e');
      _showSnackBar('Nie udało się wydrukować PDF: $e');
    }
  }

  Future<void> _openExternal() async {
    try {
      debugPrint(
        '[NativePdfViewer] openExternal.start filePath=${widget.filePath}',
      );

      if (Platform.isWindows) {
        await Process.start(
          'cmd',
          ['/c', 'start', '', widget.filePath],
          runInShell: true,
        );
      } else if (Platform.isMacOS) {
        await Process.start('open', [widget.filePath]);
      } else if (Platform.isLinux) {
        await Process.start('xdg-open', [widget.filePath]);
      } else {
        _showSnackBar('Otwieranie systemowe nie jest dostępne na tej platformie.');
      }

      debugPrint(
        '[NativePdfViewer] openExternal.done filePath=${widget.filePath}',
      );
    } catch (e) {
      debugPrint('[NativePdfViewer] openExternal.error $e');
      _showSnackBar('Nie udało się otworzyć PDF w systemie: $e');
    }
  }

  void _scrollToPreviousPage() {
    if (!_scrollController.hasClients) return;

    final viewport = _lastViewportHeight <= 0 ? 700.0 : _lastViewportHeight;
    final nextOffset = (_scrollController.offset - viewport * 0.92)
        .clamp(0.0, _scrollController.position.maxScrollExtent)
        .toDouble();

    _scrollController.animateTo(
      nextOffset,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollToNextPage() {
    if (!_scrollController.hasClients) return;

    final viewport = _lastViewportHeight <= 0 ? 700.0 : _lastViewportHeight;
    final nextOffset = (_scrollController.offset + viewport * 0.92)
        .clamp(0.0, _scrollController.position.maxScrollExtent)
        .toDouble();

    _scrollController.animateTo(
      nextOffset,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
  }

  Future<_RenderedPdfPage> _renderDesktopPage({
    required PdfDocument document,
    required int pageNumber,
  }) {
    final existing = _desktopPageFutures[pageNumber];
    if (existing != null) return existing;

    final future = _renderDesktopPageInternal(
      document: document,
      pageNumber: pageNumber,
    );

    _desktopPageFutures[pageNumber] = future;
    return future;
  }

  Future<_RenderedPdfPage> _renderDesktopPageInternal({
    required PdfDocument document,
    required int pageNumber,
  }) async {
    debugPrint(
      '[NativePdfViewer] renderDesktopPage.start '
      'page=$pageNumber '
      'filePath=${widget.filePath}',
    );

    final page = await document.getPage(pageNumber);

    try {
      final sourceWidth = page.width;
      final sourceHeight = page.height;

      final renderScale = _desktopRenderScale(sourceWidth, sourceHeight);

      final image = await page.render(
        width: sourceWidth * renderScale,
        height: sourceHeight * renderScale,
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
      );

      if (image == null) {
        throw StateError('PDF page render returned null for page $pageNumber.');
      }

      debugPrint(
        '[NativePdfViewer] renderDesktopPage.done '
        'page=$pageNumber '
        'source=${sourceWidth.toStringAsFixed(1)}x${sourceHeight.toStringAsFixed(1)} '
        'rendered=${image.width}x${image.height} '
        'bytes=${image.bytes.length}',
      );

      return _RenderedPdfPage(
        pageNumber: pageNumber,
        bytes: image.bytes,
        renderedWidth: image.width!,
        renderedHeight: image.height!,
        sourceWidth: sourceWidth,
        sourceHeight: sourceHeight,
      );
    } finally {
      try {
        await page.close();
      } catch (e) {
        debugPrint(
          '[NativePdfViewer] page close error '
          'page=$pageNumber '
          'error=$e',
        );
      }
    }
  }

  double _desktopRenderScale(double pageWidth, double pageHeight) {
    final longestSide = pageWidth > pageHeight ? pageWidth : pageHeight;

    if (longestSide <= 0) return 2.0;

    const targetLongestSide = 1900.0;
    final scale = targetLongestSide / longestSide;

    return scale.clamp(1.4, 3.2).toDouble();
  }

  String get _displayFileName {
    final normalized = widget.filePath.replaceAll('\\', '/');
    final parts = normalized.split('/');

    if (parts.isEmpty || parts.last.trim().isEmpty) {
      return 'PDF';
    }

    return parts.last.trim();
  }

  Widget _buildToolbar({required bool compact}) {
    final pagesText = _pagesCount <= 0
        ? 'Strona $_currentPageEstimate'
        : 'Strona $_currentPageEstimate / $_pagesCount';

    final toolbarActions = <Widget>[
      if (!compact) ...[
        _ToolbarButton(
          icon: Icons.keyboard_arrow_up_rounded,
          tooltip: 'Poprzednia strona',
          onPressed: _scrollToPreviousPage,
        ),
        _ToolbarButton(
          icon: Icons.keyboard_arrow_down_rounded,
          tooltip: 'Następna strona',
          onPressed: _scrollToNextPage,
        ),
        const _ToolbarDivider(),
        _ToolbarButton(
          icon: Icons.zoom_out_rounded,
          tooltip: 'Oddal',
          onPressed: _zoomOut,
        ),
        _ToolbarChip(text: '${(_zoom * 100).round()}%'),
        _ToolbarButton(
          icon: Icons.zoom_in_rounded,
          tooltip: 'Przybliż',
          onPressed: _zoomIn,
        ),
        _ToolbarButton(
          icon: Icons.fit_screen_rounded,
          tooltip: 'Dopasuj szerokość',
          onPressed: _fitWidth,
        ),
        _ToolbarButton(
          icon: Icons.restart_alt_rounded,
          tooltip: 'Reset zoom',
          onPressed: _resetZoom,
        ),
        const _ToolbarDivider(),
        _ToolbarButton(
          icon: Icons.rotate_left_rounded,
          tooltip: 'Obróć w lewo',
          onPressed: _rotateLeft,
        ),
        _ToolbarButton(
          icon: Icons.rotate_right_rounded,
          tooltip: 'Obróć w prawo',
          onPressed: _rotateRight,
        ),
        const _ToolbarDivider(),
      ],
      _ToolbarButton(
        icon: Icons.print_rounded,
        tooltip: 'Drukuj',
        onPressed: _printPdf,
      ),
      _ToolbarButton(
        icon: Icons.open_in_new_rounded,
        tooltip: 'Otwórz w systemie',
        onPressed: _openExternal,
      ),
    ];

    return Material(
      color: const Color(0xFF111318),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          compact ? 10 : 14,
          compact ? 8 : 10,
          compact ? 10 : 14,
          compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withAlpha(22)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 34 : 38,
              height: compact ? 34 : 38,
              decoration: BoxDecoration(
                color: Colors.redAccent.withAlpha(24),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withAlpha(65)),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayFileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 12 : 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ToolbarChip(text: pagesText),
                      if (!compact) ...[
                        const SizedBox(width: 8),
                        _ToolbarChip(text: 'PDF'),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: toolbarActions
                      .map(
                        (action) => Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: action,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopPdfView() {
    final documentFuture = _desktopDocumentFuture;

    if (documentFuture == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _lastViewportWidth = constraints.maxWidth;
        _lastViewportHeight = constraints.maxHeight;

        final pdfContent = FutureBuilder<PdfDocument>(
          future: documentFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _PdfLoadingView(
                message: 'Ładowanie PDF...',
              );
            }

            if (snapshot.hasError) {
              return _PdfErrorView(
                title: 'Nie udało się otworzyć PDF',
                message: snapshot.error.toString(),
              );
            }

            final document = snapshot.data;

            if (document == null) {
              return const _PdfErrorView(
                title: 'Nie udało się otworzyć PDF',
                message: 'Brak dokumentu PDF po załadowaniu.',
              );
            }

            final pagesCount = document.pagesCount;

            if (pagesCount <= 0) {
              return const _PdfErrorView(
                title: 'Nie udało się otworzyć PDF',
                message: 'Dokument PDF nie ma stron.',
              );
            }

            return Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: ListView.separated(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                itemCount: pagesCount,
                separatorBuilder: (_, __) => const SizedBox(height: 26),
                itemBuilder: (context, index) {
                  final pageNumber = index + 1;

                  return _DesktopPdfPageView(
                    key: ValueKey(
                      'pdf_page_${widget.filePath}_$pageNumber',
                    ),
                    future: _renderDesktopPage(
                      document: document,
                      pageNumber: pageNumber,
                    ),
                    zoom: _zoom,
                    rotationTurns: _rotationTurns,
                  );
                },
              ),
            );
          },
        );

        if (!widget.showToolbar) {
          return pdfContent;
        }

        return Column(
          children: [
            _buildToolbar(compact: false),
            Expanded(child: pdfContent),
          ],
        );
      },
    );
  }

  Widget _buildMobilePdfView() {
    final controller = _pinchController;

    if (controller == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final pdfContent = PdfViewPinch(
      controller: controller,
      scrollDirection: Axis.vertical,
      onDocumentLoaded: (document) {
        debugPrint(
          '[NativePdfViewer] PdfViewPinch loaded '
          'pages=${document.pagesCount} '
          'filePath=${widget.filePath}',
        );

        if (mounted) {
          setState(() {
            _pagesCount = document.pagesCount;
          });
          _syncController();
        }
      },
      onDocumentError: (error) {
        debugPrint(
          '[NativePdfViewer] PdfViewPinch error '
          'error=$error '
          'filePath=${widget.filePath}',
        );
      },
    );

    if (!widget.showToolbar) {
      return pdfContent;
    }

    return Column(
      children: [
        _buildToolbar(compact: true),
        Expanded(child: pdfContent),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[NativePdfViewer] build '
      'filePath=${widget.filePath} '
      'platform=$defaultTargetPlatform '
      'desktopRenderer=$_useDesktopRenderer',
    );

    if (kIsWeb) {
      return const _PdfErrorView(
        title: 'PDF preview unavailable',
        message:
            'NativePdfViewer is not used on web. Use HtmlElementView PDF preview instead.',
      );
    }

    if (_useDesktopRenderer) {
      return _buildDesktopPdfView();
    }

    return _buildMobilePdfView();
  }
}

class _DesktopPdfPageView extends StatelessWidget {
  final Future<_RenderedPdfPage> future;
  final double zoom;
  final int rotationTurns;

  const _DesktopPdfPageView({
    required this.future,
    required this.zoom,
    required this.rotationTurns,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RenderedPdfPage>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _DesktopPdfPagePlaceholder(zoom: zoom);
        }

        if (snapshot.hasError) {
          return _PdfErrorView(
            title: 'Nie udało się wyrenderować strony PDF',
            message: snapshot.error.toString(),
          );
        }

        final page = snapshot.data;

        if (page == null) {
          return const _PdfErrorView(
            title: 'Nie udało się wyrenderować strony PDF',
            message: 'Brak danych strony.',
          );
        }

        final displayWidth = (page.sourceWidth * zoom).clamp(160.0, 4000.0);
        final turns = rotationTurns % 4;

        Widget image = Image.memory(
          page.bytes,
          width: displayWidth,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return _PdfErrorView(
              title: 'Nie udało się wyświetlić strony PDF',
              message: error.toString(),
            );
          },
        );

        if (turns != 0) {
          image = RotatedBox(
            quarterTurns: turns,
            child: image,
          );
        }

        return Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(42),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: image,
          ),
        );
      },
    );
  }
}

class _DesktopPdfPagePlaceholder extends StatelessWidget {
  final double zoom;

  const _DesktopPdfPagePlaceholder({
    required this.zoom,
  });

  @override
  Widget build(BuildContext context) {
    final width = (595.0 * zoom).clamp(220.0, 1800.0);
    final height = (842.0 * zoom).clamp(320.0, 2600.0);

    return Center(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withAlpha(isEnabled ? 18 : 8),
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(11),
          child: SizedBox(
            width: 36,
            height: 34,
            child: Icon(
              icon,
              color: Colors.white.withAlpha(isEnabled ? 235 : 90),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarChip extends StatelessWidget {
  final String text;

  const _ToolbarChip({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(22)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white.withAlpha(225),
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ToolbarText extends StatelessWidget {
  final String text;

  const _ToolbarText(this.text);

  @override
  Widget build(BuildContext context) {
    return _ToolbarChip(text: text);
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      color: Colors.white.withAlpha(35),
    );
  }
}

class _PdfLoadingView extends StatelessWidget {
  final String message;

  const _PdfLoadingView({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfErrorView extends StatelessWidget {
  final String title;
  final String message;

  const _PdfErrorView({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.dividerColor.withAlpha(140),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.picture_as_pdf_outlined,
                size: 46,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withAlpha(180),
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RenderedPdfPage {
  final int pageNumber;
  final Uint8List bytes;

  final int renderedWidth;
  final int renderedHeight;

  final double sourceWidth;
  final double sourceHeight;

  const _RenderedPdfPage({
    required this.pageNumber,
    required this.bytes,
    required this.renderedWidth,
    required this.renderedHeight,
    required this.sourceWidth,
    required this.sourceHeight,
  });
}