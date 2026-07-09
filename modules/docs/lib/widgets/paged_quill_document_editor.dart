import 'dart:convert';
import 'dart:math' as math;

import 'package:docs/provider/document_page_setup_provider.dart';
import 'package:docs/widgets/document_page_break.dart';
import 'package:docs/widgets/time_stamp_embed_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:core/theme/apptheme.dart';

class PagedQuillDocumentEditor extends StatefulWidget {
  final QuillController masterController;
  final ScrollController outerScrollController;
  final DocumentPageSetup pageSetup;
  final ThemeColors resolvedTheme;
  final bool whitePaperMode;
  final String placeholder;
  final FocusNode? focusNode;
  final bool readOnly;
  final bool enableAutoPagination;

  /// When true, wraps the pages in a pinch-to-zoom/pannable viewer that
  /// initially fits the page width to the available viewport. Intended for
  /// read-only previews where there is no scroll-to-cursor logic to keep
  /// in sync with the applied scale.
  final bool enableZoom;

  /// Reports the automatic "fit to screen width" scale whenever it changes
  /// (only relevant when [enableZoom] is false). Callers that programmatically
  /// scroll to a page (in pixel space) can use this to keep their target
  /// offsets in sync with the visually shrunk page size.
  final ValueChanged<double>? onFitScaleChanged;

  const PagedQuillDocumentEditor({
    super.key,
    required this.masterController,
    required this.outerScrollController,
    required this.pageSetup,
    required this.resolvedTheme,
    required this.whitePaperMode,
    required this.placeholder,
    this.focusNode,
    this.readOnly = false,
    this.enableAutoPagination = true,
    this.enableZoom = false,
    this.onFitScaleChanged,
  });

  @override
  State<PagedQuillDocumentEditor> createState() =>
      _PagedQuillDocumentEditorState();
}

class _PagedQuillDocumentEditorState extends State<PagedQuillDocumentEditor> {
  List<_DocumentPageSlice> _pages = const [];
  bool _disposed = false;
  bool _suppressMasterListener = false;

  final TransformationController _zoomController = TransformationController();
  double _fitScale = 1.0;
  double _zoomFitScale = 1.0;
  bool _userAdjustedZoom = false;

  @override
  void initState() {
    super.initState();
    widget.masterController.addListener(_handleMasterChanged);
    _rebuildPagesFromMaster();
  }

  @override
  void didUpdateWidget(covariant PagedQuillDocumentEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.masterController != widget.masterController) {
      oldWidget.masterController.removeListener(_handleMasterChanged);
      widget.masterController.addListener(_handleMasterChanged);
      _rebuildPagesFromMaster();
      return;
    }

    if (oldWidget.pageSetup != widget.pageSetup ||
        oldWidget.enableAutoPagination != widget.enableAutoPagination ||
        oldWidget.whitePaperMode != widget.whitePaperMode ||
        oldWidget.readOnly != widget.readOnly) {
      _rebuildPagesFromMaster();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    widget.masterController.removeListener(_handleMasterChanged);
    _zoomController.dispose();
    super.dispose();
  }

  void _handleBackgroundPointerDown() {
    if (!mounted) return;
    FocusScope.of(context).unfocus();
  }

  void _applyZoomFit({
    required double viewportWidth,
    required double contentWidth,
  }) {
    final scaledWidth = contentWidth * _zoomFitScale;
    final dx = math.max(0.0, (viewportWidth - scaledWidth) / 2);

    _zoomController.value = Matrix4.identity()
      ..translate(dx, 0.0)
      ..scale(_zoomFitScale);
  }

  void _handleMasterChanged() {
    if (_disposed || _suppressMasterListener) return;
    _rebuildPagesFromMaster();
  }

  void _rebuildPagesFromMaster() {
    final delta = widget.masterController.document.toDelta();

    final pages = _DocumentPaginator.paginate(
      delta: delta,
      pageSetup: widget.pageSetup,
      enableAutoPagination: widget.enableAutoPagination,
    );

    if (!mounted || _disposed) return;

    setState(() {
      _pages = pages.isEmpty ? [_DocumentPageSlice.empty(0)] : pages;
    });
  }

  Color get _pageColor {
    if (widget.whitePaperMode) return Colors.white;
    return widget.resolvedTheme.dashboardContainer;
  }

  Color get _pageBorderColor {
    if (widget.whitePaperMode) return Colors.black.withAlpha(28);
    return widget.resolvedTheme.dashboardBoarder.withAlpha(125);
  }

  Color get _textColor {
    if (widget.whitePaperMode) return Colors.black;
    return widget.resolvedTheme.textColor;
  }

  Color get _placeholderColor {
    if (widget.whitePaperMode) return Colors.black.withAlpha(90);
    return widget.resolvedTheme.textColor.withAlpha(90);
  }

  Color get _pageNumberColor {
    if (widget.whitePaperMode) return Colors.black.withAlpha(95);
    return widget.resolvedTheme.textColor.withAlpha(125);
  }

  double get _contentWidth {
    final margins = widget.pageSetup.marginInsetsPx;

    return math.max(
      1,
      widget.pageSetup.widthPx - margins.horizontal,
    ).toDouble();
  }

