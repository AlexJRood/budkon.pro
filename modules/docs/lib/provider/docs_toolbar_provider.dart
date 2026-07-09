import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';

class DocsToolbarState {
  final QuillController? controller;
  final FocusNode? editorFocusNode;

  final VoidCallback? onMyDocumentPressed;
  final VoidCallback? onCreateTemplatePressed;
  final VoidCallback? onGeneratePressed;
  final VoidCallback? onSavePressed;
  final VoidCallback? onInsertPageBreakPressed;
  final VoidCallback? onOpenVersionsPressed;
  final VoidCallback? onOpenCommentsPressed;
  final VoidCallback? onOpenFillSessionPressed;

  final VoidCallback? onNewPagePressed;
  final VoidCallback? onPrintPressed;
  final VoidCallback? onPageSetupPressed;

  const DocsToolbarState({
    this.controller,
    this.editorFocusNode,
    this.onMyDocumentPressed,
    this.onCreateTemplatePressed,
    this.onGeneratePressed,
    this.onSavePressed,
    this.onInsertPageBreakPressed,
    this.onOpenVersionsPressed,
    this.onOpenCommentsPressed,
    this.onOpenFillSessionPressed,
    this.onNewPagePressed,
    this.onPrintPressed,
    this.onPageSetupPressed,
  });

  DocsToolbarState copyWith({
    QuillController? controller,
    FocusNode? editorFocusNode,
    VoidCallback? onMyDocumentPressed,
    VoidCallback? onCreateTemplatePressed,
    VoidCallback? onGeneratePressed,
    VoidCallback? onSavePressed,
    VoidCallback? onInsertPageBreakPressed,
    VoidCallback? onOpenVersionsPressed,
    VoidCallback? onOpenCommentsPressed,
    VoidCallback? onOpenFillSessionPressed,
    VoidCallback? onNewPagePressed,
    VoidCallback? onPrintPressed,
    VoidCallback? onPageSetupPressed,
  }) {
    return DocsToolbarState(
      controller: controller ?? this.controller,
      editorFocusNode: editorFocusNode ?? this.editorFocusNode,
      onMyDocumentPressed: onMyDocumentPressed ?? this.onMyDocumentPressed,
      onCreateTemplatePressed:
          onCreateTemplatePressed ?? this.onCreateTemplatePressed,
      onGeneratePressed: onGeneratePressed ?? this.onGeneratePressed,
      onSavePressed: onSavePressed ?? this.onSavePressed,
      onInsertPageBreakPressed:
          onInsertPageBreakPressed ?? this.onInsertPageBreakPressed,
      onOpenVersionsPressed:
          onOpenVersionsPressed ?? this.onOpenVersionsPressed,
      onOpenCommentsPressed:
          onOpenCommentsPressed ?? this.onOpenCommentsPressed,
      onOpenFillSessionPressed:
          onOpenFillSessionPressed ?? this.onOpenFillSessionPressed,
      onNewPagePressed: onNewPagePressed ?? this.onNewPagePressed,
      onPrintPressed: onPrintPressed ?? this.onPrintPressed,
      onPageSetupPressed: onPageSetupPressed ?? this.onPageSetupPressed,
    );
  }

  static const empty = DocsToolbarState();
}

class DocsToolbarNotifier extends StateNotifier<DocsToolbarState> {
  DocsToolbarNotifier() : super(DocsToolbarState.empty);

  void bind({
    required QuillController controller,
    required FocusNode editorFocusNode,
    VoidCallback? onMyDocumentPressed,
    VoidCallback? onCreateTemplatePressed,
    VoidCallback? onGeneratePressed,
    VoidCallback? onSavePressed,
    VoidCallback? onInsertPageBreakPressed,
    VoidCallback? onOpenVersionsPressed,
    VoidCallback? onOpenCommentsPressed,
    VoidCallback? onOpenFillSessionPressed,
    VoidCallback? onNewPagePressed,
    VoidCallback? onPrintPressed,
    VoidCallback? onPageSetupPressed,
  }) {
    state = DocsToolbarState(
      controller: controller,
      editorFocusNode: editorFocusNode,
      onMyDocumentPressed: onMyDocumentPressed,
      onCreateTemplatePressed: onCreateTemplatePressed,
      onGeneratePressed: onGeneratePressed,
      onSavePressed: onSavePressed,
      onInsertPageBreakPressed: onInsertPageBreakPressed,
      onOpenVersionsPressed: onOpenVersionsPressed,
      onOpenCommentsPressed: onOpenCommentsPressed,
      onOpenFillSessionPressed: onOpenFillSessionPressed,
      onNewPagePressed: onNewPagePressed,
      onPrintPressed: onPrintPressed,
      onPageSetupPressed: onPageSetupPressed,
    );
  }

  void clear() {
    state = DocsToolbarState.empty;
  }
}

final docsToolbarProvider =
    StateNotifierProvider<DocsToolbarNotifier, DocsToolbarState>(
  (ref) => DocsToolbarNotifier(),
);