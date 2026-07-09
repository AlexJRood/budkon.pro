import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wall/wall_screen/model/community_post_model.dart';
import 'package:wall/wall_screen/providers/wall_posts_paging_provider.dart';
import 'package:wall/wall_screen/screens/widgets/all_screens_list.dart';
import 'package:wall/wall_screen/screens/widgets/components/location_selector.dart';
import '../model/create_post_model.dart';
import 'wall_post_provider.dart';

typedef PickedFile = dynamic; // File (mobile/desktop) or PlatformFile (web)

// State class to hold all the post creation data
class PostCreateState {
  final TextEditingController contentController;
  final LocationData? selectedLocation;
  final String wallType;
  final List<PickedFile> selectedFiles;
  final List<int> taggedUserIds;
  final bool loading;
  final String? statusMsg;
  final List<int>
  deleteMediaIds; // IDs of existing media to delete (edit mode only)

  PostCreateState({
    required this.contentController,
    this.selectedLocation,
    this.wallType = 'both',
    this.selectedFiles = const [],
    this.taggedUserIds = const [],
    this.loading = false,
    this.statusMsg,
    this.deleteMediaIds = const [],
  });

  factory PostCreateState.fromCommunityPost(CommunityPost post) {
    return PostCreateState(
      contentController: TextEditingController(text: post.content),
      selectedLocation: post.location != null
          ? LocationData(
              displayName: post.location!,
              latitude: post.lat!,
              longitude: post.lon!,
            )
          : null,
      wallType: post.wallType,
      selectedFiles: [], // Existing media handled separately in UI
      taggedUserIds: post.taggedUsers,
      loading: false,
      statusMsg: null,
      deleteMediaIds: [], // Start with empty list for edit mode
    );
  }

  PostCreateState copyWith({
    TextEditingController? contentController,
    LocationData? selectedLocation,
    String? wallType,
    List<PickedFile>? selectedFiles,
    List<int>? taggedUserIds,
    bool? loading,
    String? statusMsg,
    List<int>? deleteMediaIds,
    bool clearLocation = false,
  }) {
    return PostCreateState(
      contentController: contentController ?? this.contentController,
      selectedLocation: clearLocation
          ? null
          : (selectedLocation ?? this.selectedLocation),
      wallType: wallType ?? this.wallType,
      selectedFiles: selectedFiles ?? List.from(this.selectedFiles),
      taggedUserIds: taggedUserIds ?? List.from(this.taggedUserIds),
      loading: loading ?? this.loading,
      statusMsg: statusMsg,
      deleteMediaIds: deleteMediaIds ?? List.from(this.deleteMediaIds),
    );
  }

  bool get readyToUpload => _filesReady();

  bool _filesReady() {
    // ✅ If content controller has text, allow post creation
    if (contentController.text.trim().isNotEmpty) return true;

    // ✅ If no files selected, allow
    if (selectedFiles.isEmpty) return true;

    // ✅ Validate selected files
    for (final f in selectedFiles) {
      if (kIsWeb && f is PlatformFile) {
        if (f.bytes == null || f.bytes!.isEmpty) return false;
      } else if (f is File) {
        if (!f.existsSync() || f.lengthSync() == 0) return false;
      }
    }

    return true;
  }
}

// StateNotifier to manage post creation logic
class PostCreateStateNotifier extends StateNotifier<PostCreateState> {
  PostCreateStateNotifier()
    : super(PostCreateState(contentController: TextEditingController()));

  @override
  void dispose() {
    state.contentController.dispose();
    super.dispose();
  }

  // Initialize state from CommunityPost for editing
  void initializeFromPost(CommunityPost post) {
    state = PostCreateState.fromCommunityPost(post);
  }

  // Update wall type
  void updateWallType(String wallType) {
    state = state.copyWith(wallType: wallType);
  }

  // Update location
  void updateLocation(LocationData? location) {
    state = state.copyWith(selectedLocation: location);
  }

  void clearLocation() {
    state = state.copyWith(clearLocation: true);
  }

  // Add files from file picker
  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.media,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final currentFiles = List<PickedFile>.from(state.selectedFiles);

      if (kIsWeb) {
        currentFiles.addAll(
          result.files
              .where((f) => f.bytes != null)
              .where(
                (f) => !currentFiles.any(
                  (existing) =>
                      (existing is PlatformFile && existing.name == f.name),
                ),
              ),
        );
      } else {
        currentFiles.addAll(
          result.paths
              .whereType<String>()
              .map((p) => File(p))
              .where(
                (f) => !currentFiles.any(
                  (existing) => existing is File && existing.path == f.path,
                ),
              ),
        );
      }

