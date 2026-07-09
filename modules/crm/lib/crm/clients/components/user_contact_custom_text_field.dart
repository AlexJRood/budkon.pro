import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

final textFieldFocusProvider =
    StateNotifierProvider<TextFieldFocusNotifier, Map<int, bool>>(
  (ref) => TextFieldFocusNotifier(),
);

class TextFieldFocusNotifier extends StateNotifier<Map<int, bool>> {
  TextFieldFocusNotifier() : super({});

  void setFocus(int id, bool isFocused) {
    state = {...state, id: isFocused};
  }
}

/// Controller that renders inline suffix as part of the same text layout.
/// Text stored inside controller is the DISPLAY text (may include spaces),
/// but we keep syncing a RAW version to the external controller.
class SuffixTextEditingController extends TextEditingController {
  String _suffix = '';

  String get suffix => _suffix;

  set suffix(String v) {
    final nv = v.trim();
    if (nv == _suffix) return;
    _suffix = nv;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = super.buildTextSpan(
      context: context,
      style: style,
      withComposing: withComposing,
    );

    if (_suffix.isEmpty || text.isEmpty) return base;

    final suffixStyle = (style ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w700,
      color: (style?.color ?? Colors.white).withAlpha(220),
    );

    return TextSpan(
      children: [
        base,
        TextSpan(text: ' $_suffix', style: suffixStyle),
      ],
    );
  }
}

class UserContactCustomTextField extends ConsumerStatefulWidget {
  final int id;
  final String hintText;
  final TextEditingController controller;
  final String valueKey;
  final void Function(String, String) onChanged;

  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final void Function(String)? onFieldSubmitted;
  final int maxLines;

  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool normalizeCommaToDot;

  /// Inline suffix (e.g. PLN / %)
  final String? inlineSuffixText;

  final TextStyle? textStyle;

  /// Format thousands in UI: 1000000 -> 1 000 000
  final bool formatThousands;
  final String thousandSeparator;

  /// Optional external focus node
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final TextInputAction? textInputAction;

  const UserContactCustomTextField({
    super.key,
    required this.id,
    required this.hintText,
    required this.controller,
    required this.valueKey,
    required this.onChanged,
    this.validator,
    this.onSaved,
    this.onFieldSubmitted,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.normalizeCommaToDot = false,
    this.inlineSuffixText,
    this.textStyle,
    this.formatThousands = true,
    this.thousandSeparator = ' ',
    this.focusNode,
    this.nextFocusNode,
    this.textInputAction,
  });

  @override
  ConsumerState<UserContactCustomTextField> createState() =>
      _UserContactCustomTextFieldState();
}

