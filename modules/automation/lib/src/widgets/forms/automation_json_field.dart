import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core/theme/text_field.dart';

class AutomationJsonField extends StatefulWidget {
  final String label;
  final Map<String, dynamic> value;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final int minLines;
  final int maxLines;
  final bool enabled;

  const AutomationJsonField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.minLines = 5,
    this.maxLines = 14,
    this.enabled = true,
  });

  @override
  State<AutomationJsonField> createState() => _AutomationJsonFieldState();
}

class _AutomationJsonFieldState extends State<AutomationJsonField> {
  late final TextEditingController _controller;
  String? _error;
  bool _isFocused = false;

  static const _encoder = JsonEncoder.withIndent('  ');

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _pretty(widget.value));
  }

  @override
  void didUpdateWidget(covariant AutomationJsonField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value && _error == null && !_isFocused) {
      final nextText = _pretty(widget.value);
      if (_controller.text != nextText) {
        _controller.text = nextText;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _pretty(Map<String, dynamic> value) {
    try {
      return _encoder.convert(value);
    } catch (_) {
      return '{}';
    }
  }

  void _apply(String text) {
    try {
      final decoded = jsonDecode(text);

      if (decoded is! Map) {
        setState(() => _error = 'JSON must be an object.');
        return;
      }

      final next = Map<String, dynamic>.from(decoded);

      setState(() => _error = null);
      widget.onChanged(next);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _formatJson() {
    try {
      final decoded = jsonDecode(_controller.text);

      if (decoded is! Map) {
        setState(() => _error = 'JSON must be an object.');
        return;
      }

      final next = Map<String, dynamic>.from(decoded);
      final formatted = _pretty(next);

      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );

      setState(() => _error = null);
      widget.onChanged(next);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        _isFocused = hasFocus;

        if (!hasFocus && _error == null) {
          _formatJson();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CoreTextField(
            label: widget.label,
            controller: _controller,
            enabled: widget.enabled,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            onChanged: _apply,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F]')),
            ],
            suffixIcon: IconButton(
              tooltip: 'Format JSON',
              onPressed: widget.enabled ? _formatJson : null,
              icon: const Icon(Icons.data_object_rounded),
            ),
            helperText: _error == null ? 'JSON object' : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
