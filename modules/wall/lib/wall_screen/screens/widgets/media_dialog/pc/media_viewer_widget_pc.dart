import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:wall/emma/anchors/anchors_wall.dart';
import 'package:wall/wall_screen/model/community_post_model.dart';
import 'package:wall/wall_screen/screens/widgets/comment_widgets/comment_section_widget.dart';
import '../file_handler.dart';
import '../media_state_provider.dart';

class MediaViewerWidget extends ConsumerStatefulWidget {
  final List<CommunityMedia> media;
  final CommunityPost postData;
  final int initialIndex;
  final bool isSingle;
  final String? feedType; // Feed type to identify which feed to update

  const MediaViewerWidget({
    super.key,
    required this.media,
    required this.initialIndex,
    required this.postData,
    this.isSingle = false,
    this.feedType,
  });

  @override
  ConsumerState<MediaViewerWidget> createState() => _MediaViewerWidgetState();
}

class _MediaViewerWidgetState extends ConsumerState<MediaViewerWidget>
    with TickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsAnimation;
  late List<ExtendedMediaItem> _mediaList;
  late int _providerId;
  bool _showComments = true;
  bool get _isDesktop =>
      MediaQuery.of(context).size.width > 700;

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();
    _providerId = widget.initialIndex;


    // Convert CommunityMedia to ExtendedMediaItem
    _mediaList = widget.media
        .map((media) => ExtendedMediaItem.fromCommunityMedia(media))
        .toList();

    // Initialize animation controller for controls
    _controlsAnimationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _controlsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controlsAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Request focus for keyboard navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controlsAnimationController.forward();

      // Initialize media state
      ref
          .read(mediaStateProvider(_providerId).notifier)
          .initializeMedia(_mediaList);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controlsAnimationController.dispose();
    super.dispose();
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final notifier = ref.read(mediaStateProvider(_providerId).notifier);

      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        notifier.previousMedia(_mediaList);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        notifier.nextMedia(_mediaList);
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        final currentMedia =
        _mediaList[ref.read(mediaStateProvider(_providerId)).currentIndex];
        if (currentMedia.isVideo) {
          notifier.toggleVideoPlayback();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaState = ref.watch(mediaStateProvider(_providerId));
    final safeIndex = mediaState.currentIndex.clamp(0, _mediaList.length - 1);
    final currentMedia = _mediaList[safeIndex];
    return EmmaUiAnchorTarget(
      anchorKey: WallEmmaAnchors.mediaViewer.anchorKey,

      spec: WallEmmaAnchors.mediaViewer,
      runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
      tapMode: EmmaUiAnchorTapMode.disabled,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(0),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: CustomColors.secondaryWidgetColor(context, ref),
          child: RawKeyboardListener(
            focusNode: _focusNode,
            onKey: _handleKeyPress,
            child: GestureDetector(
              onTap: () {
                ref
                    .read(mediaStateProvider(_providerId).notifier)
                    .showControlsTemporarily();
                if (!_controlsAnimationController.isCompleted) {
                  _controlsAnimationController.forward();
                }
              },
              child: Row(
                children: [
                  // Main Content Area
                  Expanded(
                    flex: _showComments && _isDesktop  ? 7 : 10,
                    child: Stack(
                      children: [
                        // File Content
                        Center(
                          child: FileHandler(
                            mediaItem: currentMedia,
                            providerId: _providerId,
                            showCommentToggle: _isDesktop && currentMedia.isVideo,
                            areCommentsVisible: _showComments,
                            onToggleComments: () {
                              setState(() {
                                _showComments = !_showComments;
                              });
                          },),
                        ),
      
                        // Navigation Controls
                        _buildNavigationControls(mediaState),
      
                        // Top Controls
                        _buildTopControls(mediaState, currentMedia),
      
                      ],
                    ),
                  ),
      
                  // Comments Section (for desktop)
                  if (_isDesktop && _showComments) ...[
                    Expanded(
                      flex: 3,
                      //child: Container(),
                      child: CommentSection(
                        post: widget.postData,
                        feedType: widget.feedType,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildNavigationControls(MediaState mediaState) {
    return AnimatedBuilder(
      animation: _controlsAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: mediaState.showControls ? _controlsAnimation.value : 0.0,
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Navigation
          Padding(
            padding: EdgeInsets.only(left: 20),
            child: Center(
              child: EmmaUiAnchorTarget(
                 anchorKey: WallEmmaAnchors.mediaViewerNavPrev.anchorKey,

                 spec: WallEmmaAnchors.mediaViewerNavPrev,
                 runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                 tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                child: NavigationButton(
                  icon: HugeIcons.strokeRoundedArrowLeft02,
                  onPressed: mediaState.currentIndex > 0
                      ? () => ref
                      .read(mediaStateProvider(_providerId).notifier)
                      .previousMedia(_mediaList)
                      : null,
                  isLeft: true,
                ),
              ),
            ),
          ),

          // Right Navigation
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: Center(
              child: EmmaUiAnchorTarget(
                anchorKey: WallEmmaAnchors.mediaViewerNavNext.anchorKey,

                spec: WallEmmaAnchors.mediaViewerNavNext,
                runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                child: NavigationButton(
                  icon: HugeIcons.strokeRoundedArrowRight02,
                  onPressed: mediaState.currentIndex < _mediaList.length - 1
                      ? () => ref
                      .read(mediaStateProvider(_providerId).notifier)
                      .nextMedia(_mediaList)
                      : null,
                  isLeft: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopControls(
      MediaState mediaState,
      ExtendedMediaItem currentMedia,
      ) {
    return Positioned(
      top: 30,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _controlsAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: mediaState.showControls ? _controlsAnimation.value : 0.0,
            child: child,
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Close Button
            Padding(
              padding: EdgeInsets.only(left: 15),
              child: EmmaUiAnchorTarget(
                anchorKey: WallEmmaAnchors.mediaViewerCloseButton.anchorKey,

                spec: WallEmmaAnchors.mediaViewerCloseButton,
                runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                child: Container(
                  decoration: BoxDecoration(
                    color: CustomColors.secondaryWidgetColor(context, ref),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: CustomColors.secondaryWidgetTextColor(
                        context,
                        ref,
                      ).withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.of(context).pop(),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: Icon(
                          Icons.close,
                          color: CustomColors.secondaryWidgetTextColor(
                            context,
                            ref,
                          ),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Media Counter (Center)
            Center(
              child: MediaCounter(
                currentMedia: currentMedia,
                currentIndex: mediaState.currentIndex,
                totalCount: _mediaList.length,
              ),
            ),

            // Spacer for symmetry
            SizedBox(width: 65), // Same width as close button + padding
          ],
        ),
      ),
    );
  }
}
