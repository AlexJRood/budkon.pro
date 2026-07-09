import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart'; // Assuming this is your custom theme file
import 'package:wall/emma/anchors/anchors_wall.dart';
import 'package:wall/wall_screen/providers/comment_post_provider.dart';
import 'dart:typed_data';
import 'package:get/get_utils/get_utils.dart';
import '../../../model/comment_post_model.dart'; // Import the community_comment.dart file

class CommentTextField extends ConsumerStatefulWidget {
  final PagingController<int, CommunityComment> paginationController;
  final int postId;

  const CommentTextField({
    super.key,
    required this.postId,
    required this.paginationController,
  });

  @override
  ConsumerState<CommentTextField> createState() => _CommentTextFieldState();
}

class _CommentTextFieldState extends ConsumerState<CommentTextField> {
  bool _showEmojiPicker = false;
  Uint8List? _selectedImageBytes; // Use Uint8List for web compatibility
  final ImagePicker _picker = ImagePicker();
  TextEditingController controller = TextEditingController();
  bool _isSubmitting = false;

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
    if (_showEmojiPicker) {
      _showEmojiDialog();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showEmojiDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black26,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: _buildEmojiPickerDialog(),
        );
      },
    ).then((_) {
      setState(() {
        _showEmojiPicker = false;
      });
    });
  }

  void _hideEmojiPicker() {
    if (_showEmojiPicker) {
      Navigator.of(context).pop();
      setState(() => _showEmojiPicker = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        if (foundation.kIsWeb) {
          final bytes = await picked.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
          });
        } else {
          setState(() {
            _selectedImageBytes = null; // Handle non-web case if needed
          });
        }
      }
    } catch (e) {
      // Handle errors (e.g., permission denied)
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${'Error picking image:'.tr} $e')));
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageBytes = null;
    });
  }

  Widget _buildEmojiPickerDialog() {
    return Container(
      width: 400,
      height: 500,
      decoration: BoxDecoration(
        color: CustomColors.secondaryWidgetColor(context, ref),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CustomColors.secondaryWidgetColor(
              context,
              ref,
            ).withAlpha(76),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CustomColors.secondaryWidgetTextColor(
                context,
                ref,
              ).withAlpha(26),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Choose Emoji'.tr,
                  style: TextStyle(
                    color: CustomColors.secondaryWidgetTextColor(context, ref),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: _hideEmojiPicker,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: CustomColors.secondaryWidgetTextColor(
                        context,
                        ref,
                      ).withAlpha(51),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: CustomColors.secondaryWidgetTextColor(
                        context,
                        ref,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                setState(() {
                  controller.text = controller.text + emoji.emoji;
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length),
                  );
                });
                _hideEmojiPicker(); // Close picker after selection
              },
              config: Config(
                height: 450,
                emojiViewConfig: EmojiViewConfig(
                  emojiSizeMax:
                      28 *
                      (foundation.kIsWeb
                          ? 1.0
                          : foundation.defaultTargetPlatform ==
                                TargetPlatform.iOS
                          ? 1.20
                          : 1.0),
                  backgroundColor: CustomColors.secondaryWidgetColor(
                    context,
                    ref,
                  ),
                  columns: 8,
                  gridPadding: const EdgeInsets.all(12),
                ),
                categoryViewConfig: CategoryViewConfig(
                  backgroundColor: CustomColors.secondaryWidgetColor(
                    context,
                    ref,
                  ),
                  indicatorColor: CustomColors.thirdWidgetColor(context, ref),
                  iconColor: CustomColors.secondaryWidgetTextColor(
                    context,
                    ref,
                  ).withAlpha(102),
                  iconColorSelected: CustomColors.thirdWidgetColor(
                    context,
                    ref,
                  ),
                  dividerColor: CustomColors.secondaryWidgetTextColor(
                    context,
                    ref,
                  ).withAlpha(51),
                ),
                skinToneConfig: SkinToneConfig(
                  enabled: true,
                  dialogBackgroundColor: CustomColors.secondaryWidgetColor(
                    context,
                    ref,
                  ),
                  indicatorColor: CustomColors.secondaryWidgetTextColor(
                    context,
                    ref,
                  ),
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  enabled: true,
                  backgroundColor: CustomColors.secondaryWidgetTextColor(
                    context,
                    ref,
                  ).withAlpha(26),
                  buttonColor: CustomColors.secondaryWidgetTextColor(
                    context,
                    ref,
                  ).withAlpha(51),
                  buttonIconColor: CustomColors.secondaryWidgetTextColor(
                    context,
                    ref,
                  ),
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: CustomColors.secondaryWidgetColor(
                    context,
                    ref,
                  ),
                  buttonIconColor: CustomColors.secondaryWidgetTextColor(
                    context,
                    ref,
                  ),
                ),
                viewOrderConfig: const ViewOrderConfig(
                  top: EmojiPickerItem.categoryBar,
                  middle: EmojiPickerItem.emojiView,
                  bottom: EmojiPickerItem.searchBar,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 40, top: 10),
          decoration: BoxDecoration(
            color: theme.settingsMenutile,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withAlpha(76), width: 1),
          ),
          child: Row(
            children: [
              if (_selectedImageBytes != null && foundation.kIsWeb)
                Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _selectedImageBytes!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: InkWell(
                        onTap: _removeImage,
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedBadmintonShuttle,
                          size: 16,

                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    fillColor: CustomColors.secondaryTextfieldFillColor(
                      context,
                      ref,
                    ),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    hintText: "whats on your mind".tr,
                    focusColor: Colors.transparent,
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: CustomColors.secondaryWidgetTextColor(
                        context,
                        ref,
                      ).withAlpha(128),
                    ),
                  ),
                  style: TextStyle(
                    color: CustomColors.secondaryWidgetTextColor(context, ref),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  onTap:
                      _hideEmojiPicker, // Hide emoji picker when tapping text field
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 4,
          left: 8,
          child: Row(
            children: [
              EmmaUiAnchorTarget(
                anchorKey: WallEmmaAnchors.commentEmojiButton.anchorKey,

                spec: WallEmmaAnchors.commentEmojiButton,
                runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                child: IconButton(
                  icon: Icon(
                    Icons.emoji_emotions_outlined,
                    color: CustomColors.secondaryWidgetTextColor(context, ref),
                  ),
                  onPressed: _toggleEmojiPicker,
                ),
              ),
              EmmaUiAnchorTarget(
               anchorKey: WallEmmaAnchors.commentImageButton.anchorKey,

               spec: WallEmmaAnchors.commentImageButton,
               runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
               tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                child: IconButton(
                  icon: Icon(
                    Icons.camera_alt_outlined,
                    color: CustomColors.secondaryWidgetTextColor(context, ref),
                  ),
                  onPressed: _pickImage,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 4,
          right: 8,
          child: EmmaUiAnchorTarget(
            anchorKey: WallEmmaAnchors.commentSubmitButton.anchorKey,

            spec: WallEmmaAnchors.commentSubmitButton,
            runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
            tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
            child: IconButton(
              icon: _isSubmitting
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: CustomColors.thirdWidgetColor(context, ref),
                      ),
                    )
                  : Icon(
                      Icons.send,
                      color: CustomColors.thirdWidgetColor(context, ref),
                    ),
              onPressed: _isSubmitting
                  ? null // Disable button while submitting
                  : () async {
                      final content = controller.text.trim();
                      if (content.isEmpty && _selectedImageBytes == null) {
                        return; // Don't submit if both content and image are empty
                      }
            
                      setState(() {
                        _isSubmitting = true; // Start loading
                      });
            
                      final success = await ref
                          .read(postCommentProvider.notifier)
                          .submit(
                            postId: widget.postId,
                            content: content,
                            image: _selectedImageBytes,
                            ref: ref,
                          );
            
                      if (success && mounted) {
                        final newComment = ref.read(postCommentProvider).value;
                        if (newComment != null) {
                          ref
                              .read(commentsProvider(widget.postId).notifier)
                              .addNewComment(newComment);
                          final currentItems =
                              widget.paginationController.value.itemList ?? [];
                          widget.paginationController.itemList = [
                            newComment,
                            ...currentItems,
                          ];
                        }
                        controller.clear();
                        setState(() {
                          _selectedImageBytes = null;
                          _isSubmitting = false; // Stop loading
                        });
                        debugPrint("success");
                      } else if (mounted) {
                        setState(() {
                          _isSubmitting = false; // Stop loading on failure
                        });
                        debugPrint("failed");
                      }
                    },
            ),
          ),
        ),
      ],
    );
  }
}
