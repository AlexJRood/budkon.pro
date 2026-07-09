import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:portal/screens/landing_page/widgets/landing_page_pc/footer_widget.dart';
import 'package:profile/screens/user_profile_default_screen.dart';
import 'package:profile/widgets/active_projects_widget.dart';
import 'package:profile/widgets/all_widget.dart';
import 'package:profile/widgets/company_card_widget.dart';
import 'package:profile/widgets/expired_projects_widget.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';
import 'package:core/user/user/user_model.dart';
import 'package:core/user/user/user_provider.dart';
import 'package:wall/wall_screen/screens/widgets/wall_posts_widget.dart';

const kProfileEditUrl = 'https://www.superbee.cloud/user/edit-account/';

class UserProfileDefaultTablet extends ConsumerStatefulWidget {
  final ThemeColors theme;
  final List<String> tabs;
  final int grid;
  final UserModel? profileData;
  final bool isCurrentUser;

  const UserProfileDefaultTablet({
    super.key,
    required this.theme,
    required this.tabs,
    required this.grid,
    this.profileData,
    this.isCurrentUser = true,
  });

  @override
  ConsumerState<UserProfileDefaultTablet> createState() =>
      _UserProfileDefaultTabletState();
}

class _UserProfileDefaultTabletState extends ConsumerState<UserProfileDefaultTablet> {
  bool _isUploadingBg = false;
  String? _tempBackgroundPath;

