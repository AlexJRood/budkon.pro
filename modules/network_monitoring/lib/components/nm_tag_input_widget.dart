import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/providers/tag_input_provider.dart';
import 'package:network_monitoring/widgets/filter/controllers.dart';
import 'package:core/theme/apptheme.dart';
import 'package:flutter/rendering.dart';

class NMTagInputWidget extends ConsumerStatefulWidget {
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final String providerId;
  final Function(List<String>) onItemsChanged;
  final bool useSearchController; 
  final TextEditingController? externalController;

  const NMTagInputWidget({
    super.key,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    required this.providerId,
    required this.onItemsChanged,
    this.useSearchController = false,
    this.externalController,
  });

  @override
  ConsumerState<NMTagInputWidget> createState() => _NMTagInputWidgetState();
}

class _NMTagInputWidgetState extends ConsumerState<NMTagInputWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();

    if (widget.externalController != null) {
      _controller = widget.externalController!;
    } else {
      _controller = TextEditingController();
    }
    
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _scrollAfterKeyboardOpen();
      }
    });
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    if (widget.externalController == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    ref.read(nmTagInputProvider(widget.providerId).notifier).updateText(_controller.text);
  }

  void _scrollAfterKeyboardOpen() {
    Future<void> scrollAfter(Duration delay) async {
      await Future.delayed(delay);
      if (!mounted) return;

      final scrollable = Scrollable.maybeOf(context);
      if (scrollable == null) return;

      final position = scrollable.position;
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final viewport = RenderAbstractViewport.of(renderBox);
      if (viewport == null) return;

      final targetOffset = viewport.getOffsetToReveal(renderBox, 0.65).offset;

      final safeOffset = targetOffset.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );

      await position.animateTo(
        safeOffset,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await scrollAfter(const Duration(milliseconds: 180));
      await scrollAfter(const Duration(milliseconds: 650));
    });
  }
  void _addItem() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      ref.read(nmTagInputProvider(widget.providerId).notifier).addItem(text);
      _controller.clear();
      widget.onItemsChanged(ref.read(nmTagInputProvider(widget.providerId)).items);
      _focusNode.requestFocus();
    }
  }

  void _removeItem(String item) {
    ref.read(nmTagInputProvider(widget.providerId).notifier).removeItem(item);
    widget.onItemsChanged(ref.read(nmTagInputProvider(widget.providerId)).items);
  }

  void _clearText() {
    _controller.clear();
    ref.read(nmTagInputProvider(widget.providerId).notifier).clearText();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final state = ref.watch(nmTagInputProvider(widget.providerId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 50.0,
          child: TextField(
            textInputAction: TextInputAction.done,
            scrollPadding: EdgeInsets.zero,
            onTap: _scrollAfterKeyboardOpen,
            controller: _controller,
            focusNode: _focusNode,
            style: TextStyle(color: theme.textColor),
            cursorColor: theme.textColor,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hintText,
              labelStyle: TextStyle(color: theme.textColor),
              floatingLabelStyle: TextStyle(color: theme.textColor),
              hintStyle: TextStyle(color: theme.textColor.withOpacity(0.7)),
              prefixIcon: Icon(
                widget.prefixIcon,
                color: theme.textColor,
                size: 20,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.currentText.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.check,
                        color: theme.textColor,
                        size: 18,
                      ),
                      onPressed: _addItem,
                      splashRadius: 15,
                    ),
                  if (state.currentText.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: theme.textColor,
                        size: 18,
                      ),
                      onPressed: _clearText,
                      splashRadius: 15,
                    ),
                ],
              ),
              filled: true,
              fillColor: theme.textFieldColor,
              border: const OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
              errorBorder: const OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _addItem(),
          ),
        ),
        if (state.items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: state.items.map((item) {
                return Chip(
                  side: BorderSide.none,
                  elevation: 0,
                  surfaceTintColor: theme.textFieldColor,
                  label: Text(
                    item,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: theme.textFieldColor,
                  deleteIcon: Icon(
                    Icons.close,
                    color: theme.textColor,
                    size: 16,
                  ),
                  onDeleted: () => _removeItem(item),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: theme.textFieldColor)
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}