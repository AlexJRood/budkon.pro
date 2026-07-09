import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';
import 'package:tms_app/todo/provider/mentions_provider.dart';
import 'package:core/user/user/user_provider.dart';
import '../../provider/todo_provider.dart';
import 'mentions_overlay_widget.dart';

class CommentField extends ConsumerStatefulWidget {
  final String taskId;
  const CommentField({super.key, required this.taskId});

  @override
  ConsumerState<CommentField> createState() => _CommentFieldState();
}

class _CommentFieldState extends ConsumerState<CommentField> {
  late final MentionTextEditingController _controller;
  final FocusNode _textFocus = FocusNode();
  final GlobalKey _commentKey = GlobalKey();
  // overlay plumbing
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _entry;
  final ScrollController _overlayScroll = ScrollController();
  double _suggestWidth = 350;

  // manual Riverpod subscription for mention controller
  ProviderSubscription<MentionState>? _mentionSub;

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
  void initState() {
    super.initState();
    final theme = ref.read(themeColorsProvider);
    _controller = MentionTextEditingController(
      mentionStyle: TextStyle(
        color: theme.themeColor,
        fontWeight: FontWeight.w600,
      ),
    );
    _controller.addListener(_onTextChanged);

    // przeniesiony nasłuch z build() -> initState()
    _mentionSub = ref.listenManual<MentionState>(
      mentionControllerProvider(widget.taskId),
          (prev, next) {
        final wasOpen = prev?.open ?? false;
        final isOpen = next.open;
        if (!wasOpen && isOpen) {
          _insertOverlay();
        } else if (wasOpen && !isOpen) {
          _removeOverlay();
        }
      },
    );
    _textFocus.addListener(() {
      if (_textFocus.hasFocus) {
        _scrollToField(_commentKey);
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _textFocus.dispose();
    _removeOverlay();
    _mentionSub?.close();
    super.dispose();
  }

  void _submit(WidgetRef ref, String author) {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      Get.snackbar('Error'.tr, 'Comment cannot be empty!'.tr);
      return;
    }
    ref.read(commentsProvider.notifier).addComment(widget.taskId, value, author, ref);
    _controller.clear();
    _textFocus.requestFocus();
    ref.read(mentionControllerProvider(widget.taskId).notifier).close();
    Get.snackbar('Success'.tr, 'Comment added successfully!'.tr);
  }

  void _onTextChanged() {
    final sel = _controller.selection;
    final caret = sel.baseOffset;
    final mention = ref.read(mentionControllerProvider(widget.taskId).notifier);

    if (caret < 0) {
      mention.resetRange();
      mention.close();
      return;
    }

    final text = _controller.text;
    final uptoCaret = text.substring(0, math.min(caret, text.length));

    final m2 = RegExp(r'@@([^\s@]*)$').firstMatch(uptoCaret);
    if (m2 != null) {
      mention.setRange(m2.start, caret);
      mention.filterMembers(m2.group(1) ?? '');
      return;
    }

    final m1 = RegExp(r'@([^\s@]*)$').firstMatch(uptoCaret);
    if (m1 != null) {
      mention.setRange(m1.start, caret);
      mention.filterClients(m1.group(1) ?? '');
      return;
    }

    mention.resetRange();
    mention.close();
  }

  String _toHandle(String s) {
    final norm = s.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return norm.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  }

  void _insertMentionFromState(MentionState st, dynamic item) {
    if (st.rangeStart == null || st.rangeEnd == null) return;

    final text = _controller.text;
    final s = st.rangeStart!;
    final e = st.rangeEnd!;
    if (s < 0 || e < 0 || s > text.length || e > text.length || s > e) return;

    final display = st.mode == MentionMode.members
        ? MentionController.memberName(item)
        : MentionController.clientName(item);
    final handle = _toHandle(display);

    final prefix = st.mode == MentionMode.members ? '@@' : '@';
    final insert = '$prefix$handle ';

    final newText = text.replaceRange(s, e, insert);
    final newCaret = s + insert.length;

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCaret),
    );

    ref.read(mentionControllerProvider(widget.taskId).notifier).close();
    Future.microtask(() => _textFocus.requestFocus());
  }