class _UserContactCustomTextFieldState
    extends ConsumerState<UserContactCustomTextField> {
  late FocusNode _focusNode;
  late final SuffixTextEditingController _displayCtrl;

  bool _syncing = false;
  bool _ownsFocusNode = false;

  @override
  void initState() {
    super.initState();

    _initFocusNode(widget.focusNode);

    _displayCtrl = SuffixTextEditingController();
    _displayCtrl.suffix = (widget.inlineSuffixText ?? '').trim();

    _displayCtrl.text = _toDisplay(widget.controller.text);
    _displayCtrl.selection = TextSelection.collapsed(
      offset: _displayCtrl.text.length,
    );

    widget.controller.addListener(_syncFromExternal);
    _displayCtrl.addListener(_syncFromDisplay);
    _displayCtrl.addListener(_clampSelection);
  }

  void _initFocusNode(FocusNode? externalFocusNode) {
    _ownsFocusNode = externalFocusNode == null;
    _focusNode = externalFocusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(textFieldFocusProvider.notifier)
          .setFocus(widget.id, _focusNode.hasFocus);
    });
  }
  void _ensureVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;

      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: 0.55,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }
  void _disposeFocusNode() {
    _focusNode.removeListener(_handleFocusChanged);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
  }

  void _handleFocusChanged() {
    if (!mounted) return;

    ref
        .read(textFieldFocusProvider.notifier)
        .setFocus(widget.id, _focusNode.hasFocus);

    if (_focusNode.hasFocus) {
      _ensureVisible();
    }
  }

  @override
  void didUpdateWidget(covariant UserContactCustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    _displayCtrl.suffix = (widget.inlineSuffixText ?? '').trim();

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncFromExternal);
      widget.controller.addListener(_syncFromExternal);

      _displayCtrl.text = _toDisplay(widget.controller.text);
      _displayCtrl.selection = TextSelection.collapsed(
        offset: _displayCtrl.text.length,
      );
    }

    if (oldWidget.focusNode != widget.focusNode) {
      _disposeFocusNode();
      _initFocusNode(widget.focusNode);
    }

    if (oldWidget.id != widget.id) {
      ref.read(textFieldFocusProvider.notifier).setFocus(oldWidget.id, false);
      ref
          .read(textFieldFocusProvider.notifier)
          .setFocus(widget.id, _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromExternal);
    _displayCtrl.removeListener(_syncFromDisplay);
    _displayCtrl.removeListener(_clampSelection);
    _displayCtrl.dispose();
    _disposeFocusNode();
    super.dispose();
  }

  String _normalizeToDot(String v) => v.replaceAll(',', '.');

  String _stripThousands(String v) {
    if (v.isEmpty) return v;

    if (widget.thousandSeparator.isNotEmpty) {
      v = v.replaceAll(widget.thousandSeparator, '');
    }

    // Defensive cleanup for numeric fields only.
    v = v.replaceAll(' ', '');
    return v;
  }

  String _formatThousands(String raw) {
    if (raw.isEmpty) return raw;

    final cleaned = _stripThousands(raw);
    final parts = cleaned.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : null;

    if (intPart.isEmpty) return cleaned;

    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final idxFromEnd = intPart.length - i;
      buf.write(intPart[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) {
        buf.write(widget.thousandSeparator);
      }
    }

    final formattedInt = buf.toString();
    if (decPart == null) return formattedInt;
    return '$formattedInt.$decPart';
  }

  String _toDisplay(String externalRaw) {
    var v = externalRaw;

    if (widget.normalizeCommaToDot) {
      v = _normalizeToDot(v);
    }

    if (widget.formatThousands) {
      v = _formatThousands(v);
    }

    return v;
  }

  String _toExternalRaw(String display) {
    var v = display;

    // IMPORTANT:
    // Do not strip spaces for regular text fields like title.
    if (widget.formatThousands) {
      v = _stripThousands(v);
    }

    if (widget.normalizeCommaToDot) {
      v = _normalizeToDot(v);
    }

    return v;
  }

  void _syncFromExternal() {
    if (_syncing) return;
    _syncing = true;

    final display = _toDisplay(widget.controller.text);
    final old = _displayCtrl.text;

    if (display != old) {
      _displayCtrl.value = _displayCtrl.value.copyWith(
        text: display,
        selection: TextSelection.collapsed(
          offset: display.length.clamp(0, display.length),
        ),
        composing: TextRange.empty,
      );
    }

    _syncing = false;
  }

  void _syncFromDisplay() {
    if (_syncing) return;
    _syncing = true;

    final raw = _toExternalRaw(_displayCtrl.text);
    if (widget.controller.text != raw) {
      widget.controller.value = widget.controller.value.copyWith(
        text: raw,
        selection: TextSelection.collapsed(offset: raw.length),
        composing: TextRange.empty,
      );
    }

    _syncing = false;
  }

  void _clampSelection() {
    final max = _displayCtrl.text.length;
    final sel = _displayCtrl.selection;

    final base = sel.baseOffset.clamp(0, max);
    final extent = sel.extentOffset.clamp(0, max);

    if (base != sel.baseOffset || extent != sel.extentOffset) {
      _displayCtrl.selection = TextSelection(
        baseOffset: base,
        extentOffset: extent,
      );
    }
  }

  int _countDigits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '').length;

  int _findCursorByDigitIndex(String display, int digitIndex) {
    if (digitIndex <= 0) return 0;

    int seen = 0;
    for (int i = 0; i < display.length; i++) {
      final ch = display[i];
      if (RegExp(r'[0-9]').hasMatch(ch)) {
        seen++;
        if (seen >= digitIndex) return i + 1;
      }
    }

    return display.length;
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = ref.watch(textFieldFocusProvider)[widget.id] ?? false;
    final theme = ref.watch(themeColorsProvider);

    final effectiveTextStyle =
        (widget.textStyle ??
                Theme.of(context).textTheme.bodyMedium ??
                const TextStyle())
            .copyWith(color: theme.textColor);

    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: TextFormField(
        textInputAction: widget.textInputAction ?? TextInputAction.next,
        onFieldSubmitted: widget.onFieldSubmitted ??
                (_) {
              if (widget.nextFocusNode != null) {
                widget.nextFocusNode!.requestFocus();
              } else {
                FocusScope.of(context).nextFocus();
              }
            },
        controller: _displayCtrl,
        focusNode: _focusNode,
        maxLines: widget.maxLines,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        style: effectiveTextStyle,
        scrollPadding: EdgeInsets.only(
          left: 20,
          top: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 140,
        ),
        onTap: _ensureVisible,
        decoration: InputDecoration(
          filled: true,
          fillColor: isFocused ? Colors.transparent : theme.dashboardContainer,
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: theme.textColor,
            fontSize: 12,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 14.0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.0),
            borderSide: BorderSide(color: theme.dashboardBoarder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: theme.dashboardBoarder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.0),
            borderSide: BorderSide(color: theme.dashboardBoarder),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.0),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
        cursorColor: theme.textColor,
        validator: widget.validator,
        onSaved: widget.onSaved,
        onChanged: (rawDisplay) {
          if (widget.normalizeCommaToDot && rawDisplay.contains(',')) {
            final oldSel = _displayCtrl.selection;
            final norm = _normalizeToDot(rawDisplay);

            _displayCtrl.value = _displayCtrl.value.copyWith(
              text: norm,
              selection: TextSelection.collapsed(
                offset: oldSel.baseOffset.clamp(0, norm.length),
              ),
              composing: TextRange.empty,
            );
          }

          if (widget.formatThousands) {
            final before = _displayCtrl.text;
            final sel = _displayCtrl.selection;

            final digitsBeforeCursor = _countDigits(
              before.substring(0, sel.baseOffset.clamp(0, before.length)),
            );

            final externalRaw = _toExternalRaw(before);
            final formatted = _formatThousands(externalRaw);

            if (formatted != before) {
              final newCursor =
                  _findCursorByDigitIndex(formatted, digitsBeforeCursor);
              _displayCtrl.value = _displayCtrl.value.copyWith(
                text: formatted,
                selection: TextSelection.collapsed(
                  offset: newCursor.clamp(0, formatted.length),
                ),
                composing: TextRange.empty,
              );
            }
          }

          final externalRaw = _toExternalRaw(_displayCtrl.text);
          widget.onChanged(widget.valueKey, externalRaw);
        },
      ),
    );
  }
}