      state = state.copyWith(selectedFiles: currentFiles);
    }
  }

  // Pick image from camera
  Future<void> pickFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      final currentFiles = List<PickedFile>.from(state.selectedFiles);
      currentFiles.add(File(pickedFile.path));
      state = state.copyWith(selectedFiles: currentFiles);
    }
  }

  // Remove a file (for newly added files in create/edit mode)
  void removeFile(PickedFile file) {
    final currentFiles = List<PickedFile>.from(state.selectedFiles);
    currentFiles.remove(file);
    state = state.copyWith(selectedFiles: currentFiles);
  }

  // Remove existing media (for edit mode only - adds ID to deletion list)
  void removeExistingMedia(int mediaId) {
    final currentDeleteIds = List<int>.from(state.deleteMediaIds);
    if (!currentDeleteIds.contains(mediaId)) {
      currentDeleteIds.add(mediaId);
      state = state.copyWith(deleteMediaIds: currentDeleteIds);
      log(
        "📝 Added media ID $mediaId to deletion list. Total to delete: ${currentDeleteIds.length}",
      );
    }
  }

  // Update tagged users
  void updateTaggedUsers(List<int> userIds) {
    state = state.copyWith(taggedUserIds: userIds);
  }

  // Remove tagged user
  void removeTaggedUser(int userId) {
    final currentUsers = List<int>.from(state.taggedUserIds);
    currentUsers.remove(userId);
    state = state.copyWith(taggedUserIds: currentUsers);
  }

  // Set loading state
  void setLoading(bool loading) {
    state = state.copyWith(loading: loading);
  }

  void clearController() {
    state.contentController.clear();

    debugPrint(
      "Content controller cleared value after clearController(): ${state.contentController.text}",
    );
  }

  // Set status message
  void setStatusMessage(String? message) {
    state = state.copyWith(statusMsg: message);
  }

  // Clear form after successful post
  void clearForm() {
    state = state.copyWith(
      wallType: 'both',
      selectedLocation: null,
      selectedFiles: <PickedFile>[],
      taggedUserIds: <int>[],
      statusMsg: null,
      loading: false,
      clearLocation: true,
      contentController: TextEditingController(),
    );
  }

  // Create post
  Future<void> createPost({
    required BuildContext context,
    required WidgetRef ref,
    required int tabIndex,
  }) async {
    try {
      setLoading(true);
      setStatusMessage(null);

      if (!state.readyToUpload) {
        setLoading(false);
        setStatusMessage('some_files_not_ready_for_upload'.tr);
        return;
      }

      final List<Uint8List> imagesData = state.selectedFiles
          .where((file) => file is PlatformFile && file.bytes != null)
          .map((file) => (file as PlatformFile).bytes!)
          .toList();

      final formState = CreatePostState(
        content: state.contentController.text.trim(),
        wallType: state.wallType,
        location: state.selectedLocation?.displayName,
        lat: state.selectedLocation?.latitude,
        lon: state.selectedLocation?.longitude,
        imagesData: imagesData.isNotEmpty ? imagesData : null,
        taggedUserIds: state.taggedUserIds,
      );

      log("📩 Creating post with ${imagesData.length} images");

      await ref
          .read(createPostWithFeedUpdateProvider)
          .createPost(
            context: context,
            tabIndex: tabIndex,
            formState: formState,
            postCreateNotifier: this,
          );
    } catch (e) {
      setLoading(false);
      setStatusMessage('failed_to_create_post_error'.tr + e.toString());
      log("Error creating post: $e");
    }
  }

  // Edit post
  Future<bool> editPost({
    required BuildContext context,
    required WidgetRef ref,
    required int userId,
    required int postId,
    required int tabIndex,
  }) async {
    try {
      setLoading(true);
      setStatusMessage(null);

      if (!state.readyToUpload) {
        setLoading(false);
        setStatusMessage('some_files_not_ready_for_upload'.tr);
        return false;
      }

      final List<Uint8List> imagesData = state.selectedFiles
          .where((file) => file is PlatformFile && file.bytes != null)
          .map((file) => (file as PlatformFile).bytes!)
          .toList();

      final formState = CreatePostState(
        content: state.contentController.text.trim(),
        wallType: state.wallType,
        location: state.selectedLocation?.displayName,
        lat: state.selectedLocation?.latitude,
        lon: state.selectedLocation?.longitude,
        imagesData: imagesData.isNotEmpty ? imagesData : null,
        taggedUserIds: state.taggedUserIds,
        deleteMediaIds: state.deleteMediaIds,
      );

      log(
        "✏️ Editing post ID $postId with ${imagesData.length} new images and ${state.deleteMediaIds.length} media to delete",
      );

      final success = await ref
          .read(wallPostProvider.notifier)
          .editPost(context: context, postId: postId, formState: formState);

      if (success) {
        final editedPost = ref.read(wallPostProvider).value;
        if (editedPost != null) {
          // Update feeds with edited post using tab index
          await ref
              .read(createPostWithFeedUpdateProvider)
              .updateFeedsWithEditedPost(
                editedPost: editedPost,
                tabIndex: tabIndex,
              );

          // Update profile wall posts
          updatePostInPagingController(
            ref,
            editedPost.author.userId.toString(),
            editedPost,
          );

          clearForm();
          clearController();
          log("✅ Post edited successfully and feeds updated");
          return true;
        } else {
          setLoading(false);
          setStatusMessage('post_edit_failed_no_post_returned'.tr);
          return false;
        }
      } else {
        setLoading(false);
        setStatusMessage('failed_to_edit_post'.tr);
        return false;
      }
    } catch (e) {
      setLoading(false);
      setStatusMessage('failed_to_edit_post_error'.tr + e.toString());
      log("Error editing post: $e");
      return false;
    }
  }

  bool get mounted => true;
}