  void _insertOverlay() {
    if (_entry != null) return;
    _entry = OverlayEntry(
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final theme = ref.watch(themeColorsProvider);
          final st = ref.watch(mentionControllerProvider(widget.taskId));
          return MentionsOverlay(
            link: _layerLink,
            width: _suggestWidth,
            theme: theme,
            state: st,
            scrollController: _overlayScroll,
            onHoverIndex: (i) =>
                ref.read(mentionControllerProvider(widget.taskId).notifier).setActive(i),
            onTapItem: (item) => _insertMentionFromState(st, item),
          );
        },
      ),
    );
    if (!mounted) return;
    final overlay = Overlay.of(context);
    if (overlay != null) {
      overlay.insert(_entry!);
    }
  }

  void _removeOverlay() {
    _entry?.remove();
    _entry = null;
  }

  bool _handleEnterWhenOpen() {
    final st = ref.read(mentionControllerProvider(widget.taskId));
    if (!st.open || st.items.isEmpty) return false;
    final idx = st.activeIndex.clamp(0, st.items.length - 1);
    final item = st.items[idx];
    _insertMentionFromState(st, item);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    // odśwież styl mention przy zmianie tematu
    _controller.mentionStyle = TextStyle(
      color: theme.themeColor,
      fontWeight: FontWeight.w600,
    );

    // WATCH so the UI updates when user loads; don't force non-null
    final user = ref.watch(userStateProvider); // may be null initially
    final author =
    user == null ? 'Unknown' : '${user.firstName} ${user.lastName}'.trim();

    final hasAvatar =
        user != null && user.avatarUrl != null && user.avatarUrl!.isNotEmpty;
    final initial = (user == null || user.firstName.isEmpty)
        ? 'U'
        : user.firstName[0].toUpperCase();

    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: theme.textFieldColor,
            backgroundImage: hasAvatar ? NetworkImage(user!.avatarUrl!) : null,
            child: hasAvatar
                ? null
                : Text(
              initial,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            key: _commentKey,
            child: CompositedTransformTarget(
              link: _layerLink,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.textFieldColor,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _suggestWidth = math.min(constraints.maxWidth, 360);
                    return CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.enter): () {
                          final pressed =
                              HardwareKeyboard.instance.logicalKeysPressed;
                          final shiftDown =
                              pressed.contains(LogicalKeyboardKey.shiftLeft) ||
                                  pressed.contains(LogicalKeyboardKey.shiftRight);
                          if (!shiftDown) {
                            final handled = _handleEnterWhenOpen();
                            if (!handled) _submit(ref, author);
                          }
                        },
                        const SingleActivator(LogicalKeyboardKey.arrowDown): () {
                          ref
                              .read(mentionControllerProvider(widget.taskId)
                              .notifier)
                              .next();
                        },
                        const SingleActivator(LogicalKeyboardKey.arrowUp): () {
                          ref
                              .read(mentionControllerProvider(widget.taskId)
                              .notifier)
                              .prev();
                        },
                        const SingleActivator(LogicalKeyboardKey.escape): () {
                          ref
                              .read(mentionControllerProvider(widget.taskId)
                              .notifier)
                              .close();
                        },
                        const SingleActivator(LogicalKeyboardKey.tab): () {
                          _handleEnterWhenOpen();
                        },
                      },
                      child: TextField(
                        focusNode: _textFocus,
                        controller: _controller, // highlights mentions
                        cursorColor: theme.textColor,
                        style: TextStyle(color: theme.textColor),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: theme.textFieldColor,
                          hintText: 'Add a comment...'.tr,
                          hintStyle: TextStyle(color: theme.textColor),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          isDense: true,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: () => _submit(ref, author),
          icon: AppIcons.sendAbove(color: theme.textColor),
        ),
      ],
    );
  }
}
