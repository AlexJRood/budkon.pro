import 'dart:typed_data';

import 'package:docs/provider/document_page_setup_provider.dart';
import 'package:docs/widgets/document_page_break.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:docs/platforms/pdf_download_stub.dart'
    if (dart.library.html) 'package:docs/platforms/pdf_download_web.dart';

import 'package:docs/widgets/document_exporter_platform.dart';

class DocumentExporter {
  static String _sanitizeFileName(String name) {
    final sanitized = name
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (sanitized.isEmpty) {
      return 'document';
    }

    return sanitized;
  }

  static PdfPageFormat _pdfPageFormat(DocumentPageSetup pageSetup) {
    return PdfPageFormat(
      pageSetup.widthMm * PdfPageFormat.mm,
      pageSetup.heightMm * PdfPageFormat.mm,
      marginTop: pageSetup.margins.topMm * PdfPageFormat.mm,
      marginRight: pageSetup.margins.rightMm * PdfPageFormat.mm,
      marginBottom: pageSetup.margins.bottomMm * PdfPageFormat.mm,
      marginLeft: pageSetup.margins.leftMm * PdfPageFormat.mm,
    );
  }

  static pw.EdgeInsets _pdfMargins(DocumentPageSetup pageSetup) {
    return pw.EdgeInsets.fromLTRB(
      pageSetup.margins.leftMm * PdfPageFormat.mm,
      pageSetup.margins.topMm * PdfPageFormat.mm,
      pageSetup.margins.rightMm * PdfPageFormat.mm,
      pageSetup.margins.bottomMm * PdfPageFormat.mm,
    );
  }

