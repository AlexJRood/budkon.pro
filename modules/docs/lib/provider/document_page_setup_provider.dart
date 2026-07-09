import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DocumentPaperSize {
  a4,
  a5,
  letter,
  legal,
}

enum DocumentPageOrientation {
  portrait,
  landscape,
}

enum DocumentPaperPreviewMode {
  whitePaper,
  themePaper,
}

extension DocumentPaperPreviewModeX on DocumentPaperPreviewMode {
  bool get isWhitePaper => this == DocumentPaperPreviewMode.whitePaper;

  String get label {
    switch (this) {
      case DocumentPaperPreviewMode.whitePaper:
        return 'Biała kartka';
      case DocumentPaperPreviewMode.themePaper:
        return 'Theme';
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentPaperPreviewMode.whitePaper:
        return Icons.article_outlined;
      case DocumentPaperPreviewMode.themePaper:
        return Icons.dark_mode_outlined;
    }
  }
}

class DocumentPaperSizeSpec {
  final String label;
  final double widthMm;
  final double heightMm;

  const DocumentPaperSizeSpec({
    required this.label,
    required this.widthMm,
    required this.heightMm,
  });
}

extension DocumentPaperSizeX on DocumentPaperSize {
  DocumentPaperSizeSpec get spec {
    switch (this) {
      case DocumentPaperSize.a4:
        return const DocumentPaperSizeSpec(
          label: 'A4',
          widthMm: 210,
          heightMm: 297,
        );

      case DocumentPaperSize.a5:
        return const DocumentPaperSizeSpec(
          label: 'A5',
          widthMm: 148,
          heightMm: 210,
        );

      case DocumentPaperSize.letter:
        return const DocumentPaperSizeSpec(
          label: 'Letter',
          widthMm: 215.9,
          heightMm: 279.4,
        );

      case DocumentPaperSize.legal:
        return const DocumentPaperSizeSpec(
          label: 'Legal',
          widthMm: 215.9,
          heightMm: 355.6,
        );
    }
  }
}

class DocumentPageMargins {
  final double topMm;
  final double rightMm;
  final double bottomMm;
  final double leftMm;

  const DocumentPageMargins({
    required this.topMm,
    required this.rightMm,
    required this.bottomMm,
    required this.leftMm,
  });

  static const wordDefault = DocumentPageMargins(
    topMm: 25.4,
    rightMm: 25.4,
    bottomMm: 25.4,
    leftMm: 25.4,
  );

  DocumentPageMargins copyWith({
    double? topMm,
    double? rightMm,
    double? bottomMm,
    double? leftMm,
  }) {
    return DocumentPageMargins(
      topMm: topMm ?? this.topMm,
      rightMm: rightMm ?? this.rightMm,
      bottomMm: bottomMm ?? this.bottomMm,
      leftMm: leftMm ?? this.leftMm,
    );
  }
}

class DocumentPageSetup {
  final DocumentPaperSize paperSize;
  final DocumentPageOrientation orientation;
  final DocumentPageMargins margins;

  const DocumentPageSetup({
    required this.paperSize,
    required this.orientation,
    required this.margins,
  });

  static const double previewDpi = 96;
  static const double typographicDpi = 72;

  /// 12 pt w typografii powinno wyglądać jak 16 logical px w preview.
  static const double editorTextScale = previewDpi / typographicDpi;

  static const a4Default = DocumentPageSetup(
    paperSize: DocumentPaperSize.a4,
    orientation: DocumentPageOrientation.portrait,
    margins: DocumentPageMargins.wordDefault,
  );

  DocumentPageSetup copyWith({
    DocumentPaperSize? paperSize,
    DocumentPageOrientation? orientation,
    DocumentPageMargins? margins,
  }) {
    return DocumentPageSetup(
      paperSize: paperSize ?? this.paperSize,
      orientation: orientation ?? this.orientation,
      margins: margins ?? this.margins,
    );
  }

  double get widthMm {
    final spec = paperSize.spec;

    if (orientation == DocumentPageOrientation.landscape) {
      return spec.heightMm;
    }

    return spec.widthMm;
  }

  double get heightMm {
    final spec = paperSize.spec;

    if (orientation == DocumentPageOrientation.landscape) {
      return spec.widthMm;
    }

    return spec.heightMm;
  }

  double get widthPx => mmToPreviewPx(widthMm);
  double get heightPx => mmToPreviewPx(heightMm);

  double get contentWidthPx {
    final value = widthPx -
        mmToPreviewPx(margins.leftMm) -
        mmToPreviewPx(margins.rightMm);

    return math.max(1, value);
  }

  double get contentHeightPx {
    final value = heightPx -
        mmToPreviewPx(margins.topMm) -
        mmToPreviewPx(margins.bottomMm);

    return math.max(1, value);
  }

  EdgeInsets get marginInsetsPx {
    return EdgeInsets.fromLTRB(
      mmToPreviewPx(margins.leftMm),
      mmToPreviewPx(margins.topMm),
      mmToPreviewPx(margins.rightMm),
      mmToPreviewPx(margins.bottomMm),
    );
  }

  static double mmToPreviewPx(double mm) {
    return mm / 25.4 * previewDpi;
  }

  static double ptToPreviewPx(double pt) {
    return pt * editorTextScale;
  }

  static double previewPxToPt(double px) {
    return px / editorTextScale;
  }
}

class DocumentPageSetupNotifier extends StateNotifier<DocumentPageSetup> {
  DocumentPageSetupNotifier() : super(DocumentPageSetup.a4Default);

  void update(DocumentPageSetup setup) {
    state = setup;
  }

  void resetToA4() {
    state = DocumentPageSetup.a4Default;
  }
}

final documentPageSetupProvider =
    StateNotifierProvider<DocumentPageSetupNotifier, DocumentPageSetup>(
  (ref) => DocumentPageSetupNotifier(),
);

final documentPaperPreviewModeProvider =
    StateProvider<DocumentPaperPreviewMode>(
  (ref) => DocumentPaperPreviewMode.whitePaper,
);