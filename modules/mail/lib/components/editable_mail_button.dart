import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

class EditableEmailField extends ConsumerStatefulWidget {
  final TextEditingController controller;

  const EditableEmailField({super.key, required this.controller});

  @override
  ConsumerState<EditableEmailField> createState() => _EditableEmailFieldState();
}

class _EditableEmailFieldState extends ConsumerState<EditableEmailField> {
  bool _isEditing = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        setState(() => _isEditing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    return _isEditing
        ? SizedBox(
            width: 300,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              autofocus: true,
              style: TextStyle(color: theme.textColor),
              keyboardType: TextInputType.emailAddress,
              onSubmitted: (_) => setState(() => _isEditing = false),
              decoration: InputDecoration(
                hintText: 'email_address'.tr,
                filled: true,
                fillColor: theme.dashboardContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: theme.textColor.withAlpha(120)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: theme.textColor.withAlpha(120)),
                ),
              ),
            ),
          )
        : InkWell(
            onTap: () {
              setState(() => _isEditing = true);
              _focusNode.requestFocus();
            },
            child: Text(
              widget.controller.text.isEmpty
              ? '[click_to_add_email]'.tr
              : widget.controller.text,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
}
