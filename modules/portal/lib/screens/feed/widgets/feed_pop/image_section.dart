import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/global_widgets/full_screen_image.dart';

class ImageSectionMobile extends ConsumerStatefulWidget {
  final List<String> images;
  final String heroTag;
  final double mainWidth;
  final double mainHeight;

  const ImageSectionMobile({
    super.key,
    required this.images,
    required this.heroTag,
    required this.mainWidth,
    required this.mainHeight,
  });

  @override
  ConsumerState<ImageSectionMobile> createState() => _ImageSectionMobileState();
}

class _ImageSectionMobileState extends ConsumerState<ImageSectionMobile> {
  late final PageController _pageController;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _current);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final total = widget.images.length;
    final next = (_current + delta).clamp(0, total - 1);
    if (next != _current) {
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final hasMany = widget.images.length > 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Główne zdjęcie z przewijaniem (swipe) + strzałki
        Hero(
          tag: widget.heroTag,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: widget.mainWidth,
                height: widget.mainHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _current = i),
                    itemCount: widget.images.isNotEmpty ? widget.images.length : 1,
                    itemBuilder: (context, index) {
                      if (widget.images.isEmpty) {
                        return const ShimmerPlaceholder(width: double.infinity, height: double.infinity);
                      }
                      final imageUrl = widget.images[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              opaque: false,
                              pageBuilder: (_, animation, __) => FadeTransition(
                                opacity: animation,
                                child: FullScreenImageView(
                                  tag: widget.heroTag,
                                  images: widget.images,
                                  initialPage: _current,
                                ),
                              ),
                            ),
                          );
                        },
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => ShimmerPlaceholder(
                            width: widget.mainWidth,
                            height: widget.mainHeight,
                          ),
                          errorWidget: (context, url, error) => Stack(
                            fit: StackFit.expand,
                            children: [
                              ShimmerPlaceholder(
                                width: widget.mainWidth,
                                height: widget.mainHeight,
                              ),
                              Center(
                                child: Material(
                                  color: Colors.transparent,
                                  child: Text(
                                    'no image found'.tr,
                                    style: TextStyle(color: AppColors.redBeige),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Strzałka w lewo
              if (hasMany && _current > 0)
                Positioned(
                  left: 8,
                  child: _ArrowButton(
                    onTap: () => _go(-1),
                    icon: Icons.chevron_left,
                  ),
                ),

              // Strzałka w prawo
              if (hasMany && _current < widget.images.length - 1)
                Positioned(
                  right: 8,
                  child: _ArrowButton(
                    onTap: () => _go(1),
                    icon: Icons.chevron_right,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 7.5),

        // Miniaturki
        SizedBox(
          width: widget.mainWidth,
          height: 120,
          child: widget.images.isNotEmpty
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.images.length,
                  itemBuilder: (context, index) {
                    final url = widget.images[index];
                    final isActive = index == _current;
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? 0 : 5.0,
                          right: index == widget.images.length - 1 ? 0 : 5.0,
                        ),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                width: isActive ? 2 : 1,
                                color: isActive ? theme.themeColor : theme.textColor.withAlpha(80),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                placeholder: (context, __) => const ShimmerPlaceholder(width: 120, height: 120),
                                errorWidget: (context, __, ___) => const Stack(
                                  children: [
                                    ShimmerPlaceholder(width: 120, height: 120),
                                    Center(child: Icon(Icons.error)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, __) => const ShimmerPlaceholder(width: 120, height: 120),
                ),
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;

  const _ArrowButton({
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha(64),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
