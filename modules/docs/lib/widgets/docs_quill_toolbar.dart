import 'package:docs/emma/anchors/docs_emma_anchors.dart';
import 'package:docs/widgets/color_picker_result.dart';
import 'package:docs/widgets/mobile/docs_link_sheet.dart';
import 'package:docs/widgets/mobile/docs_search_sheet.dart';
import 'package:docs/widgets/mobile/version_comment_sheet.dart';
import 'package:docs/widgets/show_draggable_sheet.dart';
import 'package:docs/widgets/version_comment_dialog.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';

class DocsQuillToolbar extends ConsumerStatefulWidget {
  const DocsQuillToolbar({
    super.key,
    required this.controller,
    required this.resolvedTheme,
    required this.sidebarColor,
    required this.editorFocusNode,
    this.header,
    this.onMyDocumentPressed,
    this.onCreateTemplatePressed,
    this.onSavePressed,
    this.onSaveVersionPressed,
    this.onGeneratePressed,
    this.onInsertPageBreakPressed,
    this.isTemplateMode = false,
    this.isConnected = false,
    this.hasUnsavedChanges = false,
    this.compact = false,
    this.isDocumentHeaderVisible = true,
    this.onToggleDocumentHeaderPressed,
    this.onNewPagePressed,
    this.onPrintPressed,
    this.onPageSetupPressed,

    this.whitePaperMode = true,
    this.onTogglePaperModePressed,
    this.onEmmaTogglePressed,
    this.emmaActive = false,
  });


  final bool whitePaperMode;
  final VoidCallback? onTogglePaperModePressed;

  final VoidCallback? onEmmaTogglePressed;
  final bool emmaActive;

  final VoidCallback? onNewPagePressed;
  final VoidCallback? onPrintPressed;
  final VoidCallback? onPageSetupPressed;


  final QuillController controller;
  final ThemeColors resolvedTheme;
  final Color sidebarColor;
  final FocusNode editorFocusNode;

  /// Górna część unified bara, np. tytuł dokumentu + statusy.
  final Widget? header;

  final VoidCallback? onMyDocumentPressed;
  final VoidCallback? onCreateTemplatePressed;
  final VoidCallback? onSavePressed;
  final Future<void> Function(String comment)? onSaveVersionPressed;
  final VoidCallback? onGeneratePressed;
  final VoidCallback? onInsertPageBreakPressed;

  final bool isTemplateMode;
  final bool isConnected;
  final bool hasUnsavedChanges;
  final bool compact;

  final bool isDocumentHeaderVisible;
  final VoidCallback? onToggleDocumentHeaderPressed;

  @override
  ConsumerState<DocsQuillToolbar> createState() => _DocsQuillToolbarState();
}

class _DocsQuillToolbarState extends ConsumerState<DocsQuillToolbar> {
  bool _isSearchDialogOpen = false;
  bool _isLinkDialogOpen = false;

  static const List<String> _fontFamilies = [
    'Roboto',
    'Arial',
    'Times New Roman',
    'Georgia',
    'Verdana',
    'Courier New',
  ];

  static const List<String> _fontSizes = [
    '8',
    '9',
    '10',
    '11',
    '12',
    '14',
    '16',
    '18',
    '20',
    '22',
    '24',
    '26',
    '28',
    '32',
    '36',
    '48',
    '72',
  ];

  static const List<String> _lineHeights = [
    '1.0',
    '1.15',
    '1.3',
    '1.5',
    '1.75',
    '2.0',
  ];

  bool get _isMobileToolbar {
    final width = MediaQuery.maybeSizeOf(context)?.width ?? 1600;
    return widget.compact || width < 700;
  }

  bool get _dense {
    final width = MediaQuery.maybeSizeOf(context)?.width ?? 1600;
    return widget.compact || width < 1450;
  }

  bool get _veryDense {
    final width = MediaQuery.maybeSizeOf(context)?.width ?? 1600;
    return widget.compact || width < 1240;
  }

  double get _bottomToolbarHeight => _isMobileToolbar ? 58 : 66;
  double get _buttonHeight => _isMobileToolbar ? 42 : 48;
  double get _buttonRadius => 14;
  double get _iconSize => _isMobileToolbar ? 19 : 21;

  double get _paragraphWidth => _dense ? 138 : 158;
  double get _fontWidth => _dense ? 136 : 158;

