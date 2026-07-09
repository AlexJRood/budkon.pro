import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:wall/wall_screen/model/community_post_model.dart';
import 'package:wall/wall_screen/screens/widgets/comment_widgets/comment_section_widget.dart';
import 'package:wall/wall_screen/screens/widgets/components/feedcard_action_buttons.dart';
import 'package:wall/wall_screen/screens/widgets/media_dialog/file_handler.dart';
import 'package:wall/wall_screen/screens/widgets/media_dialog/media_state_provider.dart';

class MobileMediaViewerWidget extends ConsumerStatefulWidget {
  final List<CommunityMedia> media;
  final CommunityPost postData;
  final int initialIndex;
  final bool isSingle;
  final String? feedType; // Feed type to identify which feed to update

  const MobileMediaViewerWidget({
    super.key,
    required this.media,
    required this.initialIndex,
    required this.postData,
    this.isSingle = false,
    this.feedType,
  });

  @override
  ConsumerState<MobileMediaViewerWidget> createState() =>
      _MobileMediaViewerWidgetState();
}

class _MobileMediaViewerWidgetState
    extends ConsumerState<MobileMediaViewerWidget>
    with TickerProviderStateMixin {
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsAnimation;
  late List<ExtendedMediaItem> _mediaList;
  late int _providerId;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();

    _providerId =
        DateTime.now().millisecondsSinceEpoch.hashCode ^
        widget.postData.hashCode;

    _mediaList = widget.media
        .map((media) => ExtendedMediaItem.fromCommunityMedia(media))
        .toList();

    _pageController = PageController(initialPage: widget.initialIndex);

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controlsAnimationController.forward();
      ref
          .read(mediaStateProvider(_providerId).notifier)
          .initializeMedia(
            _mediaList,
            initialIndex: widget.initialIndex,
          ); // ✅ fix
    });
  }

  @override
  void dispose() {
    _controlsAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaState = ref.watch(mediaStateProvider(_providerId));
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: CustomColors.secondaryWidgetColor(context, ref),
      body: Column(
        children: [
          Container(height: statusBarHeight, color: Colors.transparent),

          Stack(
            children: [
              Container(
                color: Colors.transparent,
                height: screenHeight - statusBarHeight - bottomPadding,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _mediaList.length,
                  onPageChanged: (index) {
                    ref
                        .read(mediaStateProvider(_providerId).notifier)
                        .setCurrentIndex(index);
                    ref
                        .read(mediaStateProvider(_providerId).notifier)
                        .showControlsTemporarily();
                  },
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        ref
                            .read(mediaStateProvider(_providerId).notifier)
                            .showControlsTemporarily();
                        if (!_controlsAnimationController.isCompleted) {
                          _controlsAnimationController.forward();
                        }
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: Center(
                          child: FileHandler(
                            mediaItem: _mediaList[index],
                            providerId: _providerId,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              _buildMobileTopControls(mediaState),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTopControls(MediaState mediaState) {
    return Positioned(
      top: 0,
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
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(128),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),

                MobileMediaCounter(
                  currentIndex: mediaState.currentIndex,
                  totalCount: _mediaList.length,
                  currentMedia: _mediaList[mediaState.currentIndex],
                ),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(128),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _showCommentsBottomSheet(context, ref),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedComment01,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCommentsBottomSheet(BuildContext context, WidgetRef ref) {
    if (widget.isSingle) {
      ref.read(postProvider.notifier).setPost(widget.postData);
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true, // ✅ tap outside closes
      enableDrag: true, // ✅ swipe down closes
      backgroundColor: Colors.transparent, // ✅ so curve is visible
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: CustomColors.secondaryWidgetColor(context, ref),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20), // ✅ curved top left
                topRight: Radius.circular(20), // ✅ curved top right
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: CommentSection(
                post: widget.postData,
                feedType: widget.feedType,
                // if CommentSection is scrollable, pass scrollController here
                // scrollController: scrollController,
              ),
            ),
          );
        },
      ),
    );
  }
}

class MobileMediaCounter extends ConsumerWidget {
  final ExtendedMediaItem currentMedia;
  final int currentIndex;
  final int totalCount;

  const MobileMediaCounter({
    super.key,
    required this.currentMedia,
    required this.currentIndex,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (totalCount <= 1) return SizedBox.shrink();

    IconData getIcon() {
      switch (currentMedia.type) {
        case FileType.video:
          return Icons.videocam;
        case FileType.pdf:
          return Icons.picture_as_pdf;
        case FileType.image:
          return Icons.image;
        default:
          return Icons.insert_drive_file;
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(178),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(getIcon(), color: Colors.white.withAlpha(204), size: 14),
          SizedBox(width: 6),
          Text(
            '${currentIndex + 1} / $totalCount',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
