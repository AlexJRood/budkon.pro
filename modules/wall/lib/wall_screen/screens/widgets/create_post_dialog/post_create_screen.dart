
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';

import 'package:core/common/global_secondary_textfield.dart';
import 'package:core/common/global_user_card.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/user/user/user_provider.dart';
import 'package:wall/wall_screen/screens/widgets/components/custom_components.dart';
import 'package:wall/wall_screen/screens/widgets/components/location_selector.dart';
import 'package:wall/wall_screen/screens/widgets/create_post_dialog/components.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:wall/wall_screen/model/community_post_model.dart';
import 'package:wall/wall_screen/screens/widgets/create_post_dialog/post_create_dialog.dart';
import 'package:wall/wall_screen/providers/post_create_provider.dart'
    hide PickedFile;
import 'package:wall/wall_screen/wall_screen_community_pc.dart';

class PostCreateScreen extends StatelessWidget {
  final CommunityPost? post;

  PostCreateScreen({super.key, this.post});

  @override
  Widget build(BuildContext context) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    return BarManager(
      isTopAppBarOff: true,
      isTopAppBarHoveroverUI: true,
      sideMenuKey: sideMenuKey,
      appModule: AppModule.portal,
      childMobile: PostCreateScreenMobile(post: post),
      childPc: WallScreenCommunityPc(isDialog: true),
    );
  }
}

class PostCreateScreenMobile extends ConsumerStatefulWidget {
  final CommunityPost? post;

  PostCreateScreenMobile({super.key, this.post});

  @override
  ConsumerState<PostCreateScreenMobile> createState() =>
      _PostCreateScreenMobileState();
}