  double get _contentHeight {
    final margins = widget.pageSetup.marginInsetsPx;

    return math.max(
      1,
      widget.pageSetup.heightPx - margins.vertical,
    ).toDouble();
  }

  void _handlePageChanged({
    required int pageIndex,
    required Delta delta,
    required TextSelection localSelection,
  }) {
    if (_disposed || widget.readOnly) return;
    if (pageIndex < 0 || pageIndex >= _pages.length) return;

    final currentPage = _pages[pageIndex];
    final normalizedDelta = _DocumentPaginator.normalizePageDelta(delta);

    if (_deltaEquals(currentPage.delta, normalizedDelta)) {
      _syncMasterSelection(
        pageIndex: pageIndex,
        localSelection: localSelection,
      );
      return;
    }

    final updatedPages = [..._pages];
    updatedPages[pageIndex] = currentPage.copyWith(delta: normalizedDelta);

    final composedDelta = _DocumentPaginator.composePages(updatedPages);

    _suppressMasterListener = true;

    try {
      widget.masterController.document = Document.fromDelta(composedDelta);

      final safeSelection = _mapLocalSelectionToMaster(
        pages: updatedPages,
        pageIndex: pageIndex,
        localSelection: localSelection,
      );

      widget.masterController.updateSelection(
        safeSelection,
        ChangeSource.local,
      );
    } finally {
      _suppressMasterListener = false;
    }

    final repaginatedPages = _DocumentPaginator.paginate(
      delta: composedDelta,
      pageSetup: widget.pageSetup,
      enableAutoPagination: widget.enableAutoPagination,
    );

    if (!mounted || _disposed) return;

    setState(() {
      _pages = repaginatedPages.isEmpty
          ? [_DocumentPageSlice.empty(0)]
          : repaginatedPages;
    });
  }

  void _syncMasterSelection({
    required int pageIndex,
    required TextSelection localSelection,
  }) {
    if (_disposed || widget.readOnly) return;

    final selection = _mapLocalSelectionToMaster(
      pages: _pages,
      pageIndex: pageIndex,
      localSelection: localSelection,
    );

    _suppressMasterListener = true;

    try {
      widget.masterController.updateSelection(
        selection,
        ChangeSource.local,
      );
    } catch (_) {
      // Selection sync is best-effort.
    } finally {
      _suppressMasterListener = false;
    }
  }

  TextSelection _mapLocalSelectionToMaster({
    required List<_DocumentPageSlice> pages,
    required int pageIndex,
    required TextSelection localSelection,
  }) {
    final pageOffset = _DocumentPaginator.globalOffsetForPage(
      pages: pages,
      pageIndex: pageIndex,
    );

    final pageLength = pageIndex >= 0 && pageIndex < pages.length
        ? math.max(0, pages[pageIndex].documentLength - 1)
        : 0;

    int mapOffset(int value) {
      if (value < 0) return pageOffset;
      return pageOffset + value.clamp(0, pageLength).toInt();
    }

    final base = mapOffset(localSelection.baseOffset);
    final extent = mapOffset(localSelection.extentOffset);

    final masterLength = math.max(0, widget.masterController.document.length);

    return TextSelection(
      baseOffset: base.clamp(0, masterLength).toInt(),
      extentOffset: extent.clamp(0, masterLength).toInt(),
      affinity: localSelection.affinity,
      isDirectional: localSelection.isDirectional,
    );
  }

  bool _deltaEquals(Delta a, Delta b) {
    try {
      return jsonEncode(a.toJson()) == jsonEncode(b.toJson());
    } catch (_) {
      return false;
    }
  }

