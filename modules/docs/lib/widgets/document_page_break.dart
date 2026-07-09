import 'dart:convert';
import 'dart:math' as math;

import 'package:docs/provider/document_page_setup_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:core/theme/apptheme.dart';

class DocumentPageBreakEmbed extends CustomBlockEmbed {
  const DocumentPageBreakEmbed()
      : super(
          DocumentPageBreakTools.embedType,
          '{"kind":"page_break"}',
        );
}

class DocumentPageBreakTools {
  static const String embedType = 'document_page_break';

  static final RegExp legacyTextRegex = RegExp(
    r'(\n\s*)?---\s*PAGE\s*BREAK\s*---(\s*\n)?',
    caseSensitive: false,
    multiLine: true,
  );

  static int insertAtSelection(QuillController controller) {
    final selection = controller.selection;
    final documentLength = controller.document.length;
    final safeEndIndex = math.max(0, documentLength - 1);

    final hasValidSelection =
        selection.isValid && selection.start >= 0 && selection.end >= 0;

    final start = hasValidSelection
        ? selection.start.clamp(0, safeEndIndex).toInt()
        : safeEndIndex;

    final length = hasValidSelection && !selection.isCollapsed
        ? (selection.end - selection.start).abs()
        : 0;

    return insertAtIndex(
      controller,
      start,
      replaceLength: length,
      preserveSelection: false,
    );
  }

  static int insertAtIndex(
    QuillController controller,
    int index, {
    int replaceLength = 0,
    bool preserveSelection = false,
  }) {
    final documentLength = controller.document.length;
    final safeEndIndex = math.max(0, documentLength - 1);
    final safeIndex = index.clamp(0, safeEndIndex).toInt();

    final oldSelection = controller.selection;

    controller.replaceText(
      safeIndex,
      replaceLength,
      '\n',
      TextSelection.collapsed(offset: safeIndex + 1),
    );

    controller.replaceText(
      safeIndex + 1,
      0,
      const DocumentPageBreakEmbed(),
      TextSelection.collapsed(offset: safeIndex + 2),
    );

    controller.replaceText(
      safeIndex + 2,
      0,
      '\n\n',
      TextSelection.collapsed(offset: safeIndex + 3),
    );

    final maxCursorOffset = math.max(0, controller.document.length - 1);

    // IMPORTANT:
    // Cursor goes to safeIndex + 3, not +4.
    // +3 is the first normal writable paragraph after the page break.
    final caretOffset = (safeIndex + 3)
        .clamp(0, maxCursorOffset)
        .toInt();

    if (!preserveSelection || !oldSelection.isValid) {
      controller.updateSelection(
        TextSelection.collapsed(offset: caretOffset),
        ChangeSource.local,
      );

      return caretOffset;
    }

    const insertedLength = 4;

    int shiftOffset(int value) {
      if (value < safeIndex) return value;

      return (value + insertedLength - replaceLength)
          .clamp(0, maxCursorOffset)
          .toInt();
    }

    final newSelection = TextSelection(
      baseOffset: shiftOffset(oldSelection.baseOffset),
      extentOffset: shiftOffset(oldSelection.extentOffset),
      affinity: oldSelection.affinity,
      isDirectional: oldSelection.isDirectional,
    );

    controller.updateSelection(newSelection, ChangeSource.local);

    return newSelection.extentOffset;
  }

  static bool isPageBreakInsert(dynamic insert) {
    return _isPageBreakInsert(insert);
  }

  /// Flutter Quill CustomBlockEmbed expects:
  ///
  /// {
  ///   "insert": {
  ///     "custom": "{\"type\":\"document_page_break\",\"data\":\"...\"}"
  ///   }
  /// }
  ///
  /// NOT:
  ///
  /// {
  ///   "insert": {
  ///     "custom": {
  ///       "type": "document_page_break",
  ///       "data": ""
  ///     }
  ///   }
  /// }
  static String pageBreakCustomEmbedDataString() {
    return jsonEncode({
      'type': embedType,
      'data': '{"kind":"page_break"}',
    });
  }

