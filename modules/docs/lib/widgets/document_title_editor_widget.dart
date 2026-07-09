import 'package:docs/api/cloud_docs_service.dart';
import 'package:docs/emma/anchors/docs_emma_anchors.dart';
import 'package:docs/provider/cloud_doc_provider.dart';
import 'package:docs/widgets/sheet_scaffold.dart';
import 'package:docs/widgets/show_draggable_sheet.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

final documentTitleEditingProvider =
    StateProvider.family<bool, String>((ref, documentId) => false);

final documentTitleSavingProvider =
    StateProvider.family<bool, String>((ref, documentId) => false);

class DocumentTitleEditor extends ConsumerStatefulWidget {
  final String documentId;
  final bool compact;

  const DocumentTitleEditor({
    super.key,
    required this.documentId,
    this.compact = false,
  });

  @override
  ConsumerState<DocumentTitleEditor> createState() =>
      _DocumentTitleEditorState();
}

class _DocumentTitleEditorState extends ConsumerState<DocumentTitleEditor> {
  late TextEditingController _titleController;
  final FocusNode _focusNode = FocusNode(debugLabel: 'document_title_focus');

  @override
  void initState() {
    super.initState();

    final localTitles = ref.read(documentTitlesProvider);
    final initialTitle = localTitles[widget.documentId] ?? 'Untitled Document';

    _titleController = TextEditingController(text: initialTitle);
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant DocumentTitleEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.documentId == widget.documentId) return;

    final isEditing =
        ref.read(documentTitleEditingProvider(widget.documentId));

