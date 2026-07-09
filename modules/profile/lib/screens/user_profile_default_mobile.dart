import 'dart:io';

import 'package:core/ui/device_type_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_mobile/footer_mobile_widget.dart';
import 'package:profile/emma/anchors/anchors_profile.dart';
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
import 'package:get/get_utils/get_utils.dart';

const kProfileEditUrl = 'https://www.superbee.cloud/user/edit-account/';

class UserProfileDefaultMobile extends ConsumerStatefulWidget {
  final ThemeColors theme;
  final List<String> tabs;
  final int grid;
  final UserModel? profileData;
  final bool isCurrentUser;

  const UserProfileDefaultMobile({
    super.key,
    required this.theme,
    required this.tabs,
    required this.grid,
    this.profileData,
    this.isCurrentUser = true,
  });

  @override
  ConsumerState<UserProfileDefaultMobile> createState() =>
      _UserProfileDefaultMobileState();
}

class _UserProfileDefaultMobileState
    extends ConsumerState<UserProfileDefaultMobile> {
  bool _isUploadingBg = false;
  String? _tempBackgroundPath;
  final _scrollController = ScrollController();

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
        'background_image': MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
        ),
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
             SnackBar(
              content: Text('background_updated'.tr),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
              content: Text('error_uploading_background'.tr),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${"an_error_occurred".tr} $e'),
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profileData ?? ref.watch(userStateProvider);

    if (profile == null) {
      return Center(child: AppLottie.loading(size: 300));
    }
    final selectedTab = ref.watch(selectedTabIndexProvider);
    final topInset = TopAppBarSize.resolve(context);

    return EmmaUiAnchorTarget(
      anchorKey: 'profile.mobile.root',
      // @emma-backend: ProfileEmmaAnchors.mobileRoot,
      child: CustomScrollView(
        controller: _scrollController,
        primary: false,
        key: const PageStorageKey('UserProfileDefaultMobileScroll'),
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: topInset)),
          _sliverHeader(profile),
          _sliverBasicInfo(profile),
          _sliverCompanyCard(profile),
          _sliverEditButton(),
          _sliverTabs(),
          SliverMainAxisGroup(
          key: ValueKey('tab-content-$selectedTab'),
          slivers: _buildTabSlivers(selectedTab, widget.grid, profile),
        ),
          _sliverFooter(),
        ],
      ),
    );
  }

  SliverToBoxAdapter _sliverHeader(UserModel profile) {
    return SliverToBoxAdapter(
      child: EmmaUiAnchorTarget(
        anchorKey: 'profile.mobile.header',
        // @emma-backend: ProfileEmmaAnchors.mobileRoot,Header,
        child: SizedBox(
          height: 315.h,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                height: 150.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F4F4F),
                  image:
                      _tempBackgroundPath != null
                          ? DecorationImage(
                            image:
                                kIsWeb
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
                    if (widget.isCurrentUser &&
                        profile.backroundImage?.isEmpty != false &&
                        _tempBackgroundPath == null)
                      Center(
                        child: EmmaUiAnchorTarget(
                          anchorKey:
                              'profile.mobile.header.background_upload_button',
                          // @emma-backend: ProfileEmmaAnchors.mobileBackgroundUploadButton,
                          child: InkWell(
                            onTap: _isUploadingBg ? null : _uploadBackground,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 10.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(230),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: widget.theme.textColor.withAlpha(76),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isUploadingBg)
                                    SizedBox(
                                      width: 14.w,
                                      height: 14.w,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: widget.theme.textColor,
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.add_photo_alternate,
                                      color: widget.theme.textColor,
                                      size: 18.w,
                                    ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    _isUploadingBg
                                        ? 'uploading...'.tr
                                        : 'Add Background Image'.tr,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color: widget.theme.textColor,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (widget.isCurrentUser &&
                        (profile.backroundImage?.isNotEmpty == true ||
                            _tempBackgroundPath != null))
                      Positioned(
                        top: 10.h,
                        right: 10.w,
                        child: EmmaUiAnchorTarget(
                          anchorKey:
                              'profile.mobile.header.background_upload_button',
                          // @emma-backend: ProfileEmmaAnchors.mobileBackgroundUploadButton,
                          child: InkWell(
                            onTap: _isUploadingBg ? null : _uploadBackground,
                            child: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(128),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child:
                                  _isUploadingBg
                                      ? SizedBox(
                                        width: 16.w,
                                        height: 16.w,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 16.w,
                                      ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                top: 125.h,
                child: EmmaUiAnchorTarget(
                  anchorKey: 'profile.mobile.header.avatar',
                  // @emma-backend: ProfileEmmaAnchors.mobileRoot,.mobileAvatar,
                  child: Container(
                    height: 140.w,
                    width: 140.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: CachedNetworkImage(
                        imageUrl: profile.avatarUrl ?? '',
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) =>
                                Container(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _sliverBasicInfo(UserModel profile) {
    return SliverToBoxAdapter(
      child: EmmaUiAnchorTarget(
        anchorKey: 'profile.mobile.basic_info',
        // @emma-backend: ProfileEmmaAnchors.mobileRoot,BasicInfo,
        child: Padding(
          padding: EdgeInsets.only(top: 8.h),
          child: Column(
            children: [
              Text(
                '${profile.firstName} ${profile.lastName}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: widget.theme.textColor,
                  fontSize: 22.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                profile.email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: widget.theme.textColor.withAlpha(140),
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _sliverCompanyCard(UserModel profile) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: EmmaUiAnchorTarget(
          anchorKey: 'profile.mobile.company_card',
          // @emma-backend: ProfileEmmaAnchors.mobileRoot,CompanyCard,
          child: CompanyCardWidget(
            userModel: profile,
            isCurrentUser: widget.isCurrentUser,
          ),
        ),
      ),
    );
  }

  Widget _sliverEditButton() {
    if (!widget.isCurrentUser) {
      return const SliverToBoxAdapter(child: SizedBox(height: 10));
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        child: EmmaUiAnchorTarget(
          anchorKey: 'profile.mobile.edit_profile_button',
          // @emma-backend: ProfileEmmaAnchors.mobileRoot,EditProfileButton,
          child: InkWell(
            onTap: () =>
                ref.read(navigationService).pushNamedScreen(Routes.settings),
            child: Container(
              height: 48.h,
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              decoration: BoxDecoration(
                border: Border.all(color: widget.theme.textColor),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcons.pencil(
                    color: widget.theme.textColor,
                    height: 20.w,
                    width: 20.w,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Edit Profile Info'.tr,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: widget.theme.textColor,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _sliverTabs() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: ProjectTabsScreen(
          theme: widget.theme,
          tabs: widget.tabs,
          selectedIndex: ref.watch(selectedTabIndexProvider),
          anchorPlatform: 'mobile',
          tabIds: const ['user_advertisements', 'wall_posts'],
          onTabChanged: (index) {
            ref.read(selectedTabIndexProvider.notifier).state = index;
          },
        ),
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

  SliverToBoxAdapter _sliverFooter() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          SizedBox(height: 18.h),
          FooterWidgetMobile(
            paddingDynamic: MediaQuery.of(context).size.width / 12,
            isMobile: true,
          ),
        ],
      ),
    );
  }
}