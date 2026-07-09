import 'package:docs/provider/document_page_setup_provider.dart';
import 'package:docs/widgets/document_page_break.dart';
import 'package:docs/widgets/paged_quill_document_editor.dart';
import 'package:docs/widgets/template_editor/template_editor_models.dart';
import 'package:docs/widgets/template_editor/template_editor_syntax.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';

class DocEditorWithFloatingToolbar extends StatefulWidget {
  final QuillController controller;
  final FocusNode editorFocusNode;
  final ScrollController editorScrollController;
  final ThemeColors resolvedTheme;
  final Color sidebarColor;
  final Color textColor;
  final DocumentPageSetup pageSetup;
  final bool whitePaperMode;
  final ValueChanged<double>? onFitScaleChanged;

  final VoidCallback? onMyDocumentPressed;
  final VoidCallback? onCreateTemplatePressed;
  final VoidCallback? onSaveVersionPressed;
  final VoidCallback? onGeneratePressed;

  /// Set this to false when the main/pro toolbar is already visible.
  final bool showFloatingQuickActions;

  final bool showTemplatePlaceholders;
  final List<String> templatePlaceholders;
  final Map<String, String>? placeholderValues;
  final Function(String key, String value)? onPlaceholderValueChanged;

  const DocEditorWithFloatingToolbar({
    super.key,
    required this.pageSetup,
    required this.controller,
    required this.editorFocusNode,
    required this.editorScrollController,
    required this.resolvedTheme,
    required this.sidebarColor,
    required this.textColor,
    this.whitePaperMode = true,
    this.onFitScaleChanged,
    this.onMyDocumentPressed,
    this.onCreateTemplatePressed,
    this.onSaveVersionPressed,
    this.onGeneratePressed,
    this.showFloatingQuickActions = true,
    this.showTemplatePlaceholders = false,
    this.templatePlaceholders = const [
      'Imię klienta',
      'Nazwisko klienta',
      'Płeć',
      'Nazwa firmy',
      'Opiekun',
    ],
    this.placeholderValues,
    this.onPlaceholderValueChanged,
  });

  @override
  State<DocEditorWithFloatingToolbar> createState() =>
      _DocEditorWithFloatingToolbarState();
}