  Future<void> _uploadBackground() async {
    try {
      setState(() => _isUploadingBg = true);

      final res = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (res == null || res.files.isEmpty) return;

      final file = res.files.single;
      if (file.bytes == null) return;

      setState(() => _tempBackgroundPath = file.path);

      final formData = FormData.fromMap({
        'background_image':
            MultipartFile.fromBytes(file.bytes!, filename: file.name),
      });

      final response = await ApiServices.patch(
        kProfileEditUrl,
        formData: formData,
        hasToken: true,
        ref: ref,
      );

      if (response != null && (response.statusCode ?? 500) < 300) {
        ref.invalidate(userProvider);
        ref.invalidate(userStateProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Background updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error uploading background'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingBg = false;
          _tempBackgroundPath = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profileData ?? ref.watch(userStateProvider);
    final selectedTab = ref.watch(selectedTabIndexProvider);
    if (profile == null) {
      return Center(child: AppLottie.loading(size: 300));
    }

    // Tablet specific geometries (Fixed sizes as requested)
    const double horizontalPad = 32.0;
    const double bannerH = 220.0;
    const double avatarSize = 130.0;
    const double avatarOverlap = 30.0;

    return EmmaUiAnchorTarget(
      // @emma-backend: ProfileEmmaAnchors.tabletRoot
      anchorKey: 'profile.tablet.root',
      child: CustomScrollView(
        slivers: [
          // 1) HEADER (Banner + Avatar)
          SliverToBoxAdapter(
            child: _TabletHeader(
              profile: profile,
              isCurrentUser: widget.isCurrentUser,
              isUploadingBg: _isUploadingBg,
              tempBackgroundPath: _tempBackgroundPath,
              onUploadBackground: _uploadBackground,
              bannerH: bannerH,
              avatarSize: avatarSize,
              avatarOverlap: avatarOverlap,
              horizontalPad: horizontalPad,
            ),
          ),

          // 2) BASIC INFO & ASSOCIATION (pinned below banner)
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 16.0),
            sliver: SliverToBoxAdapter(
              child: SizedBox(height: 0), // Spacer managed internally
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPad),
            sliver: SliverToBoxAdapter(
              child: _TabletProfileInfo(
                profile: profile,
                theme: widget.theme,
                avatarOverlap: avatarOverlap,
                isCurrentUser: widget.isCurrentUser,
                onEditProfile: () => ref.read(navigationService).pushNamedScreen(Routes.settings),
              ),
            ),
          ),

          // 3) TABS
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPad),
            sliver: SliverToBoxAdapter(
              child: _TabletTabsScreen(
                theme: widget.theme,
                tabs: widget.tabs,
                selectedIndex: ref.watch(selectedTabIndexProvider),
                onTabChanged: (index) {
                  ref.read(selectedTabIndexProvider.notifier).state = index;
                },
              ),
            ),
          ),

          // 4) CONTENT (Grid = 1 as requested)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 10.0),
            sliver: SliverMainAxisGroup(
              key: ValueKey('tab-content-$selectedTab'),
              slivers: _buildTabSlivers(selectedTab, widget.grid, profile),
            ),
          ),

          // 5) FOOTER
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              children: [
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: horizontalPad),
                  child: FooterWidget(
                    paddingDynamic: MediaQuery.of(context).size.width / 10,
                    isProfile: true,
                  ),
                ),
                const SizedBox(height: 40.0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTabSlivers(int index, int grid, UserModel profile) {
    switch (index) {
      case 0:
        return [AllWidgetSliver(grid: grid, profile: profile)];
      case 1:
        return [ActiveProjectsWidgetSliver(grid: grid, profile: profile)];
      case 2:
        return [WallPostsWidgetSliver(grid: grid, profile: profile)];
      case 3:
        return [ExpiredProjectsWidgetSliver(grid: grid)];
      default:
        return [AllWidgetSliver(grid: grid, profile: profile)];
    }
  }
}

class _TabletHeader extends StatelessWidget {
  final UserModel profile;
  final bool isCurrentUser;
  final bool isUploadingBg;
  final String? tempBackgroundPath;
  final VoidCallback onUploadBackground;
  final double bannerH;
  final double avatarSize;
  final double avatarOverlap;
  final double horizontalPad;

  const _TabletHeader({
    required this.profile,
    required this.isCurrentUser,
    required this.isUploadingBg,
    this.tempBackgroundPath,
    required this.onUploadBackground,
    required this.bannerH,
    required this.avatarSize,
    required this.avatarOverlap,
    required this.horizontalPad,
  });

  @override
  Widget build(BuildContext context) {
    return EmmaUiAnchorTarget(
      // @emma-backend: ProfileEmmaAnchors.tabletHeader
      anchorKey: 'profile.tablet.header',
      child: SizedBox(
        height: bannerH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Banner
            Container(
              height: bannerH,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF4F4F4F),
                image: tempBackgroundPath != null
                    ? DecorationImage(
                        image: kIsWeb
                            ? NetworkImage(tempBackgroundPath!)
                            : FileImage(File(tempBackgroundPath!)) as ImageProvider,
                        fit: BoxFit.cover,
                      )
                    : (profile.backroundImage?.isNotEmpty == true
                        ? DecorationImage(
                            image: NetworkImage(profile.backroundImage!),
                            fit: BoxFit.cover,
                          )
                        : null),
              ),
              child: isCurrentUser
                  ? Stack(
                      children: [
                        Positioned(
                          top: 20.0,
                          right: 20.0,
                          child: InkWell(
                            onTap: isUploadingBg ? null : onUploadBackground,
                            child: Container(
                              padding: const EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(128),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: isUploadingBg
                                  ? const SizedBox(
                                      width: 18.0,
                                      height: 18.0,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.camera_alt, color: Colors.white, size: 20.0),
                            ),
                          ),
                        ),
                      ],
                    )
                  : null,
            ),

            // Avatar
            Positioned(
              top: bannerH - avatarSize + avatarOverlap,
              left: horizontalPad,
              child: EmmaUiAnchorTarget(
                // @emma-backend: ProfileEmmaAnchors.tabletAvatar
                anchorKey: 'profile.tablet.header.avatar',
                child: Container(
                  height: avatarSize,
                  width: avatarSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedNetworkImage(
                    imageUrl: profile.avatarUrl ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(color: Colors.grey),
                  ),
                ),
              ),
            ),
            
            Positioned(
              bottom: -20.0,
              right: horizontalPad,
              child: EmmaUiAnchorTarget(
                // @emma-backend: ProfileEmmaAnchors.tabletAssociationCard
                anchorKey: 'profile.tablet.header.association_card',
                child: SizedBox(
                  width: 280.0,
                  child: AssociationCardWidget(userModel: profile, isCurrentUser: isCurrentUser),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabletProfileInfo extends StatelessWidget {
  final UserModel profile;
  final ThemeColors theme;
  final double avatarOverlap;
  final bool isCurrentUser;
  final VoidCallback onEditProfile;

  const _TabletProfileInfo({
    required this.profile,
    required this.theme,
    required this.avatarOverlap,
    required this.isCurrentUser,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = profile.dateCreated != null
        ? DateFormat.yMMMMd().format(profile.dateCreated!)
        : 'N/A';

    return Padding(
      padding: EdgeInsets.only(top: avatarOverlap + 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EmmaUiAnchorTarget(
                  // @emma-backend: ProfileEmmaAnchors.tabletBasicInfo
                  anchorKey: 'profile.tablet.basic_info',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${profile.firstName} ${profile.lastName}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: theme.textColor,
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        profile.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: theme.textColor.withAlpha(153),
                          fontSize: 15.0,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        'MEMBER SINCE: $formattedDate',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: theme.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),
                EmmaUiAnchorTarget(
                  // @emma-backend: ProfileEmmaAnchors.tabletCompanyCard
                  anchorKey: 'profile.tablet.company_card',
                  child: CompanyCardWidget(userModel: profile, isCurrentUser: isCurrentUser),
                ),
              ],
            ),
          ),
          
          if (isCurrentUser)
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: EmmaUiAnchorTarget(
                // @emma-backend: ProfileEmmaAnchors.tabletEditProfileButton
                anchorKey: 'profile.tablet.edit_profile_button',
                child: InkWell(
                  onTap: onEditProfile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.textColor),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcons.pencil(
                          color: theme.textColor,
                          height: 20.0,
                          width: 20.0,
                        ),
                        const SizedBox(width: 10.0),
                        Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabletTabsScreen extends ConsumerWidget {
  final ThemeColors theme;
  final List<String> tabs;
  final int? selectedIndex;
  final ValueChanged<int>? onTabChanged;

  const _TabletTabsScreen({
    required this.theme,
    required this.tabs,
    this.selectedIndex,
    this.onTabChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = selectedIndex ?? ref.watch(selectedTabIndexProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(tabs.length, (index) {
            final isSelected = currentIndex == index;

            return InkWell(
              onTap: () {
                if (onTabChanged != null) {
                  onTabChanged!(index);
                  return;
                }
                ref.read(selectedTabIndexProvider.notifier).state = index;
              },
              borderRadius: BorderRadius.circular(6.0),
              splashColor: theme.textColor.withAlpha(26),
              hoverColor: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 24.0),
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                decoration: BoxDecoration(
                  border: isSelected
                      ? const Border(
                          bottom: BorderSide(
                            color: Colors.cyanAccent,
                            width: 2.0,
                          ),
                        )
                      : null,
                ),
                child: Text(
                  tabs[index],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isSelected ? theme.textColor : theme.textColor.withAlpha(128),
                    fontWeight: FontWeight.bold,
                    fontSize: 15.0,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
