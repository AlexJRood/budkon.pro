import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_pc/footer_widget.dart';
import 'package:profile/emma/anchors/anchors_profile.dart';
import 'package:profile/screens/user_profile_default_screen.dart';
import 'package:profile/widgets/active_projects_widget.dart';
import 'package:profile/widgets/all_widget.dart';
import 'package:profile/widgets/company_card_widget.dart';
import 'package:profile/widgets/professional_license_sheet.dart';
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

class UserProfileDefaultPc extends ConsumerStatefulWidget {
  final ThemeColors theme;
  final List<String> tabs;
  final int grid;
  final UserModel? profileData;
  final bool isCurrentUser;

  const UserProfileDefaultPc({
    super.key,
    required this.theme,
    required this.tabs,
    required this.grid,
    this.profileData,
    this.isCurrentUser = true,
  });

  @override
  ConsumerState<UserProfileDefaultPc> createState() =>
      _UserProfileDefaultPcState();
}

class _UserProfileDefaultPcState extends ConsumerState<UserProfileDefaultPc> {
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

    final leftPad = 40.w;
    final rightPad = 40.w;
    final leftColumnWidth = 320.w;
    final gapBetweenColumns = 60.w;
    final bannerH = 200.h;
    final avatarSize = 140.w;
    final avatarOverlap = 40.h;

    return EmmaUiAnchorTarget(
      anchorKey: 'profile.desktop.root',
      // @emma-backend: ProfileEmmaAnchors.desktopRoot,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _header(
              profile,
              leftPad: leftPad,
              rightPad: rightPad,
              bannerH: bannerH,
              avatarSize: avatarSize,
              avatarOverlap: avatarOverlap,
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(left: leftPad, right: rightPad, top: 10),
            sliver: SliverCrossAxisGroup(
              slivers: [
                SliverConstrainedCrossAxis(
                  maxExtent: leftColumnWidth + gapBetweenColumns,
                  sliver: SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: gapBetweenColumns,
                        top: avatarOverlap,
                      ),
                      child: EmmaUiAnchorTarget(
                        anchorKey: 'profile.desktop.left_panel',
                        // @emma-backend: ProfileEmmaAnchors.desktopLeftPanel,
                        child: _leftPanel(profile),
                      ),
                    ),
                  ),
                ),
                SliverCrossAxisExpanded(
                  flex: 1,
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: ProjectTabsScreen(
                          theme: widget.theme,
                          tabs: widget.tabs,
                          anchorPlatform: 'desktop',
                          tabIds: const ['user_advertisements', 'wall_posts'],
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.only(top: 10, bottom: 150),
                        sliver: SliverMainAxisGroup(
                          slivers: [
                            ..._buildTabSlivers(
                              selectedTab,
                              widget.grid,
                              profile,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              children: [
                FooterWidget(
                  paddingDynamic: leftPad,
                  isProfile: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(
    UserModel profile, {
    required double leftPad,
    required double rightPad,
    required double bannerH,
    required double avatarSize,
    required double avatarOverlap,
  }) {
    return EmmaUiAnchorTarget(
      anchorKey: 'profile.desktop.header',
      // @emma-backend: ProfileEmmaAnchors.desktopHeader,
      child: SizedBox(
        height: bannerH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: bannerH,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF4F4F4F),
                image: _tempBackgroundPath != null
                    ? DecorationImage(
                        image: kIsWeb
                            ? NetworkImage(_tempBackgroundPath!)
                            : FileImage(File(_tempBackgroundPath!))
                                as ImageProvider,
                        fit: BoxFit.cover,
                      )
                    : (profile.backroundImage?.isNotEmpty == true
                        ? DecorationImage(
                            image: NetworkImage(profile.backroundImage!),
                            fit: BoxFit.cover,
                          )
                        : null),
              ),
              child: Stack(
                children: [
                  if (widget.isCurrentUser)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: EmmaUiAnchorTarget(
                        anchorKey:
                            'profile.desktop.header.background_upload_button',
                        // @emma-backend: ProfileEmmaAnchors.desktopBackgroundUploadButton,
                        child: InkWell(
                          onTap: _isUploadingBg ? null : _uploadBackground,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: _isUploadingBg
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: AppIcons.iosArrowLeft(color: Colors.white),
                onPressed: () {
                  ref.read(navigationService).beamPop();
                },
              ),
            ),
            Positioned(
              top: bannerH - avatarSize + avatarOverlap,
              left: leftPad,
              child: EmmaUiAnchorTarget(
                anchorKey: 'profile.desktop.header.avatar',
                // @emma-backend: ProfileEmmaAnchors.desktopAvatar,
                child: Container(
                  height: avatarSize,
                  width: avatarSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedNetworkImage(
                    imageUrl: profile.avatarUrl ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        Container(color: Colors.grey),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              right: leftPad,
              child: EmmaUiAnchorTarget(
                anchorKey: 'profile.desktop.header.association_card',
                // @emma-backend: ProfileEmmaAnchors.desktopAssociationCard,
                child: SizedBox(
                  width: 300,
                  child: AssociationCardWidget(
                    userModel: profile,
                    isCurrentUser: widget.isCurrentUser,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leftPanel(UserModel profile) {
    final formattedDate = profile.dateCreated != null
        ? DateFormat.yMMMMd().format(profile.dateCreated!)
        : 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EmmaUiAnchorTarget(
          anchorKey: 'profile.desktop.basic_info',
          // @emma-backend: ProfileEmmaAnchors.desktopBasicInfo,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${profile.firstName} ${profile.lastName}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: widget.theme.textColor,
                      fontSize: 24.sp,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                profile.email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: widget.theme.textColor.withAlpha(153),
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                '${"MEMBER SINCE".tr}: $formattedDate',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: widget.theme.textColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        EmmaUiAnchorTarget(
          anchorKey: 'profile.desktop.company_card',
          // @emma-backend: ProfileEmmaAnchors.desktopCompanyCard,
          child: CompanyCardWidget(
            userModel: profile,
            isCurrentUser: widget.isCurrentUser,
          ),
        ),

        if (profile.professionalCredentials.isNotEmpty) ...[
          const SizedBox(height: 16),
          ProfessionalLicenseButton(
            credentials: profile.professionalCredentials,
            theme: widget.theme,
          ),
        ],
        const SizedBox(height: 16),
        if (widget.isCurrentUser)
          EmmaUiAnchorTarget(
            anchorKey: 'profile.desktop.edit_profile_button',
            // @emma-backend: ProfileEmmaAnchors.desktopEditProfileButton,
            child: InkWell(
              onTap: () =>
                  ref.read(navigationService).pushNamedScreen(Routes.settings),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: widget.theme.textColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppIcons.pencil(
                      color: widget.theme.textColor,
                      height: 18,
                      width: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Edit Profile'.tr,
                      style: TextStyle(color: widget.theme.textColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildTabSlivers(int index, int grid, UserModel profile) {
    switch (index) {
      case 0:
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