class _PostCreateScreenMobileState
    extends ConsumerState<PostCreateScreenMobile> {
  Future<void> pickFiles() async {
    await ref.read(postCreateStateProvider.notifier).pickFiles();
  }

  void removeFile(PickedFile file) {
    ref.read(postCreateStateProvider.notifier).removeFile(file);
  }

  Future<void> submitPost(int index) async {
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

      if (success) {
          ref.read(navigationService).pushNamedScreen(Routes.wall);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            Customsnackbar().showSnackBar(
              "Success".tr,
              "post_edited_successfully".tr,
              "success",
              () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          );
        
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          Customsnackbar().showSnackBar(
            "Error".tr,
            'failed_to_edit_post'.tr,
            "error",
            () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        );
      }
    } else {
      // Create mode
      await ref
          .read(postCreateStateProvider.notifier)
          .createPost(context: context, ref: ref, tabIndex: index);
      if (mounted) {
        ref.read(navigationService).pushNamedScreen(Routes.wall);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(dialogProvider)) {
        // If provider is true, close the dialog
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        ref.read(dialogProvider.notifier).state = false; // reset
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final postState = ref.watch(postCreateStateProvider);
    final postStateNotifier = ref.read(postCreateStateProvider.notifier);

    final screenWidth = MediaQuery.of(context).size.width;
    double postWidth = screenWidth;
    double aspectRatio = 1.5;
    double imageHeight = postWidth / aspectRatio;
    double avatarSize = 40;
    double titleFontSize = 16;
    double subtitleFontSize = 14;
    double iconSize = 22;

    return Scaffold(
      backgroundColor: CustomColors.secondaryWidgetColor(context, ref),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MobileWallAppbar(
              title: widget.post != null ? "edit post".tr : "create post".tr,
              onPressed: () {
                ref.read(navigationService).beamPop();
              },
            ),
            // User row with dropdown
            Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  GlobalUserCard(
                    size: avatarSize,
                    userAsyncValue: ref.watch(userProvider),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "John Doe",
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w600,
                            color: CustomColors.secondaryWidgetTextColor(
                              context,
                              ref,
                            ),
                          ),
                        ),
                        if (postState.selectedLocation != null)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              postState.selectedLocation!.displayName,
                              style: TextStyle(
                                fontSize: subtitleFontSize,
                                color: CustomColors.secondaryWidgetTextColor(
                                  context,
                                  ref,
                                ).withAlpha(178),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Wall Type Dropdown
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.transparent,
                      border: Border.all(
                        color: CustomColors.secondaryWidgetTextColor(
                          context,
                          ref,
                        ).withAlpha(51),
                      ),
                    ),
                    child: DropdownButton<String>(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      value: postState.wallType,
                      isDense: true,
                      underline: Container(),
                      borderRadius: BorderRadius.circular(8),
                      dropdownColor: CustomColors.secondaryWidgetColor(
                        context,
                        ref,
                      ),
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowDown01,
                        color: CustomColors.secondaryWidgetTextColor(
                          context,
                          ref,
                        ).withAlpha(178),
                        size: 16,
                      ),
                      style: TextStyle(
                        color: CustomColors.secondaryWidgetTextColor(
                          context,
                          ref,
                        ).withAlpha(204),
                        fontSize: 13,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'both',
                          child: Text(
                            'Everyone'.tr,
                            style: TextStyle(
                              fontSize: 13,
                              color: CustomColors.secondaryWidgetTextColor(
                                context,
                                ref,
                              ).withAlpha(178),
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'favourites',
                          child: Text(
                            'Favourites'.tr,
                            style: TextStyle(
                              fontSize: 13,
                              color: CustomColors.secondaryWidgetTextColor(
                                context,
                                ref,
                              ).withAlpha(178),
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'groups',
                          child: Text(
                            'Groups'.tr,
                            style: TextStyle(
                              fontSize: 13,
                              color: CustomColors.secondaryWidgetTextColor(
                                context,
                                ref,
                              ).withAlpha(178),
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'developers',
                          child: Text(
                            'Developers'.tr,
                            style: TextStyle(
                              fontSize: 13,
                              color: CustomColors.secondaryWidgetTextColor(
                                context,
                                ref,
                              ).withAlpha(178),
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'agents',
                          child: Text(
                            'Agents'.tr,
                            style: TextStyle(
                              fontSize: 13,
                              color: CustomColors.secondaryWidgetTextColor(
                                context,
                                ref,
                              ).withAlpha(178),
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'flipers',
                          child: Text(
                            'Flipers'.tr,
                            style: TextStyle(
                              fontSize: 13,
                              color: CustomColors.secondaryWidgetTextColor(
                                context,
                                ref,
                              ).withAlpha(178),
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'hously',
                          child: Text(
                            'Hously',
                            style: TextStyle(
                              fontSize: subtitleFontSize,
                              color: CustomColors.secondaryWidgetTextColor(
                                context,
                                ref,
                              ).withAlpha(178),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          postStateNotifier.updateWallType(value!),
                    ),
                  ),
                ],
              ),
            ),

            // Textfield
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: GlobalSecondaryTextfield(
                onChanged: (p0) {
                  setState(() {});
                },
                isExpanded:
                    postState.selectedFiles.isEmpty &&
                    (widget.post?.media.isEmpty ?? true),
                controller: postState.contentController,
                hintText: "whats on your mind".tr,
              ),
            ),

            // Existing media (for edit mode)
            if (widget.post != null && widget.post!.media.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: CustomColors.secondaryWidgetTextColor(
                            context,
                            ref,
                          ).withAlpha(26),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Header for existing media section
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: CustomColors.secondaryWidgetTextColor(
                                context,
                                ref,
                              ).withAlpha(13),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedImage01,
                                  size: 18,
                                  color: CustomColors.secondaryWidgetTextColor(
                                    context,
                                    ref,
                                  ).withAlpha(178),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "${'existing_media'.tr} (${widget.post!.media.where((m) => !postState.deleteMediaIds.contains(m.id)).length})",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        CustomColors.secondaryWidgetTextColor(
                                          context,
                                          ref,
                                        ).withAlpha(178),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Existing media grid
                          Padding(
                            padding: EdgeInsets.all(12),
                            child: _buildExistingMediaGrid(
                              widget.post!.media
                                  .where(
                                    (m) => !postState.deleteMediaIds.contains(
                                      m.id,
                                    ),
                                  )
                                  .toList(),
                              postWidth,
                              imageHeight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Selected images with improved design
            if (postState.selectedFiles.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: CustomColors.secondaryWidgetTextColor(
                            context,
                            ref,
                          ).withAlpha(26),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Header for media section
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: CustomColors.secondaryWidgetTextColor(
                                context,
                                ref,
                              ).withAlpha(13),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedImage01,
                                  size: 18,
                                  color: CustomColors.secondaryWidgetTextColor(
                                    context,
                                    ref,
                                  ).withAlpha(178),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "${'media'.tr} (${postState.selectedFiles.length})",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        CustomColors.secondaryWidgetTextColor(
                                          context,
                                          ref,
                                        ).withAlpha(178),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Media grid
                          Padding(
                            padding: EdgeInsets.all(12),
                            child: postState.selectedFiles.length == 1
                                ? _buildSingleMedia(
                                    postState.selectedFiles.first,
                                    postWidth,
                                    imageHeight,
                                  )
                                : _buildMediaGrid(
                                    postState.selectedFiles,
                                    postWidth,
                                    imageHeight,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 20),

            // Add to your post
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "add to your post".tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CustomColors.secondaryWidgetTextColor(context, ref),
                ),
              ),
            ),
            SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: postState.selectedFiles.isNotEmpty
                      ? Colors.green.withAlpha(26)
                      : Theme.of(context).primaryColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedGooglePhotos,
                  color: postState.selectedFiles.isNotEmpty
                      ? Colors.green
                      : CustomColors.secondaryWidgetTextColor(context, ref),
                  size: iconSize,
                ),
              ),
              title: Text(
               "photo_video".tr,
                style: TextStyle(
                  color: CustomColors.secondaryWidgetTextColor(context, ref),
                ),
              ),
              onTap: pickFiles,
            ),
            LocationSearchTile(
              selectedLocation: postState.selectedLocation,
              onLocationSelected: (location) {
                postStateNotifier.updateLocation(location);
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: HugeIcon(
                  icon: Icons.emoji_emotions_outlined,
                  color: CustomColors.secondaryWidgetTextColor(context, ref),
                  size: iconSize,
                ),
              ),
              title: Text(
                "activity_feeling".tr,
                style: TextStyle(
                  color: CustomColors.secondaryWidgetTextColor(context, ref),
                ),
              ),
              onTap: () {
                // handle later
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedVideo01,
                  color: CustomColors.secondaryWidgetTextColor(context, ref),
                  size: iconSize,
                ),
              ),
              title: Text(
                "live_video".tr,
                style: TextStyle(
                  color: CustomColors.secondaryWidgetTextColor(context, ref),
                ),
              ),
              onTap: () {
                // handle later
              },
            ),
            SizedBox(height: 20),
            
            // Save/Update Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: postState.contentController.text.trim().isEmpty
                      ? null
                      : () => submitPost(0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: postState.contentController.text.trim().isEmpty
                        ? CustomColors.secondaryWidgetTextColor(
                            context,
                            ref,
                          ).withAlpha(76)
                        : CustomColors.secondaryWidgetTextColor(
                            context,
                            ref,
                          ),
                    foregroundColor: CustomColors.secondaryWidgetColor(
                      context,
                      ref,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: postState.loading
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
                      : Text(widget.post != null ? 'update'.tr : 'post'.tr),
                ),
              ),
            ),
            SizedBox(height: 56),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleMedia(
    PickedFile file,
    double postWidth,
    double imageHeight,
  ) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            height: imageHeight * 0.8,
            color: Colors.grey.shade100,
            child: Thumbnail(file: file),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: InkWell(
            onTap: () => removeFile(file),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(178),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaGrid(
    List<PickedFile> files,
    double postWidth,
    double imageHeight,
  ) {
    if (files.length == 2) {
      return Row(
        children: files.asMap().entries.map((entry) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: entry.key == 0 ? 4 : 0,
                left: entry.key == 1 ? 4 : 0,
              ),
              child: _buildMediaItem(
                entry.value,
                (postWidth - 36) / 2,
                imageHeight * 0.6,
              ),
            ),
          );
        }).toList(),
      );
    } else if (files.length == 3) {
      return Column(
        children: [
          _buildMediaItem(files[0], double.infinity, imageHeight * 0.6),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  child: _buildMediaItem(
                    files[1],
                    (postWidth - 40) / 2,
                    imageHeight * 0.4,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 4),
                  child: _buildMediaItem(
                    files[2],
                    (postWidth - 40) / 2,
                    imageHeight * 0.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // For 4+ files, create a two-column grid
      List<Widget> rows = [];
      double itemWidth =
          (postWidth - 44) / 2; // Account for padding and spacing
      double itemHeight = imageHeight * 0.4;

      for (int i = 0; i < files.length; i += 2) {
        List<Widget> rowChildren = [];

        // First item in row
        rowChildren.add(
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              child: _buildMediaItem(files[i], itemWidth, itemHeight),
            ),
          ),
        );

        // Second item in row (if exists)
        if (i + 1 < files.length) {
          rowChildren.add(
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 4),
                child: _buildMediaItem(files[i + 1], itemWidth, itemHeight),
              ),
            ),
          );
        } else {
          // Add empty space if odd number of items
          rowChildren.add(const Expanded(child: SizedBox()));
        }

        rows.add(Row(children: rowChildren));

        // Add spacing between rows (except last row)
        if (i + 2 < files.length) {
          rows.add(const SizedBox(height: 8));
        }
      }

      return Column(children: rows);
    }
  }

  Widget _buildMediaItem(PickedFile file, double width, double height) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: width,
            height: height,
            color: Colors.grey.shade100,
            child: Thumbnail(file: file),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: InkWell(
            onTap: () => removeFile(file),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(178),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method for building existing media grid
  Widget _buildExistingMediaGrid(
    List<CommunityMedia> mediaList,
    double postWidth,
    double imageHeight,
  ) {
    if (mediaList.isEmpty) {
      return SizedBox.shrink();
    }

    if (mediaList.length == 1) {
      return _buildExistingMediaItem(
        mediaList.first,
        double.infinity,
        imageHeight * 0.8,
      );
    } else if (mediaList.length == 2) {
      return Row(
        children: mediaList.asMap().entries.map((entry) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: entry.key == 0 ? 4 : 0,
                left: entry.key == 1 ? 4 : 0,
              ),
              child: _buildExistingMediaItem(
                entry.value,
                (postWidth - 36) / 2,
                imageHeight * 0.6,
              ),
            ),
          );
        }).toList(),
      );
    } else if (mediaList.length == 3) {
      return Column(
        children: [
          _buildExistingMediaItem(
            mediaList[0],
            double.infinity,
            imageHeight * 0.6,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  child: _buildExistingMediaItem(
                    mediaList[1],
                    (postWidth - 40) / 2,
                    imageHeight * 0.4,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 4),
                  child: _buildExistingMediaItem(
                    mediaList[2],
                    (postWidth - 40) / 2,
                    imageHeight * 0.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // For 4+ files, create a two-column grid
      List<Widget> rows = [];
      double itemWidth = (postWidth - 44) / 2;
      double itemHeight = imageHeight * 0.4;

      for (int i = 0; i < mediaList.length; i += 2) {
        List<Widget> rowChildren = [];

        rowChildren.add(
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              child: _buildExistingMediaItem(
                mediaList[i],
                itemWidth,
                itemHeight,
              ),
            ),
          ),
        );

        if (i + 1 < mediaList.length) {
          rowChildren.add(
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 4),
                child: _buildExistingMediaItem(
                  mediaList[i + 1],
                  itemWidth,
                  itemHeight,
                ),
              ),
            ),
          );
        } else {
          rowChildren.add(const Expanded(child: SizedBox()));
        }

        rows.add(Row(children: rowChildren));

        if (i + 2 < mediaList.length) {
          rows.add(const SizedBox(height: 8));
        }
      }

      return Column(children: rows);
    }
  }

  Widget _buildExistingMediaItem(
    CommunityMedia media,
    double width,
    double height,
  ) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: width,
            height: height,
            color: Colors.grey.shade100,
            child: NetworkMediaThumbnail(url: media.url),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: InkWell(
            onTap: () {
              ref
                  .read(postCreateStateProvider.notifier)
                  .removeExistingMedia(media.id);
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(178),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