class _DocEditorWithFloatingToolbarState
    extends State<DocEditorWithFloatingToolbar> {
  bool _initialized = false;
  bool _disposed = false;
  bool _templateTokenDialogOpen = false;
  bool _suppressNextDetection = false;
  bool _normalizingPageBreaks = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _disposed) return;

      _normalizeLegacyPageBreakMarkers();
      _initializeTemplateContent();
      _setupTemplateTokenDetection();
    });
  }

  @override
  void didUpdateWidget(covariant DocEditorWithFloatingToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_disposed) return;

    if (oldWidget.controller != widget.controller) {
      try {
        oldWidget.controller.removeListener(_detectTemplateTokenTap);
      } catch (_) {}

      _setupTemplateTokenDetection();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _disposed) return;
        _normalizeLegacyPageBreakMarkers();
      });
    }

    if (widget.showTemplatePlaceholders && !_initialized && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _disposed) return;
        _initializeTemplateContent();
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;

    try {
      widget.controller.removeListener(_detectTemplateTokenTap);
    } catch (_) {}

    super.dispose();
  }

  int _safeDocumentInsertIndex() {
    final length = widget.controller.document.length;
    if (length <= 0) return 0;
    return length - 1;
  }

  int _safeDocumentLength() {
    final length = widget.controller.document.length;
    if (length < 0) return 0;
    return length;
  }

  int _clampDocumentIndex(int value) {
    final maxIndex = _safeDocumentInsertIndex();
    return value.clamp(0, maxIndex).toInt();
  }

  int _safeReplaceLength({
    required int start,
    required int requestedLength,
  }) {
    final documentLength = _safeDocumentLength();
    if (documentLength <= 0) return 0;

    final maxLength = (documentLength - start).clamp(0, documentLength).toInt();

    return requestedLength.clamp(0, maxLength).toInt();
  }

  void _requestEditorFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _disposed) return;
      widget.editorFocusNode.requestFocus();
    });
  }

  void _normalizeLegacyPageBreakMarkers() {
    if (_normalizingPageBreaks) return;

    final text = widget.controller.document.toPlainText();
    final matches =
        DocumentPageBreakTools.legacyTextRegex.allMatches(text).toList();

    if (matches.isEmpty) return;

    _normalizingPageBreaks = true;
    _suppressNextDetection = true;

    try {
      for (final match in matches.reversed) {
        final start = _clampDocumentIndex(match.start);
        final length = _safeReplaceLength(
          start: start,
          requestedLength: match.end - match.start,
        );

        widget.controller.replaceText(
          start,
          length,
          '',
          TextSelection.collapsed(offset: start),
        );

        DocumentPageBreakTools.insertAtIndex(
          widget.controller,
          start,
        );
      }

      if (mounted) {
        setState(() {});
      }
    } finally {
      _normalizingPageBreaks = false;
    }
  }

  void _initializeTemplateContent() {
    if (!widget.showTemplatePlaceholders ||
        _initialized ||
        !mounted ||
        _disposed) {
      return;
    }

    final text = widget.controller.document.toPlainText().trim();

    if (text.isEmpty || text == '\u0000') {
      final initialContent = widget.templatePlaceholders
          .map(
            (label) => TemplateEditorSyntax.formatField(
              TemplateEditorFieldSpec(label: label),
            ),
          )
          .join(' ');

      widget.controller.replaceText(
        0,
        0,
        initialContent,
        TextSelection.collapsed(offset: initialContent.length),
      );
    }

    _initialized = true;
  }

  void _setupTemplateTokenDetection() {
    if (!mounted || _disposed) return;

    try {
      widget.controller.removeListener(_detectTemplateTokenTap);
    } catch (_) {}

    widget.controller.addListener(_detectTemplateTokenTap);
  }

  void _detectTemplateTokenTap() {
    if (!mounted || _disposed) return;
    if (!widget.showTemplatePlaceholders) return;
    if (_templateTokenDialogOpen) return;
    if (_normalizingPageBreaks) return;

    if (_suppressNextDetection) {
      _suppressNextDetection = false;
      return;
    }

    final selection = widget.controller.selection;
    if (!selection.isCollapsed) return;

    final position = selection.baseOffset;
    if (position < 0) return;

    final text = widget.controller.document.toPlainText();
    final safePosition = position.clamp(0, text.length).toInt();
    final token = TemplateEditorSyntax.tokenAtPosition(text, safePosition);

    if (token == null) return;
    if (token.kind == TemplateEditorTokenKind.segmentEnd) return;

    _templateTokenDialogOpen = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _disposed) {
        _templateTokenDialogOpen = false;
        return;
      }

      try {
        if (token.kind == TemplateEditorTokenKind.field) {
          final spec = TemplateEditorSyntax.parseFieldToken(token.raw);

          await _showFieldDialog(
            initialSpec: spec,
            replaceRange: TextRange(start: token.start, end: token.end),
          );
        } else if (token.kind == TemplateEditorTokenKind.segmentStart) {
          final segment = TemplateEditorSyntax.parseSegmentStartToken(token.raw);

          await _showSegmentDialog(
            initialSpec: segment,
            replaceRange: TextRange(start: token.start, end: token.end),
          );
        }
      } finally {
        _templateTokenDialogOpen = false;
      }
    });
  }

  EdgeInsets _dialogInset(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < 620) {
      return const EdgeInsets.symmetric(horizontal: 14, vertical: 18);
    }

    return const EdgeInsets.symmetric(horizontal: 24, vertical: 24);
  }

  Alignment _dialogAlignment(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < 900) {
      return Alignment.center;
    }

    return Alignment.centerLeft;
  }

  EdgeInsets _dialogPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < 900) {
      return const EdgeInsets.all(0);
    }

    return const EdgeInsets.only(left: 120);
  }

  Future<void> _showFieldDialog({
    TemplateEditorFieldSpec? initialSpec,
    TextRange? replaceRange,
  }) async {
    if (!mounted || _disposed) return;

    final labelController = TextEditingController(
      text: initialSpec?.label ?? '',
    );
    final keyController = TextEditingController(
      text: initialSpec?.key ?? '',
    );
    final helpController = TextEditingController(
      text: initialSpec?.helpText ?? '',
    );
    final defaultValueController = TextEditingController(
      text: initialSpec?.defaultValue ?? '',
    );
    final maxLengthController = TextEditingController(
      text: initialSpec?.maxLength?.toString() ?? '',
    );
    final minController = TextEditingController(
      text: initialSpec?.min?.toString() ?? '',
    );
    final maxController = TextEditingController(
      text: initialSpec?.max?.toString() ?? '',
    );
    final prefixController = TextEditingController(
      text: initialSpec?.defaultPrefix ?? '',
    );
    final optionsController = TextEditingController(
      text: TemplateEditorSyntax.optionsToEditableText(
        initialSpec?.options ?? const [],
      ),
    );

    var selectedType = initialSpec?.type ?? TemplateEditorFieldType.text;
    var required = initialSpec?.required ?? false;

    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'template-field-edit',
      barrierDismissible: true,
      barrierColor: widget.resolvedTheme.dashboardContainer.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void refreshPreview([String? _]) {
              setDialogState(() {});
            }

            final previewSpec = TemplateEditorFieldSpec(
              label: labelController.text.trim().isEmpty
                  ? 'Nazwa pola'
                  : labelController.text.trim(),
              key: keyController.text.trim().isEmpty
                  ? null
                  : keyController.text.trim(),
              type: selectedType,
              required: required,
              maxLength: int.tryParse(maxLengthController.text.trim()),
              min: num.tryParse(
                minController.text.trim().replaceAll(',', '.'),
              ),
              max: num.tryParse(
                maxController.text.trim().replaceAll(',', '.'),
              ),
              defaultPrefix: prefixController.text.trim().isEmpty
                  ? null
                  : prefixController.text.trim(),
              defaultValue: defaultValueController.text.trim().isEmpty
                  ? null
                  : defaultValueController.text.trim(),
              helpText: helpController.text.trim().isEmpty
                  ? null
                  : helpController.text.trim(),
              options: TemplateEditorSyntax.parseEditableOptions(
                optionsController.text,
              ),
            );

            return SafeArea(
              child: Material(
                type: MaterialType.transparency,
                child: Align(
                  alignment: _dialogAlignment(context),
                  child: Padding(
                    padding: _dialogPadding(context),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: AlertDialog(
                        backgroundColor: widget.resolvedTheme.dashboardContainer,
                        surfaceTintColor: Colors.transparent,
                        insetPadding: _dialogInset(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: widget.resolvedTheme.dashboardBoarder,
                          ),
                        ),
                        titlePadding:
                            const EdgeInsets.fromLTRB(22, 20, 22, 8),
                        contentPadding:
                            const EdgeInsets.fromLTRB(22, 10, 22, 8),
                        actionsPadding:
                            const EdgeInsets.fromLTRB(18, 0, 18, 16),
                        title: Row(
                          children: [
                            Icon(
                              Icons.input_outlined,
                              color: widget.resolvedTheme.textColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                initialSpec == null
                                    ? 'Wstaw pole formularza'
                                    : 'Edytuj pole formularza',
                                style: TextStyle(
                                  color: widget.resolvedTheme.textColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _TemplateDialogTextField(
                                controller: labelController,
                                theme: widget.resolvedTheme,
                                label: 'Nazwa pola',
                                hint: 'np. Imię klienta',
                                icon: Icons.label_outline,
                                autofocus: true,
                                onChanged: refreshPreview,
                              ),
                              const SizedBox(height: 12),
                              _TemplateDialogTextField(
                                controller: keyController,
                                theme: widget.resolvedTheme,
                                label: 'Klucz techniczny',
                                hint: 'np. client_name',
                                icon: Icons.key_outlined,
                                onChanged: refreshPreview,
                              ),
                              const SizedBox(height: 12),
                              _TemplateFieldTypeDropdown(
                                value: selectedType,
                                theme: widget.resolvedTheme,
                                onChanged: (value) {
                                  if (value == null) return;

                                  setDialogState(() {
                                    selectedType = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              CheckboxListTile(
                                value: required,
                                activeColor: widget.resolvedTheme.themeColor,
                                checkColor: widget.resolvedTheme.themeColorText,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  'Pole wymagane',
                                  style: TextStyle(
                                    color: widget.resolvedTheme.textColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                onChanged: (value) {
                                  setDialogState(() {
                                    required = value ?? false;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              _TemplateDialogTextField(
                                controller: defaultValueController,
                                theme: widget.resolvedTheme,
                                label: 'Domyślna wartość',
                                hint: 'Opcjonalnie',
                                icon: Icons.edit_note_outlined,
                                onChanged: refreshPreview,
                              ),
                              const SizedBox(height: 12),
                              _TemplateDialogTextField(
                                controller: helpController,
                                theme: widget.resolvedTheme,
                                label: 'Tekst pomocy',
                                hint: 'Krótka instrukcja dla klienta',
                                icon: Icons.help_outline,
                                minLines: 2,
                                maxLines: 4,
                                onChanged: refreshPreview,
                              ),
                              const SizedBox(height: 12),
                              if (selectedType ==
                                  TemplateEditorFieldType.text) ...[
                                _TemplateDialogTextField(
                                  controller: maxLengthController,
                                  theme: widget.resolvedTheme,
                                  label: 'Limit znaków',
                                  hint: 'np. 50',
                                  icon: Icons.text_fields_outlined,
                                  keyboardType: TextInputType.number,
                                  onChanged: refreshPreview,
                                ),
                              ],
                              if (selectedType ==
                                  TemplateEditorFieldType.phone) ...[
                                _TemplateDialogTextField(
                                  controller: prefixController,
                                  theme: widget.resolvedTheme,
                                  label: 'Domyślny prefix',
                                  hint: 'np. +48',
                                  icon: Icons.tag_outlined,
                                  onChanged: refreshPreview,
                                ),
                                const SizedBox(height: 12),
                                _TemplateDialogTextField(
                                  controller: maxLengthController,
                                  theme: widget.resolvedTheme,
                                  label: 'Limit znaków numeru',
                                  hint: 'np. 9',
                                  icon: Icons.text_fields_outlined,
                                  keyboardType: TextInputType.number,
                                  onChanged: refreshPreview,
                                ),
                              ],
                              if (selectedType ==
                                      TemplateEditorFieldType.number ||
                                  selectedType ==
                                      TemplateEditorFieldType.money) ...[
                                _TemplateDialogTextField(
                                  controller: minController,
                                  theme: widget.resolvedTheme,
                                  label: 'Minimalna wartość',
                                  hint: 'np. 0',
                                  icon: Icons.keyboard_double_arrow_down,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    signed: true,
                                    decimal: true,
                                  ),
                                  onChanged: refreshPreview,
                                ),
                                const SizedBox(height: 12),
                                _TemplateDialogTextField(
                                  controller: maxController,
                                  theme: widget.resolvedTheme,
                                  label: 'Maksymalna wartość',
                                  hint: 'np. 1000000',
                                  icon: Icons.keyboard_double_arrow_up,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    signed: true,
                                    decimal: true,
                                  ),
                                  onChanged: refreshPreview,
                                ),
                              ],
                              if (selectedType ==
                                      TemplateEditorFieldType.dropdown ||
                                  selectedType ==
                                      TemplateEditorFieldType.multiselect) ...[
                                _TemplateDialogTextField(
                                  controller: optionsController,
                                  theme: widget.resolvedTheme,
                                  label: 'Opcje',
                                  hint:
                                      'man:Mężczyzna\nwoman:Kobieta\nother:Inne',
                                  icon: Icons.list_alt_outlined,
                                  minLines: 4,
                                  maxLines: 7,
                                  onChanged: refreshPreview,
                                ),
                              ],
                              const SizedBox(height: 14),
                              _TemplateSyntaxPreviewBox(
                                theme: widget.resolvedTheme,
                                text: TemplateEditorSyntax.formatField(
                                  previewSpec,
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: widget.resolvedTheme.textColor,
                            ),
                            child: Text(
                              'Cancel'.tr,
                              style: TextStyle(
                                color: widget.resolvedTheme.textColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              final label = labelController.text.trim();

                              if (label.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Podaj nazwę pola.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              final spec = TemplateEditorFieldSpec(
                                label: label,
                                key: keyController.text.trim().isEmpty
                                    ? null
                                    : keyController.text.trim(),
                                type: selectedType,
                                required: required,
                                maxLength: int.tryParse(
                                  maxLengthController.text.trim(),
                                ),
                                min: num.tryParse(
                                  minController.text
                                      .trim()
                                      .replaceAll(',', '.'),
                                ),
                                max: num.tryParse(
                                  maxController.text
                                      .trim()
                                      .replaceAll(',', '.'),
                                ),
                                defaultPrefix:
                                    prefixController.text.trim().isEmpty
                                        ? null
                                        : prefixController.text.trim(),
                                defaultValue:
                                    defaultValueController.text.trim().isEmpty
                                        ? null
                                        : defaultValueController.text.trim(),
                                helpText: helpController.text.trim().isEmpty
                                    ? null
                                    : helpController.text.trim(),
                                options:
                                    TemplateEditorSyntax.parseEditableOptions(
                                  optionsController.text,
                                ),
                              );

                              final token =
                                  TemplateEditorSyntax.formatField(spec);

                              _insertOrReplaceText(
                                token,
                                replaceRange: replaceRange,
                              );

                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.resolvedTheme.themeColor,
                              foregroundColor:
                                  widget.resolvedTheme.themeColorText,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.check),
                            label: Text(
                              'Save'.tr,
                              style: TextStyle(
                                color: widget.resolvedTheme.themeColorText,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );

    labelController.dispose();
    keyController.dispose();
    helpController.dispose();
    defaultValueController.dispose();
    maxLengthController.dispose();
    minController.dispose();
    maxController.dispose();
    prefixController.dispose();
    optionsController.dispose();
  }

  Future<void> _showSegmentDialog({
    TemplateEditorSegmentSpec? initialSpec,
    TextRange? replaceRange,
  }) async {
    if (!mounted || _disposed) return;

    final labelController = TextEditingController(
      text: initialSpec?.label ?? '',
    );

    var skipable = initialSpec?.skipable ?? true;

    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'template-segment-edit',
      barrierDismissible: true,
      barrierColor: widget.resolvedTheme.dashboardContainer.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void refreshPreview([String? _]) {
              setDialogState(() {});
            }

            final previewSpec = TemplateEditorSegmentSpec(
              label: labelController.text.trim().isEmpty
                  ? 'Dane dodatkowe'
                  : labelController.text.trim(),
              skipable: skipable,
            );

            return SafeArea(
              child: Material(
                type: MaterialType.transparency,
                child: Align(
                  alignment: _dialogAlignment(context),
                  child: Padding(
                    padding: _dialogPadding(context),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: AlertDialog(
                        backgroundColor: widget.resolvedTheme.dashboardContainer,
                        surfaceTintColor: Colors.transparent,
                        insetPadding: _dialogInset(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: widget.resolvedTheme.dashboardBoarder,
                          ),
                        ),
                        titlePadding:
                            const EdgeInsets.fromLTRB(22, 20, 22, 8),
                        contentPadding:
                            const EdgeInsets.fromLTRB(22, 10, 22, 8),
                        actionsPadding:
                            const EdgeInsets.fromLTRB(18, 0, 18, 16),
                        title: Row(
                          children: [
                            Icon(
                              Icons.segment_outlined,
                              color: widget.resolvedTheme.textColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                initialSpec == null
                                    ? 'Wstaw segment'
                                    : 'Edytuj segment',
                                style: TextStyle(
                                  color: widget.resolvedTheme.textColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _TemplateDialogTextField(
                                controller: labelController,
                                theme: widget.resolvedTheme,
                                label: 'Nazwa segmentu',
                                hint: 'np. Dane dodatkowe',
                                icon: Icons.segment_outlined,
                                autofocus: true,
                                onChanged: refreshPreview,
                              ),
                              const SizedBox(height: 12),
                              CheckboxListTile(
                                value: skipable,
                                activeColor: widget.resolvedTheme.themeColor,
                                checkColor: widget.resolvedTheme.themeColorText,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  'Segment pomijalny',
                                  style: TextStyle(
                                    color: widget.resolvedTheme.textColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  'Jeśli klient nie uzupełni pól albo pominie sekcję, cały segment zniknie z dokumentu.',
                                  style: TextStyle(
                                    color: widget.resolvedTheme.textColor
                                        .withAlpha(150),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onChanged: (value) {
                                  setDialogState(() {
                                    skipable = value ?? true;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              _TemplateSyntaxPreviewBox(
                                theme: widget.resolvedTheme,
                                text: TemplateEditorSyntax.formatSegmentStart(
                                  previewSpec,
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: widget.resolvedTheme.textColor,
                            ),
                            child: Text(
                              'Cancel'.tr,
                              style: TextStyle(
                                color: widget.resolvedTheme.textColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              final label = labelController.text.trim();

                              if (label.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Podaj nazwę segmentu.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              final spec = TemplateEditorSegmentSpec(
                                label: label,
                                skipable: skipable,
                              );

                              if (replaceRange != null) {
                                _insertOrReplaceText(
                                  TemplateEditorSyntax.formatSegmentStart(spec),
                                  replaceRange: replaceRange,
                                );
                              } else {
                                _insertSegmentAroundSelection(spec);
                              }

                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.resolvedTheme.themeColor,
                              foregroundColor:
                                  widget.resolvedTheme.themeColorText,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.check),
                            label: Text(
                              'Save'.tr,
                              style: TextStyle(
                                color: widget.resolvedTheme.themeColorText,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );

    labelController.dispose();
  }

  void _insertOrReplaceText(
    String text, {
    TextRange? replaceRange,
  }) {
    if (!mounted || _disposed) return;

    _suppressNextDetection = true;

    final selection = widget.controller.selection;

    final int start;
    final int requestedLength;

    if (replaceRange != null) {
      start = _clampDocumentIndex(replaceRange.start);
      requestedLength = replaceRange.end - replaceRange.start;
    } else if (selection.isValid) {
      final base = selection.baseOffset;
      final extent = selection.extentOffset;

      start = _clampDocumentIndex(base < extent ? base : extent);
      requestedLength = (base - extent).abs();
    } else {
      start = _safeDocumentInsertIndex();
      requestedLength = 0;
    }

    final length = _safeReplaceLength(
      start: start,
      requestedLength: requestedLength,
    );

    widget.controller.replaceText(
      start,
      length,
      text,
      TextSelection.collapsed(offset: start + text.length),
    );

    _requestEditorFocus();
  }

  void _insertSegmentAroundSelection(TemplateEditorSegmentSpec spec) {
    if (!mounted || _disposed) return;

    _suppressNextDetection = true;

    final selection = widget.controller.selection;
    final startToken = TemplateEditorSyntax.formatSegmentStart(spec);
    final endToken = TemplateEditorSyntax.formatSegmentEnd();

    if (!selection.isValid || selection.isCollapsed) {
      final start = selection.isValid
          ? _clampDocumentIndex(selection.baseOffset)
          : _safeDocumentInsertIndex();

      final block = '$startToken\n\n$endToken';

      widget.controller.replaceText(
        start,
        0,
        block,
        TextSelection.collapsed(offset: start + startToken.length + 1),
      );

      _requestEditorFocus();
      return;
    }

    final base = selection.baseOffset;
    final extent = selection.extentOffset;

    final start = _clampDocumentIndex(base < extent ? base : extent);
    final end = _clampDocumentIndex(base < extent ? extent : base);

    widget.controller.replaceText(
      end,
      0,
      '\n$endToken',
      TextSelection.collapsed(offset: end),
    );

    widget.controller.replaceText(
      start,
      0,
      '$startToken\n',
      TextSelection.collapsed(offset: start + startToken.length + 1),
    );

    _requestEditorFocus();
  }

  ThemeData _buildQuillPopupTheme(BuildContext context) {
    final base = Theme.of(context);
    final popupBg = widget.resolvedTheme.dashboardContainer;
    final popupText = widget.resolvedTheme.textColor;
    final cs = base.colorScheme;

    final themedText = base.textTheme.apply(
      bodyColor: popupText,
      displayColor: popupText,
    );

    return base.copyWith(
      textTheme: themedText,
      colorScheme: cs.copyWith(
        surface: popupBg,
        onSurface: popupText,
        primary: widget.resolvedTheme.themeColor,
      ),
      canvasColor: popupBg,
      cardColor: popupBg,
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: popupBg,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: themedText.titleLarge,
        contentTextStyle: themedText.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      popupMenuTheme: base.popupMenuTheme.copyWith(
        color: popupBg,
        surfaceTintColor: Colors.transparent,
        textStyle: themedText.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(popupBg),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        textStyle: themedText.bodyMedium,
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(popupBg),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        textColor: popupText,
        iconColor: popupText,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        labelStyle: TextStyle(
          color: widget.resolvedTheme.textColor.withAlpha(165),
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(
          color: widget.resolvedTheme.textColor.withAlpha(120),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFloatingToolbar() {
    if (!widget.showFloatingQuickActions && !widget.showTemplatePlaceholders) {
      return const SizedBox.shrink();
    }

    final buttons = <Widget>[];

    void addButton({
      required String tooltip,
      required IconData icon,
      required VoidCallback? onPressed,
      String? label,
    }) {
      if (onPressed == null) return;

      buttons.add(
        _FloatingToolbarButton(
          tooltip: tooltip,
          icon: icon,
          label: label,
          theme: widget.resolvedTheme,
          onPressed: onPressed,
        ),
      );
    }

    if (widget.showFloatingQuickActions) {
      addButton(
        tooltip: 'Moje dokumenty',
        icon: Icons.folder_copy_outlined,
        label: 'Dokumenty',
        onPressed: widget.onMyDocumentPressed,
      );

      addButton(
        tooltip: 'Utwórz template',
        icon: Icons.dashboard_customize_outlined,
        label: 'Template',
        onPressed: widget.onCreateTemplatePressed,
      );

      addButton(
        tooltip: 'Zapisz wersję',
        icon: Icons.save_as_outlined,
        label: 'Wersja',
        onPressed: widget.onSaveVersionPressed,
      );

      addButton(
        tooltip: 'Generuj dokument',
        icon: Icons.picture_as_pdf_outlined,
        label: 'Generuj',
        onPressed: widget.onGeneratePressed,
      );
    }

    if (widget.showTemplatePlaceholders) {
      buttons.add(
        _FloatingToolbarButton(
          tooltip: 'Wstaw pole formularza',
          icon: Icons.input_outlined,
          label: 'Pole',
          theme: widget.resolvedTheme,
          onPressed: () => _showFieldDialog(),
        ),
      );

      buttons.add(
        _FloatingToolbarButton(
          tooltip: 'Wstaw segment pomijalny',
          icon: Icons.segment_outlined,
          label: 'Segment',
          theme: widget.resolvedTheme,
          onPressed: () => _showSegmentDialog(),
        ),
      );
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 14,
      right: 18,
      child: Material(
        color: widget.resolvedTheme.dashboardContainer.withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.resolvedTheme.dashboardBoarder),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: buttons,
          ),
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return PagedQuillDocumentEditor(

      masterController: widget.controller,
      outerScrollController: widget.editorScrollController,
      pageSetup: widget.pageSetup,
      resolvedTheme: widget.resolvedTheme,
      whitePaperMode: widget.whitePaperMode,
      focusNode: widget.editorFocusNode,
      onFitScaleChanged: widget.onFitScaleChanged,
      placeholder: widget.showTemplatePlaceholders
          ? ''
          : 'Start writing your document...'.tr,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _buildQuillPopupTheme(context),
      child: Stack(
        children: [
          _buildEditor(),
          _buildFloatingToolbar(),
        ],
      ),
    );
  }
}

class _FloatingToolbarButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final String? label;
  final ThemeColors theme;
  final VoidCallback onPressed;

  const _FloatingToolbarButton({
    required this.tooltip,
    required this.icon,
    required this.theme,
    required this.onPressed,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final content = label == null
        ? Icon(icon, size: 18)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17),
              const SizedBox(width: 6),
              Text(
                label!,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          );

    return Tooltip(
      message: tooltip,
      child: Material(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: label == null ? 10 : 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dashboardBoarder),
            ),
            child: IconTheme(
              data: IconThemeData(color: theme.textColor),
              child: DefaultTextStyle(
                style: TextStyle(color: theme.textColor),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateDialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final ThemeColors theme;
  final String label;
  final String hint;
  final IconData icon;
  final bool autofocus;
  final int minLines;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _TemplateDialogTextField({
    required this.controller,
    required this.theme,
    required this.label,
    required this.hint,
    required this.icon,
    this.autofocus = false,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      cursorColor: theme.themeColor,
      style: TextStyle(
        color: theme.textColor,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: theme.textColor.withAlpha(150)),
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: theme.textColor.withAlpha(165),
          fontWeight: FontWeight.w700,
        ),
        floatingLabelStyle: TextStyle(
          color: theme.themeColor,
          fontWeight: FontWeight.w900,
        ),
        hintStyle: TextStyle(
          color: theme.textColor.withAlpha(120),
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: theme.dashboardContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dashboardBoarder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dashboardBoarder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.themeColor, width: 1.4),
        ),
      ),
    );
  }
}

class _TemplateFieldTypeDropdown extends StatelessWidget {
  final TemplateEditorFieldType value;
  final ThemeColors theme;
  final ValueChanged<TemplateEditorFieldType?> onChanged;

  const _TemplateFieldTypeDropdown({
    required this.value,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField2<TemplateEditorFieldType>(
      value: value,
      isExpanded: true,
      dropdownStyleData: DropdownStyleData(
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dashboardBoarder),
        ),
      ),
      buttonStyleData: const ButtonStyleData(
        height: 52,
        padding: EdgeInsets.only(right: 10),
      ),
      iconStyleData: IconStyleData(
        icon: Icon(Icons.arrow_drop_down, color: theme.textColor),
      ),
      style: TextStyle(
        color: theme.textColor,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.category_outlined,
          color: theme.textColor.withAlpha(150),
        ),
        labelText: 'Typ pola',
        labelStyle: TextStyle(
          color: theme.textColor.withAlpha(165),
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: theme.dashboardContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dashboardBoarder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dashboardBoarder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.themeColor, width: 1.4),
        ),
      ),
      items: TemplateEditorFieldType.values.map((type) {
        return DropdownMenuItem<TemplateEditorFieldType>(
          value: type,
          child: Text(
            TemplateEditorSyntax.typeLabel(type),
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _TemplateSyntaxPreviewBox extends StatelessWidget {
  final ThemeColors theme;
  final String text;

  const _TemplateSyntaxPreviewBox({
    required this.theme,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: SelectableText(
        text,
        style: TextStyle(
          color: theme.textColor.withAlpha(175),
          fontWeight: FontWeight.w800,
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }
}