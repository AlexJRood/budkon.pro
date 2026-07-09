import 'dart:convert';
import 'package:crm/crm_urls.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/user/user/user_provider.dart';

class CommentSectionPc extends ConsumerStatefulWidget {
  final int id;
  final bool isMobile;
  const CommentSectionPc({super.key, required this.id, this.isMobile = false});

  @override
  _CommentSectionPcState createState() => _CommentSectionPcState();
}

class _CommentSectionPcState extends ConsumerState<CommentSectionPc> {
  List<dynamic> _comments = [];

  // ── nowy composer (input) ───────────────────────────────────────────────────
  final TextEditingController _composerController = TextEditingController();
  final FocusNode _composerFocus = FocusNode();

  String? _currentUserAvatarUrl;
  String _currentUserFirstNameInitial = 'U';

  @override
  void initState() {
    super.initState();
    _fetchComments();
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    ref.read(userProvider.future).then((user) {
      if (!mounted || user == null) return;
      setState(() {
        _currentUserAvatarUrl = user.avatarUrl;
        final name = user.firstName;
        _currentUserFirstNameInitial =
            name.isNotEmpty ? name[0].toUpperCase() : 'U';
      });
    });
  }

  @override
  void dispose() {
    _composerController.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    try {
      final response = await ApiServices.get(
        ref: ref,
        CrmUrls.commentsByUserContacts('${widget.id}'),
        hasToken: true,
      );

      if (!mounted) return;

      if (response != null && response.statusCode == 200) {
        final decodedBody = utf8.decode(response.data);
        final jsonData = jsonDecode(decodedBody);
        setState(() {
          _comments = jsonData is List ? jsonData : [];
        });
      } else {
        final sb = Customsnackbar().showSnackBar(
          "Error".tr,
          'error_loading_comments'.tr,
          "error",
          () =>
              mounted
                  ? ScaffoldMessenger.of(context).hideCurrentSnackBar()
                  : null,
        );
        ScaffoldMessenger.of(context).showSnackBar(sb);
      }
    } catch (e) {
      if (!mounted) return;
      final sb = Customsnackbar().showSnackBar(
        "Error".tr,
        '${'error_loading_comments_with_details'.tr} $e',
        "error",
        () =>
            mounted
                ? ScaffoldMessenger.of(context).hideCurrentSnackBar()
                : null,
      );
      ScaffoldMessenger.of(context).showSnackBar(sb);
    }
  }

  Future<void> _submitComment() async {
    final text = _composerController.text.trim();
    if (text.isEmpty) return;

    try {
      final response = await ApiServices.post(
        CrmUrls.commentsByUserContacts('${widget.id}'),
        hasToken: true,
        data: {'content': text},
      );

      if (!mounted) return;

      if (response != null && response.statusCode == 201) {
        final sb = Customsnackbar().showSnackBar(
          "success".tr,
          'comment_added_success'.tr,
          "success",
          () =>
              mounted
                  ? ScaffoldMessenger.of(context).hideCurrentSnackBar()
                  : null,
        );
        ScaffoldMessenger.of(context).showSnackBar(sb);
        _composerController.clear();
        _fetchComments();
        _composerFocus.requestFocus();
      } else {
        final sb = Customsnackbar().showSnackBar(
          "Error".tr,
          'error_adding_comment'.tr,
          "error",
          () =>
              mounted
                  ? ScaffoldMessenger.of(context).hideCurrentSnackBar()
                  : null,
        );
        ScaffoldMessenger.of(context).showSnackBar(sb);
      }
    } catch (e) {
      if (!mounted) return;
      final sb = Customsnackbar().showSnackBar(
        "Error".tr,
        '${'error_adding_comment_with_details'.tr} $e',
        "error",
        () =>
            mounted
                ? ScaffoldMessenger.of(context).hideCurrentSnackBar()
                : null,
      );
      ScaffoldMessenger.of(context).showSnackBar(sb);
    }
  }