  static Map<String, dynamic> pageBreakInsertOp() {
    return {
      'insert': {
        'custom': pageBreakCustomEmbedDataString(),
      },
    };
  }

  static dynamic normalizePageBreakInsertForQuill(dynamic insert) {
    if (!_isPageBreakInsert(insert)) {
      return insert;
    }

    return {
      'custom': pageBreakCustomEmbedDataString(),
    };
  }

  static int countInDelta(Delta delta) {
    var count = 0;

    for (final op in delta.toJson()) {
      if (op is! Map) continue;

      final insert = op['insert'];

      if (insert is String) {
        count += legacyTextRegex.allMatches(insert).length;
        continue;
      }

      if (_isPageBreakInsert(insert)) {
        count++;
      }
    }

    return count;
  }

  static int _deltaDocumentLength(Delta delta) {
    var length = 0;

    for (final op in delta.toJson()) {
      if (op is! Map) continue;

      final insert = op['insert'];
      length += insert is String ? insert.length : 1;
    }

    return math.max(0, length);
  }

  static List<int> breakOffsetsInDelta(Delta delta) {
    final offsets = <int>[];
    var cursor = 0;

    for (final op in delta.toJson()) {
      if (op is! Map) continue;

      final insert = op['insert'];

      if (insert is String) {
        for (final match in legacyTextRegex.allMatches(insert)) {
          offsets.add(cursor + match.start);
        }

        cursor += insert.length;
        continue;
      }

      if (_isPageBreakInsert(insert)) {
        offsets.add(cursor);
      }

      cursor += 1;
    }

    offsets.sort();
    return offsets;
  }

  static bool isOffsetOnPageBreakCursorZone(
    Delta delta,
    int offset,
  ) {
    if (offset < 0) return false;

    final breakOffsets = breakOffsetsInDelta(delta);

    for (final breakOffset in breakOffsets) {
      // breakOffset     = embed position
      // breakOffset + 1 = position directly after embed
      // breakOffset + 2 = first newline after embed
      //
      // All 3 positions are visually unstable for a collapsed caret.
      // The first normal writable paragraph after the page break is +3.
      if (offset >= breakOffset && offset <= breakOffset + 2) {
        return true;
      }
    }

    return false;
  }

  static bool selectionTouchesPageBreakCursorZone(
    Delta delta,
    TextSelection selection,
  ) {
    if (!selection.isValid) return false;

    // IMPORTANT:
    // Expanded selections must be allowed to cross page breaks.
    // Otherwise Ctrl+A and mouse range selection are broken.
    if (!selection.isCollapsed) {
      return false;
    }

    return isOffsetOnPageBreakCursorZone(delta, selection.baseOffset);
  }

  static int normalizeCaretOffsetAwayFromPageBreak(
    Delta delta,
    int offset, {
    bool preferAfter = true,
  }) {
    if (offset < 0) return offset;

    final breakOffsets = breakOffsetsInDelta(delta);
    final maxOffset = math.max(0, _deltaDocumentLength(delta) - 1);

    for (final breakOffset in breakOffsets) {
      final dangerStart = breakOffset;
      final dangerEnd = breakOffset + 2;

      if (offset >= dangerStart && offset <= dangerEnd) {
        // +3 is the first normal writable paragraph after the page break.
        final normalized = preferAfter ? breakOffset + 3 : breakOffset - 1;

        return normalized.clamp(0, maxOffset).toInt();
      }
    }

    return offset.clamp(0, maxOffset).toInt();
  }

