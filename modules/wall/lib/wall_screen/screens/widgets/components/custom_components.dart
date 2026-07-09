import 'package:core/ui/cache_manager.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/common/global_user_card.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:shimmer/shimmer.dart';
import 'package:core/user/user/user_provider.dart';
import 'package:wall/emma/anchors/anchors_wall.dart';
import 'package:wall/wall_screen/providers/post_create_provider.dart';
import 'package:wall/wall_screen/screens/widgets/create_post_dialog/post_create_dialog.dart';

import '../../../model/community_post_model.dart';

class AvatarImageWidget extends ConsumerWidget {
  final String imageUrl;
  final double avatarSize;
  final BoxFit? fit;
  final Color? placeholderColor;
  final Color? errorIconColor;
  final double? strokeWidth;
  final double borderRadius;

  const AvatarImageWidget({
    super.key,
    required this.imageUrl,
    required this.avatarSize,
    this.fit = BoxFit.cover,
    this.placeholderColor,
    this.errorIconColor = Colors.red,
    this.strokeWidth = 2,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int cacheSize = (avatarSize * 2).toInt();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        cacheManager: UserCacheManager.instance,
        imageUrl: imageUrl,
        width: avatarSize * 2,
        height: avatarSize * 2,
        fit: fit!,
        filterQuality: FilterQuality.low, // ↓ lighter sampling
        memCacheWidth: cacheSize,
        memCacheHeight: cacheSize,
        maxWidthDiskCache: cacheSize,
        maxHeightDiskCache: cacheSize,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: ShimmerColors.base(context),
          highlightColor: ShimmerColors.highlight(context),
          child: Container(
            width: avatarSize * 2,
            height: avatarSize * 2,
            color: CustomColors.secondaryWidgetColor(context, ref),
          ),
        ),
        errorWidget: (context, url, error) {
          return Container(
            width: avatarSize * 2,
            height: avatarSize * 2,
            color: placeholderColor ?? Colors.grey[300],
            child: Icon(Icons.error, color: errorIconColor),
          );
        },
      ),
    );
  }
}

class PostComposer extends ConsumerWidget {
  final void Function(CommunityPost post)? onPostCreated;

  const PostComposer({super.key, this.onPostCreated});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final double postWidth = screenWidth > 700 ? 700 : screenWidth * 0.7;

        final double dynamicPadding =
        screenWidth >= 1980 ? screenWidth / 6 : screenWidth / 8;

