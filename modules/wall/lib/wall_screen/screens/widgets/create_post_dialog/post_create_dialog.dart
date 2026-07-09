import 'dart:developer';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:core/common/global_secondary_textfield.dart';
import 'package:core/common/global_user_card.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/user/user/user_provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:wall/emma/anchors/anchors_wall.dart';

import 'package:wall/wall_screen/model/community_post_model.dart';
import 'package:wall/wall_screen/screens/widgets/components/location_selector.dart';
import 'package:wall/wall_screen/screens/widgets/create_post_dialog/components.dart';
import 'package:wall/wall_screen/providers/post_create_provider.dart';
import 'package:wall/wall_screen/services/confetti/confetti_service.dart';
import 'package:wall/wall_screen/services/haptics/emoji_haptic.dart';
import 'package:wall/wall_screen/wall_screen_community_pc.dart';

typedef PickedFile = dynamic; // File (mobile/desktop) or PlatformFile (web)

class PostCreateDialog extends ConsumerStatefulWidget {
  final BuildContext? snackContext;
  final List<Map<String, dynamic>>? userOptions;
  final CommunityPost? post; // Add post parameter for editing
  final String? initialAction; // 'video', 'image', or null

  const PostCreateDialog({
    super.key,
    this.userOptions,
    this.post,
    this.snackContext,
    this.initialAction,
  });

  @override
  ConsumerState<PostCreateDialog> createState() => _PostCreateDialogState();
}