    if (!isEditing) {
      final localTitles = ref.read(documentTitlesProvider);
      final newTitle = localTitles[widget.documentId] ?? 'Untitled Document';
      _titleController.text = newTitle;
    }
  }

  void _handleFocusChange() {
    if (!mounted) return;
    if (MediaQuery.sizeOf(context).width < 600) return;

    if (!_focusNode.hasFocus) {
      final isEditing =
          ref.read(documentTitleEditingProvider(widget.documentId));

      if (isEditing) {
        _saveTitle();
      }
    }
  }

  Future<void> _saveTitle() async {
    final newTitle = _titleController.text.trim();
    final currentTitle = ref.read(documentProvider.notifier).getLocalTitle(ref);

    if (newTitle.isEmpty || newTitle == currentTitle) {
      ref.read(documentTitleEditingProvider(widget.documentId).notifier).state =
          false;
      return;
    }

    ref.read(documentTitleSavingProvider(widget.documentId).notifier).state =
        true;

    try {
      ref.read(documentProvider.notifier).updateLocalTitle(newTitle, ref);

      final document = ref.read(documentProvider).valueOrNull;

      if (document != null) {
        await DocumentService.updateDocument(
          documentId: widget.documentId,
          title: newTitle,
          ref: ref,
        );

        await ref
            .read(documentProvider.notifier)
            .fetchDocument(widget.documentId, ref);
      }

      ref.read(documentTitleEditingProvider(widget.documentId).notifier).state =
          false;
    } catch (e) {
      debugPrint('Error saving title: $e');

      if (!mounted) return;

      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('Failed to save title: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        ref.read(documentTitleSavingProvider(widget.documentId).notifier).state =
            false;
      }
    }
  }

  void _startEditing() {
    ref.read(documentTitleEditingProvider(widget.documentId).notifier).state =
        true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _titleController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _titleController.text.length,
      );

      _focusNode.requestFocus();
    });
  }

  void _cancelEdit() {
    final currentTitle = ref.read(documentProvider.notifier).getLocalTitle(ref);

    _titleController.text = currentTitle;

    ref.read(documentTitleEditingProvider(widget.documentId).notifier).state =
        false;

    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(documentProvider);

    final theme = ref.watch(themeColorsProvider);
    final isEditing =
        ref.watch(documentTitleEditingProvider(widget.documentId));
    final isSaving = ref.watch(documentTitleSavingProvider(widget.documentId));
    final currentTitle = ref.read(documentProvider.notifier).getLocalTitle(ref);

    if (_titleController.text != currentTitle && !isEditing) {
      _titleController.text = currentTitle;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final editorHeight = widget.compact
            ? 42.0
            : isMobile
                ? 56.0
                : 80.0;

        final titleFontSize = widget.compact
            ? 20.0
            : isMobile
                ? 18.0
                : 24.0;

        final actionBtnSize = widget.compact
            ? 30.0
            : isMobile
                ? 32.0
                : 40.0;

        final actionIconSize = widget.compact
            ? 16.0
            : isMobile
                ? 16.0
                : 20.0;

        if (isEditing) {
          return SizedBox(
            width: double.infinity,
            height: editorHeight,
            child: Container(
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                borderRadius: BorderRadius.circular(widget.compact ? 10 : 12),
                border: Border.all(
                  color: theme.textColor.withAlpha(76),
                  width: 1.3,
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 8 : 12,
                vertical: widget.compact ? 4 : 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      focusNode: _focusNode,
                      autofocus: true,
                      cursorColor: theme.textColor,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w800,
                        color: theme.textColor,
                        height: 1.1,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        filled: true,
                        fillColor: theme.adPopBackground,
                        hintText: 'Enter document title...',
                        hintStyle: TextStyle(
                          color: theme.textColor.withAlpha(102),
                          fontWeight: FontWeight.w500,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: widget.compact ? 4 : 8,
                          horizontal: 8,
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _saveTitle(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isSaving)
                    SizedBox(
                      width: actionBtnSize,
                      height: actionBtnSize,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    _ActionButton(
                      icon: Icons.check_rounded,
                      color: Colors.green,
                      onTap: _saveTitle,
                      buttonSize: actionBtnSize,
                      iconSize: actionIconSize,
                    ),
                  const SizedBox(width: 6),
                  _ActionButton(
                    icon: Icons.close_rounded,
                    color: Colors.grey,
                    onTap: _cancelEdit,
                    buttonSize: actionBtnSize,
                    iconSize: actionIconSize,
                  ),
                ],
              ),
            ),
          );
        }

        return EmmaUiAnchorTarget(
          anchorKey: DocsEmmaAnchors.documentTitleEditor.anchorKey,

          spec: DocsEmmaAnchors.documentTitleEditor,
          runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
          tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                final isMobile = MediaQuery.sizeOf(context).width < 600;

                if (isMobile) {
                  _openTitleEditSheet();
                } else {
                  _startEditing();
                }
              },
              child: Container(
                width: isMobile ? double.infinity : null,
                height: widget.compact ? 40 : null,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.compact ? 8 : 16,
                  vertical: widget.compact ? 6 : 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.transparent),
                ),
                child: Row(
                  mainAxisSize:
                      widget.compact ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Text(
                        currentTitle.trim().isEmpty
                            ? 'Dokument bez tytułu'
                            : currentTitle,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w900,
                          color: theme.textColor,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: widget.compact ? 28 : 32,
                      height: widget.compact ? 28 : 32,
                      decoration: BoxDecoration(
                        color: theme.dashboardContainer,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.dashboardBoarder),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        size: widget.compact ? 14 : 16,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openTitleEditSheet() async {
    final theme = ref.read(themeColorsProvider);
    final currentTitle = ref.read(documentProvider.notifier).getLocalTitle(ref);

    _titleController.text = currentTitle;

    await showDraggableSheet<void>(
      context: context,
      initialChildSize: 0.45,
      minChildSize: 0.30,
      maxChildSize: 0.55,
      builder: (ctx, sc) {
        final isSaving =
            ref.watch(documentTitleSavingProvider(widget.documentId));

        return Container(
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(6),
            ),
          ),
          child: SheetScaffold(
            scrollController: sc,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit title',
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  autofocus: true,
                  cursorColor: theme.textColor,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.textFieldColor,
                    hintText: 'Enter document title...',
                    hintStyle: TextStyle(color: theme.textColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) async {
                    await _saveTitleFromSheet();

                    if (mounted) {
                      Navigator.pop(ctx);
                    }
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _titleController.text = currentTitle;
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              await _saveTitleFromSheet();

                              if (mounted) {
                                Navigator.pop(ctx);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.themeColor,
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Save',
                              style: TextStyle(color: theme.textColor),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveTitleFromSheet() async {
    final newTitle = _titleController.text.trim();
    final currentTitle = ref.read(documentProvider.notifier).getLocalTitle(ref);

    if (newTitle.isEmpty || newTitle == currentTitle) return;

    ref.read(documentTitleSavingProvider(widget.documentId).notifier).state =
        true;

    try {
      ref.read(documentProvider.notifier).updateLocalTitle(newTitle, ref);

      final document = ref.read(documentProvider).valueOrNull;

      if (document != null) {
        await DocumentService.updateDocument(
          documentId: widget.documentId,
          title: newTitle,
          ref: ref,
        );

        await ref
            .read(documentProvider.notifier)
            .fetchDocument(widget.documentId, ref);
      }
    } catch (e) {
      debugPrint('Error saving title from sheet: $e');

      if (!mounted) return;

      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('Failed to save title: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        ref.read(documentTitleSavingProvider(widget.documentId).notifier).state =
            false;
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _titleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double iconSize;
  final double buttonSize;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.iconSize = 20,
    this.buttonSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Material(
        color: color.withAlpha(26),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(
            icon,
            size: iconSize,
            color: color,
          ),
        ),
      ),
    );
  }
}
