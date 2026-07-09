import 'package:core/ui/anchors/anchor_spec.dart';

abstract final class WallEmmaAnchors {
  static const String _module = 'wall';
  static const String _route = '/wall';
  static const EmmaUiAnchorSpec wallScreen = EmmaUiAnchorSpec(
    anchorKey: 'wall.screen.root',
    frontendRef: 'WallEmmaAnchors.wallScreen',
    label: 'Wall Screen',
    description: 'Main community wall screen with posts feed.',
    module: _module,
    screenKey: 'wall',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['wall', 'community', 'screen'],
    meta: {'group': 'screen'},
    onboardingOrder: 1,
    onboardingMessage: 'This is the community wall where you can see posts.',
  );

  static const EmmaUiAnchorSpec wallScreenPc = EmmaUiAnchorSpec(
    anchorKey: 'wall.screen.pc',
    frontendRef: 'WallEmmaAnchors.wallScreenPc',
    label: 'Wall Screen PC',
    description: 'Desktop version of community wall.',
    module: _module,
    screenKey: 'wall_pc',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['wall', 'community', 'pc', 'desktop'],
    meta: {'group': 'screen', 'platform': 'desktop'},
  );

  static const EmmaUiAnchorSpec wallScreenMobile = EmmaUiAnchorSpec(
    anchorKey: 'wall.screen.mobile',
    frontendRef: 'WallEmmaAnchors.wallScreenMobile',
    label: 'Wall Screen Mobile',
    description: 'Mobile version of community wall.',
    module: _module,
    screenKey: 'wall_mobile',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['wall', 'community', 'mobile'],
    meta: {'group': 'screen', 'platform': 'mobile'},
  );

  // ==================== SIDEBAR / FEED SELECTOR ====================
  static const EmmaUiAnchorSpec wallSidebar = EmmaUiAnchorSpec(
    anchorKey: 'wall.sidebar.main',
    frontendRef: 'WallEmmaAnchors.wallSidebar',
    label: 'Wall Sidebar',
    description: 'Sidebar with feed type selector.',
    module: _module,
    screenKey: 'sidebar',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.sidebar,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['wall', 'sidebar', 'navigation'],
    meta: {'group': 'navigation'},
    onboardingOrder: 2,
    onboardingMessage: 'Use this sidebar to choose which feed to view.',
  );

  static const EmmaUiAnchorSpec feedSelectorItem = EmmaUiAnchorSpec(
    anchorKey: 'wall.feed_selector.item',
    frontendRef: 'WallEmmaAnchors.feedSelectorItem',
    label: 'Feed Selector Item',
    description: 'Individual feed type selector item (All, Favourites, etc.).',
    module: _module,
    screenKey: 'sidebar',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.listItem,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['wall', 'feed', 'selector', 'item'],
    meta: {'group': 'navigation'},
  );

  // ==================== POST COMPOSER ====================
  static const EmmaUiAnchorSpec postComposer = EmmaUiAnchorSpec(
    anchorKey: 'wall.post_composer',
    frontendRef: 'WallEmmaAnchors.postComposer',
    label: 'Post Composer',
    description: 'Component for creating new posts.',
    module: _module,
    screenKey: 'composer',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['wall', 'composer', 'create'],
    meta: {'group': 'composer'},
    onboardingOrder: 3,
    onboardingMessage: 'Click here to create a new post.',
  );

  static const EmmaUiAnchorSpec postComposerTextField = EmmaUiAnchorSpec(
    anchorKey: 'wall.post_composer.text_field',
    frontendRef: 'WallEmmaAnchors.postComposerTextField',
    label: 'Post Composer Text Field',
    description: 'Text field for writing post content.',
    module: _module,
    screenKey: 'composer',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.input,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['wall', 'composer', 'input', 'text'],
    meta: {'group': 'composer'},
  );