  Future<void> _editComment(int commentId, String newComment) async {
    try {
      final response = await ApiServices.put(
        CrmUrls.userContactsCommentDetails('$commentId'),
        hasToken: true,
        data: {'content': newComment},
      );

      if (!mounted) return;

      if (response != null && response.statusCode == 200) {
        final sb = Customsnackbar().showSnackBar(
          "success".tr,
          'comment_updated_success'.tr,
          "success",
          () =>
              mounted
                  ? ScaffoldMessenger.of(context).hideCurrentSnackBar()
                  : null,
        );
        ScaffoldMessenger.of(context).showSnackBar(sb);
        _fetchComments();
      } else {
        final sb = Customsnackbar().showSnackBar(
          "Error".tr,
          'error_editing_comment'.tr,
          "error",
          () =>
              mounted
                  ? ScaffoldMessenger.of(context).hideCurrentSnackBar()
                  : null,
        );
        ScaffoldMessenger.of(context).showSnackBar(sb);
      }
    } catch (e) {
      if (!mounted) return;
      final sb = Customsnackbar().showSnackBar(
        "Error".tr,
        '${'error_editing_comment_with_details'.tr} $e',
        "error",
        () =>
            mounted
                ? ScaffoldMessenger.of(context).hideCurrentSnackBar()
                : null,
      );
      ScaffoldMessenger.of(context).showSnackBar(sb);
    }
  }

  Future<void> _deleteComment(int commentId) async {
    try {
      final response = await ApiServices.delete(
        CrmUrls.userContactsCommentDetails('$commentId'),
        hasToken: true,
      );

      if (!mounted) return;

      if (response != null &&
          (response.statusCode == 204 || response.statusCode == 200)) {
        final sb = Customsnackbar().showSnackBar(
          "success".tr,
          'comment_deleted_success'.tr,
          "success",
          () =>
              mounted
                  ? ScaffoldMessenger.of(context).hideCurrentSnackBar()
                  : null,
        );
        ScaffoldMessenger.of(context).showSnackBar(sb);
        _fetchComments();
      } else {
        debugPrint('Younis response ${response?.statusCode}');
        final sb = Customsnackbar().showSnackBar(
          "Error".tr,
          'error_deleting_comment'.tr,
          "error",
          () =>
              mounted
                  ? ScaffoldMessenger.of(context).hideCurrentSnackBar()
                  : null,
        );
        ScaffoldMessenger.of(context).showSnackBar(sb);
      }
    } catch (e) {
      if (!mounted) return;
      final sb = Customsnackbar().showSnackBar(
        "Error".tr,
        '${'error_deleting_comment_with_details'.tr} $e',
        "error",
        () =>
            mounted
                ? ScaffoldMessenger.of(context).hideCurrentSnackBar()
                : null,
      );
      ScaffoldMessenger.of(context).showSnackBar(sb);
    }
  }

  String _formatDate(String date) {
    final DateTime dateTime = DateTime.parse(date);
    return DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
  }

  // Enter → wyślij, Shift+Enter → nowa linia
  bool _handleEnterNoShift() {
    _submitComment();
    return true; // „zjedz” event
  }

  bool _handleShiftEnterInsertNewline() {
    final sel = _composerController.selection;
    final text = _composerController.text;
    final start = sel.start.clamp(0, text.length);
    final end = sel.end.clamp(0, text.length);
    final newText = text.replaceRange(start, end, '\n');
    _composerController.text = newText;
    final pos = start + 1;
    _composerController.selection = TextSelection.collapsed(offset: pos);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    double screenWidth = MediaQuery.of(context).size.width;
    double paddingSize = screenWidth / 4;
    double itemWidth = screenWidth / 1920 * 180;
    itemWidth = max(120.0, min(itemWidth, 180.0));

    // ✅ Mobile style values (PC view remains the same when isMobile == false)
    final EdgeInsets contentPadding =
        widget.isMobile
            ? const EdgeInsets.symmetric(horizontal: 12)
            : EdgeInsets.symmetric(horizontal: paddingSize);

    final double avatarRadius = widget.isMobile ? 16 : 20;

    final BorderRadius composerRadius =
        widget.isMobile
            ? const BorderRadius.all(Radius.circular(12))
            : const BorderRadius.all(Radius.circular(10));

    final EdgeInsets composerBubblePadding =
        widget.isMobile
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 10);