  static Future<String?> exportToPdfFromController({
    required QuillController controller,
    required String title,
    DocumentPageSetup pageSetup = DocumentPageSetup.a4Default,
    bool includeGeneratedFooter = true,
  }) async {
    try {
      final bytes = await exportToPdfBytesFromController(
        controller: controller,
        title: title,
        pageSetup: pageSetup,
        includeGeneratedFooter: includeGeneratedFooter,
      );

      final safeName = '${_sanitizeFileName(title)}.pdf';

      final downloaded = downloadPdfOnWeb(bytes, safeName);
      if (downloaded) return null;

      final fileName =
          '${_sanitizeFileName(title)}-${DateTime.now().millisecondsSinceEpoch}.pdf';

      return saveOrDownloadPdf(bytes: bytes, fileName: fileName);
    } catch (e, stackTrace) {
      debugPrint('PDF generation failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  static Future<void> printFromController({
    required QuillController controller,
    required String title,
    DocumentPageSetup pageSetup = DocumentPageSetup.a4Default,
    bool includeGeneratedFooter = true,
  }) async {
    final bytes = await exportToPdfBytesFromController(
      controller: controller,
      title: title,
      pageSetup: pageSetup,
      includeGeneratedFooter: includeGeneratedFooter,
    );

    await Printing.layoutPdf(
      name: '${_sanitizeFileName(title)}.pdf',
      format: _pdfPageFormat(pageSetup),
      onLayout: (_) async => bytes,
    );
  }

  static Future<Uint8List> exportToPdfBytesFromController({
    required QuillController controller,
    required String title,
    DocumentPageSetup pageSetup = DocumentPageSetup.a4Default,
    bool includeGeneratedFooter = true,
  }) async {
    final pdf = pw.Document(
      title: title,
      author: 'Hously',
      creator: 'Hously Docs',
      producer: 'Hously Docs',
    );

    final blocks = _parseControllerBlocks(controller);

    final widgets = <pw.Widget>[];
    var orderedListIndex = 1;

    for (final block in blocks) {
      if (block is _PdfPageBreakBlock) {
        widgets.add(pw.NewPage());
        orderedListIndex = 1;
        continue;
      }

      if (block is _PdfLineBlock) {
        final listType = block.line.listType;

        if (listType == 'ordered') {
          widgets.add(
            _buildLineWidget(
              block.line,
              orderedListIndex: orderedListIndex,
            ),
          );
          orderedListIndex++;
        } else {
          widgets.add(_buildLineWidget(block.line));
          orderedListIndex = 1;
        }
      }
    }

    if (widgets.isEmpty) {
      widgets.add(pw.SizedBox(height: 1));
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: _pdfPageFormat(pageSetup),
        margin: _pdfMargins(pageSetup),
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        footer: includeGeneratedFooter
            ? (context) {
                return pw.Container(
                  alignment: pw.Alignment.centerRight,
                  margin: const pw.EdgeInsets.only(top: 10),
                  child: pw.Text(
                    'Generated on ${DateTime.now().toString().substring(0, 19)}'
                    ' · ${context.pageNumber}/${context.pagesCount}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                );
              }
            : null,
        build: (_) => widgets,
      ),
    );

    return pdf.save();
  }

  static List<_PdfBlock> _parseControllerBlocks(QuillController controller) {
    final delta = controller.document.toDelta();
    final blocks = <_PdfBlock>[];

    var currentSegments = <_PdfTextSegment>[];

    void flushLine(Map<String, dynamic> blockAttributes) {
      blocks.add(
        _PdfLineBlock(
          _PdfLine(
            segments: List<_PdfTextSegment>.from(currentSegments),
            blockAttributes: Map<String, dynamic>.from(blockAttributes),
          ),
        ),
      );

      currentSegments = <_PdfTextSegment>[];
    }

    void addTextSegment(String text, Map<String, dynamic> attributes) {
      if (text.isEmpty) return;

      currentSegments.add(
        _PdfTextSegment(
          text: text,
          attributes: Map<String, dynamic>.from(attributes),
        ),
      );
    }

    void processPlainText(
      String text,
      Map<String, dynamic> attributes,
    ) {
      if (text.isEmpty) return;

      final parts = text.split('\n');

      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];

        if (part.isNotEmpty) {
          addTextSegment(part, attributes);
        }

        final isLineEnd = i < parts.length - 1;
        if (isLineEnd) {
          flushLine(attributes);
        }
      }
    }

    void processTextWithLegacyPageBreaks(
      String text,
      Map<String, dynamic> attributes,
    ) {
      final matches =
          DocumentPageBreakTools.legacyTextRegex.allMatches(text).toList();

      if (matches.isEmpty) {
        processPlainText(text, attributes);
        return;
      }

      var cursor = 0;

      for (final match in matches) {
        final before = text.substring(cursor, match.start);

        if (before.isNotEmpty) {
          processPlainText(before, attributes);
        }

        if (currentSegments.isNotEmpty) {
          flushLine(<String, dynamic>{});
        }

        blocks.add(const _PdfPageBreakBlock());
        cursor = match.end;
      }

      final after = text.substring(cursor);

      if (after.isNotEmpty) {
        processPlainText(after, attributes);
      }
    }

    for (final rawOp in delta.toJson()) {
      if (rawOp is! Map) continue;

      final op = Map<String, dynamic>.from(rawOp);
      final insert = op['insert'];
      final attributes = _normalizeAttributes(op['attributes']);

      if (_isPageBreakInsert(insert)) {
        if (currentSegments.isNotEmpty) {
          flushLine(<String, dynamic>{});
        }

        blocks.add(const _PdfPageBreakBlock());
        continue;
      }

      if (insert is String) {
        processTextWithLegacyPageBreaks(insert, attributes);
        continue;
      }

      if (insert is Map) {
        final placeholder = _placeholderForUnknownEmbed(insert);

        if (placeholder != null) {
          addTextSegment(
            placeholder,
            {
              ...attributes,
              'italic': true,
              'color': '#777777',
            },
          );
        }
      }
    }

    if (currentSegments.isNotEmpty || blocks.isEmpty) {
      flushLine(<String, dynamic>{});
    }

    return blocks;
  }