  static const EmmaUiAnchorSpec postComposerImageButton = EmmaUiAnchorSpec(
    anchorKey: 'wall.post_composer.image_button',
    frontendRef: 'WallEmmaAnchors.postComposerImageButton',
    label: 'Add Image Button',
    description: 'Button to add images to post.',
    module: _module,
    screenKey: 'composer',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'composer', 'image', 'button'],
    meta: {'group': 'composer'},
  );

  static const EmmaUiAnchorSpec postComposerVideoButton = EmmaUiAnchorSpec(
    anchorKey: 'wall.post_composer.video_button',
    frontendRef: 'WallEmmaAnchors.postComposerVideoButton',
    label: 'Add Video Button',
    description: 'Button to add videos to post.',
    module: _module,
    screenKey: 'composer',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'composer', 'video', 'button'],
    meta: {'group': 'composer'},
  );

  static const EmmaUiAnchorSpec postComposerLocationButton = EmmaUiAnchorSpec(
    anchorKey: 'wall.post_composer.location_button',
    frontendRef: 'WallEmmaAnchors.postComposerLocationButton',
    label: 'Add Location Button',
    description: 'Button to add location to post.',
    module: _module,
    screenKey: 'composer',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'composer', 'location', 'button'],
    meta: {'group': 'composer'},
  );

  static const EmmaUiAnchorSpec postComposerFeelingButton = EmmaUiAnchorSpec(
    anchorKey: 'wall.post_composer.feeling_button',
    frontendRef: 'WallEmmaAnchors.postComposerFeelingButton',
    label: 'Add Feeling Button',
    description: 'Button to add feeling/emoji to post.',
    module: _module,
    screenKey: 'composer',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'composer', 'feeling', 'button'],
    meta: {'group': 'composer'},
  );

  static const EmmaUiAnchorSpec postComposerSubmitButton = EmmaUiAnchorSpec(
    anchorKey: 'wall.post_composer.submit_button',
    frontendRef: 'WallEmmaAnchors.postComposerSubmitButton',
    label: 'Submit Post Button',
    description: 'Button to submit/create post.',
    module: _module,
    screenKey: 'composer',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['wall', 'composer', 'submit', 'button'],
    meta: {'group': 'composer'},
    onboardingOrder: 4,
    onboardingMessage: 'Click here to publish your post.',
  );

  // ==================== CREATE POST DIALOG ====================
  static const EmmaUiAnchorSpec createPostDialog = EmmaUiAnchorSpec(
    anchorKey: 'wall.create_post.dialog',
    frontendRef: 'WallEmmaAnchors.createPostDialog',
    label: 'Create Post Dialog',
    description: 'Dialog for creating a new post.',
    module: _module,
    screenKey: 'create_post',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.overlay,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['wall', 'create', 'dialog'],
    meta: {'group': 'dialogs'},
  );

  static const EmmaUiAnchorSpec createPostWallTypeDropdown = EmmaUiAnchorSpec(
    anchorKey: 'wall.create_post.wall_type',
    frontendRef: 'WallEmmaAnchors.createPostWallTypeDropdown',
    label: 'Wall Type Dropdown',
    description: 'Dropdown to select who can see the post.',
    module: _module,
    screenKey: 'create_post',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.input,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'create', 'dropdown', 'visibility'],
    meta: {'group': 'form'},
  );

  static const EmmaUiAnchorSpec createPostContentField = EmmaUiAnchorSpec(
    anchorKey: 'wall.create_post.content_field',
    frontendRef: 'WallEmmaAnchors.createPostContentField',
    label: 'Post Content Field',
    description: 'Text field for post content.',
    module: _module,
    screenKey: 'create_post',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.input,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['wall', 'create', 'input', 'content'],
    meta: {'group': 'form'},
  );

  static const EmmaUiAnchorSpec createPostEmojiButton = EmmaUiAnchorSpec(
    anchorKey: 'wall.create_post.emoji_button',
    frontendRef: 'WallEmmaAnchors.createPostEmojiButton',
    label: 'Emoji Button',
    description: 'Button to open emoji picker.',
    module: _module,
    screenKey: 'create_post',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'create', 'emoji', 'button'],
    meta: {'group': 'form_actions'},
  );

  // ==================== POST CARD / FEED ITEMS ====================
  static const EmmaUiAnchorSpec postCard = EmmaUiAnchorSpec(
    anchorKey: 'wall.post_card',
    frontendRef: 'WallEmmaAnchors.postCard',
    label: 'Post Card',
    description: 'Individual post card in the feed.',
    module: _module,
    screenKey: 'feed',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.card,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['wall', 'post', 'card', 'feed'],
    meta: {'group': 'feed'},
  );

  static const EmmaUiAnchorSpec postAuthorAvatar = EmmaUiAnchorSpec(
    anchorKey: 'wall.post_card.author_avatar',
    frontendRef: 'WallEmmaAnchors.postAuthorAvatar',
    label: 'Post Author Avatar',
    description: 'Avatar of the post author.',
    module: _module,
    screenKey: 'feed',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'post', 'avatar', 'author'],
    meta: {'group': 'post_header'},
  );

  static const EmmaUiAnchorSpec postAuthorName = EmmaUiAnchorSpec(
    anchorKey: 'wall.post_card.author_name',
    frontendRef: 'WallEmmaAnchors.postAuthorName',
    label: 'Post Author Name',
    description: 'Name of the post author (clickable to profile).',
    module: _module,
    screenKey: 'feed',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'post', 'name', 'author'],
    meta: {'group': 'post_header'},
  );

  static const EmmaUiAnchorSpec postContent = EmmaUiAnchorSpec(
    anchorKey: 'wall.post_card.content',
    frontendRef: 'WallEmmaAnchors.postContent',
    label: 'Post Content',
    description: 'Text content of the post.',
    module: _module,
    screenKey: 'feed',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'post', 'content'],
    meta: {'group': 'post_content'},
  );

  static const EmmaUiAnchorSpec postMedia = EmmaUiAnchorSpec(
    anchorKey: 'wall.post_card.media',
    frontendRef: 'WallEmmaAnchors.postMedia',
    label: 'Post Media',
    description: 'Images/videos attached to the post.',
    module: _module,
    screenKey: 'feed',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'post', 'media', 'image', 'video'],
    meta: {'group': 'post_media'},
  );

  static const EmmaUiAnchorSpec postLocation = EmmaUiAnchorSpec(
    anchorKey: 'wall.post_card.location',
    frontendRef: 'WallEmmaAnchors.postLocation',
    label: 'Post Location',
    description: 'Location attached to the post.',
    module: _module,
    screenKey: 'feed',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'post', 'location'],
    meta: {'group': 'post_metadata'},
  );

  // ==================== POST ACTION BUTTONS ====================
  static const EmmaUiAnchorSpec postLikeButton = EmmaUiAnchorSpec(
    anchorKey: 'wall.post_card.like_button',
    frontendRef: 'WallEmmaAnchors.postLikeButton',
    label: 'Like Button',
    description: 'Button to like/unlike a post.',
    module: _module,
    screenKey: 'feed',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['wall', 'post', 'like', 'button'],
    meta: {'group': 'post_actions'},
  );

  static const EmmaUiAnchorSpec postCommentButton = EmmaUiAnchorSpec(
    anchorKey: 'wall.post_card.comment_button',
    frontendRef: 'WallEmmaAnchors.postCommentButton',
    label: 'Comment Button',
    description: 'Button to open comments section.',
    module: _module,
    screenKey: 'feed',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['wall', 'post', 'comment', 'button'],
    meta: {'group': 'post_actions'},
    onboardingOrder: 5,
    onboardingMessage: 'Click here to view or add comments.',
  );

  static const EmmaUiAnchorSpec postShareButton = EmmaUiAnchorSpec(
    anchorKey: 'wall.post_card.share_button',
    frontendRef: 'WallEmmaAnchors.postShareButton',
    label: 'Share Button',
    description: 'Button to share a post.',
    module: _module,
    screenKey: 'feed',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'post', 'share', 'button'],
    meta: {'group': 'post_actions'},
  );

  static const EmmaUiAnchorSpec postCopyButton = EmmaUiAnchorSpec(
    anchorKey: 'wall.post_card.copy_button',
    frontendRef: 'WallEmmaAnchors.postCopyButton',
    label: 'Copy Link Button',
    description: 'Button to copy post link.',
    module: _module,
    screenKey: 'feed',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'post', 'copy', 'button'],
    meta: {'group': 'post_actions'},
  );

  // ==================== POST MENU (EDIT/DELETE/REPORT) ====================
  static const EmmaUiAnchorSpec postMenuButton = EmmaUiAnchorSpec(
    anchorKey: 'wall.post_card.menu_button',
    frontendRef: 'WallEmmaAnchors.postMenuButton',
    label: 'Post Menu Button',
    description: 'Button to open post actions menu.',
    module: _module,
    screenKey: 'feed',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'post', 'menu', 'button'],
    meta: {'group': 'post_actions'},
  );

  static const EmmaUiAnchorSpec postEditButton = EmmaUiAnchorSpec(
    anchorKey: 'wall.post_card.edit_button',
    frontendRef: 'WallEmmaAnchors.postEditButton',
    label: 'Edit Post Button',
    description: 'Button to edit a post (own posts only).',
    module: _module,
    screenKey: 'feed',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'post', 'edit', 'button'],
    meta: {'group': 'post_menu'},
  );

  static const EmmaUiAnchorSpec postDeleteButton = EmmaUiAnchorSpec(
    anchorKey: 'wall.post_card.delete_button',
    frontendRef: 'WallEmmaAnchors.postDeleteButton',
    label: 'Delete Post Button',
    description: 'Button to delete a post (own posts only).',
    module: _module,
    screenKey: 'feed',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'post', 'delete', 'button'],
    meta: {'group': 'post_menu'},
  );

  static const EmmaUiAnchorSpec postReportButton = EmmaUiAnchorSpec(
    anchorKey: 'wall.post_card.report_button',
    frontendRef: 'WallEmmaAnchors.postReportButton',
    label: 'Report Post Button',
    description: 'Button to report a post.',
    module: _module,
    screenKey: 'feed',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'post', 'report', 'button'],
    meta: {'group': 'post_menu'},
  );

  // ==================== COMMENTS SECTION ====================
  static const EmmaUiAnchorSpec commentsDialog = EmmaUiAnchorSpec(
    anchorKey: 'wall.comments.dialog',
    frontendRef: 'WallEmmaAnchors.commentsDialog',
    label: 'Comments Dialog',
    description: 'Dialog showing comments for a post.',
    module: _module,
    screenKey: 'comments',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.overlay,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['wall', 'comments', 'dialog'],
    meta: {'group': 'dialogs'},
  );

  static const EmmaUiAnchorSpec commentsBottomSheet = EmmaUiAnchorSpec(
    anchorKey: 'wall.comments.bottom_sheet',
    frontendRef: 'WallEmmaAnchors.commentsBottomSheet',
    label: 'Comments Bottom Sheet',
    description: 'Bottom sheet showing comments (mobile).',
    module: _module,
    screenKey: 'comments',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.overlay,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['wall', 'comments', 'bottom_sheet'],
    meta: {'group': 'dialogs', 'platform': 'mobile'},
  );

  static const EmmaUiAnchorSpec commentTextField = EmmaUiAnchorSpec(
    anchorKey: 'wall.comments.text_field',
    frontendRef: 'WallEmmaAnchors.commentTextField',
    label: 'Comment Text Field',
    description: 'Text field for writing comments.',
    module: _module,
    screenKey: 'comments',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.input,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['wall', 'comments', 'input'],
    meta: {'group': 'comments'},
    onboardingOrder: 6,
    onboardingMessage: 'Type your comment here.',
  );

  static const EmmaUiAnchorSpec commentSubmitButton = EmmaUiAnchorSpec(
    anchorKey: 'wall.comments.submit_button',
    frontendRef: 'WallEmmaAnchors.commentSubmitButton',
    label: 'Submit Comment Button',
    description: 'Button to submit a comment.',
    module: _module,
    screenKey: 'comments',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['wall', 'comments', 'submit', 'button'],
    meta: {'group': 'comments'},
  );

  static const EmmaUiAnchorSpec commentEmojiButton = EmmaUiAnchorSpec(
    anchorKey: 'wall.comments.emoji_button',
    frontendRef: 'WallEmmaAnchors.commentEmojiButton',
    label: 'Comment Emoji Button',
    description: 'Button to open emoji picker for comments.',
    module: _module,
    screenKey: 'comments',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'comments', 'emoji', 'button'],
    meta: {'group': 'comments'},
  );

  static const EmmaUiAnchorSpec commentImageButton = EmmaUiAnchorSpec(
    anchorKey: 'wall.comments.image_button',
    frontendRef: 'WallEmmaAnchors.commentImageButton',
    label: 'Comment Image Button',
    description: 'Button to attach image to comment.',
    module: _module,
    screenKey: 'comments',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'comments', 'image', 'button'],
    meta: {'group': 'comments'},
  );

  static const EmmaUiAnchorSpec commentLikeButton = EmmaUiAnchorSpec(
    anchorKey: 'wall.comments.like_button',
    frontendRef: 'WallEmmaAnchors.commentLikeButton',
    label: 'Comment Like Button',
    description: 'Button to like a comment.',
    module: _module,
    screenKey: 'comments',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'comments', 'like', 'button'],
    meta: {'group': 'comments'},
  );

  // ==================== MEDIA VIEWER ====================
  static const EmmaUiAnchorSpec mediaViewer = EmmaUiAnchorSpec(
    anchorKey: 'wall.media_viewer',
    frontendRef: 'WallEmmaAnchors.mediaViewer',
    label: 'Media Viewer',
    description: 'Fullscreen media viewer for images/videos.',
    module: _module,
    screenKey: 'media_viewer',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.overlay,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'media', 'viewer'],
    meta: {'group': 'overlays'},
  );

  static const EmmaUiAnchorSpec mediaViewerCloseButton = EmmaUiAnchorSpec(
    anchorKey: 'wall.media_viewer.close_button',
    frontendRef: 'WallEmmaAnchors.mediaViewerCloseButton',
    label: 'Media Viewer Close Button',
    description: 'Button to close media viewer.',
    module: _module,
    screenKey: 'media_viewer',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'media', 'close', 'button'],
    meta: {'group': 'media_controls'},
  );

  static const EmmaUiAnchorSpec mediaViewerNavPrev = EmmaUiAnchorSpec(
    anchorKey: 'wall.media_viewer.nav_prev',
    frontendRef: 'WallEmmaAnchors.mediaViewerNavPrev',
    label: 'Media Viewer Previous Button',
    description: 'Button to go to previous media.',
    module: _module,
    screenKey: 'media_viewer',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'media', 'navigation', 'button'],
    meta: {'group': 'media_controls'},
  );

  static const EmmaUiAnchorSpec mediaViewerNavNext = EmmaUiAnchorSpec(
    anchorKey: 'wall.media_viewer.nav_next',
    frontendRef: 'WallEmmaAnchors.mediaViewerNavNext',
    label: 'Media Viewer Next Button',
    description: 'Button to go to next media.',
    module: _module,
    screenKey: 'media_viewer',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'media', 'navigation', 'button'],
    meta: {'group': 'media_controls'},
  );

  static const EmmaUiAnchorSpec mediaViewerCommentsButton = EmmaUiAnchorSpec(
    anchorKey: 'wall.media_viewer.comments_button',
    frontendRef: 'WallEmmaAnchors.mediaViewerCommentsButton',
    label: 'Media Viewer Comments Button',
    description: 'Button to show comments from media viewer.',
    module: _module,
    screenKey: 'media_viewer',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'media', 'comments', 'button'],
    meta: {'group': 'media_controls'},
  );

  // ==================== LOCATION SEARCH ====================
  static const EmmaUiAnchorSpec locationSearchDialog = EmmaUiAnchorSpec(
    anchorKey: 'wall.location_search.dialog',
    frontendRef: 'WallEmmaAnchors.locationSearchDialog',
    label: 'Location Search Dialog',
    description: 'Dialog for searching locations.',
    module: _module,
    screenKey: 'location_search',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.overlay,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'location', 'search', 'dialog'],
    meta: {'group': 'dialogs'},
  );

  static const EmmaUiAnchorSpec locationSearchField = EmmaUiAnchorSpec(
    anchorKey: 'wall.location_search.field',
    frontendRef: 'WallEmmaAnchors.locationSearchField',
    label: 'Location Search Field',
    description: 'Search field for finding locations.',
    module: _module,
    screenKey: 'location_search',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.input,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'location', 'search', 'input'],
    meta: {'group': 'form'},
  );

  static const EmmaUiAnchorSpec locationResultItem = EmmaUiAnchorSpec(
    anchorKey: 'wall.location_search.result_item',
    frontendRef: 'WallEmmaAnchors.locationResultItem',
    label: 'Location Result Item',
    description: 'Individual location search result.',
    module: _module,
    screenKey: 'location_search',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.listItem,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'location', 'result', 'item'],
    meta: {'group': 'results'},
  );

  // ==================== DELETE CONFIRMATION ====================
  static const EmmaUiAnchorSpec deleteConfirmationDialog = EmmaUiAnchorSpec(
    anchorKey: 'wall.delete_confirmation.dialog',
    frontendRef: 'WallEmmaAnchors.deleteConfirmationDialog',
    label: 'Delete Confirmation Dialog',
    description: 'Dialog to confirm post deletion.',
    module: _module,
    screenKey: 'delete_confirmation',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.overlay,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'delete', 'confirmation', 'dialog'],
    meta: {'group': 'dialogs'},
  );

  static const EmmaUiAnchorSpec deleteConfirmButton = EmmaUiAnchorSpec(
    anchorKey: 'wall.delete_confirmation.confirm',
    frontendRef: 'WallEmmaAnchors.deleteConfirmButton',
    label: 'Confirm Delete Button',
    description: 'Button to confirm deletion.',
    module: _module,
    screenKey: 'delete_confirmation',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'delete', 'confirm', 'button'],
    meta: {'group': 'dialog_actions'},
  );

  static const EmmaUiAnchorSpec deleteCancelButton = EmmaUiAnchorSpec(
    anchorKey: 'wall.delete_confirmation.cancel',
    frontendRef: 'WallEmmaAnchors.deleteCancelButton',
    label: 'Cancel Delete Button',
    description: 'Button to cancel deletion.',
    module: _module,
    screenKey: 'delete_confirmation',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'delete', 'cancel', 'button'],
    meta: {'group': 'dialog_actions'},
  );

  // ==================== FEED LIST ====================
  static const EmmaUiAnchorSpec feedList = EmmaUiAnchorSpec(
    anchorKey: 'wall.feed.list',
    frontendRef: 'WallEmmaAnchors.feedList',
    label: 'Feed List',
    description: 'Scrollable list of posts.',
    module: _module,
    screenKey: 'feed',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['wall', 'feed', 'list'],
    meta: {'group': 'feed'},
  );

  // ==================== MOBILE FEED SHEET ====================
  static const EmmaUiAnchorSpec mobileFeedSheet = EmmaUiAnchorSpec(
    anchorKey: 'wall.mobile.feed_sheet',
    frontendRef: 'WallEmmaAnchors.mobileFeedSheet',
    label: 'Mobile Feed Sheet',
    description: 'Bottom sheet for feed selection on mobile.',
    module: _module,
    screenKey: 'mobile_feed_sheet',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.overlay,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'mobile', 'feed', 'sheet'],
    meta: {'group': 'sheets', 'platform': 'mobile'},
  );

  static const EmmaUiAnchorSpec mobileFeedSheetButton = EmmaUiAnchorSpec(
    anchorKey: 'wall.mobile.feed_sheet_button',
    frontendRef: 'WallEmmaAnchors.mobileFeedSheetButton',
    label: 'Mobile Feed Sheet Button',
    description: 'Button to open feed selection sheet.',
    module: _module,
    screenKey: 'wall',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['wall', 'mobile', 'feed', 'sheet', 'button'],
    meta: {'group': 'navigation', 'platform': 'mobile'},
  );
}