import 'package:docs/provider/docs_toolbar_provider.dart';
import 'package:docs/widgets/docs_quill_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'dart:ui' as ui;


class DocsMobileToolbarStrip extends ConsumerWidget {
  const DocsMobileToolbarStrip({super.key});

  static const double height = 56;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final toolbarState = ref.watch(docsToolbarProvider);

    if (toolbarState.controller == null) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 35, sigmaY: 35),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DocsQuillToolbar(
              controller: toolbarState.controller!,
              editorFocusNode: toolbarState.editorFocusNode!,
              resolvedTheme: theme,
              sidebarColor: theme.dashboardContainer,
              onMyDocumentPressed: toolbarState.onMyDocumentPressed,
              onCreateTemplatePressed: toolbarState.onCreateTemplatePressed,
              onGeneratePressed: toolbarState.onGeneratePressed,
            ),
          ),
        ),
      ),
    );
  }
}