  static TextSelection normalizeSelectionAwayFromPageBreak(
    Delta delta,
    TextSelection selection, {
    bool preferAfter = true,
  }) {
    if (!selection.isValid) return selection;

    // IMPORTANT:
    // Never collapse real text selections.
    // Ctrl+A and drag selection need to stay untouched.
    if (!selection.isCollapsed) {
      return selection;
    }

    if (!isOffsetOnPageBreakCursorZone(delta, selection.baseOffset)) {
      return selection;
    }

    final normalizedOffset = normalizeCaretOffsetAwayFromPageBreak(
      delta,
      selection.baseOffset,
      preferAfter: preferAfter,
    );

    return TextSelection.collapsed(
      offset: normalizedOffset,
      affinity: selection.affinity,
    );
  }

  static bool hasPageBreakNearOffset(
    Delta delta,
    int offset, {
    int distance = 4,
  }) {
    final offsets = breakOffsetsInDelta(delta);

    for (final breakOffset in offsets) {
      if ((breakOffset - offset).abs() <= distance) {
        return true;
      }
    }

    return false;
  }

  static int countBeforeOffset(Delta delta, int offset) {
    var count = 0;
    var cursor = 0;

    for (final op in delta.toJson()) {
      if (op is! Map) continue;

      final insert = op['insert'];
      final length = insert is String ? insert.length : 1;
      final nextCursor = cursor + length;

      if (nextCursor > offset) {
        if (insert is String) {
          final localEnd = (offset - cursor).clamp(0, insert.length).toInt();
          final fragment = insert.substring(0, localEnd);
          count += legacyTextRegex.allMatches(fragment).length;
        }

        break;
      }

      if (insert is String) {
        count += legacyTextRegex.allMatches(insert).length;
      } else if (_isPageBreakInsert(insert)) {
        count++;
      }

      cursor = nextCursor;
    }

    return count;
  }

  static bool _isPageBreakInsert(dynamic insert) {
    if (insert is Map) {
      if (insert.containsKey(embedType)) return true;

      final type = insert['type']?.toString();
      if (type == embedType) return true;

      final custom = insert['custom'];

      if (custom is Map) {
        if (custom.containsKey(embedType)) return true;
        if (custom['type']?.toString() == embedType) return true;
      }

      if (custom is String) {
        if (custom.contains(embedType)) return true;

        try {
          final decoded = jsonDecode(custom);

          if (decoded is Map && decoded['type']?.toString() == embedType) {
            return true;
          }
        } catch (_) {
          // Ignore invalid custom JSON.
        }
      }

      for (final value in insert.values) {
        if (value is Map && value['type']?.toString() == embedType) {
          return true;
        }

        if (value is String && value.contains(embedType)) {
          return true;
        }
      }
    }

    if (insert is String) {
      return legacyTextRegex.hasMatch(insert);
    }

    return false;
  }
}

class DocumentPageBreakLayoutScope extends InheritedWidget {
  final GlobalKey contentOriginKey;
  final DocumentPageSetup pageSetup;
  final double pageGap;
  final int layoutRevision;

  const DocumentPageBreakLayoutScope({
    super.key,
    required this.contentOriginKey,
    required this.pageSetup,
    required this.pageGap,
    required this.layoutRevision,
    required super.child,
  });

  static DocumentPageBreakLayoutScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DocumentPageBreakLayoutScope>();
  }

  @override
  bool updateShouldNotify(DocumentPageBreakLayoutScope oldWidget) {
    return contentOriginKey != oldWidget.contentOriginKey ||
        pageSetup != oldWidget.pageSetup ||
        pageGap != oldWidget.pageGap ||
        layoutRevision != oldWidget.layoutRevision;
  }
}

class DocumentPageBreakEmbedBuilder extends EmbedBuilder {
  final ThemeColors theme;
  final DocumentPageSetup? pageSetup;
  final bool whitePaperMode;

  const DocumentPageBreakEmbedBuilder({
    required this.theme,
    this.pageSetup,
    this.whitePaperMode = true,
  });