class _PostCreateDialogState extends ConsumerState<PostCreateDialog> {
  @override
  void initState() {
    super.initState();
    // Auto-trigger action based on initialAction
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialAction == 'video') {
        pickFiles();
      } else if (widget.initialAction == 'image') {
        pickFiles();
      } else if (widget.initialAction == 'emoji') {
        _showEmojiDialog();
      }
    });
  }

  Future<void> pickFiles() async {
    // For now, use the provider's pickFiles method
    // TODO: Add filtering based on initialAction in the provider
    await ref.read(postCreateStateProvider.notifier).pickFiles();
  }

  void _showEmojiDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black26,
      builder: (context) {
        return EmmaUiAnchorTarget(
            anchorKey: WallEmmaAnchors.createPostDialog.anchorKey,

            spec: WallEmmaAnchors.createPostDialog,
            runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
            tapMode: EmmaUiAnchorTapMode.disabled,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: _buildEmojiPickerDialog(),
          ),
        );
      },
    );
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
            ).withOpacity(0.3),
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
              ).withOpacity(0.1),
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
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: CustomColors.secondaryWidgetTextColor(
                        context,
                        ref,
                      ).withOpacity(0.2),
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
                final postState = ref.read(postCreateStateProvider);
                final currentText = postState.contentController.text;
                postState.contentController.text = currentText + emoji.emoji;
                postState
                    .contentController
                    .selection = TextSelection.fromPosition(
                  TextPosition(offset: postState.contentController.text.length),
                );
                Navigator.of(context).pop();
              },
              config: Config(
                height: 450,
                checkPlatformCompatibility: true,
                emojiViewConfig: EmojiViewConfig(
                  emojiSizeMax: 28,
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
                  iconColorSelected: Theme.of(context).primaryColor,
                  iconColor: CustomColors.secondaryWidgetTextColor(
                    context,
                    ref,
                  ).withOpacity(0.5),
                ),
                bottomActionBarConfig: const BottomActionBarConfig(
                  enabled: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> pickFromCamera() async {
    await ref.read(postCreateStateProvider.notifier).pickFromCamera();
  }

  void removeFile(PickedFile file) {
    ref.read(postCreateStateProvider.notifier).removeFile(file);
  }

  Future<void> submitPost(int index) async {
    final postState = ref.read(postCreateStateProvider);
    if (widget.post != null) {
      // Edit mode
      bool success = await ref
          .read(postCreateStateProvider.notifier)
          .editPost(
            context: context,
            ref: ref,
            userId: widget.post!.author.userId,
            postId: widget.post!.id,
            tabIndex: index,
          );

      if (!mounted) return;

      if (success) {
        if (context.mounted) {
          // Close dialog first
          Navigator.of(context).pop();

          // Then show snackbar
          if (widget.snackContext != null) {
            ScaffoldMessenger.of(widget.snackContext!).showSnackBar(
              Customsnackbar().showSnackBar(
                "Success".tr,
                'post_edited_successfully'.tr,
                "success",
                () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              ),
            );
           
          }
        }
      } else {
        if (context.mounted) {
          // Close dialog first
          Navigator.of(context).pop();

          // Then show error
          ScaffoldMessenger.of(context).showSnackBar(
            Customsnackbar().showSnackBar(
              "Error".tr,
              'failed_to_edit_post'.tr,
              "error",
              () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          );
        }
      }
    } else {
      // Create mode
      await ref
          .read(postCreateStateProvider.notifier)
          .createPost(context: context, ref: ref, tabIndex: index);

      if (mounted && context.mounted) {
        Navigator.of(context).pop();
        ref.read(confettiServiceProvider).show();
      
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedIndexProviderWall);
    final postState = ref.watch(postCreateStateProvider);
    final postStateNotifier = ref.read(postCreateStateProvider.notifier);
    log(postState.contentController.text);
    final username = ref.watch(userStateProvider)!.username;
    return Hero(
      tag: "post",
      child: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double postWidth = screenWidth > 700 ? 700 : screenWidth * 0.8;
          double aspectRatio = screenWidth > 1980 ? 1.4 : 1.7;
          double imageHeight = postWidth / aspectRatio;
          double avatarSize = postWidth * 0.07;
          double titleFontSize = postWidth * 0.028;
          double subtitleFontSize = postWidth * 0.022;
          double buttonFontSize = postWidth * 0.024;
          double horizontalPadding = postWidth * 0.03;
          double verticalPadding = postWidth * 0.02;
          double iconSize = postWidth * 0.03;

          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: postWidth,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: CustomColors.secondaryWidgetColor(context, ref),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: EdgeInsets.all(horizontalPadding),
                      child: Row(
                        children: [
                          Text(
                            widget.post != null ? 'Edit Post'.tr : 'Create Post'.tr,
                            style: TextStyle(
                              color: CustomColors.secondaryWidgetTextColor(
                                context,
                                ref,
                              ),
                              fontSize: titleFontSize * 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            child: Icon(
                              Icons.close,
                              size: iconSize * 1.2,
                              color: CustomColors.secondaryWidgetTextColor(
                                context,
                                ref,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: CustomColors.secondaryWidgetTextColor(
                        context,
                        ref,
                      ).withOpacity(0.1),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (postState.statusMsg != null)
                              Padding(
                                padding: EdgeInsets.all(horizontalPadding),
                                child: Text(
                                  postState.statusMsg!,
                                  style: TextStyle(color: Colors.amber),
                                ),
                              ),
                            // Profile section
                            Padding(
                              padding: EdgeInsets.all(horizontalPadding),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GlobalUserCard(
                                    size: avatarSize,
                                    userAsyncValue: ref.watch(userProvider),
                                  ),
                                  SizedBox(width: horizontalPadding),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          username, // Replace with actual user data
                                          style: TextStyle(
                                            color:
                                                CustomColors.secondaryWidgetTextColor(
                                                  context,
                                                  ref,
                                                ),
                                            fontSize: titleFontSize,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (postState.selectedLocation != null)
                                          Text(
                                            postState
                                                .selectedLocation!
                                                .displayName,
                                            style: TextStyle(
                                              overflow: TextOverflow.ellipsis,
                                              color:
                                                  CustomColors.secondaryWidgetTextColor(
                                                    context,
                                                    ref,
                                                  ).withOpacity(0.7),
                                              fontSize: subtitleFontSize,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.transparent,
                                    ),
                                    child: EmmaUiAnchorTarget(
                                        anchorKey: WallEmmaAnchors.createPostWallTypeDropdown.anchorKey,

                                        spec: WallEmmaAnchors.createPostWallTypeDropdown,
                                        runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                                        tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                                      child: DropdownButton<String>(
                                        padding: EdgeInsets.all(10),
                                        value: postState.wallType,
                                        isDense: true,
                                        underline: Container(),
                                        borderRadius: BorderRadius.circular(10),
                                        dropdownColor:
                                            CustomColors.secondaryWidgetColor(
                                              context,
                                              ref,
                                            ),
                                        icon: HugeIcon(
                                          icon:
                                              HugeIcons.strokeRoundedArrowDown01,
                                          color:
                                              CustomColors.secondaryWidgetTextColor(
                                                context,
                                                ref,
                                              ).withOpacity(0.7),
                                          size: iconSize,
                                        ),
                                        style: TextStyle(
                                          color:
                                              CustomColors.secondaryWidgetTextColor(
                                                context,
                                                ref,
                                              ).withOpacity(0.8),
                                          fontSize: subtitleFontSize,
                                        ),
                                        items: [
                                          DropdownMenuItem(
                                            value: 'both',
                                            child: Text(
                                              'Everyone'.tr,
                                              style: TextStyle(
                                                fontSize: subtitleFontSize,
                                                color:
                                                    CustomColors.secondaryWidgetTextColor(
                                                      context,
                                                      ref,
                                                    ).withOpacity(0.7),
                                              ),
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'favourites',
                                            child: Text(
                                              'Favourites'.tr,
                                              style: TextStyle(
                                                fontSize: subtitleFontSize,
                                                color:
                                                    CustomColors.secondaryWidgetTextColor(
                                                      context,
                                                      ref,
                                                    ).withOpacity(0.7),
                                              ),
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'groups',
                                            child: Text(
                                              'Groups'.tr,
                                              style: TextStyle(
                                                fontSize: subtitleFontSize,
                                                color:
                                                    CustomColors.secondaryWidgetTextColor(
                                                      context,
                                                      ref,
                                                    ).withOpacity(0.7),
                                              ),
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'developers',
                                            child: Text(
                                              'Developers'.tr,
                                              style: TextStyle(
                                                fontSize: subtitleFontSize,
                                                color:
                                                    CustomColors.secondaryWidgetTextColor(
                                                      context,
                                                      ref,
                                                    ).withOpacity(0.7),
                                              ),
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'agents',
                                            child: Text(
                                              'Agents'.tr,
                                              style: TextStyle(
                                                fontSize: subtitleFontSize,
                                                color:
                                                    CustomColors.secondaryWidgetTextColor(
                                                      context,
                                                      ref,
                                                    ).withOpacity(0.7),
                                              ),
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'flipers',
                                            child: Text(
                                              'Flipers'.tr,
                                              style: TextStyle(
                                                fontSize: subtitleFontSize,
                                                color:
                                                    CustomColors.secondaryWidgetTextColor(
                                                      context,
                                                      ref,
                                                    ).withOpacity(0.7),
                                              ),
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'hously',
                                            child: Text(
                                              'Hously',
                                              style: TextStyle(
                                                fontSize: subtitleFontSize,
                                                color:
                                                    CustomColors.secondaryWidgetTextColor(
                                                      context,
                                                      ref,
                                                    ).withOpacity(0.7),
                                              ),
                                            ),
                                          ),
                                        ],
                                        onChanged: (value) => postStateNotifier
                                            .updateWallType(value!),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Text input area
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                              ),
                              child: Stack(
                                children: [
                                  EmmaUiAnchorTarget(
                                     anchorKey: WallEmmaAnchors.createPostContentField.anchorKey,

                                     spec: WallEmmaAnchors.createPostContentField,
                                     runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                                     tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                                    child: GlobalSecondaryTextfield(
                                      isExpanded:
                                          postState.selectedFiles.isEmpty &&
                                          (widget.post?.media.isEmpty ?? true),
                                      onChanged: (value) {
                                        setState(() {});
                                      },
                                      controller: postState.contentController,
                                      hintText: "What's on your mind?".tr,
                                    ),
                                  ),
                                  Positioned(
                                    right: horizontalPadding * 0.5,
                                    bottom: horizontalPadding * 0.5,
                                    child: EmmaUiAnchorTarget(
                                       anchorKey: WallEmmaAnchors.createPostEmojiButton.anchorKey,

                                       spec: WallEmmaAnchors.createPostEmojiButton,
                                       runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                                       tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                                      child: InkWell(
                                        onTap: _showEmojiDialog,
                                        child: Container(
                                          padding: EdgeInsets.all(
                                            horizontalPadding * 0.6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: HugeIcon(
                                            icon: HugeIcons.strokeRoundedHappy,
                                            size: iconSize * 1.2,
                                            color:
                                                CustomColors.secondaryWidgetTextColor(
                                                  context,
                                                  ref,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Existing media (for edit mode)
                            if (widget.post != null &&
                                widget.post!.media.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.all(horizontalPadding),
                                child: Column(
                                  children: widget.post!.media
                                      .asMap()
                                      .entries
                                      .where((entry) {
                                        // Filter out media that has been marked for deletion
                                        return !postState.deleteMediaIds
                                            .contains(entry.value.id);
                                      })
                                      .map((entry) {
                                        int index = entry.key;
                                        CommunityMedia media = entry.value;
                                        return Container(
                                          margin: EdgeInsets.only(
                                            bottom: verticalPadding,
                                          ),
                                          child: Stack(
                                            children: [
                                              Container(
                                                width: double.infinity,
                                                height: imageHeight * 0.8,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color:
                                                      CustomColors.secondaryWidgetTextColor(
                                                        context,
                                                        ref,
                                                      ).withOpacity(0.1),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: NetworkMediaThumbnail(
                                                    url: media.url,
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: InkWell(
                                                  onTap: () {
                                                    // Remove existing media by adding its ID to deletion list
                                                    ref
                                                        .read(
                                                          postCreateStateProvider
                                                              .notifier,
                                                        )
                                                        .removeExistingMedia(
                                                          media.id,
                                                        );
                                                  },
                                                  child: Container(
                                                    padding: EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.6),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.close,
                                                      size: iconSize * 0.8,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      })
                                      .toList(),
                                ),
                              ),
                            // Selected images
                            if (postState.selectedFiles.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.all(horizontalPadding),
                                child: Column(
                                  children: postState.selectedFiles
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                        int index = entry.key;
                                        PickedFile file = entry.value;
                                        return Container(
                                          margin: EdgeInsets.only(
                                            bottom: verticalPadding,
                                          ),
                                          child: Stack(
                                            children: [
                                              Container(
                                                width: double.infinity,
                                                height: imageHeight * 0.8,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color:
                                                      CustomColors.secondaryWidgetTextColor(
                                                        context,
                                                        ref,
                                                      ).withOpacity(0.1),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Thumbnail(file: file),
                                                ),
                                              ),
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: InkWell(
                                                  onTap: () => removeFile(file),
                                                  child: Container(
                                                    padding: EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.6),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.close,
                                                      size: iconSize * 0.8,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      })
                                      .toList(),
                                ),
                              ),
                            // Tagged users
                            if (postState.taggedUserIds.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.all(horizontalPadding),
                                child: Wrap(
                                  spacing: 8,
                                  children: widget.userOptions!
                                      .where(
                                        (user) => postState.taggedUserIds
                                            .contains(user['id']),
                                      )
                                      .map(
                                        (user) => Chip(
                                          label: Text('${user['name']}'),
                                          onDeleted: () {
                                            postStateNotifier.removeTaggedUser(
                                              user['id'],
                                            );
                                          },
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Add to your post section
                    Padding(
                      padding: EdgeInsets.all(horizontalPadding),
                      child: Row(
                        children: [
                          Text(
                            'Add to your post'.tr,
                            style: TextStyle(
                              color: CustomColors.secondaryWidgetTextColor(
                                context,
                                ref,
                              ),
                              fontSize: subtitleFontSize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              InkWell(
                                onTap: pickFiles,
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: postState.selectedFiles.isNotEmpty
                                        ? Colors.green.withOpacity(0.2)
                                        : Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedImage01,
                                    size: iconSize * 1.2,
                                    color: postState.selectedFiles.isNotEmpty
                                        ? Colors.green
                                        : CustomColors.secondaryWidgetTextColor(
                                            context,
                                            ref,
                                          ).withOpacity(0.7),
                                  ),
                                ),
                              ),
                              SizedBox(width: horizontalPadding * 0.5),
                              // TODO: finish flow
                              // InkWell(
                              //   onTap: () async {
                              //     if (widget.userOptions != null) {
                              //       final selectedIds =
                              //           await showDialog<List<int>>(
                              //             context: context,
                              //             builder: (ctx) {
                              //               List<int> tempIds = List.from(
                              //                 postState.taggedUserIds,
                              //               );
                              //               return AlertDialog(
                              //                 title: const Text("Tag users"),
                              //                 content: SingleChildScrollView(
                              //                   child: Wrap(
                              //                     spacing: 8,
                              //                     children: widget.userOptions!
                              //                         .map((user) {
                              //                           final isSelected =
                              //                               tempIds.contains(
                              //                                 user['id'],
                              //                               );
                              //                           return FilterChip(
                              //                             label: Text(
                              //                               '${user['name']}',
                              //                             ),
                              //                             selected: isSelected,
                              //                             onSelected: (sel) {
                              //                               if (sel) {
                              //                                 tempIds.add(
                              //                                   user['id'],
                              //                                 );
                              //                               } else {
                              //                                 tempIds.remove(
                              //                                   user['id'],
                              //                                 );
                              //                               }
                              //                             },
                              //                           );
                              //                         })
                              //                         .toList(),
                              //                   ),
                              //                 ),
                              //                 actions: [
                              //                   TextButton(
                              //                     onPressed: () =>
                              //                         Navigator.pop(
                              //                           ctx,
                              //                           tempIds,
                              //                         ),
                              //                     child: const Text('OK'),
                              //                   ),
                              //                 ],
                              //               );
                              //             },
                              //           );
                              //       if (selectedIds != null) {
                              //         postStateNotifier.updateTaggedUsers(
                              //           selectedIds,
                              //         );
                              //       }
                              //     }
                              //   },
                              //   child: Container(
                              //     decoration: BoxDecoration(
                              //       color: Theme.of(
                              //         context,
                              //       ).primaryColor.withOpacity(0.1),
                              //       borderRadius: BorderRadius.circular(8),
                              //     ),
                              //     padding: EdgeInsets.all(8),
                              //     child: HugeIcon(
                              //       icon: HugeIcons.strokeRoundedProfile,
                              //       size: iconSize * 1.2,
                              //       color:
                              //           CustomColors.secondaryWidgetTextColor(
                              //             context,
                              //             ref,
                              //           ).withOpacity(0.7),
                              //     ),
                              //   ),
                              // ),
                              SizedBox(width: horizontalPadding * 0.5),
                              LocationSearchButton(
                                selectedLocation: postState.selectedLocation,
                                onLocationSelected: (location) {
                                  postStateNotifier.updateLocation(location);
                                },
                                iconSize: iconSize,
                              ),
                              SizedBox(width: horizontalPadding * 0.5),
                              InkWell(
                                onTap: pickFiles, // Same as image for now
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.all(8),
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedVideo01,
                                    size: iconSize * 1.2,
                                    color:
                                        CustomColors.secondaryWidgetTextColor(
                                          context,
                                          ref,
                                        ).withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Post/Edit button
                    Padding(
                      padding: EdgeInsets.all(horizontalPadding),
                      child: SizedBox(
                        width: double.infinity,
                        child: EmmaUiAnchorTarget(
                           anchorKey: WallEmmaAnchors.postComposerSubmitButton.anchorKey,

                           spec: WallEmmaAnchors.postComposerSubmitButton,
                           runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                           tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                          child: ElevatedButton.icon(
                            label: postState.loading
                                ? SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      color: CustomColors.secondaryWidgetColor(
                                        context,
                                        ref,
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(widget.post != null ? 'Update'.tr : 'post'.tr),
                            onPressed:
                                (postState.contentController.text.trim().isEmpty)
                                ? null
                                : () {
                                    submitPost(selectedIndex);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  postState.contentController.text.trim().isEmpty
                                  ? CustomColors.secondaryWidgetTextColor(
                                      context,
                                      ref,
                                    ).withOpacity(0.3)
                                  : CustomColors.secondaryWidgetTextColor(
                                      context,
                                      ref,
                                    ),
                              foregroundColor: CustomColors.secondaryWidgetColor(
                                context,
                                ref,
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: verticalPadding * 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
