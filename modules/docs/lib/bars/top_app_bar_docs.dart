import 'dart:ui' as ui;
import 'package:docs/provider/cloud_doc_provider.dart';
import 'package:docs/provider/docs_toolbar_provider.dart';
import 'package:docs/widgets/docs_quill_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:flutter/gestures.dart';

class TopAppBarDocs extends ConsumerWidget {
  const TopAppBarDocs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final toolbarState = ref.watch(docsToolbarProvider);
    final doc = ref.watch(documentProvider).valueOrNull;
    final isEditingTemplate = doc?.isEditingTemplate == true;
    if (isEditingTemplate) return const SizedBox.shrink();
    return SizedBox(
      height: 100,
      width: double.infinity,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 35, sigmaY: 35),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (toolbarState.controller != null)
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: ScrollConfiguration(
                        behavior: const _DragScrollBehavior(),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DocsQuillToolbar(
                            controller: toolbarState.controller!,
                            editorFocusNode: toolbarState.editorFocusNode!,
                            resolvedTheme: theme,
                            sidebarColor: theme.dashboardContainer,
                            onMyDocumentPressed:
                                toolbarState.onMyDocumentPressed,
                            onCreateTemplatePressed:
                                toolbarState.onCreateTemplatePressed,
                            onGeneratePressed: toolbarState.onGeneratePressed,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DragScrollBehavior extends MaterialScrollBehavior {
  const _DragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}