  static Map<String, dynamic> _normalizeAttributes(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  static bool _isPageBreakInsert(dynamic insert) {
    if (insert is String) {
      return DocumentPageBreakTools.legacyTextRegex.hasMatch(insert);
    }

    if (insert is! Map) return false;

    if (insert.containsKey(DocumentPageBreakTools.embedType)) {
      return true;
    }

    final type = insert['type']?.toString();
    if (type == DocumentPageBreakTools.embedType) {
      return true;
    }

    final custom = insert['custom'];

    if (custom is Map) {
      if (custom.containsKey(DocumentPageBreakTools.embedType)) {
        return true;
      }

      if (custom['type']?.toString() == DocumentPageBreakTools.embedType) {
        return true;
      }
    }

    if (custom is String && custom.contains(DocumentPageBreakTools.embedType)) {
      return true;
    }

    for (final value in insert.values) {
      if (value is Map &&
          value['type']?.toString() == DocumentPageBreakTools.embedType) {
        return true;
      }

      if (value is String && value.contains(DocumentPageBreakTools.embedType)) {
        return true;
      }
    }

    return false;
  }

  static String? _placeholderForUnknownEmbed(Map<dynamic, dynamic> insert) {
    if (insert.containsKey('image')) {
      return '[Image]';
    }

    if (insert.containsKey('video')) {
      return '[Video]';
    }

    if (insert.containsKey('formula')) {
      return '[Formula]';
    }

    if (insert.containsKey('custom')) {
      return '[Embedded content]';
    }

    return null;
  }

  static pw.Widget _buildLineWidget(
    _PdfLine line, {
    int? orderedListIndex,
  }) {
    if (line.isEmpty) {
      return pw.SizedBox(height: 10);
    }

    final content = _buildRichText(line);
    final listType = line.listType;

    pw.Widget child = content;

    if (listType == 'bullet') {
      child = pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 16,
            child: pw.Text(
              '•',
              style: _baseTextStyle(line),
            ),
          ),
          pw.Expanded(child: content),
        ],
      );
    } else if (listType == 'ordered') {
      child = pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 22,
            child: pw.Text(
              '${orderedListIndex ?? 1}.',
              style: _baseTextStyle(line),
            ),
          ),
          pw.Expanded(child: content),
        ],
      );
    }

    if (line.isQuote) {
      return pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.symmetric(vertical: 4),
        padding: const pw.EdgeInsets.only(left: 10, top: 4, bottom: 4),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            left: pw.BorderSide(
              color: PdfColors.grey500,
              width: 2,
            ),
          ),
        ),
        child: child,
      );
    }

    if (line.isCodeBlock) {
      return pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.symmetric(vertical: 4),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey200,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: child,
      );
    }

    return pw.Padding(
      padding: _linePadding(line),
      child: child,
    );
  }

  static pw.EdgeInsets _linePadding(_PdfLine line) {
    if (line.headerLevel == 1) {
      return const pw.EdgeInsets.only(top: 14, bottom: 7);
    }

    if (line.headerLevel == 2) {
      return const pw.EdgeInsets.only(top: 12, bottom: 6);
    }

    if (line.headerLevel == 3) {
      return const pw.EdgeInsets.only(top: 10, bottom: 5);
    }

    return const pw.EdgeInsets.only(bottom: 4);
  }

  static pw.RichText _buildRichText(_PdfLine line) {
    return pw.RichText(
      textAlign: _textAlign(line),
      text: pw.TextSpan(
        children: line.segments.map((segment) {
          return pw.TextSpan(
            text: segment.text,
            style: _segmentTextStyle(
              segment,
              line: line,
            ),
          );
        }).toList(),
      ),
    );
  }

  static pw.TextStyle _baseTextStyle(_PdfLine line) {
    final headerLevel = line.headerLevel;

    double fontSize = 11;
    var fontWeight = pw.FontWeight.normal;

    if (headerLevel == 1) {
      fontSize = 22;
      fontWeight = pw.FontWeight.bold;
    } else if (headerLevel == 2) {
      fontSize = 18;
      fontWeight = pw.FontWeight.bold;
    } else if (headerLevel == 3) {
      fontSize = 15;
      fontWeight = pw.FontWeight.bold;
    }

    if (line.isCodeBlock) {
      fontSize = 10;
    }

    return pw.TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      lineSpacing: _lineSpacing(line),
      color: PdfColors.black,
    );
  }

  static pw.TextStyle _segmentTextStyle(
    _PdfTextSegment segment, {
    required _PdfLine line,
  }) {
    final attrs = segment.attributes;
    final base = _baseTextStyle(line);

    final fontSize = _readFontSize(attrs) ?? base.fontSize;
    final color = _readColor(attrs) ?? base.color;

    final isBold = attrs['bold'] == true || line.headerLevel != null;
    final isItalic = attrs['italic'] == true;
    final isUnderline = attrs['underline'] == true;

    return base.copyWith(
      fontSize: fontSize,
      color: color,
      fontWeight: isBold ? pw.FontWeight.bold : base.fontWeight,
      fontStyle: isItalic ? pw.FontStyle.italic : base.fontStyle,
      decoration:
          isUnderline ? pw.TextDecoration.underline : pw.TextDecoration.none,
    );
  }

  static double? _readFontSize(Map<String, dynamic> attrs) {
    final raw = attrs['size'];
    if (raw == null) return null;

    if (raw is num) {
      return raw.toDouble().clamp(4, 200).toDouble();
    }

    final parsed = double.tryParse(raw.toString().trim());
    if (parsed == null) return null;

    return parsed.clamp(4, 200).toDouble();
  }

  static PdfColor? _readColor(Map<String, dynamic> attrs) {
    final raw = attrs['color'];
    if (raw == null) return null;

    final text = raw.toString().replaceAll('#', '').trim();

    if (text.length != 6 && text.length != 8) {
      return null;
    }

    try {
      final start = text.length == 8 ? 2 : 0;

      final r = int.parse(text.substring(start, start + 2), radix: 16) / 255.0;
      final g =
          int.parse(text.substring(start + 2, start + 4), radix: 16) / 255.0;
      final b =
          int.parse(text.substring(start + 4, start + 6), radix: 16) / 255.0;

      return PdfColor(r, g, b);
    } catch (_) {
      return null;
    }
  }

  static double _lineSpacing(_PdfLine line) {
    final raw = line.blockAttributes['line-height'];

    if (raw == null) {
      if (line.headerLevel != null) return 2;
      return 3;
    }

    final parsed = double.tryParse(raw.toString());
    if (parsed == null) return 3;

    return (parsed * 2).clamp(0, 12).toDouble();
  }

  static pw.TextAlign _textAlign(_PdfLine line) {
    final raw = line.blockAttributes['align']?.toString();

    switch (raw) {
      case 'center':
        return pw.TextAlign.center;
      case 'right':
        return pw.TextAlign.right;
      case 'justify':
        return pw.TextAlign.justify;
      case 'left':
      default:
        return pw.TextAlign.left;
    }
  }
}