  Widget _buildPage({
    required BuildContext context,
    required _DocumentPageSlice page,
    required int visibleIndex,
    required int totalPages,
  }) {
    final margins = widget.pageSetup.marginInsetsPx;

    final content = widget.readOnly
        ? _ReadOnlyDeltaPageContent(
            delta: page.delta,
            placeholder: visibleIndex == 0 ? widget.placeholder : '',
            textColor: _textColor,
            placeholderColor: _placeholderColor,
            pageBackgroundColor: _pageColor,
            whitePaperMode: widget.whitePaperMode,
            resolvedTheme: widget.resolvedTheme,
          )
        : _PagedQuillPageEditor(
            key: ValueKey('paged-quill-page-${page.pageIndex}'),
            pageIndex: page.pageIndex,
            delta: page.delta,
            pageSetup: widget.pageSetup,
            resolvedTheme: widget.resolvedTheme,
            whitePaperMode: widget.whitePaperMode,
            placeholder: visibleIndex == 0 ? widget.placeholder : '',
            textColor: _textColor,
            placeholderColor: _placeholderColor,
            onChanged: _handlePageChanged,
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Center(
        child: Container(
          width: widget.pageSetup.widthPx,
          height: widget.pageSetup.heightPx,
          decoration: BoxDecoration(
            color: _pageColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _pageBorderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(
                  widget.whitePaperMode ? 32 : 46,
                ),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: margins,
                  child: SizedBox(
                    width: _contentWidth,
                    height: _contentHeight,
                    child: ClipRect(
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: const TextScaler.linear(
                            DocumentPageSetup.editorTextScale,
                          ),
                        ),
                        child: content,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: math.max(12, margins.right * 0.35),
                bottom: math.max(10, margins.bottom * 0.30),
                child: Text(
                  '${visibleIndex + 1}',
                  style: TextStyle(
                    color: _pageNumberColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPages(BuildContext context, BoxConstraints constraints) {
    final viewportWidth =
        constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

    final viewportHeight =
        constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;

    final horizontalPadding = viewportWidth < 700 ? 16.0 : 34.0;
    final verticalPadding = viewportWidth < 700 ? 18.0 : 30.0;

    final pages = _pages.isEmpty ? [_DocumentPageSlice.empty(0)] : _pages;

    final naturalWidth = widget.pageSetup.widthPx + horizontalPadding * 2;
    final naturalHeight = verticalPadding * 2 +
        pages.length * (widget.pageSetup.heightPx + 28);

    final fitScale = naturalWidth > 0
        ? (viewportWidth / naturalWidth).clamp(0.15, 1.0).toDouble()
        : 1.0;

    if ((_fitScale - fitScale).abs() > 0.001) {
      _fitScale = fitScale;

      final callback = widget.onFitScaleChanged;
      if (callback != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _disposed) return;
          callback(_fitScale);
        });
      }
    }

    final pagesColumn = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < pages.length; i++)
            _buildPage(
              context: context,
              page: pages[i],
              visibleIndex: i,
              totalPages: pages.length,
            ),
        ],
      ),
    );

    final Widget content;

    if (widget.enableZoom) {
      if ((_zoomFitScale - fitScale).abs() > 0.001) {
        _zoomFitScale = fitScale;

        if (!_userAdjustedZoom) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _disposed) return;
            _applyZoomFit(
              viewportWidth: viewportWidth,
              contentWidth: naturalWidth,
            );
          });
        }
      }

      content = InteractiveViewer(
        transformationController: _zoomController,
        constrained: false,
        panEnabled: true,
        scaleEnabled: true,
        minScale: math.max(0.1, _zoomFitScale * 0.4),
        maxScale: math.max(_zoomFitScale * 5, 3.0),
        boundaryMargin: EdgeInsets.symmetric(
          horizontal: viewportWidth,
          vertical: naturalHeight,
        ),
        onInteractionEnd: (_) {
          _userAdjustedZoom = true;
        },
        child: SizedBox(
          width: naturalWidth,
          child: pagesColumn,
        ),
      );
    } else {
      final scaledWidth = naturalWidth * fitScale;
      final scaledHeight = naturalHeight * fitScale;

      content = Scrollbar(
        controller: widget.outerScrollController,
        thumbVisibility: false,
        child: SingleChildScrollView(
          controller: widget.outerScrollController,
          physics: const ClampingScrollPhysics(),
          child: Center(
            child: SizedBox(
              width: scaledWidth,
              height: scaledHeight,
              child: FittedBox(
                fit: BoxFit.fill,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: naturalWidth,
                  height: naturalHeight,
                  child: pagesColumn,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: viewportWidth,
      height: viewportHeight,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _handleBackgroundPointerDown(),
        child: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = LayoutBuilder(
      builder: _buildPages,
    );

    final focusNode = widget.focusNode;

    if (focusNode == null) {
      return child;
    }

    return Focus(
      focusNode: focusNode,
      canRequestFocus: true,
      child: child,
    );
  }
}

class _ReadOnlyDeltaPageContent extends StatelessWidget {
  final Delta delta;
  final String placeholder;
  final Color textColor;
  final Color placeholderColor;
  final Color pageBackgroundColor;
  final bool whitePaperMode;
  final ThemeColors resolvedTheme;

  const _ReadOnlyDeltaPageContent({
    required this.delta,
    required this.placeholder,
    required this.textColor,
    required this.placeholderColor,
    required this.pageBackgroundColor,
    required this.whitePaperMode,
    required this.resolvedTheme,
  });

  static const String _safeFontFamily = 'Roboto';

  TextStyle _baseStyle() {
    return TextStyle(
      color: textColor,
      fontSize: 11,
      height: 1.45,
      fontWeight: FontWeight.w400,
      fontFamily: _safeFontFamily,
    );
  }

  Color _ensureReadableColor(Color color, Color fallback) {
    final a = color.computeLuminance();
    final b = pageBackgroundColor.computeLuminance();

    if ((a - b).abs() < 0.22) {
      return fallback;
    }

    return color;
  }

  Color? _parseColor(dynamic value) {
    if (value == null) return null;

    final raw = value.toString().replaceAll('#', '').trim();

    try {
      if (raw.length == 6) {
        return Color(int.parse('FF$raw', radix: 16));
      }

      if (raw.length == 8) {
        return Color(int.parse(raw, radix: 16));
      }
    } catch (_) {}

    return null;
  }

  TextStyle _styleFromAttributes(Map<String, dynamic>? attributes) {
    var style = _baseStyle();

    if (attributes == null || attributes.isEmpty) {
      return style;
    }

    final rawColor = _parseColor(attributes['color']);
    final rawBackground = _parseColor(attributes['background']);

    final header = attributes['header']?.toString();

    double fontSize = 11;
    FontWeight fontWeight = FontWeight.w400;
    double height = 1.45;

    if (header == '1') {
      fontSize = 22;
      fontWeight = FontWeight.w900;
      height = 1.22;
    } else if (header == '2') {
      fontSize = 18;
      fontWeight = FontWeight.w900;
      height = 1.28;
    } else if (header == '3') {
      fontSize = 15;
      fontWeight = FontWeight.w800;
      height = 1.32;
    }

    final rawSize = attributes['size'];

    if (rawSize is num) {
      fontSize = rawSize.toDouble();
    } else if (rawSize is String) {
      fontSize = double.tryParse(rawSize) ?? fontSize;
    }

    final rawLineHeight = attributes['line-height'];

    if (rawLineHeight is num) {
      height = rawLineHeight.toDouble();
    } else if (rawLineHeight is String) {
      height = double.tryParse(rawLineHeight) ?? height;
    }

    if (attributes['bold'] == true) {
      fontWeight = FontWeight.w800;
    }

    final fontFamily = attributes['font']?.toString();

    final decorations = <TextDecoration>[];

    if (attributes['underline'] == true) {
      decorations.add(TextDecoration.underline);
    }

    if (attributes['strike'] == true) {
      decorations.add(TextDecoration.lineThrough);
    }

    TextDecoration? decoration;

    if (decorations.length == 1) {
      decoration = decorations.first;
    } else if (decorations.length > 1) {
      decoration = TextDecoration.combine(decorations);
    }

    final effectiveColor = rawColor == null
        ? textColor
        : _ensureReadableColor(rawColor, textColor);

    return style.copyWith(
      color: effectiveColor,
      backgroundColor: rawBackground,
      fontSize: fontSize,
      height: height,
      fontWeight: fontWeight,
      fontStyle:
          attributes['italic'] == true ? FontStyle.italic : FontStyle.normal,
      fontFamily: fontFamily == null || fontFamily.trim().isEmpty
          ? _safeFontFamily
          : fontFamily,
      decoration: decoration,
    );
  }

  List<InlineSpan> _buildSpans() {
    final spans = <InlineSpan>[];

    for (final rawOp in delta.toJson()) {
      if (rawOp is! Map) continue;

      final op = Map<String, dynamic>.from(rawOp);
      final insert = op['insert'];

      if (DocumentPageBreakTools.isPageBreakInsert(insert)) {
        continue;
      }

      Map<String, dynamic>? attributes;

      if (op['attributes'] is Map) {
        attributes = Map<String, dynamic>.from(op['attributes'] as Map);
      }

      if (insert is String) {
        if (insert.isEmpty) continue;

        spans.add(
          TextSpan(
            text: insert,
            style: _styleFromAttributes(attributes),
          ),
        );

        continue;
      }

      spans.add(
        TextSpan(
          text: ' [Element] ',
          style: _baseStyle().copyWith(
            color: _ensureReadableColor(
              resolvedTheme.themeColor,
              textColor,
            ),
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final spans = _buildSpans();

    if (spans.isEmpty) {
      return SelectableText(
        placeholder.isEmpty ? ' ' : placeholder,
        style: _baseStyle().copyWith(
          color: placeholderColor,
        ),
      );
    }

    return SelectableText.rich(
      TextSpan(
        style: _baseStyle(),
        children: spans,
      ),
      textAlign: TextAlign.left,
    );
  }
}

class _PagedQuillPageEditor extends StatefulWidget {
  final int pageIndex;
  final Delta delta;
  final DocumentPageSetup pageSetup;
  final ThemeColors resolvedTheme;
  final bool whitePaperMode;
  final String placeholder;
  final Color textColor;
  final Color placeholderColor;

  final void Function({
    required int pageIndex,
    required Delta delta,
    required TextSelection localSelection,
  }) onChanged;

  const _PagedQuillPageEditor({
    super.key,
    required this.pageIndex,
    required this.delta,
    required this.pageSetup,
    required this.resolvedTheme,
    required this.whitePaperMode,
    required this.placeholder,
    required this.textColor,
    required this.placeholderColor,
    required this.onChanged,
  });

  @override
  State<_PagedQuillPageEditor> createState() => _PagedQuillPageEditorState();
}

class _PagedQuillPageEditorState extends State<_PagedQuillPageEditor> {
  late QuillController _controller;
  late ScrollController _scrollController;
  late FocusNode _focusNode;

  bool _disposed = false;
  bool _suppressListener = false;

  String _lastDocumentJson = '';
  TextSelection _lastSelection = const TextSelection.collapsed(offset: 0);

  static const String _safeFontFamily = 'Roboto';

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _focusNode = FocusNode(
      debugLabel: 'paged_quill_page_${widget.pageIndex}_focus',
      canRequestFocus: true,
    );

    final normalizedDelta = _DocumentPaginator.normalizePageDelta(widget.delta);

    _controller = QuillController(
      document: Document.fromDelta(normalizedDelta),
      selection: const TextSelection.collapsed(offset: 0),
    );

    _lastDocumentJson = jsonEncode(_controller.document.toDelta().toJson());

    _controller.addListener(_handleLocalChanged);
  }

  @override
  void didUpdateWidget(covariant _PagedQuillPageEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_disposed) return;

    final oldJson = jsonEncode(
      _DocumentPaginator.normalizePageDelta(oldWidget.delta).toJson(),
    );

    final newJson = jsonEncode(
      _DocumentPaginator.normalizePageDelta(widget.delta).toJson(),
    );

    if (oldJson == newJson) return;

    _replaceControllerDocument(
      _DocumentPaginator.normalizePageDelta(widget.delta),
      preserveSelection: true,
    );
  }

  @override
  void dispose() {
    _disposed = true;

    _controller.removeListener(_handleLocalChanged);
    _controller.dispose();

    _scrollController.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  void _replaceControllerDocument(
    Delta delta, {
    required bool preserveSelection,
  }) {
    if (_disposed) return;

    _suppressListener = true;

    try {
      final oldSelection = _controller.selection;

      _controller.document = Document.fromDelta(delta);

      final maxOffset = math.max(0, _controller.document.length - 1);

      final selection = preserveSelection && oldSelection.isValid
          ? TextSelection(
              baseOffset: oldSelection.baseOffset.clamp(0, maxOffset).toInt(),
              extentOffset:
                  oldSelection.extentOffset.clamp(0, maxOffset).toInt(),
              affinity: oldSelection.affinity,
              isDirectional: oldSelection.isDirectional,
            )
          : const TextSelection.collapsed(offset: 0);

      _controller.updateSelection(
        selection,
        ChangeSource.local,
      );

      _lastDocumentJson = jsonEncode(_controller.document.toDelta().toJson());
    } finally {
      _suppressListener = false;
    }
  }

  void _handleLocalChanged() {
    if (_disposed || _suppressListener) return;

    final currentDelta = _controller.document.toDelta();
    final currentJson = jsonEncode(currentDelta.toJson());
    final currentSelection = _controller.selection;

    if (currentJson == _lastDocumentJson) {
      // Content unchanged — only propagate if selection actually changed.
      if (currentSelection != _lastSelection) {
        _lastSelection = currentSelection;
        widget.onChanged(
          pageIndex: widget.pageIndex,
          delta: currentDelta,
          localSelection: currentSelection,
        );
      }
      return;
    }

    _lastDocumentJson = currentJson;
    _lastSelection = currentSelection;

    widget.onChanged(
      pageIndex: widget.pageIndex,
      delta: currentDelta,
      localSelection: currentSelection,
    );
  }

  TextStyle _style({
    required double fontSize,
    required double height,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
  }) {
    return TextStyle(
      color: color ?? widget.textColor,
      fontSize: fontSize,
      height: height,
      fontWeight: fontWeight,
      fontFamily: _safeFontFamily,
      decorationThickness: 1.5,
    );
  }

  DefaultStyles _buildStyles() {
    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(
        _style(
          fontSize: 11,
          height: 1.45,
          fontWeight: FontWeight.w400,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
      h1: DefaultTextBlockStyle(
        _style(
          fontSize: 22,
          height: 1.22,
          fontWeight: FontWeight.w900,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(18, 10),
        const VerticalSpacing(0, 0),
        null,
      ),
      h2: DefaultTextBlockStyle(
        _style(
          fontSize: 18,
          height: 1.28,
          fontWeight: FontWeight.w900,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(16, 8),
        const VerticalSpacing(0, 0),
        null,
      ),
      h3: DefaultTextBlockStyle(
        _style(
          fontSize: 15,
          height: 1.32,
          fontWeight: FontWeight.w800,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(14, 7),
        const VerticalSpacing(0, 0),
        null,
      ),
      placeHolder: DefaultTextBlockStyle(
        _style(
          fontSize: 11,
          height: 1.45,
          fontWeight: FontWeight.w400,
          color: widget.placeholderColor,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
    );
  }

  ThemeData _buildSafeQuillTheme(BuildContext context) {
    final base = Theme.of(context);

    final bg = widget.whitePaperMode
        ? Colors.white
        : widget.resolvedTheme.dashboardContainer;

    final fg = widget.whitePaperMode
        ? Colors.black
        : widget.resolvedTheme.textColor;

    final bodyStyle = _style(
      fontSize: 11,
      height: 1.45,
      fontWeight: FontWeight.w400,
      color: fg,
    );

    final titleStyle = _style(
      fontSize: 18,
      height: 1.25,
      fontWeight: FontWeight.w900,
      color: fg,
    );

    final textTheme = base.textTheme.copyWith(
      bodySmall: bodyStyle,
      bodyMedium: bodyStyle,
      bodyLarge: bodyStyle,
      labelSmall: bodyStyle,
      labelMedium: bodyStyle,
      labelLarge: bodyStyle,
      titleSmall: titleStyle,
      titleMedium: titleStyle,
      titleLarge: titleStyle,
      headlineSmall: titleStyle.copyWith(fontSize: 20),
      headlineMedium: titleStyle.copyWith(fontSize: 22),
      headlineLarge: titleStyle.copyWith(fontSize: 24),
      displaySmall: titleStyle.copyWith(fontSize: 26),
      displayMedium: titleStyle.copyWith(fontSize: 28),
      displayLarge: titleStyle.copyWith(fontSize: 30),
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      canvasColor: bg,
      cardColor: bg,
      scaffoldBackgroundColor: bg,
      colorScheme: base.colorScheme.copyWith(
        surface: bg,
        onSurface: fg,
        primary: widget.resolvedTheme.themeColor,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: widget.resolvedTheme.themeColor,
        selectionColor: widget.resolvedTheme.themeColor.withAlpha(75),
        selectionHandleColor: widget.resolvedTheme.themeColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Theme(
        data: _buildSafeQuillTheme(context),
        child: DefaultTextStyle(
          style: _style(
            fontSize: 11,
            height: 1.45,
            fontWeight: FontWeight.w400,
          ),
          child: IconTheme(
            data: IconThemeData(
              color: widget.textColor,
              size: 18,
            ),
            child: Material(
              color: Colors.transparent,
              child: QuillEditor(
                focusNode: _focusNode,
                scrollController: _scrollController,
                controller: _controller,
                config: QuillEditorConfig(
                  placeholder: widget.placeholder,
                  scrollable: false,
                  expands: false,
                  padding: EdgeInsets.zero,
                  showCursor: true,
                  autoFocus: false,
                  enableInteractiveSelection: true,
                  customStyles: _buildStyles(),
                  embedBuilders: [
                    DocumentPageBreakEmbedBuilder(
                      theme: widget.resolvedTheme,
                      pageSetup: widget.pageSetup,
                      whitePaperMode: widget.whitePaperMode,
                    ),
                    ...FlutterQuillEmbeds.editorBuilders(),
                    TimeStampEmbedBuilder(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentPageSlice {
  final int pageIndex;
  final Delta delta;
  final bool autoGenerated;

  const _DocumentPageSlice({
    required this.pageIndex,
    required this.delta,
    this.autoGenerated = false,
  });

  factory _DocumentPageSlice.empty(int index) {
    return _DocumentPageSlice(
      pageIndex: index,
      delta: Delta()..insert('\n'),
    );
  }

  int get documentLength {
    try {
      return Document.fromDelta(
        _DocumentPaginator.normalizePageDelta(delta),
      ).length;
    } catch (_) {
      return 1;
    }
  }

  _DocumentPageSlice copyWith({
    Delta? delta,
    bool? autoGenerated,
  }) {
    return _DocumentPageSlice(
      pageIndex: pageIndex,
      delta: delta ?? this.delta,
      autoGenerated: autoGenerated ?? this.autoGenerated,
    );
  }
}

class _DocumentPaginator {
  static List<_DocumentPageSlice> paginate({
    required Delta delta,
    required DocumentPageSetup pageSetup,
    required bool enableAutoPagination,
  }) {
    final maxContentHeight = math.max(
      1.0,
      pageSetup.heightPx - pageSetup.marginInsetsPx.vertical,
    );

    final contentWidth = math.max(
      1.0,
      pageSetup.widthPx - pageSetup.marginInsetsPx.horizontal,
    );

    final builder = _PageBuildState(
      pageIndex: 0,
      maxHeight: maxContentHeight,
      contentWidth: contentWidth,
      enableAutoPagination: enableAutoPagination,
    );

    final pages = <_DocumentPageSlice>[];

    void flushPage({
      bool force = false,
      bool autoGenerated = false,
    }) {
      if (!force && builder.isEmpty) return;

      pages.add(
        _DocumentPageSlice(
          pageIndex: pages.length,
          delta: normalizePageDelta(Delta.fromJson(builder.ops)),
          autoGenerated: autoGenerated,
        ),
      );

      builder.reset(pageIndex: pages.length);
    }

    for (final rawOp in delta.toJson()) {
      if (rawOp is! Map) continue;

      final op = Map<String, dynamic>.from(rawOp);
      final insert = op['insert'];
      final attributes = _readAttributes(op);

      if (DocumentPageBreakTools.isPageBreakInsert(insert)) {
        flushPage(force: true);
        continue;
      }

      if (insert is String) {
        _appendStringToPages(
          text: insert,
          attributes: attributes,
          builder: builder,
          pages: pages,
        );
        continue;
      }

      _appendEmbedToPages(
        insert: insert,
        attributes: attributes,
        builder: builder,
        pages: pages,
      );
    }

    flushPage(force: pages.isEmpty || !builder.isEmpty);

    for (var i = 0; i < pages.length; i++) {
      pages[i] = _DocumentPageSlice(
        pageIndex: i,
        delta: normalizePageDelta(pages[i].delta),
        autoGenerated: pages[i].autoGenerated,
      );
    }

    return pages;
  }

  static void _appendStringToPages({
    required String text,
    required Map<String, dynamic>? attributes,
    required _PageBuildState builder,
    required List<_DocumentPageSlice> pages,
  }) {
    if (text.isEmpty) return;

    final tokens = _splitTextKeepingNewLines(text);

    for (final token in tokens) {
      if (token.isEmpty) continue;

      final estimatedHeight = _estimateTextHeight(
        text: token,
        attributes: attributes,
        contentWidth: builder.contentWidth,
      );

      if (builder.shouldStartNewPage(estimatedHeight)) {
        pages.add(
          _DocumentPageSlice(
            pageIndex: pages.length,
            delta: normalizePageDelta(Delta.fromJson(builder.ops)),
            autoGenerated: true,
          ),
        );

        builder.reset(pageIndex: pages.length);
      }

      if (estimatedHeight > builder.maxHeight && token.trim().isNotEmpty) {
        final chunks = _splitLargeTextToken(
          text: token,
          attributes: attributes,
          contentWidth: builder.contentWidth,
          maxHeight: builder.maxHeight,
        );

        for (final chunk in chunks) {
          if (chunk.isEmpty) continue;

          final chunkHeight = _estimateTextHeight(
            text: chunk,
            attributes: attributes,
            contentWidth: builder.contentWidth,
          );

          if (builder.shouldStartNewPage(chunkHeight)) {
            pages.add(
              _DocumentPageSlice(
                pageIndex: pages.length,
                delta: normalizePageDelta(Delta.fromJson(builder.ops)),
                autoGenerated: true,
              ),
            );

            builder.reset(pageIndex: pages.length);
          }

          builder.addText(
            chunk,
            attributes: attributes,
            estimatedHeight: chunkHeight,
          );
        }

        continue;
      }

      builder.addText(
        token,
        attributes: attributes,
        estimatedHeight: estimatedHeight,
      );
    }
  }

  static void _appendEmbedToPages({
    required dynamic insert,
    required Map<String, dynamic>? attributes,
    required _PageBuildState builder,
    required List<_DocumentPageSlice> pages,
  }) {
    const estimatedHeight = 140.0;

    if (builder.shouldStartNewPage(estimatedHeight)) {
      pages.add(
        _DocumentPageSlice(
          pageIndex: pages.length,
          delta: normalizePageDelta(Delta.fromJson(builder.ops)),
          autoGenerated: true,
        ),
      );

      builder.reset(pageIndex: pages.length);
    }

    final op = <String, dynamic>{
      'insert': insert,
      if (attributes != null && attributes.isNotEmpty)
        'attributes': attributes,
    };

    builder.addOp(op, estimatedHeight: estimatedHeight);
  }

  static Delta normalizePageDelta(Delta delta) {
    final ops = <dynamic>[];

    for (final rawOp in delta.toJson()) {
      if (rawOp is! Map) continue;

      final op = Map<String, dynamic>.from(rawOp);
      final insert = op['insert'];

      if (DocumentPageBreakTools.isPageBreakInsert(insert)) {
        continue;
      }

      ops.add(op);
    }

    if (ops.isEmpty) {
      return Delta()..insert('\n');
    }

    final last = ops.last;

    if (last is Map && last['insert'] is String) {
      final text = last['insert'] as String;

      if (!text.endsWith('\n')) {
        last['insert'] = '$text\n';
      }
    } else {
      ops.add({'insert': '\n'});
    }

    return Delta.fromJson(ops);
  }

  static Delta composePages(List<_DocumentPageSlice> pages) {
    final ops = <dynamic>[];

    for (var i = 0; i < pages.length; i++) {
      final pageOps = _trimTrailingDocumentNewLine(pages[i].delta);
      ops.addAll(pageOps);

      if (i < pages.length - 1) {
        ops.add({'insert': '\n'});
        ops.add(DocumentPageBreakTools.pageBreakInsertOp());
        ops.add({'insert': '\n'});
      }
    }

    if (ops.isEmpty) {
      ops.add({'insert': '\n'});
    }

    final last = ops.last;

    if (last is Map && last['insert'] is String) {
      final text = last['insert'] as String;

      if (!text.endsWith('\n')) {
        last['insert'] = '$text\n';
      }
    } else {
      ops.add({'insert': '\n'});
    }

    return Delta.fromJson(ops);
  }

  static int globalOffsetForPage({
    required List<_DocumentPageSlice> pages,
    required int pageIndex,
  }) {
    var offset = 0;

    for (var i = 0; i < pageIndex && i < pages.length; i++) {
      final pageLength = _deltaLengthFromOps(
        _trimTrailingDocumentNewLine(pages[i].delta),
      );

      offset += pageLength + 3;
    }

    return offset;
  }

  static List<dynamic> _trimTrailingDocumentNewLine(Delta delta) {
    final ops = <dynamic>[];

    for (final rawOp in delta.toJson()) {
      if (rawOp is! Map) continue;
      ops.add(Map<String, dynamic>.from(rawOp));
    }

    if (ops.isEmpty) return ops;

    final last = ops.last;

    if (last is Map && last['insert'] is String) {
      final text = last['insert'] as String;

      if (text.endsWith('\n')) {
        final trimmed = text.substring(0, text.length - 1);

        if (trimmed.isEmpty) {
          ops.removeLast();
        } else {
          last['insert'] = trimmed;
        }
      }
    }

    return ops;
  }

  static int _deltaLengthFromOps(List<dynamic> ops) {
    var length = 0;

    for (final op in ops) {
      if (op is! Map) continue;

      final insert = op['insert'];

      if (insert is String) {
        length += insert.length;
      } else {
        length += 1;
      }
    }

    return length;
  }

  static Map<String, dynamic>? _readAttributes(Map<String, dynamic> op) {
    final attributes = op['attributes'];

    if (attributes is Map) {
      return Map<String, dynamic>.from(attributes);
    }

    return null;
  }

  static List<String> _splitTextKeepingNewLines(String text) {
    final result = <String>[];
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      buffer.write(char);

      if (char == '\n') {
        result.add(buffer.toString());
        buffer.clear();
      }
    }

    if (buffer.isNotEmpty) {
      result.add(buffer.toString());
    }

    return result;
  }

  static List<String> _splitLargeTextToken({
    required String text,
    required Map<String, dynamic>? attributes,
    required double contentWidth,
    required double maxHeight,
  }) {
    final fontSize = _fontSizeForAttributes(attributes);
    final lineHeight = _lineHeightForAttributes(attributes);
    final linePixelHeight = fontSize * lineHeight;

    final charsPerLine = math.max(
      8,
      (contentWidth / math.max(1.0, fontSize * 0.56)).floor(),
    );

    final maxLines = math.max(
      1,
      (maxHeight / math.max(1.0, linePixelHeight)).floor() - 1,
    );

    final maxChars = math.max(12, charsPerLine * maxLines);

    if (text.length <= maxChars) return [text];

    final chunks = <String>[];
    var remaining = text;

    while (remaining.length > maxChars) {
      var splitIndex = remaining.lastIndexOf(' ', maxChars);

      if (splitIndex < maxChars * 0.45) {
        splitIndex = maxChars;
      }

      chunks.add(remaining.substring(0, splitIndex));
      remaining = remaining.substring(splitIndex).trimLeft();
    }

    if (remaining.isNotEmpty) {
      chunks.add(remaining);
    }

    return chunks;
  }

  static double _estimateTextHeight({
    required String text,
    required Map<String, dynamic>? attributes,
    required double contentWidth,
  }) {
    if (text.isEmpty) return 0;

    final fontSize = _fontSizeForAttributes(attributes);
    final lineHeight = _lineHeightForAttributes(attributes);
    final visibleText = text.replaceAll('\n', '');

    final charsPerLine = math.max(
      8,
      (contentWidth / math.max(1.0, fontSize * 0.56)).floor(),
    );

    final explicitLines = '\n'.allMatches(text).length;

    final wrappedLines = visibleText.trim().isEmpty
        ? 1
        : math.max(
            1,
            (visibleText.length / charsPerLine).ceil(),
          );

    final lines = wrappedLines + explicitLines;

    final header = attributes?['header']?.toString();

    double extraSpacing = 0;

    if (header == '1') {
      extraSpacing = 24;
    } else if (header == '2') {
      extraSpacing = 20;
    } else if (header == '3') {
      extraSpacing = 16;
    }

    if (attributes?['list'] != null) {
      extraSpacing += 3;
    }

    return math.max(
      fontSize * lineHeight,
      lines * fontSize * lineHeight + extraSpacing,
    );
  }

  static double _fontSizeForAttributes(Map<String, dynamic>? attributes) {
    final header = attributes?['header']?.toString();

    if (header == '1') return 22;
    if (header == '2') return 18;
    if (header == '3') return 15;

    final rawSize = attributes?['size'];

    if (rawSize is num) {
      return rawSize.toDouble();
    }

    if (rawSize is String) {
      final parsed = double.tryParse(rawSize);
      if (parsed != null) return parsed;
    }

    return 11;
  }

  static double _lineHeightForAttributes(Map<String, dynamic>? attributes) {
    final rawLineHeight = attributes?['line-height'];

    if (rawLineHeight is num) {
      return rawLineHeight.toDouble();
    }

    if (rawLineHeight is String) {
      final parsed = double.tryParse(rawLineHeight);
      if (parsed != null) return parsed;
    }

    final header = attributes?['header']?.toString();

    if (header == '1') return 1.22;
    if (header == '2') return 1.28;
    if (header == '3') return 1.32;

    return 1.45;
  }
}

class _PageBuildState {
  int pageIndex;
  final double maxHeight;
  final double contentWidth;
  final bool enableAutoPagination;

  final List<dynamic> ops = [];
  double usedHeight = 0;

  _PageBuildState({
    required this.pageIndex,
    required this.maxHeight,
    required this.contentWidth,
    required this.enableAutoPagination,
  });

  bool get isEmpty {
    if (ops.isEmpty) return true;

    if (ops.length == 1 && ops.first is Map) {
      final insert = (ops.first as Map)['insert'];

      if (insert is String && insert.trim().isEmpty) {
        return true;
      }
    }

    return false;
  }

  bool shouldStartNewPage(double incomingHeight) {
    if (!enableAutoPagination) return false;
    if (isEmpty) return false;

    return usedHeight + incomingHeight > maxHeight;
  }

  void addText(
    String text, {
    required Map<String, dynamic>? attributes,
    required double estimatedHeight,
  }) {
    final op = <String, dynamic>{
      'insert': text,
      if (attributes != null && attributes.isNotEmpty)
        'attributes': attributes,
    };

    addOp(op, estimatedHeight: estimatedHeight);
  }

  void addOp(
    Map<String, dynamic> op, {
    required double estimatedHeight,
  }) {
    ops.add(op);
    usedHeight += estimatedHeight;
  }

  void reset({
    required int pageIndex,
  }) {
    this.pageIndex = pageIndex;
    ops.clear();
    usedHeight = 0;
  }
}