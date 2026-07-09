import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:tms_app/todo/board/provider/board_provider.dart';
import 'package:tms_app/todo/provider/todo_provider.dart';

class DescriptionEditor extends ConsumerStatefulWidget {
  final String? initialDescription;
  final int taskId;

  const DescriptionEditor({
    super.key,
    required this.initialDescription,
    required this.taskId,
  });

  @override
  ConsumerState<DescriptionEditor> createState() => _DescriptionEditorState();
}

class _DescriptionEditorState extends ConsumerState<DescriptionEditor> {
  late final TextEditingController _controller;
  final FocusNode _descriptionFocus = FocusNode();
  final GlobalKey _descriptionKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialDescription ?? '',
    );

    _descriptionFocus.addListener(() {
      if (_descriptionFocus.hasFocus) {
        _scrollToField(_descriptionKey);
      }
    });
  }

  void _scrollToField(GlobalKey key) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      final ctx = key.currentContext;
      if (ctx == null) return;

      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: 0.2,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final state = ref.watch(descriptionProvider(widget.initialDescription));
    final notifier = ref.read(descriptionProvider(widget.initialDescription).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Description".tr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          key: _descriptionKey,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: theme.textFieldColor,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: TextField(
            focusNode: _descriptionFocus,
            controller: _controller,
            minLines: 3,
            maxLines: null,
            textInputAction: TextInputAction.newline,
            keyboardType: TextInputType.multiline,
            cursorColor: theme.textColor,
            style: TextStyle(color: theme.textColor),
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.textFieldColor,
              hintText: 'Add a more detailed description...'.tr,
              hintStyle: TextStyle(color: theme.textColor),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              isDense: true,
            ),
            onTap: () => _scrollToField(_descriptionKey),
            onChanged: notifier.update,
          ),
        ),
        const SizedBox(height: 10),
        if (state.hasChanged)
          Row(
            children: [
              InkWell(
                onTap: () async {
                  await ref
                      .read(taskProvider.notifier)
                      .editTask(
                        context,
                        widget.taskId.toString(),
                        'description',
                        state.currentDescription,
                      )
                      .whenComplete(() {
                        ref
                            .read(boardManagementProvider.notifier)
                            .fetchBoards(ref);
                      });
                  notifier.save(state.currentDescription);
                },
                child: Container(
                  height: 32,
                  width: 53,
                  decoration: BoxDecoration(
                    color: theme.themeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      'Save'.tr,
                      style: TextStyle(color: theme.themeColorText, fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => notifier.reset(),
                child: Container(
                  height: 32,
                  width: 53,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      'Cancel'.tr,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