  @override
  String get key => DocumentPageBreakTools.embedType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    return DocumentPageBreakWidget(
      theme: theme,
      pageSetup: pageSetup,
      whitePaperMode: whitePaperMode,
    );
  }

  @override
  String toPlainText(Embed node) {
    return '\n--- PAGE BREAK ---\n';
  }
}

class DocumentPageBreakWidget extends StatefulWidget {
  final ThemeColors theme;
  final DocumentPageSetup? pageSetup;
  final bool whitePaperMode;

  const DocumentPageBreakWidget({
    super.key,
    required this.theme,
    this.pageSetup,
    this.whitePaperMode = true,
  });

  @override
  State<DocumentPageBreakWidget> createState() =>
      _DocumentPageBreakWidgetState();
}

class _DocumentPageBreakWidgetState extends State<DocumentPageBreakWidget> {
  double _height = 1;
  int? _lastLayoutRevision;
  double? _lastPageStride;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final scope = DocumentPageBreakLayoutScope.maybeOf(context);
    _applyTemporarySafeHeightIfNeeded(scope);
    _scheduleHeightUpdate();
  }

  @override
  void didUpdateWidget(covariant DocumentPageBreakWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final scope = DocumentPageBreakLayoutScope.maybeOf(context);
    _applyTemporarySafeHeightIfNeeded(scope);
    _scheduleHeightUpdate();
  }

  void _applyTemporarySafeHeightIfNeeded(
    DocumentPageBreakLayoutScope? scope,
  ) {
    if (scope == null) return;

    final pageStride = scope.pageSetup.heightPx + scope.pageGap;
    if (pageStride <= 0 || !pageStride.isFinite) return;

    final revisionChanged = _lastLayoutRevision != scope.layoutRevision;
    final strideChanged =
        _lastPageStride == null || (_lastPageStride! - pageStride).abs() > 0.5;

    if (!revisionChanged && !strideChanged) {
      return;
    }

    _lastLayoutRevision = scope.layoutRevision;
    _lastPageStride = pageStride;

    // Anti-flicker guard:
    // after pressing Enter above an existing page break, the old spacer height
    // can be too small for one frame. A full page stride is visually safe,
    // because it hides the next-page text until the exact height is recalculated.
    _height = pageStride.toDouble();
  }

  void _scheduleHeightUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateHeightFromLayout();
    });
  }

  void _updateHeightFromLayout() {
    final scope = DocumentPageBreakLayoutScope.maybeOf(context);
    if (scope == null) {
      if (_height != 1) {
        setState(() {
          _height = 1;
        });
      }
      return;
    }

    final originContext = scope.contentOriginKey.currentContext;
    final originRender = originContext?.findRenderObject();
    final currentRender = context.findRenderObject();

    if (originRender is! RenderBox || currentRender is! RenderBox) {
      return;
    }

    if (!originRender.hasSize || !currentRender.hasSize) {
      return;
    }

    final originGlobal = originRender.localToGlobal(Offset.zero);
    final currentGlobal = currentRender.localToGlobal(Offset.zero);

    final yInContent = currentGlobal.dy - originGlobal.dy;
    if (!yInContent.isFinite) return;

    final pageStride = scope.pageSetup.heightPx + scope.pageGap;
    if (pageStride <= 0) return;

    final normalizedY = yInContent % pageStride;

    final calculatedHeight = (pageStride - normalizedY).clamp(
      1.0,
      pageStride,
    );

    if ((calculatedHeight - _height).abs() < 1) {
      return;
    }

    setState(() {
      _height = calculatedHeight.toDouble();
      _lastPageStride = pageStride;
      _lastLayoutRevision = scope.layoutRevision;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: ExcludeSemantics(
        child: SizedBox(
          height: _height,

          // IMPORTANT:
          // Do not use double.infinity here.
          // A full-width page-break embed can be painted/selected by Quill
          // as a large filled block between pages.
          //
          // A tiny width still contributes vertical layout height,
          // but visually behaves like empty space.
          width: 0.01,
        ),
      ),
    );
  }
}