        return Material(
          color: Colors.transparent,
          child: EmmaUiAnchorTarget(
            anchorKey: WallEmmaAnchors.postComposer.anchorKey,

            spec: WallEmmaAnchors.postComposer,
            runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
            tapMode: EmmaUiAnchorTapMode.disabled,
            child: Hero(
              tag: "post",
              child: Padding(
                padding: EdgeInsets.only(left: dynamicPadding, right: dynamicPadding, bottom: 20),
                child: RepaintBoundary(
                  child: Container(
                    width: postWidth,
                    margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CustomColors.secondaryWidgetColor(context, ref),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GlobalUserCard(
                                userAsyncValue: ref.watch(userProvider),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  cursorColor:
                                  CustomColors.secondaryWidgetTextColor(
                                    context,
                                    ref,
                                  ),
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    fillColor:
                                    CustomColors.secondaryTextfieldFillColor(
                                      context,
                                      ref,
                                    ),
                                    filled: true,
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 12,
                                    ),
                                    hintText: "whats on your mind".tr,
                                    focusColor: Colors.transparent,
                                    focusedBorder: const OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(
                                      color:
                                      CustomColors.secondaryWidgetTextColor(
                                        context,
                                        ref,
                                      ).withAlpha(128),
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: CustomColors.secondaryWidgetTextColor(
                                      context,
                                      ref,
                                    ),
                                  ),
                                  maxLines: null,
                                  textInputAction: TextInputAction.newline,
                                  onTap: () {
                                    ref
                                        .read(postCreateStateProvider.notifier)
                                        .clearController();
                                    ref
                                        .read(postCreateStateProvider.notifier)
                                        .clearForm();
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        opaque: false,
                                        barrierColor: Colors.black54,
                                        transitionDuration:
                                        const Duration(milliseconds: 350),
                                        reverseTransitionDuration:
                                        const Duration(milliseconds: 250),
                                        pageBuilder: (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            ) {
                                          return const PostCreateDialog();
                                        },
                                        transitionsBuilder: (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            child,
                                            ) {
                                          final curvedAnimation =
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeInOutCubic,
                                          );
            
                                          final scaleTween = Tween<double>(
                                            begin: 0.92,
                                            end: 1.0,
                                          );
                                          final fadeTween = Tween<double>(
                                            begin: 0.0,
                                            end: 1.0,
                                          );
            
                                          return FadeTransition(
                                            opacity: fadeTween
                                                .animate(curvedAnimation),
                                            child: ScaleTransition(
                                              scale: scaleTween
                                                  .animate(curvedAnimation),
                                              child: child,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              EmmaUiAnchorTarget(
                                anchorKey: WallEmmaAnchors.postComposerVideoButton.anchorKey,

                                spec: WallEmmaAnchors.postComposerVideoButton,
                                runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                                tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                                child: _ActionItem(
                                  icon: HugeIcons.strokeRoundedVideo01,
                                  label: "Video".tr,
                                  color: CustomColors.secondaryWidgetTextColor(
                                    context,
                                    ref,
                                  ),
                                  onTap: () {
                                    ref
                                        .read(postCreateStateProvider.notifier)
                                        .clearController();
                                    ref
                                        .read(postCreateStateProvider.notifier)
                                        .clearForm();
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        opaque: false,
                                        barrierDismissible: true,
                                        transitionDuration:
                                        const Duration(milliseconds: 350),
                                        reverseTransitionDuration:
                                        const Duration(milliseconds: 250),
                                        pageBuilder: (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            ) {
                                          return const PostCreateDialog(
                                            initialAction: 'video',
                                          );
                                        },
                                        transitionsBuilder: (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            child,
                                            ) {
                                          final curvedAnimation =
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeInOutCubic,
                                          );
                                            
                                          final scaleTween = Tween<double>(
                                            begin: 0.92,
                                            end: 1.0,
                                          );
                                          final fadeTween = Tween<double>(
                                            begin: 0.0,
                                            end: 1.0,
                                          );
                                            
                                          return FadeTransition(
                                            opacity: fadeTween
                                                .animate(curvedAnimation),
                                            child: ScaleTransition(
                                              scale: scaleTween
                                                  .animate(curvedAnimation),
                                              child: child,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                              EmmaUiAnchorTarget(
                                anchorKey: WallEmmaAnchors.postComposerFeelingButton.anchorKey,

                                spec: WallEmmaAnchors.postComposerFeelingButton,
                                runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                                tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                                child: _ActionItem(
                                  icon: HugeIcons.strokeRoundedHappy,
                                  label: "Feeling".tr,
                                  color: CustomColors.secondaryWidgetTextColor(
                                    context,
                                    ref,
                                  ),
                                  onTap: () {
                                    ref
                                        .read(postCreateStateProvider.notifier)
                                        .clearController();
                                    ref
                                        .read(postCreateStateProvider.notifier)
                                        .clearForm();
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        opaque: false,
                                        barrierDismissible: true,
                                        transitionDuration:
                                        const Duration(milliseconds: 350),
                                        reverseTransitionDuration:
                                        const Duration(milliseconds: 250),
                                        pageBuilder: (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            ) {
                                          return const PostCreateDialog(
                                            initialAction: 'emoji',
                                          );
                                        },
                                        transitionsBuilder: (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            child,
                                            ) {
                                          final curvedAnimation =
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeInOutCubic,
                                          );
                                            
                                          final scaleTween = Tween<double>(
                                            begin: 0.92,
                                            end: 1.0,
                                          );
                                          final fadeTween = Tween<double>(
                                            begin: 0.0,
                                            end: 1.0,
                                          );
                                            
                                          return FadeTransition(
                                            opacity: fadeTween
                                                .animate(curvedAnimation),
                                            child: ScaleTransition(
                                              scale: scaleTween
                                                  .animate(curvedAnimation),
                                              child: child,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                              EmmaUiAnchorTarget(
                                 anchorKey: WallEmmaAnchors.postComposerImageButton.anchorKey,

                                 spec: WallEmmaAnchors.postComposerImageButton,
                                 runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                                 tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                                child: _ActionItem(
                                  icon: HugeIcons.strokeRoundedImage01,
                                  label: "Image".tr,
                                  color: CustomColors.secondaryWidgetTextColor(
                                    context,
                                    ref,
                                  ),
                                  onTap: () {
                                    ref
                                        .read(postCreateStateProvider.notifier)
                                        .clearController();
                                    ref
                                        .read(postCreateStateProvider.notifier)
                                        .clearForm();
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        opaque: false,
                                        barrierDismissible: true,
                                        transitionDuration:
                                        const Duration(milliseconds: 350),
                                        reverseTransitionDuration:
                                        const Duration(milliseconds: 250),
                                        pageBuilder: (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            ) {
                                          return const PostCreateDialog(
                                            initialAction: 'image',
                                          );
                                        },
                                        transitionsBuilder: (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            child,
                                            ) {
                                          final curvedAnimation =
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeInOutCubic,
                                          );
                                            
                                          final scaleTween = Tween<double>(
                                            begin: 0.92,
                                            end: 1.0,
                                          );
                                          final fadeTween = Tween<double>(
                                            begin: 0.0,
                                            end: 1.0,
                                          );
                                            
                                          return FadeTransition(
                                            opacity: fadeTween
                                                .animate(curvedAnimation),
                                            child: ScaleTransition(
                                              scale: scaleTween
                                                  .animate(curvedAnimation),
                                              child: child,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

// PostComposerMobile & ProfessionalImagePlaceholder & MobileWallAppbar
// stay exactly as in your latest version – no structural changes.


class PostComposerMobile extends ConsumerWidget {
  final void Function(CommunityPost post)? onPostCreated;

  const PostComposerMobile({super.key, this.onPostCreated});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GlobalUserCard(userAsyncValue: ref.watch(userProvider)),
            const SizedBox(width: 20),
            Expanded(
              child: EmmaUiAnchorTarget(
                anchorKey: WallEmmaAnchors.postComposerTextField.anchorKey,

                spec: WallEmmaAnchors.postComposerTextField,
                runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                child: TextField(
                  cursorColor: CustomColors.secondaryWidgetTextColor(
                    context,
                    ref,
                  ),
                  readOnly: true,
                  decoration: InputDecoration(
                    fillColor: CustomColors.secondaryWidgetColor(
                      context,
                      ref,
                    ).withValues(alpha: 0.8),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    hintText: "What's on your mind? john".tr,
                    focusColor: Colors.transparent,
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: CustomColors.secondaryWidgetTextColor(
                        context,
                        ref,
                      ).withAlpha(204),
                    ),
                  ),
                  style: TextStyle(
                    color: CustomColors.secondaryWidgetTextColor(context, ref),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  onTap: () {
                    ref
                        .read(postCreateStateProvider.notifier)
                        .clearController();
                    ref.read(postCreateStateProvider.notifier).clearForm();
                    ref
                        .read(navigationService)
                        .pushNamedScreen(Routes.createPostWall);
                  },
                ),
              ),
            ),
            const SizedBox(width: 20),
            HugeIcon(
              size: 35,
              icon: HugeIcons.strokeRoundedImage03,
              color: CustomColors.secondaryWidgetTextColor(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfessionalImagePlaceholder extends ConsumerWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final String? text;
  final Color? backgroundColor;
  final Color? iconColor;
  final double iconSize;
  final bool useResponsiveDimensions;

  const ProfessionalImagePlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.text,
    this.backgroundColor,
    this.iconColor,
    this.iconSize = 32,
    this.useResponsiveDimensions = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultBgColor = CustomColors.secondaryWidgetTextColor(
      context,
      ref,
    ).withValues(alpha: 0.09);
    final defaultIconColor = CustomColors.secondaryWidgetTextColor(
      context,
      ref,
    ).withValues(alpha: 0.5);

    return LayoutBuilder(
      builder: (context, constraints) {
        double finalWidth = width ?? constraints.maxWidth;
        double finalHeight = height ?? 200;

        if (useResponsiveDimensions) {
          final double screenWidth = constraints.maxWidth;
          final double postWidth =
          screenWidth > 700 ? 700 : screenWidth * 0.7;
          final double aspectRatio = screenWidth > 1980 ? 1.4 : 1.7;
          final double imageHeight = postWidth / aspectRatio;

          finalWidth = postWidth;
          finalHeight = imageHeight;
        }

        return Container(
          width: finalWidth,
          height: finalHeight,
          decoration: BoxDecoration(
            color: backgroundColor ?? defaultBgColor,
            borderRadius: borderRadius ?? BorderRadius.circular(8),
            border: Border.all(
              color: CustomColors.secondaryWidgetColor(context, ref),
              width: 1,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (iconColor ?? defaultIconColor)!.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.image_outlined,
                    color: iconColor ?? defaultIconColor,
                    size: iconSize,
                  ),
                ),
                if (text != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    text!,
                    style: TextStyle(
                      color: iconColor ?? defaultIconColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class MobileWallAppbar extends ConsumerWidget {
  final String title;
  final void Function()? onPressed;
  final IconData? rightIcon;
  final void Function()? onRightPressed;
  final bool isRightLoading;

  const MobileWallAppbar({
    super.key,
    required this.title,
    this.onPressed,
    this.rightIcon,
    this.onRightPressed,
    this.isRightLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SizedBox(
          height: foundation.kIsWeb
              ? 10
              : (DeviceTypeUtil.isCenterButtonIPhone(context) ? 20 : 50),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
              ),
              onPressed:
              onPressed ?? () => ref.read(navigationService).beamPop(),
            ),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CustomColors.secondaryWidgetColor(context, ref),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (isRightLoading)
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (rightIcon != null)
              IconButton(
                icon: Icon(
                  rightIcon,
                  color: CustomColors.secondaryWidgetColor(context, ref),
                ),
                onPressed: onRightPressed,
              )
            else
              Opacity(
                opacity: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: null,
                ),
              ),
          ],
        ),
        Divider(
          color: CustomColors.secondaryWidgetColor(
            context,
            ref,
          ).withAlpha((255 * 0.2).toInt()),
        ),
      ],
    );
  }
}