abstract class _PdfBlock {
  const _PdfBlock();
}

class _PdfPageBreakBlock extends _PdfBlock {
  const _PdfPageBreakBlock();
}

class _PdfLineBlock extends _PdfBlock {
  final _PdfLine line;

  const _PdfLineBlock(this.line);
}

class _PdfLine {
  final List<_PdfTextSegment> segments;
  final Map<String, dynamic> blockAttributes;

  const _PdfLine({
    required this.segments,
    required this.blockAttributes,
  });

  bool get isEmpty {
    if (segments.isEmpty) return true;

    return segments.every((segment) => segment.text.trim().isEmpty);
  }

  int? get headerLevel {
    final raw = blockAttributes[Attribute.header.key];

    if (raw == null) return null;

    if (raw is int) return raw;

    return int.tryParse(raw.toString());
  }

  String? get listType {
    final raw = blockAttributes[Attribute.list.key]?.toString();

    if (raw == Attribute.ul.value || raw == 'bullet') {
      return 'bullet';
    }

    if (raw == Attribute.ol.value || raw == 'ordered') {
      return 'ordered';
    }

    return null;
  }

  bool get isQuote {
    return blockAttributes['blockquote'] == true;
  }

  bool get isCodeBlock {
    return blockAttributes['code-block'] == true;
  }
}

class _PdfTextSegment {
  final String text;
  final Map<String, dynamic> attributes;

  const _PdfTextSegment({
    required this.text,
    required this.attributes,
  });
}