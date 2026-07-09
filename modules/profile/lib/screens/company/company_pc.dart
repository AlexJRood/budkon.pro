// company_pc.dart
//
// Comments in English as requested.

import 'dart:io';
import 'package:profile/profile_urls.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';
import 'package:core/user/user/user_provider.dart';
import 'package:profile/providers/company_ads_provider.dart';
import 'package:core/user/user/user_model.dart';
import 'package:core/theme/apptheme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:portal/screens/feed/components/cards/selected_card.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/lottie.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:pie_menu/pie_menu.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:core/platform/api_services.dart';

class CompanyPc extends ConsumerStatefulWidget {
  final ThemeColors theme;
  final CompanyModel? companyData;

  /// If true, this is the current user's own company view.
  /// If false, it's a public company view (e.g. other company profile).
  final bool isCurrentUserCompany;

  const CompanyPc({
    super.key,
    required this.theme,
    this.companyData,
    this.isCurrentUserCompany = true,
  });

  @override
  _CompanyPcState createState() => _CompanyPcState();
}

class _CompanyPcState extends ConsumerState<CompanyPc> {
  static const int _pageSize = 10;

  final PagingController<int, AdsListViewModel> _pagingController =
      PagingController(firstPageKey: 1);

  bool _isUploadingBg = false;
  String? _tempBackgroundPath;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      if (!mounted) return;


      int? companyId;


      if (widget.companyData != null) {
        companyId = widget.companyData!.id;
      } else {
        final profileState = ref.read(userStateProvider);
        companyId = widget.companyData?.id ??
            (profileState?.company.isNotEmpty == true
                ? profileState!.company.first.id
                : null);
      }

      if (companyId == null) {
        if (mounted) {
          _pagingController.error = Exception('Company information not available.');
        }
        return;
      }

      final advertisements = await ref
          .read(companyAdsProvider.notifier)
          .fetchCompanyAdvertisements(pageKey, _pageSize, companyId, ref);

      if (!mounted) return;

