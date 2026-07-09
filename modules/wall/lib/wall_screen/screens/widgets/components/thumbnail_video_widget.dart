import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wall/wall_screen/model/community_post_model.dart';
import 'package:wall/wall_screen/screens/widgets/components/custom_components.dart';

class VideoThumbnail extends StatefulWidget {
  final CommunityMedia media;
  final bool isMobile;

  const VideoThumbnail({super.key, required this.media, this.isMobile = false});

  @override
  _VideoThumbnailState createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  late VideoPlayerController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.media.url)
      ..initialize()
          .then((_) {
            if (mounted) setState(() {});
          })
          .catchError((_) {
            if (mounted) setState(() => _hasError = true);
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const ProfessionalImagePlaceholder();
    }

    if (!_controller.value.isInitialized) {
      return const ProfessionalImagePlaceholder();
    }

    if (widget.isMobile) {
      // Mobile version - force consistent sizing like images
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Fill the entire container with video thumbnail
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover, // Crop/scale video to fill container
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
            Icon(
              Icons.play_circle_outline,
              color: Colors.white.withAlpha(178),
              size: 36,
            ),
          ],
        ),
      );
    } else {
      // Desktop version - maintain aspect ratio
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
            Icon(
              Icons.play_circle_outline,
              color: Colors.white.withAlpha(178),
              size: 50,
            ),
          ],
        ),
      );
    }
  }
}