    final EdgeInsets composerRowPadding =
        widget.isMobile
            ? const EdgeInsets.symmetric(vertical: 8)
            : const EdgeInsets.all(0);

    final EdgeInsets commentTilePadding =
        widget.isMobile
            ? const EdgeInsets.symmetric(vertical: 6)
            : const EdgeInsets.symmetric(vertical: 5.0);

    return Padding(
      padding: contentPadding,
      child: Column(
        children: [
          SizedBox(height: widget.isMobile ? 100 : 10),

          // ── KOMENTARZ COMPOSER W STYLU PRZYKŁADU ──────────────────────────────
          Padding(
            padding: composerRowPadding,
            child: Row(
              children: [
                Padding(
                  padding:
                      widget.isMobile
                          ? const EdgeInsets.only(right: 10, top: 6, bottom: 6)
                          : const EdgeInsets.all(10),
                  child: CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: theme.textFieldColor,
                    backgroundImage:
                        (_currentUserAvatarUrl != null &&
                                _currentUserAvatarUrl!.isNotEmpty)
                            ? NetworkImage(_currentUserAvatarUrl!)
                            : null,
                    child:
                        (_currentUserAvatarUrl == null ||
                                _currentUserAvatarUrl!.isEmpty)
                            ? Text(
                              _currentUserFirstNameInitial,
                              style: TextStyle(
                                color: theme.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: widget.isMobile ? 12 : null,
                              ),
                            )
                            : null,
                  ),
                ),

                // Pole tekstowe w „dymku”
                Expanded(
                  child: Container(
                    padding: composerBubblePadding,
                    decoration: BoxDecoration(
                      color: theme.textFieldColor,
                      borderRadius: composerRadius,
                      border:
                          widget.isMobile
                              ? Border.all(
                                color: theme.textColor.withAlpha(
                                  (255 * 0.08).toInt(),
                                ),
                              )
                              : null,
                    ),
                    child: CallbackShortcuts(
                      bindings: {
                        // Enter (bez Shift) => wyślij
                        const SingleActivator(LogicalKeyboardKey.enter):
                            _handleEnterNoShift,
                        // Shift+Enter => nowa linia
                        const SingleActivator(
                              LogicalKeyboardKey.enter,
                              shift: true,
                            ):
                            _handleShiftEnterInsertNewline,
                      },
                      child: TextField(
                        focusNode: _composerFocus,
                        controller: _composerController,
                        cursorColor: theme.textColor,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: widget.isMobile ? 13 : null,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: theme.textFieldColor,
                          hintText: 'add_comment_hint'.tr,
                          hintStyle: TextStyle(
                            color: theme.textColor.withAlpha(
                              (255 * 0.6).toInt(),
                            ),
                            fontSize: widget.isMobile ? 13 : null,
                          ),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              widget.isMobile
                                  ? const EdgeInsets.symmetric(vertical: 4)
                                  : EdgeInsets.zero,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                      ),
                    ),
                  ),
                ),

                IconButton(
                  onPressed: _submitComment,
                  icon: AppIcons.sendAbove(color: theme.textColor),
                  splashRadius: widget.isMobile ? 18 : null,
                  padding: widget.isMobile ? const EdgeInsets.all(6) : null,
                  constraints:
                      widget.isMobile
                          ? const BoxConstraints(minWidth: 34, minHeight: 34)
                          : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── LISTA KOMENTARZY ─────────────────────────────────────────────────
          ..._comments.map(
            (comment) => Padding(
              padding: commentTilePadding,
              child:
                  widget.isMobile
                      ? Container(
                        decoration: BoxDecoration(
                          color: theme.textFieldColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.textColor.withAlpha(
                              (255 * 0.06).toInt(),
                            ),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          title: Text(
                            comment['content'] ?? '',
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 13,
                              height: 1.25,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _formatDate(comment['created_at']),
                              style: AppTextStyles.interLight10,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: AppIcons.pencil(color: theme.textColor),
                                splashRadius: 18,
                                onPressed: () async {
                                  String? newComment = await showDialog<String>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      final editController =
                                          TextEditingController(
                                            text: comment['content'] ?? '',
                                          );

                                      return AlertDialog(
                                        backgroundColor:
                                            theme.popupcontainercolor,
                                        title: Text(
                                          'edit_comment_title'.tr,
                                          style: TextStyle(
                                            color: theme.textColor,
                                          ),
                                        ),
                                        content: TextField(
                                          controller: editController,
                                          maxLines: null,
                                          cursorColor: theme.textColor,
                                          style: TextStyle(
                                            color: theme.textColor,
                                          ),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: theme.textFieldColor,
                                            hintText: 'enter_new_comment_hint'.tr,
                                            hintStyle: TextStyle(
                                              color: theme.textColor.withAlpha(
                                                (255 * 0.6).toInt(),
                                              ),
                                              fontSize:
                                                  widget.isMobile ? 13 : null,
                                            ),
                                            border: InputBorder.none,
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide.none,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide.none,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            isDense: true,
                                            contentPadding:
                                                widget.isMobile
                                                    ? const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                      horizontal: 10,
                                                    )
                                                    : const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                      horizontal: 10,
                                                    ),
                                          ),
                                          textInputAction:
                                              TextInputAction.newline,
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            child: Text(
                                              'cancel_button'.tr,
                                              style: TextStyle(
                                                color: theme.textColor,
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.of(
                                                context,
                                                rootNavigator: true,
                                              ).pop();
                                            },
                                          ),

                                          // ✅ FIX: Save button must pop using the dialog context,
                                          // not via navigationService (which can pop the wrong navigator on web)
                                          InkWell(
                                            onTap: () {
                                              Navigator.of(
                                                context,
                                                rootNavigator: true,
                                              ).pop(editController.text);
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 10,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: theme.themeColor,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'save_button'.tr,
                                                style: TextStyle(
                                                  color: theme.themeTextColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (newComment != null &&
                                      newComment.trim().isNotEmpty) {
                                    _editComment(
                                      comment['id'],
                                      newComment.trim(),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: AppIcons.delete(color: theme.textColor),
                                splashRadius: 18,
                                onPressed: () => _deleteComment(comment['id']),
                              ),
                            ],
                          ),
                        ),
                      )
                      : ListTile(
                        title: Text(
                          comment['content'] ?? '',
                          style: TextStyle(color: theme.textColor),
                        ),
                        subtitle: Text(
                          _formatDate(comment['created_at']),
                          style: AppTextStyles.interLight10,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: AppIcons.pencil(color: theme.textColor),
                              onPressed: () async {
                                String? newComment = await showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    final editController =
                                        TextEditingController(
                                          text: comment['content'] ?? '',
                                        );
                                    return AlertDialog(
                                      title: Text(
                                        'edit_comment_title'.tr,
                                        style: TextStyle(
                                          color: theme.textColor,
                                        ),
                                      ),
                                      content: TextField(
                                        controller: editController,
                                        decoration: InputDecoration(
                                          hintText: 'enter_new_comment_hint'.tr,
                                          hintStyle: TextStyle(
                                            color: theme.textColor,
                                          ),
                                        ),
                                        maxLines: null,
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text(
                                            'cancel_button'.tr,
                                            style: TextStyle(
                                              color: theme.textColor,
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.of(
                                              context,
                                              rootNavigator: true,
                                            ).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: Text(
                                            'save_button'.tr,
                                            style: TextStyle(
                                              color: theme.textColor,
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.of(
                                              context,
                                              rootNavigator: true,
                                            ).pop(editController.text);
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (newComment != null &&
                                    newComment.trim().isNotEmpty) {
                                  _editComment(
                                    comment['id'],
                                    newComment.trim(),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: AppIcons.delete(color: theme.textColor),
                              onPressed: () => _deleteComment(comment['id']),
                            ),
                          ],
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