class CreatePostWithFeedUpdate {
  final Ref ref;

  CreatePostWithFeedUpdate(this.ref);

  Future<void> createPost({
    required BuildContext context,
    required int tabIndex,
    required CreatePostState formState,
    required PostCreateStateNotifier postCreateNotifier,
  }) async {
    final createPostNotifier = ref.read(wallPostProvider.notifier);

    log("📩 Creating post with ${formState.imagesData?.length ?? 0} images");

    final success = await createPostNotifier.createPost(
      context: context,
      formState: formState,
    );

    if (success) {
      final createdPost = ref.read(wallPostProvider).value;

      if (createdPost != null) {
        await _updateFeedsWithNewPost(createdPost, tabIndex);
        postCreateNotifier.clearForm();
        log("✅ Post created successfully and feeds updated");
      } else {
        postCreateNotifier.setLoading(false);
       postCreateNotifier.setStatusMessage('post_creation_failed_no_post_returned'.tr);
      }
    } else {
      postCreateNotifier.setLoading(false);
      postCreateNotifier.setStatusMessage('failed_to_create_post'.tr);
    }
  }

  Future<void> updateFeedsWithEditedPost({
    required CommunityPost editedPost,
    required int tabIndex,
  }) async {
    final feedTypeMap = {
      0: 'all',
      1: 'favourites',
      2: 'groups',
      3: 'developers',
      4: 'flipers',
      5: 'agents',
    };

    // Update "all" feed
    try {
      final allFeedController = ref.read(
        feedPagingControllerProvider('all').notifier,
      );
      allFeedController.updatePost(editedPost);
      log("✅ Updated 'all' feed with edited post ID ${editedPost.id}");
    } catch (e) {
      log("❌ Could not update 'all' feed: $e");
    }

    // Update specific feed if post matches the wall type
    if (tabIndex > 0 && editedPost.wallType == feedTypeMap[tabIndex]) {
      try {
        final specificFeedController = ref.read(
          feedPagingControllerProvider(feedTypeMap[tabIndex]!).notifier,
        );
        specificFeedController.updatePost(editedPost);
        log(
          "✅ Updated '${feedTypeMap[tabIndex]}' feed with edited post ID ${editedPost.id}",
        );
      } catch (e) {
        log("❌ Could not update '${feedTypeMap[tabIndex]}' feed: $e");
      }
    }
  }

  Future<void> _updateFeedsWithNewPost(
    CommunityPost createdPost,
    int tabIndex,
  ) async {
    final feedTypeMap = {
      0: 'all',
      1: 'favourites',
      2: 'groups',
      3: 'developers',
      4: 'flipers',
      5: 'agents',
    };

    try {
      final allFeedController = ref.read(
        feedPagingControllerProvider('all').notifier,
      );
      allFeedController.addNewPost(createdPost);
      log("✅ Updated 'all' feed with new post");
    } catch (e) {
      log("❌ Could not update 'all' feed: $e");
    }

    if (tabIndex > 0 && createdPost.wallType == feedTypeMap[tabIndex]) {
      try {
        final specificFeedController = ref.read(
          feedPagingControllerProvider(feedTypeMap[tabIndex]!).notifier,
        );
        specificFeedController.addNewPost(createdPost);
        log("✅ Updated '${feedTypeMap[tabIndex]}' feed with new post");
      } catch (e) {
        log("❌ Could not update '${feedTypeMap[tabIndex]}' feed: $e");
      }
    }
  }

  Future<void> deletePostFromFeeds({
    required int postId,
    required String wallType,
    required int tabIndex,
  }) async {
    final feedTypeMap = {
      0: 'all',
      1: 'favourites',
      2: 'groups',
      3: 'developers',
      4: 'flipers',
      5: 'agents',
    };

    // Remove from "all" feed
    try {
      final allFeedController = ref.read(
        feedPagingControllerProvider('all').notifier,
      );
      allFeedController.deletePost(postId);
      log("✅ Removed post $postId from 'all' feed");
    } catch (e) {
      log("❌ Could not remove from 'all' feed: $e");
    }

    // Remove from specific feed if post matches the wall type
    if (tabIndex > 0 && wallType == feedTypeMap[tabIndex]) {
      try {
        final specificFeedController = ref.read(
          feedPagingControllerProvider(feedTypeMap[tabIndex]!).notifier,
        );
        specificFeedController.deletePost(postId);
        log("✅ Removed post $postId from '${feedTypeMap[tabIndex]}' feed");
      } catch (e) {
        log("❌ Could not remove from '${feedTypeMap[tabIndex]}' feed: $e");
      }
    }
  }
}

final postCreateStateProvider =
    StateNotifierProvider<PostCreateStateNotifier, PostCreateState>((ref) {
      return PostCreateStateNotifier();
    });

final createPostWithFeedUpdateProvider = Provider((ref) {
  return CreatePostWithFeedUpdate(ref);
});