      final isLastPage = advertisements.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(advertisements);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(advertisements, nextPageKey);
      }
    } catch (error) {
      if (mounted) {
        _pagingController.error = error;
      }
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  /// Check if current user can manage company (admin or manager role).
  bool _canManageCompany(CompanyModel company) {
    final currentUser = ref.read(userStateProvider);
    if (currentUser == null) return false;

    final currentUserId = int.tryParse(currentUser.userId ?? '0') ?? 0;

    // Find current user's membership in the company
    final membership = company.memberships
        .where((m) => m.user.id == currentUserId)
        .firstOrNull;

    if (membership == null) return false;

    final role = membership.role.toLowerCase();
    return role == 'admin' || role == 'manager';
  }

  /// Check if current user is already a member of this company/association.
  bool _isCurrentUserMember(CompanyModel company) {
    final currentUser = ref.read(userStateProvider);
    if (currentUser == null) return false;

    final currentUserId = int.tryParse(currentUser.userId ?? '0') ?? 0;
    return company.memberships.any((m) => m.user.id == currentUserId);
  }

  void _goJoinToAssociation(int associationId) {
    // Requested path: /association/id/join-to-association
    ref
        .read(navigationService)
        .pushNamedScreen('/association/$associationId/join-to-association');
  }

  Future<void> _uploadCompanyBackground(WidgetRef ref, CompanyModel company) async {
    try {
      setState(() => _isUploadingBg = true);

      final res = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (res == null || res.files.isEmpty) return;

      final file = res.files.single;
      if (file.bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to read file.'), backgroundColor: Colors.red),
        );
        return;
      }

      // Set temporary path for preview
      setState(() {
        _tempBackgroundPath = file.path;
      });

      final formData = FormData.fromMap({
        'background': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      });

      final response = await ApiServices.post(
        ProfileUrls.companyBackground,
        formData: formData,
        hasToken: true,
        ref: ref,
      );

      if (response != null && (response.statusCode ?? 500) < 300) {
        ref.invalidate(userProvider);
        setState(() {
          _tempBackgroundPath = null; // Clear temp path after successful upload
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company background updated!'), backgroundColor: Colors.green),
        );
      } else {
        setState(() {
          _tempBackgroundPath = null; // Clear temp path on error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error uploading background'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() {
        _tempBackgroundPath = null; // Clear temp path on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingBg = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    // If companyData is provided, use it directly (public company view)
    if (widget.companyData != null) {
      return _buildCompanyContent(widget.companyData!);
    }

    // Otherwise, fetch from profile provider (current user)
    final profileState = ref.watch(userStateProvider);
    if (profileState == null) {
      return _buildLoadingState();
    }


    if (profileState.company.isEmpty) {
      return _buildNoCompanyState();
    }


    return _buildCompanyContent(profileState.company.first);
  }

  Widget _buildNoCompanyState() {
    final theme = widget.theme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 64.sp,
            color: theme.textColor.withAlpha(153),
          ),
          SizedBox(height: 16.h),
          Text(
            'No Company Data Available',
            style: TextStyle(
              color: theme.textColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'This user is not associated with any company.',
            style: TextStyle(
              color: theme.textColor.withAlpha(178),
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildJoinToAssociationCta({
    required ThemeColors theme,
    required CompanyModel company,
  }) {
    // Only show in public company view (not current user's own company)
    if (widget.isCurrentUserCompany) return const SizedBox.shrink();

    // Hide if user is already a member
    if (_isCurrentUserMember(company)) return const SizedBox.shrink();

    return ElevatedButton(
      style: elevatedButtonStyleRounded10withoutPadding,
      onPressed: () => _goJoinToAssociation(company.id),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.all(Radius.circular(6)),
        border: BoxBorder.all(
          color: theme.dashboardBoarder,
          width: 1
        )

        ),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_add_rounded, color: theme.textColor, size: 18),
              SizedBox(width: 8.w),
              Text(
                'Join to association'.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 10.w),
              Icon(
                Icons.arrow_forward_rounded,
                color: theme.textColor,
                size: 18,
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildCompanyContent(CompanyModel company) {
    final theme = widget.theme;

    return Column(
      children: [
        // Company Header Section
        SizedBox(
          height: 300.h,
          child: Stack(
            children: [
              Container(
                height: 200.h,
                width: double.infinity,
                decoration: BoxDecoration(
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
                          : (company.companyBackgroundImage?.isNotEmpty == true
                              ? DecorationImage(
                                image: NetworkImage(
                                  company.companyBackgroundImage!,
                                ),
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                              )
                              : null),
                  color: const Color.fromRGBO(79, 79, 79, 1),
                ),
                child: Stack(
                  children: [
                    // Show centered button when no background image and user can manage

                    if (company.companyBackgroundImage?.isEmpty != false &&
                        _tempBackgroundPath == null &&
                        widget.isCurrentUserCompany &&
                        _canManageCompany(company))
                      Center(
                        child: InkWell(
                          onTap:
                              _isUploadingBg
                                  ? null
                                  : () =>
                                      _uploadCompanyBackground(ref, company),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(230),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: theme.textColor.withAlpha(76),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isUploadingBg)
                                  SizedBox(
                                    width: 16.w,
                                    height: 16.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.textColor,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.add_photo_alternate,
                                    color: theme.textColor,
                                    size: 20.w,
                                  ),
                                SizedBox(width: 8.w),
                                Text(
                                  _isUploadingBg ? 'Uploading...'.tr : 'Add Company Background'.tr,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: theme.textColor,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),


                    // Company logo and name in center
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height: 70.w,
                            width: 70.w,
                            decoration: BoxDecoration(
                              color: theme.buttonBackground,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6.r),
                              child: company.companyLogo?.isNotEmpty == true
                                  ? CachedNetworkImage(
                                      imageUrl: company.companyLogo!,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, error, stackTrace) {
                                        return Container(color: Colors.grey);
                                      },
                                    )
                                  : Container(color: Colors.grey),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            company.companyName ?? 'Unknown Company'.tr,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                ),
                          ),
                        ],
                      ),
                    ),

                    // ✅ Floating CTA (overlapping the background image, near the bottom)
                    Positioned(

                      right: 10,
                      bottom: 10,
                      child: Center(
                        child: _buildJoinToAssociationCta(theme: theme, company: company),
                      ),
                    ),

                    // Upload icon in top right (only show when background exists and user can manage)
                    if (widget.isCurrentUserCompany &&
                        _canManageCompany(company) &&
                        (company.companyBackgroundImage?.isNotEmpty == true || _tempBackgroundPath != null))
                      Positioned(
                        top: 15.h,
                        right: 15.w,
                        child: InkWell(
                          onTap:
                              _isUploadingBg
                                  ? null
                                  : () =>
                                      _uploadCompanyBackground(ref, company),
                          child: Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(128),
                              borderRadius: BorderRadius.circular(25.r),
                            ),
                            child: _isUploadingBg
                                ? SizedBox(
                                    width: 20.w,
                                    height: 20.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20.w,
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
            ],
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 40.w),
            Expanded(
              flex: 2,
              child: Column(
                spacing: 20.h,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    spacing: 5.h,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.companyName ?? 'Unknown Company',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: theme.textColor,
                              fontSize: 24.sp,
                            ),
                      ),
                      SizedBox(height: 5.h),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Column(
                    spacing: 6.h,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Team Members'.tr,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: theme.textColor,
                                  fontSize: 15.sp,
                                ),
                          ),
                          Text(
                            '${company.memberships.length}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: theme.textColor,
                                  fontSize: 17.sp,
                                ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Memberships'.tr,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: theme.textColor,
                                  fontSize: 15.sp,
                                ),
                          ),
                          Text(
                            '${company.memberships.length}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: theme.textColor,
                                  fontSize: 17.sp,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  if (company.representativeName?.isNotEmpty == true)
                    Text(
                      '${"REPRESENTATIVE".tr}: ${company.representativeName}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 12.sp,
                            color: theme.textColor,
                          ),
                    ),

                  // Team Members Section
                  if (company.memberships.isNotEmpty) ...[
                    SizedBox(height: 20.h),
                    Text(
                      'Team Members'.tr,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ...company.memberships.map(
                      (membership) =>
                          _buildMemberCard(ref, theme, membership.user),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 80.w),
            Expanded(
              flex: 8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 18.0, bottom: 18, right: 18),
                    child: SizedBox.shrink(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 18.0, bottom: 18, right: 18),
                    child: _buildAdsContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdsContent() {
    final theme = widget.theme;

    if (!mounted) {
      return const SizedBox.shrink();
    }


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Company Advertisements'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        Builder(
          builder: (context) {
            final width = MediaQuery.of(context).size.width;
            int gridCount;
            if (width >= 1600) {
              gridCount = 4;
            } else if (width >= 1200) {
              gridCount = 3;
            } else {
              gridCount = 2;
            }

            return PagedGridView<int, AdsListViewModel>(
              key: ValueKey('company-ads-grid-$gridCount'),
              pagingController: _pagingController,
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridCount,
                crossAxisSpacing: 7,
                mainAxisSpacing: 7,
                childAspectRatio: 1,
              ),
              builderDelegate: PagedChildBuilderDelegate<AdsListViewModel>(
                itemBuilder: (context, ad, index) {
                  final img =
                      (ad.images.isNotEmpty ? (ad.images.first ?? '') : '')
                          .toString()
                          .trim();
                  return SelectedCardWidget(
                    ad: ad,
                    tag: 'company-ad-${ad.id}',
                    mainImageUrl: img,
                    isPro: ad.isPro,
                    isDefaultDarkSystem: Theme.of(context).brightness == Brightness.dark,
                    color: theme.sideBarbackground,
                    textColor: theme.textColor,
                    textFieldColor: theme.textFieldColor,
                    buildShimmerPlaceholder: _buildShimmerPlaceholder(theme),
                    buildPieMenuActions: _buildPieMenuActions(ref, ad, context),
                    aspectRatio: 1.0,
                    isMobile: false,
                  );
                },
                firstPageProgressIndicatorBuilder: (_) => SizedBox(
                  height: 1000,
                  child: ShimmerAdvertisementGrid(crossAxisCount: gridCount),
                ),
                newPageProgressIndicatorBuilder: (_) => SizedBox(
                  height: 300,
                  child: ShimmerAdvertisementGrid(crossAxisCount: gridCount),
                ),
                noItemsFoundIndicatorBuilder: (_) => Center(child: AppLottie.noResults(size: 200)),
                firstPageErrorIndicatorBuilder: (_) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64.sp,
                        color: theme.textColor.withAlpha(153),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load company ads'.tr,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(204),
                          fontSize: 16.sp,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _pagingController.refresh(),
                        child:  Text('Retry'.tr),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }


  Widget _buildMemberCard(
    WidgetRef ref,
    ThemeColors theme,
    MembershipUser member,
  ) {
    return InkWell(
      onTap: () {
        ref.read(navigationService).pushNamedScreen('${Routes.profile}/${member.id}');
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: widget.theme.sideBarbackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: widget.theme.textFieldColor.withAlpha(76),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                color: widget.theme.textFieldColor.withAlpha(76),
              ),
              child: member.avatar?.isNotEmpty == true
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      child: CachedNetworkImage(
                        imageUrl: member.avatar!,
                        width: 40.w,
                        height: 40.h,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Icon(
                          Icons.person,
                          color: widget.theme.textColor.withAlpha(178),
                          size: 20.sp,
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.person,
                          color: widget.theme.textColor.withAlpha(178),
                          size: 20.sp,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: widget.theme.textColor.withAlpha(178),
                      size: 20.sp,
                    ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${member.firstName} ${member.lastName}',
                    style: TextStyle(
                      color: widget.theme.textColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    member.email,
                    style: TextStyle(
                      color: widget.theme.textColor.withAlpha(178),
                      fontSize: 12.sp,
                    ),
                  ),
                  if (member.phoneNumber?.isNotEmpty == true) ...[
                    SizedBox(height: 2.h),
                    Text(
                      member.phoneNumber!,
                      style: TextStyle(
                        color: widget.theme.textColor.withAlpha(178),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(40.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Header Shimmer
          Container(
            width: double.infinity,
            height: 200.h,
            decoration: BoxDecoration(
              color: widget.theme.textFieldColor.withAlpha(76),
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          SizedBox(height: 32.h),

          // Stats Row Shimmer
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 80.h,
                  decoration: BoxDecoration(
                    color: widget.theme.textFieldColor.withAlpha(76),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: Container(
                  height: 80.h,
                  decoration: BoxDecoration(
                    color: widget.theme.textFieldColor.withAlpha(76),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 32.h),

          // Content Shimmer
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: List.generate(
                    3,
                    (index) => Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      height: 80.h,
                      decoration: BoxDecoration(
                        color: widget.theme.textFieldColor.withAlpha(76),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 32.w),
              Expanded(
                child: Column(
                  children: List.generate(
                    2,
                    (index) => Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      height: 80.h,
                      decoration: BoxDecoration(
                        color: widget.theme.textFieldColor.withAlpha(76),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerPlaceholder(ThemeColors theme) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.textFieldColor.withAlpha(76),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          Icons.home,
          size: 48,
          color: theme.textColor.withAlpha(128),
        ),
      ),
    );
  }

  List<PieAction> _buildPieMenuActions(
    WidgetRef ref,
    AdsListViewModel ad,
    BuildContext context,
  ) {
    return [
      PieAction(
        tooltip:  Text("Favorite".tr),
        onSelect: () {},
        child: const FaIcon(FontAwesomeIcons.solidHeart),
      ),
      PieAction(
        tooltip: Text('Add to viewing list'.tr),
        onSelect: () {},
        child: const FaIcon(FontAwesomeIcons.list),
      ),
      PieAction(
        tooltip: Text('Hide advertisement'.tr),
        onSelect: () {},
        child: const FaIcon(FontAwesomeIcons.eyeSlash),
      ),
      PieAction(
        tooltip: Text('Share advertisement'.tr),
        onSelect: () {},
        child: const FaIcon(FontAwesomeIcons.shareNodes),
      ),
    ];
  }
}