  double get _groupGap => _dense ? 12 : 18;
  double get _itemGap => _dense ? 6 : 7;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant DocsQuillToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  ThemeData _buildPopupTheme(BuildContext context) {
    final base = Theme.of(context);
    final popupBg = widget.resolvedTheme.dashboardContainer;
    final popupText = widget.resolvedTheme.textColor;

    final themedText = base.textTheme.apply(
      bodyColor: popupText,
      displayColor: popupText,
    );

    return base.copyWith(
      textTheme: themedText,
      colorScheme: base.colorScheme.copyWith(
        surface: popupBg,
        onSurface: popupText,
        error: popupText,
        onError: popupText,
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
      menuButtonTheme: MenuButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(popupText),
          iconColor: WidgetStatePropertyAll(popupText),
          textStyle: WidgetStatePropertyAll(themedText.bodyMedium),
        ),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        textColor: popupText,
        iconColor: popupText,
      ),
    );
  }

  Style get _selectionStyle => widget.controller.getSelectionStyle();

  dynamic _attributeValue(String key) {
    return _selectionStyle.attributes[key]?.value;
  }

  bool _hasAttributeValue(String key, dynamic value) {
    return _attributeValue(key) == value;
  }

  void _requestEditorFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.editorFocusNode.requestFocus();
    });
  }

  void _formatSelection(Attribute attribute) {
    widget.controller.formatSelection(attribute);
    _requestEditorFocus();

    if (mounted) {
      setState(() {});
    }
  }

  void _formatKeyValue(String key, dynamic value) {
    final attr = Attribute.fromKeyValue(key, value);
    if (attr == null) return;

    _formatSelection(attr);
  }

  void _toggleKeyValue(String key, dynamic value) {
    final current = _attributeValue(key);
    _formatKeyValue(key, current == value ? null : value);
  }

  void _toggleAttribute(Attribute attribute) {
    final current = _selectionStyle.attributes[attribute.key];
    final isActive = current?.value == attribute.value;

    _formatSelection(
      isActive ? Attribute.clone(attribute, null) : attribute,
    );
  }

  void _clearFormatting() {
    final attributes = _selectionStyle.attributes.values.toList();
    if (attributes.isEmpty) return;

    for (final attribute in attributes) {
      widget.controller.formatSelection(Attribute.clone(attribute, null));
    }

    _requestEditorFocus();

    if (mounted) {
      setState(() {});
    }
  }

  void _clearParagraphBlockStyles() {
    _formatKeyValue(Attribute.header.key, null);
    _formatKeyValue('blockquote', null);
    _formatKeyValue('code-block', null);
  }

  void _applyParagraphStyle(String? value) {
    if (value == null) return;

    switch (value) {
      case 'normal':
        _clearParagraphBlockStyles();
        break;

      case 'h1':
        _formatKeyValue('blockquote', null);
        _formatKeyValue('code-block', null);
        _formatSelection(Attribute.h1);
        break;

      case 'h2':
        _formatKeyValue('blockquote', null);
        _formatKeyValue('code-block', null);
        _formatSelection(Attribute.h2);
        break;

      case 'h3':
        _formatKeyValue('blockquote', null);
        _formatKeyValue('code-block', null);
        _formatSelection(Attribute.h3);
        break;

      case 'quote':
        _formatKeyValue(Attribute.header.key, null);
        _formatKeyValue('code-block', null);
        _toggleKeyValue('blockquote', true);
        break;

      case 'code':
        _formatKeyValue(Attribute.header.key, null);
        _formatKeyValue('blockquote', null);
        _toggleKeyValue('code-block', true);
        break;
    }
  }

  void _applyFontFamily(String? value) {
    if (value == null) return;

    if (value == 'default') {
      _formatKeyValue(Attribute.font.key, null);
      return;
    }

    _formatKeyValue(Attribute.font.key, value);
  }

  void _applyFontSize(String? value) {
    if (value == null) return;

    if (value == 'default') {
      _formatKeyValue(Attribute.size.key, null);
      return;
    }

    _formatKeyValue(Attribute.size.key, value);
  }

  void _increaseFontSize() {
    final currentRaw = _attributeValue(Attribute.size.key)?.toString();
    final current = int.tryParse(currentRaw ?? '') ?? 12;

    final nextIndex = _fontSizes.indexWhere((size) {
      final parsed = int.tryParse(size);
      return parsed != null && parsed > current;
    });

    final next = nextIndex == -1 ? _fontSizes.last : _fontSizes[nextIndex];
    _applyFontSize(next);
  }

  void _decreaseFontSize() {
    final currentRaw = _attributeValue(Attribute.size.key)?.toString();
    final current = int.tryParse(currentRaw ?? '') ?? 12;

    var previous = _fontSizes.first;

    for (final size in _fontSizes) {
      final parsed = int.tryParse(size);
      if (parsed == null) continue;
      if (parsed >= current) break;
      previous = size;
    }

    _applyFontSize(previous);
  }

  void _applyLineHeight(String? value) {
    if (value == null) return;

    if (value == 'default') {
      _formatKeyValue('line-height', null);
      return;
    }

    _formatKeyValue('line-height', value);
  }

  void _applyAlignment(String alignment) {
    if (alignment == 'left') {
      _formatKeyValue(Attribute.align.key, null);
      return;
    }

    _formatKeyValue(Attribute.align.key, alignment);
  }

  void _increaseIndent() {
    final current =
        int.tryParse(_attributeValue('indent')?.toString() ?? '') ?? 0;
    final next = (current + 1).clamp(1, 8).toInt();

    _formatKeyValue('indent', next);
  }

  void _decreaseIndent() {
    final current =
        int.tryParse(_attributeValue('indent')?.toString() ?? '') ?? 0;
    final next = (current - 1).clamp(0, 8).toInt();

    if (next == 0) {
      _formatKeyValue('indent', null);
      return;
    }

    _formatKeyValue('indent', next);
  }

  TextRange? _safeSelectionTextRange() {
    final selection = widget.controller.selection;

    if (!selection.isValid || selection.isCollapsed) return null;

    final text = widget.controller.document.toPlainText();
    final start = selection.start.clamp(0, text.length).toInt();
    final end = selection.end.clamp(0, text.length).toInt();

    if (start >= end) return null;

    return TextRange(start: start, end: end);
  }

  void _insertTextAtSelection(String text) {
    final selection = widget.controller.selection;
    final documentLength = widget.controller.document.length;
    final safeEnd = documentLength <= 0 ? 0 : documentLength - 1;

    final start = selection.isValid
        ? selection.start.clamp(0, safeEnd).toInt()
        : safeEnd;

    final length = selection.isValid && !selection.isCollapsed
        ? (selection.end - selection.start).clamp(0, documentLength).toInt()
        : 0;

    widget.controller.replaceText(
      start,
      length,
      text,
      TextSelection.collapsed(offset: start + text.length),
    );

    _requestEditorFocus();

    if (mounted) {
      setState(() {});
    }
  }

  void _insertDate() {
    final now = DateTime.now();

    final value =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';

    _insertTextAtSelection(value);
  }

  void _insertHorizontalRule() {
    _insertTextAtSelection('\n────────────────────────────\n');
  }

  void _insertTablePlaceholder() {
    _insertTextAtSelection(
      '\n| Kolumna 1 | Kolumna 2 | Kolumna 3 |\n'
      '| --- | --- | --- |\n'
      '| Wartość | Wartość | Wartość |\n\n',
    );
  }

  Future<void> _copySelection() async {
    final range = _safeSelectionTextRange();
    if (range == null) return;

    final text = widget.controller.document.toPlainText();
    await Clipboard.setData(
      ClipboardData(text: text.substring(range.start, range.end)),
    );
  }

  Future<void> _cutSelection() async {
    final range = _safeSelectionTextRange();
    if (range == null) return;

    final text = widget.controller.document.toPlainText();
    final selected = text.substring(range.start, range.end);

    await Clipboard.setData(ClipboardData(text: selected));

    widget.controller.replaceText(
      range.start,
      range.end - range.start,
      '',
      TextSelection.collapsed(offset: range.start),
    );

    _requestEditorFocus();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pasteClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;

    if (text == null || text.isEmpty) return;

    _insertTextAtSelection(text);
  }

  void _undo() {
    try {
      widget.controller.undo();
    } catch (_) {}

    _requestEditorFocus();

    if (mounted) {
      setState(() {});
    }
  }

  void _redo() {
    try {
      widget.controller.redo();
    } catch (_) {}

    _requestEditorFocus();

    if (mounted) {
      setState(() {});
    }
  }

  String _currentParagraphValue() {
    final header = _attributeValue(Attribute.header.key);
    final blockQuote = _attributeValue('blockquote');
    final codeBlock = _attributeValue('code-block');

    if (header?.toString() == '1') return 'h1';
    if (header?.toString() == '2') return 'h2';
    if (header?.toString() == '3') return 'h3';
    if (blockQuote == true) return 'quote';
    if (codeBlock == true) return 'code';

    return 'normal';
  }

  String _currentFontFamilyValue() {
    final current = _attributeValue(Attribute.font.key)?.toString();

    if (current == null || current.trim().isEmpty) return 'default';

    if (_fontFamilies.contains(current)) return current;

    return 'default';
  }

  String _currentFontSizeValue() {
    final current = _attributeValue(Attribute.size.key)?.toString();

    if (current == null || current.trim().isEmpty) return 'default';

    if (_fontSizes.contains(current)) return current;

    return 'default';
  }

  String _toHexRGB(Color color) {
    final r = color.red.toRadixString(16).padLeft(2, '0');
    final g = color.green.toRadixString(16).padLeft(2, '0');
    final b = color.blue.toRadixString(16).padLeft(2, '0');

    return '#$r$g$b';
  }

  Color _readCurrentColorFromSelection({
    required bool isBackground,
  }) {
    final key = isBackground ? Attribute.background.key : Attribute.color.key;
    final value = _attributeValue(key);

    if (value == null) {
      return isBackground ? Colors.transparent : widget.resolvedTheme.textColor;
    }

    final raw = value.toString().replaceAll('#', '').trim();

    try {
      if (raw.length == 6) {
        return Color(int.parse('FF$raw', radix: 16));
      }

      if (raw.length == 8) {
        return Color(int.parse(raw, radix: 16));
      }
    } catch (_) {}

    return isBackground ? Colors.transparent : widget.resolvedTheme.textColor;
  }

  void _applyColor(Color color) {
    _formatKeyValue(Attribute.color.key, _toHexRGB(color));
  }

  void _applyBackground(Color color) {
    _formatKeyValue(Attribute.background.key, _toHexRGB(color));
  }

  void _clearColor() {
    _formatKeyValue(Attribute.color.key, null);
  }

  void _clearBackground() {
    _formatKeyValue(Attribute.background.key, null);
  }

  ThemeData _buildColorPickerTheme(BuildContext context) {
    final base = Theme.of(context);
    final bg = widget.resolvedTheme.dashboardContainer;
    final text = widget.resolvedTheme.textColor;
    final accent = widget.resolvedTheme.themeColor;

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        surface: bg,
        onSurface: text,
        primary: accent,
        onPrimary: text,
        outline: text.withAlpha(89),
      ),
      canvasColor: bg,
      cardColor: bg,
      iconTheme: IconThemeData(color: text),
      textTheme: base.textTheme.apply(
        bodyColor: text,
        displayColor: text,
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: text),
        hintStyle: TextStyle(color: text.withAlpha(153)),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: text.withAlpha(89)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: accent),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: bg,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: text),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(text),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(text),
          backgroundColor: WidgetStatePropertyAll(
            widget.resolvedTheme.buttonBackground,
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openThemedColorPicker({
    required bool isBackground,
  }) async {
    final theme = widget.resolvedTheme;

    Color temp = _readCurrentColorFromSelection(
      isBackground: isBackground,
    );

    final result = await showDialog<ColorPickerResult?>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Theme(
          data: _buildColorPickerTheme(context),
          child: AlertDialog(
            backgroundColor: theme.dashboardContainer,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              isBackground ? 'Kolor tła' : 'Kolor tekstu',
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: temp,
                onColorChanged: (color) => temp = color,
                enableAlpha: false,
                labelTypes: const [ColorLabelType.hex],
                hexInputBar: true,
                displayThumbColor: true,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(null),
                child: Text(
                  'Cancel'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(
                    const ColorPickerResult.clear(),
                  );
                },
                child: Text(
                  'Wyczyść',
                  style: TextStyle(color: theme.textColor),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.buttonBackground,
                  foregroundColor: theme.textColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop(
                    ColorPickerResult.pick(temp),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );

    if (result == null) return;

    if (result.isClear) {
      if (isBackground) {
        _clearBackground();
      } else {
        _clearColor();
      }
      return;
    }

    final picked = result.color;
    if (picked == null) return;

    if (isBackground) {
      _applyBackground(picked);
    } else {
      _applyColor(picked);
    }
  }

  bool _isMobileUI(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 600;
  }

  Future<void> _openCustomSearchUI() async {
    if (_isMobileUI(context)) {
      return _openCustomSearchSheet();
    }

    return _openCustomSearchDialog();
  }

  Future<void> _openCustomLinkUI() async {
    if (_isMobileUI(context)) {
      return _openCustomLinkSheet();
    }

    return _openCustomLinkDialog();
  }

  Future<void> _openCustomLinkDialog() async {
    if (_isLinkDialogOpen) return;

    _isLinkDialogOpen = true;

    final theme = widget.resolvedTheme;
    final urlController = TextEditingController();
    final urlFocus = FocusNode();

    try {
      final selection = widget.controller.selection;
      final hasSelection = selection.baseOffset != selection.extentOffset;
      final currentLink =
          _selectionStyle.attributes[Attribute.link.key]?.value?.toString() ??
              '';

      urlController.text = currentLink;

      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              final url = urlController.text.trim();

              String normalizeUrl(String value) {
                final raw = value.trim();

                if (raw.isEmpty) return raw;

                final parsed = Uri.tryParse(raw);

                if (parsed != null && parsed.hasScheme) {
                  return raw;
                }

                return 'https://$raw';
              }

              final canApply = hasSelection && url.isNotEmpty;

              void applyLink() {
                if (!canApply) return;

                _formatKeyValue(
                  Attribute.link.key,
                  normalizeUrl(urlController.text),
                );

                Navigator.of(dialogContext).pop();
              }

              return AlertDialog(
                backgroundColor: theme.dashboardContainer,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(
                  'Wstaw link',
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                content: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!hasSelection)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Zaznacz tekst, żeby dodać do niego link.',
                              style: TextStyle(
                                color: theme.textColor.withAlpha(217),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      TextField(
                        controller: urlController,
                        focusNode: urlFocus,
                        autofocus: true,
                        cursorColor: theme.themeColor,
                        style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: theme.adPopBackground,
                          hintText: 'https://example.com',
                          hintStyle: TextStyle(
                            color: theme.textColor.withAlpha(160),
                          ),
                          prefixIcon: Icon(
                            Icons.link,
                            color: theme.textColor.withAlpha(150),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (_) => setStateDialog(() {}),
                        onSubmitted: (_) => applyLink(),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      'Cancel'.tr,
                      style: TextStyle(color: theme.textColor),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _formatKeyValue(Attribute.link.key, null);
                      Navigator.of(dialogContext).pop();
                    },
                    child: Text(
                      'Usuń',
                      style: TextStyle(color: theme.textColor),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.themeColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: canApply ? applyLink : null,
                    child: const Text(
                      'Zastosuj',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      urlController.dispose();
      urlFocus.dispose();
      _isLinkDialogOpen = false;
    }
  }

  Future<void> _openCustomSearchDialog() async {
    if (_isSearchDialogOpen) return;

    _isSearchDialogOpen = true;

    final previousCanRequest = widget.editorFocusNode.canRequestFocus;
    widget.editorFocusNode.unfocus();
    widget.editorFocusNode.canRequestFocus = false;

    final textController = TextEditingController();
    final searchFieldFocus = FocusNode();

    List<int> matches = [];
    int currentMatchIndex = 0;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              void computeMatches(String query) {
                matches = [];

                if (query.isEmpty) {
                  currentMatchIndex = 0;
                  return;
                }

                final plain = widget.controller.document.toPlainText();
                final normalizedPlain = plain.toLowerCase();
                final normalizedQuery = query.toLowerCase();

                var start = 0;

                while (true) {
                  final found = normalizedPlain.indexOf(
                    normalizedQuery,
                    start,
                  );

                  if (found == -1) break;

                  matches.add(found);
                  start = found + normalizedQuery.length;
                }

                if (matches.isEmpty || currentMatchIndex >= matches.length) {
                  currentMatchIndex = 0;
                }
              }

              void goToMatch(int index) {
                if (matches.isEmpty || index < 0 || index >= matches.length) {
                  return;
                }

                final start = matches[index];
                final end = start + textController.text.length;

                widget.controller.updateSelection(
                  TextSelection(baseOffset: start, extentOffset: end),
                  ChangeSource.local,
                );
              }

              return AlertDialog(
                backgroundColor: widget.resolvedTheme.dashboardContainer,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(
                  'Szukaj w dokumencie',
                  style: TextStyle(
                    color: widget.resolvedTheme.textColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                content: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: textController,
                        focusNode: searchFieldFocus,
                        cursorColor: widget.resolvedTheme.themeColor,
                        autofocus: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: widget.resolvedTheme.adPopBackground,
                          hintText: 'Znajdź tekst',
                          hintStyle: TextStyle(
                            color:
                                widget.resolvedTheme.textColor.withAlpha(153),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color:
                                widget.resolvedTheme.textColor.withAlpha(150),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(
                          color: widget.resolvedTheme.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                        onChanged: (value) {
                          setStateDialog(() {
                            computeMatches(value);

                            if (matches.isNotEmpty) {
                              currentMatchIndex = 0;
                              goToMatch(currentMatchIndex);
                            }
                          });
                        },
                        onSubmitted: (_) {
                          if (matches.isEmpty) return;

                          setStateDialog(() {
                            currentMatchIndex =
                                (currentMatchIndex + 1) % matches.length;
                            goToMatch(currentMatchIndex);
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              matches.isEmpty
                                  ? 'Brak wyników'
                                  : 'Wynik ${currentMatchIndex + 1} z ${matches.length}',
                              style: TextStyle(
                                color: widget.resolvedTheme.textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Poprzedni wynik',
                            onPressed: matches.isEmpty
                                ? null
                                : () {
                                    setStateDialog(() {
                                      currentMatchIndex =
                                          (currentMatchIndex -
                                                  1 +
                                                  matches.length) %
                                              matches.length;
                                      goToMatch(currentMatchIndex);
                                    });
                                  },
                            icon: Icon(
                              Icons.arrow_back,
                              color: widget.resolvedTheme.textColor,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Następny wynik',
                            onPressed: matches.isEmpty
                                ? null
                                : () {
                                    setStateDialog(() {
                                      currentMatchIndex =
                                          (currentMatchIndex + 1) %
                                              matches.length;
                                      goToMatch(currentMatchIndex);
                                    });
                                  },
                            icon: Icon(
                              Icons.arrow_forward,
                              color: widget.resolvedTheme.textColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.resolvedTheme.themeColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Zamknij',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      widget.editorFocusNode.canRequestFocus = previousCanRequest;
      textController.dispose();
      searchFieldFocus.dispose();
      _isSearchDialogOpen = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (widget.editorFocusNode.canRequestFocus) {
          widget.editorFocusNode.requestFocus();
        }
      });
    }
  }

  Future<void> _openCustomSearchSheet() async {
    if (_isSearchDialogOpen) return;

    _isSearchDialogOpen = true;

    final previousCanRequest = widget.editorFocusNode.canRequestFocus;
    widget.editorFocusNode.unfocus();
    widget.editorFocusNode.canRequestFocus = false;

    try {
      await showDraggableSheet<void>(
        context: context,
        initialChildSize: 0.45,
        minChildSize: 0.30,
        maxChildSize: 0.70,
        builder: (ctx, scrollController) {
          return DocsSearchSheet(
            scrollController: scrollController,
            quillController: widget.controller,
            theme: widget.resolvedTheme,
          );
        },
      );
    } finally {
      widget.editorFocusNode.canRequestFocus = previousCanRequest;
      _isSearchDialogOpen = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (widget.editorFocusNode.canRequestFocus) {
          widget.editorFocusNode.requestFocus();
        }
      });
    }
  }

  Future<void> _openCustomLinkSheet() async {
    if (_isLinkDialogOpen) return;

    _isLinkDialogOpen = true;

    try {
      await showDraggableSheet<void>(
        context: context,
        initialChildSize: 0.45,
        minChildSize: 0.30,
        maxChildSize: 0.70,
        builder: (ctx, scrollController) {
          return DocsLinkSheet(
            scrollController: scrollController,
            quillController: widget.controller,
            theme: widget.resolvedTheme,
          );
        },
      );
    } finally {
      _isLinkDialogOpen = false;
    }
  }

  Future<String?> _showVersionComment(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    if (!isMobile) {
      return showDialog<String>(
        context: context,
        builder: (_) => const VersionCommentDialog(),
      );
    }

    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.60,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return VersionCommentSheet(scrollController: scrollController);
          },
        );
      },
    );
  }

  Future<void> _handleSaveVersion() async {
    final callback = widget.onSaveVersionPressed;
    if (callback == null) return;

    final comment = await _showVersionComment(context);
    if (comment == null) return;

    await callback(comment);
  }

  Widget _buildToolbarShell(Widget child) {
    return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: widget.sidebarColor.withAlpha(226),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: widget.resolvedTheme.dashboardBoarder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: _isMobileToolbar ? 8 : 12,
              vertical:  0,
            ),
            child: child,
    );
  }

  Widget _buildHeaderSection() {
    if (widget.header == null) {
      return const SizedBox.shrink();
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: widget.isDocumentHeaderVisible
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    _isMobileToolbar ? 8 : 14,
                     0,
                    _isMobileToolbar ? 8 : 14,
                     0,
                  ),
                  child: widget.header!,
                ),
                Container(
                  height: 1,
                  margin: EdgeInsets.symmetric(
                    horizontal: _isMobileToolbar ? 6 : 10,
                  ),
                  color: widget.resolvedTheme.dashboardBoarder.withAlpha(125),
                ),
                const SizedBox(height: 8),
              ],
            )
          : const SizedBox(width: double.infinity),
    );
  }

  Widget _gap([double? width]) {
    return SizedBox(width: width ?? _itemGap);
  }

  Widget _buildToolbarGroup({
    required List<Widget> children,
  }) {
    return
    //  Container(
    //   height: _buttonHeight + 8,
    //   padding: EdgeInsets.symmetric(
    //     horizontal: _isMobileToolbar ? 5 : 7,
    //     vertical: 4,
    //   ),
    //   decoration: BoxDecoration(
    //     color: widget.resolvedTheme.dashboardContainer.withAlpha(80),
    //     borderRadius: BorderRadius.circular(999),
    //     border: Border.all(
    //       color: widget.resolvedTheme.dashboardBoarder.withAlpha(105),
    //     ),
    //   ),
    //   child:
       Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    bool selected = false,
    bool primary = false,
    String? anchorKey,
    EmmaUiAnchorSpec? spec,
  }) {
    final theme = widget.resolvedTheme;
    final disabled = onPressed == null;

    final background =
        primary || selected ? theme.themeColor : Colors.transparent;
    final foreground = primary || selected ? Colors.white : theme.textColor;

    final button = Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: disabled ? 0.45 : 1,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(_buttonRadius),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(_buttonRadius),
            child: SizedBox(
              width: _buttonHeight,
              height: _buttonHeight,
              child: Icon(
                icon,
                size: _iconSize,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );

    if (anchorKey == null || anchorKey.trim().isEmpty) {
      return button;
    }

    return EmmaUiAnchorTarget(
      anchorKey: anchorKey,
      spec: spec,
      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
      tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
      child: button,
    );
  }


  Widget _buildHeaderToggleButton() {
    return _buildIconButton(
      icon: widget.isDocumentHeaderVisible
          ? Icons.keyboard_arrow_up_rounded
          : Icons.keyboard_arrow_down_rounded,
      tooltip: widget.isDocumentHeaderVisible
          ? 'Ukryj pasek tytułu'
          : 'Pokaż pasek tytułu',
      onPressed: widget.onToggleDocumentHeaderPressed,
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required double width,
    required String tooltip,
  }) {
    final theme = widget.resolvedTheme;

    return Tooltip(
      message: tooltip,
      child: Container(
        height: _buttonHeight,
        width: width,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(_buttonRadius),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        padding: EdgeInsets.symmetric(horizontal: _dense ? 8 : 10),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: theme.dashboardContainer,
            iconEnabledColor: theme.textColor,
            iconSize: 18,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildFontSizeStepper() {
    final theme = widget.resolvedTheme;
    final value = _currentFontSizeValue();
    final displayValue = value == 'default' ? '11' : value;

    Widget sideButton({
      required IconData icon,
      required VoidCallback onTap,
      required String tooltip,
    }) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 30,
            height: _buttonHeight,
            child: Icon(
              icon,
              size: 17,
              color: theme.textColor,
            ),
          ),
        ),
      );
    }

    return Container(
      height: _buttonHeight,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_buttonRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          sideButton(
            icon: Icons.remove,
            tooltip: 'Zmniejsz font',
            onTap: _decreaseFontSize,
          ),
          Container(
            width: 46,
            height: _buttonHeight - 8,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.adPopBackground.withAlpha(120),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dashboardBoarder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: theme.dashboardContainer,
                icon: const SizedBox.shrink(),
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
                selectedItemBuilder: (_) {
                  return [
                    Center(
                      child: Text(
                        displayValue,
                        style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    ..._fontSizes.map(
                      (size) => Center(
                        child: Text(
                          size,
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ];
                },
                items: _fontSizeItems(),
                onChanged: _applyFontSize,
              ),
            ),
          ),
          sideButton(
            icon: Icons.add,
            tooltip: 'Zwiększ font',
            onTap: _increaseFontSize,
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _paragraphItems() {
    final theme = widget.resolvedTheme;

    TextStyle style({
      double size = 12,
      FontWeight weight = FontWeight.w800,
    }) {
      return TextStyle(
        color: theme.textColor,
        fontSize: size,
        fontWeight: weight,
      );
    }

    return [
      DropdownMenuItem(
        value: 'normal',
        child: Text('Zwykły tekst', style: style()),
      ),
      DropdownMenuItem(
        value: 'h1',
        child: Text('Nagłówek 1', style: style(size: 15)),
      ),
      DropdownMenuItem(
        value: 'h2',
        child: Text('Nagłówek 2', style: style(size: 14)),
      ),
      DropdownMenuItem(
        value: 'h3',
        child: Text('Nagłówek 3', style: style(size: 13)),
      ),
      DropdownMenuItem(
        value: 'quote',
        child: Text('Cytat', style: style()),
      ),
      DropdownMenuItem(
        value: 'code',
        child: Text('Blok kodu', style: style()),
      ),
    ];
  }

  List<DropdownMenuItem<String>> _fontFamilyItems() {
    final theme = widget.resolvedTheme;

    return [
      DropdownMenuItem(
        value: 'default',
        child: Text(
          'Domyślna',
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
      ..._fontFamilies.map(
        (font) => DropdownMenuItem(
          value: font,
          child: Text(
            font,
            style: TextStyle(
              color: theme.textColor,
              fontFamily: font,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    ];
  }

  List<DropdownMenuItem<String>> _fontSizeItems() {
    final theme = widget.resolvedTheme;

    return [
      DropdownMenuItem(
        value: 'default',
        child: Text(
          '11',
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
      ..._fontSizes.map(
        (size) => DropdownMenuItem(
          value: size,
          child: Text(
            size,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    ];
  }

  PopupMenuItem<String> _moreItem({
    required String value,
    required IconData icon,
    required String label,
  }) {
    final theme = widget.resolvedTheme;

    return PopupMenuItem<String>(
      value: value,
      height: 42,
      child: Row(
        children: [
          Icon(icon, size: 19, color: theme.textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreMenuButton() {
    final theme = widget.resolvedTheme;

    return PopupMenuButton<String>(
      tooltip: 'Więcej',
      color: theme.dashboardContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.dashboardBoarder),
      ),
      onSelected: (value) {
        switch (value) {
          case 'new_page':
              if(widget.onNewPagePressed != null) {
                widget.onNewPagePressed!.call();
              } else {
                widget.onInsertPageBreakPressed?.call();
              }
              break;

            case 'print':
              widget.onPrintPressed?.call();
              break;

            case 'page_setup':
              widget.onPageSetupPressed?.call();
              break;
          case 'documents':
            widget.onMyDocumentPressed?.call();
            break;
          case 'templates':
            widget.onCreateTemplatePressed?.call();
            break;
          case 'save_version':
            _handleSaveVersion();
            break;
          case 'pdf':
            widget.onGeneratePressed?.call();
            break;
          case 'page_break':
            widget.onInsertPageBreakPressed?.call();
            break;
          case 'search':
            _openCustomSearchUI();
            break;
          case 'table':
            _insertTablePlaceholder();
            break;
          case 'line':
            _insertHorizontalRule();
            break;
          case 'date':
            _insertDate();
            break;
          case 'copy':
            _copySelection();
            break;
          case 'cut':
            _cutSelection();
            break;
          case 'paste':
            _pasteClipboard();
            break;
          case 'clear':
            _clearFormatting();
            break;
          case 'quote':
            _applyParagraphStyle('quote');
            break;
          case 'code_block':
            _applyParagraphStyle('code');
            break;
          case 'justify':
            _applyAlignment('justify');
            break;
          case 'line_height_115':
            _applyLineHeight('1.15');
            break;
          case 'line_height_15':
            _applyLineHeight('1.5');
            break;
          case 'line_height_2':
            _applyLineHeight('2.0');
            break;
        }
      },
      itemBuilder: (_) => [

        _moreItem(
          value: 'new_page',
          icon: Icons.note_add_outlined,
          label: 'Nowa strona',
        ),
        _moreItem(
          value: 'print',
          icon: Icons.print,
          label: 'Drukuj',
        ),
        _moreItem(
          value: 'page_setup',
          icon: Icons.tune_outlined,
          label: 'Ustawienia strony',
        ),


        _moreItem(
          value: 'documents',
          icon: Icons.folder_copy_outlined,
          label: 'Dokumenty',
        ),
        _moreItem(
          value: 'templates',
          icon: Icons.dashboard_customize_outlined,
          label: 'Template',
        ),
        _moreItem(
          value: 'save_version',
          icon: Icons.history_outlined,
          label: 'Zapisz wersję',
        ),
        _moreItem(
          value: 'pdf',
          icon: Icons.picture_as_pdf_outlined,
          label: 'Generuj PDF',
        ),
        _moreItem(
          value: 'page_break',
          icon: Icons.splitscreen_outlined,
          label: 'Podział strony',
        ),
        const PopupMenuDivider(),
        _moreItem(
          value: 'search',
          icon: Icons.search,
          label: 'Szukaj',
        ),
        _moreItem(
          value: 'table',
          icon: Icons.table_chart_outlined,
          label: 'Tabela tekstowa',
        ),
        _moreItem(
          value: 'line',
          icon: Icons.horizontal_rule,
          label: 'Linia pozioma',
        ),
        _moreItem(
          value: 'date',
          icon: Icons.today_outlined,
          label: 'Data',
        ),
        const PopupMenuDivider(),
        _moreItem(
          value: 'quote',
          icon: Icons.format_quote,
          label: 'Cytat',
        ),
        _moreItem(
          value: 'code_block',
          icon: Icons.integration_instructions_outlined,
          label: 'Blok kodu',
        ),
        _moreItem(
          value: 'justify',
          icon: Icons.format_align_justify,
          label: 'Wyjustuj',
        ),
        _moreItem(
          value: 'clear',
          icon: Icons.format_clear,
          label: 'Wyczyść formatowanie',
        ),
        const PopupMenuDivider(),
        _moreItem(
          value: 'line_height_115',
          icon: Icons.format_line_spacing,
          label: 'Interlinia 1.15',
        ),
        _moreItem(
          value: 'line_height_15',
          icon: Icons.format_line_spacing,
          label: 'Interlinia 1.5',
        ),
        _moreItem(
          value: 'line_height_2',
          icon: Icons.format_line_spacing,
          label: 'Interlinia 2.0',
        ),
        const PopupMenuDivider(),
        _moreItem(
          value: 'copy',
          icon: Icons.content_copy,
          label: 'Kopiuj',
        ),
        _moreItem(
          value: 'cut',
          icon: Icons.content_cut,
          label: 'Wytnij',
        ),
        _moreItem(
          value: 'paste',
          icon: Icons.content_paste,
          label: 'Wklej',
        ),
      ],
      child: Container(
        width: _buttonHeight,
        height: _buttonHeight,
        decoration: BoxDecoration(
          color: theme.dashboardContainer.withAlpha(180),
          borderRadius: BorderRadius.circular(_buttonRadius),
        ),
        child: Icon(
          Icons.more_vert,
          size: _iconSize,
          color: theme.textColor,
        ),
      ),
    );
  }

  Widget _buildHistorySaveGroup() {
    return _buildToolbarGroup(
      children: [
        _buildIconButton(
          icon: Icons.undo,
          tooltip: 'Cofnij Ctrl+Z',
          onPressed: _undo,
        ),
        _gap(),
        _buildIconButton(
          icon: Icons.redo,
          tooltip: 'Ponów Ctrl+Y',
          onPressed: _redo,
        ),
        _gap(),
        _buildIconButton(
          icon: Icons.save_outlined,
          tooltip: 'Zapisz Ctrl+S',
          primary: widget.hasUnsavedChanges,
          onPressed: widget.onSavePressed,
          anchorKey: DocsEmmaAnchors.saveDocumentButton.anchorKey,

          spec: DocsEmmaAnchors.saveDocumentButton,
        ),
        _gap(),

        _buildIconButton(
          icon: Icons.print_outlined,
          tooltip: 'Drukuj Ctrl+P',
          onPressed: widget.onPrintPressed,
        ),

        _gap(),
        _buildHeaderToggleButton(),

        _gap(),
        _buildIconButton(
          icon: widget.whitePaperMode
              ? Icons.article_outlined
              : Icons.dark_mode_outlined,
          tooltip: widget.whitePaperMode
              ? 'Przełącz na theme paper'
              : 'Przełącz na white paper',
          selected: widget.whitePaperMode,
          onPressed: widget.onTogglePaperModePressed,
        ),
        _gap(),
        _buildIconButton(
          icon: Icons.auto_awesome_rounded,
          tooltip: widget.emmaActive ? 'Ukryj Emmę' : 'Pokaż Emmę',
          selected: widget.emmaActive,
          onPressed: widget.onEmmaTogglePressed,
        ),
      ],
    );
  }

  Widget _buildTypographyGroup() {
    return _buildToolbarGroup(
      children: [
        _buildDropdown(
          value: _currentParagraphValue(),
          width: _isMobileToolbar ? 126 : _paragraphWidth,
          tooltip: 'Styl akapitu',
          items: _paragraphItems(),
          onChanged: _applyParagraphStyle,
        ),
        if (!_isMobileToolbar) ...[
          _gap(8),
          _buildDropdown(
            value: _currentFontFamilyValue(),
            width: _fontWidth,
            tooltip: 'Czcionka',
            items: _fontFamilyItems(),
            onChanged: _applyFontFamily,
          ),
        ],
        _gap(8),
        _buildFontSizeStepper(),
      ],
    );
  }

  Widget _buildTextStyleGroup() {
    return _buildToolbarGroup(
      children: [
        _buildIconButton(
          icon: Icons.format_bold,
          tooltip: 'Pogrubienie Ctrl+B',
          selected: _hasAttributeValue(Attribute.bold.key, true),
          onPressed: () => _toggleAttribute(Attribute.bold),
        ),
        _gap(),
        _buildIconButton(
          icon: Icons.format_italic,
          tooltip: 'Kursywa Ctrl+I',
          selected: _hasAttributeValue(Attribute.italic.key, true),
          onPressed: () => _toggleAttribute(Attribute.italic),
        ),
        _gap(),
        _buildIconButton(
          icon: Icons.format_underlined,
          tooltip: 'Podkreślenie Ctrl+U',
          selected: _hasAttributeValue(Attribute.underline.key, true),
          onPressed: () => _toggleAttribute(Attribute.underline),
        ),
        _gap(),
        _buildIconButton(
          icon: Icons.format_color_text,
          tooltip: 'Kolor tekstu',
          onPressed: () => _openThemedColorPicker(isBackground: false),
        ),
        _gap(),
        _buildIconButton(
          icon: Icons.format_color_fill,
          tooltip: 'Kolor tła',
          onPressed: () => _openThemedColorPicker(isBackground: true),
        ),
      ],
    );
  }

  Widget _buildParagraphGroup() {
    return _buildToolbarGroup(
      children: [
        _buildIconButton(
          icon: Icons.link,
          tooltip: 'Wstaw link',
          onPressed: _openCustomLinkUI,
          anchorKey: DocsEmmaAnchors.insertLinkButton.anchorKey,

          spec: DocsEmmaAnchors.insertLinkButton,
        ),
        _gap(),
        _buildIconButton(
          icon: Icons.format_align_left,
          tooltip: 'Wyrównaj do lewej',
          selected: _attributeValue(Attribute.align.key) == null ||
              _attributeValue(Attribute.align.key) == 'left',
          onPressed: () => _applyAlignment('left'),
        ),
        _gap(),
        _buildIconButton(
          icon: Icons.format_align_center,
          tooltip: 'Wyśrodkuj',
          selected: _hasAttributeValue(Attribute.align.key, 'center'),
          onPressed: () => _applyAlignment('center'),
        ),
        _gap(),
        _buildIconButton(
          icon: Icons.format_align_right,
          tooltip: 'Wyrównaj do prawej',
          selected: _hasAttributeValue(Attribute.align.key, 'right'),
          onPressed: () => _applyAlignment('right'),
        ),
        _gap(),
        _buildIconButton(
          icon: Icons.format_list_bulleted,
          tooltip: 'Lista punktowana',
          selected: _hasAttributeValue(
            Attribute.list.key,
            Attribute.ul.value,
          ),
          onPressed: () => _toggleAttribute(Attribute.ul),
        ),
        _gap(),
        _buildIconButton(
          icon: Icons.format_list_numbered,
          tooltip: 'Lista numerowana',
          selected: _hasAttributeValue(
            Attribute.list.key,
            Attribute.ol.value,
          ),
          onPressed: () => _toggleAttribute(Attribute.ol),
        ),
        if (!_veryDense) ...[
          _gap(),
          _buildIconButton(
            icon: Icons.format_indent_decrease,
            tooltip: 'Zmniejsz wcięcie',
            onPressed: _decreaseIndent,
          ),
          _gap(),
          _buildIconButton(
            icon: Icons.format_indent_increase,
            tooltip: 'Zwiększ wcięcie',
            onPressed: _increaseIndent,
          ),
        ],
      ],
    );
  }



  Widget _buildDesktopMainRibbon() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHistorySaveGroup(),
          _buildGap(_groupGap),
          _buildTypographyGroup(),
          _buildGap(_groupGap),
          _buildTextStyleGroup(),
          _buildGap(_groupGap),
          _buildParagraphGroup(),
          _buildGap(_groupGap),
          _buildMoreMenuButton(),
        ],
      ),
    );
  }

  Widget _buildGap(double _groupGap) {
    return Padding(
        padding: EdgeInsets.symmetric(vertical:12, horizontal: _groupGap/2),
        child: VerticalDivider(color: widget.resolvedTheme.textColor.withAlpha(125)),
      );
  }

  Widget _buildMobileRibbon() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHistorySaveGroup(),
        _buildGap(_groupGap),        
        _buildTypographyGroup(),
        _buildGap(_groupGap),
        _buildTextStyleGroup(),
        _buildGap( _groupGap),        
        _buildMoreMenuButton(),
      ],
    );
  }

  Widget _buildRibbon(BoxConstraints constraints) {
    final child =
        _isMobileToolbar ? _buildMobileRibbon() : _buildDesktopMainRibbon();

    final shouldScroll = _isMobileToolbar || constraints.maxWidth < 1360;

    if (!shouldScroll) {
      return SizedBox(
        width: double.infinity,
        height: _bottomToolbarHeight,
        child: Align(
          alignment: Alignment.center,
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: _bottomToolbarHeight,
      child: ScrollConfiguration(
        behavior: const _NoGlowScrollBehavior(),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: _isMobileToolbar
              ? const BouncingScrollPhysics()
              : const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth.isFinite ? constraints.maxWidth : 0,
            ),
            child: Align(
              alignment:
                  _isMobileToolbar ? Alignment.centerLeft : Alignment.center,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnifiedBar(BoxConstraints constraints) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeaderSection(),
        _buildRibbon(constraints),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _buildPopupTheme(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return _buildToolbarShell(_buildUnifiedBar(constraints));
        },
      ),
    );
  }
}

class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
