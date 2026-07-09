import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/backgroundgradient.dart';

class SecondaryTextfield extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String)? onChanged;
  final FocusNode? focusNode;
  final FocusNode? reqNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const SecondaryTextfield({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.focusNode,
    this.reqNode,
    this.textInputAction,
    this.onSubmitted,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  ConsumerState<SecondaryTextfield> createState() => _SecondaryTextfieldState();
}

class _SecondaryTextfieldState extends ConsumerState<SecondaryTextfield> {
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleSubmitted(String value) {
    if (widget.onSubmitted != null) {
      widget.onSubmitted!(value);
      return;
    }

    if (widget.reqNode != null && widget.reqNode!.context != null) {
      widget.reqNode!.requestFocus();
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      onSubmitted: _handleSubmitted,
      cursorColor: CustomColors.secondaryWidgetTextColor(context, ref),
      style: TextStyle(
        color: CustomColors.secondaryWidgetTextColor(context, ref),
      ),
      decoration: InputDecoration(
        labelText: widget.hintText,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: TextStyle(
          color: CustomColors.secondaryWidgetTextColor(context, ref),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: TextStyle(
          color: CustomColors.secondaryWidgetTextColor(context, ref),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 16,
        ),
        fillColor: CustomColors.secondaryWidgetColor(context, ref),
        filled: true,
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.circular(10),
        ),
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: CustomColors.secondaryWidgetTextColor(context, ref)
              .withAlpha(178),
          fontSize: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}