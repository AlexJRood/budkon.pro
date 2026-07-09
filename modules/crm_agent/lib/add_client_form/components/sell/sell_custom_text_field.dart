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

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final int? maxLength;

  ThousandsSeparatorInputFormatter({this.maxLength});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (maxLength != null && digits.length > maxLength!) {
      digits = digits.substring(0, maxLength!);
    }

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = _formatWithSpaces(digits);

    final digitsBeforeCursor = _countDigitsBeforeCursor(
      newValue.text,
      newValue.selection.baseOffset,
    );

    final newCursor = _findCursorPosition(formatted, digitsBeforeCursor);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  String _formatWithSpaces(String digits) {
    final chars = digits.split('').reversed.toList();
    final buffer = StringBuffer();

    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(chars[i]);
    }

    return buffer.toString().split('').reversed.join();
  }

  int _countDigitsBeforeCursor(String text, int cursorOffset) {
    final safeOffset = cursorOffset.clamp(0, text.length);
    return text
        .substring(0, safeOffset)
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;
  }

  int _findCursorPosition(String formatted, int digitsBeforeCursor) {
    if (digitsBeforeCursor <= 0) return 0;

    int digitCount = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (RegExp(r'\d').hasMatch(formatted[i])) {
        digitCount++;
        if (digitCount == digitsBeforeCursor) {
          return i + 1;
        }
      }
    }

    return formatted.length;
  }
}

class SellCustomTextField extends ConsumerStatefulWidget {
  final int id;
  final String hintText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final int maxLines;
  final int minLines;
  final void Function(String) onChanged;
  final String valueKey;
  final bool useThousandsSeparator;
  final int? maxLength;
  final bool emitRawValue;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  const SellCustomTextField({
    super.key,
    required this.id,
    required this.hintText,
    required this.controller,
    required this.valueKey,
    this.validator,
    this.onSaved,
    this.maxLines = 1,
    this.minLines = 1,
    required this.onChanged,
    this.useThousandsSeparator = false,
    this.maxLength,
    this.emitRawValue = false,
    this.keyboardType,
    this.focusNode,
    this.nextFocusNode,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  ConsumerState<SellCustomTextField> createState() =>
      _SellCustomTextFieldState();
}

class _SellCustomTextFieldState extends ConsumerState<SellCustomTextField> {
  late final FocusNode _internalFocusNode;

  FocusNode get focusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();

    _internalFocusNode = FocusNode();

    focusNode.addListener(() {
      if (!mounted) return;

      ref
          .read(textFieldFocusProvider.notifier)
          .setFocus(widget.id, focusNode.hasFocus);

      if (focusNode.hasFocus) {
        _ensureVisible();
      }
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
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
  List<TextInputFormatter> _buildInputFormatters() {
    if (widget.useThousandsSeparator) {
      return [
        FilteringTextInputFormatter.allow(RegExp(r'[\d\s]')),
        ThousandsSeparatorInputFormatter(maxLength: widget.maxLength),
      ];
    }

    if (widget.maxLength != null) {
      return [
        LengthLimitingTextInputFormatter(widget.maxLength),
      ];
    }

    return [];
  }

  void _handleChanged(String value) {
    if (widget.useThousandsSeparator && widget.emitRawValue) {
      widget.onChanged(value.replaceAll(' ', ''));
      return;
    }

    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = ref.watch(textFieldFocusProvider)[widget.id] ?? false;
    final theme = ref.watch(themeColorsProvider);

    return GestureDetector(
      onTap: focusNode.requestFocus,
      child: TextFormField(
        textInputAction: widget.textInputAction ?? TextInputAction.next,
        scrollPadding: EdgeInsets.only(
          left: 20,
          top: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 140,
        ),
        onTap: _ensureVisible,
        onFieldSubmitted: widget.onFieldSubmitted ??
                (_) {
              if (widget.nextFocusNode != null) {
                widget.nextFocusNode!.requestFocus();
              } else {
                FocusScope.of(context).nextFocus();
              }
            },
        controller: widget.controller,
        focusNode: focusNode,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        onChanged: _handleChanged,
        inputFormatters: _buildInputFormatters(),
        keyboardType: widget.keyboardType ??
            (widget.useThousandsSeparator
                ? TextInputType.number
                : TextInputType.text),
        maxLength: widget.useThousandsSeparator ? null : widget.maxLength,
        style: TextStyle(
          color: theme.textColor,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor:
              isFocused ? theme.textFieldColor : theme.dashboardContainer,
          labelText: widget.hintText,
          hintText: widget.hintText,
          counterText: '',
          floatingLabelStyle: TextStyle(
            color: theme.textColor,
            fontSize: 14,
          ),
          labelStyle: TextStyle(
            color: theme.textColor,
            fontSize: 14,
          ),
          hintStyle: TextStyle(
            color: theme.textColor,
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: theme.dashboardBoarder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: theme.dashboardBoarder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: theme.dashboardBoarder),
          ),
        ),
        cursorColor: theme.textColor,
        validator: widget.validator,
        onSaved: widget.onSaved,
      ),
    );
  }
}