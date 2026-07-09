// company_mobile.dart
//
// Comments in English as requested.

import 'dart:io';
import 'package:profile/profile_urls.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

class CompanyMobile extends ConsumerStatefulWidget {
  final ThemeColors theme;
  final CompanyModel? companyData;
  final bool isCurrentUserCompany;

  const CompanyMobile({
    super.key,
    required this.theme,
    this.companyData,
    this.isCurrentUserCompany = true,
  });

  @override
  _CompanyMobileState createState() => _CompanyMobileState();
}

class _CompanyMobileState extends ConsumerState<CompanyMobile> {
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
        _pagingController.error =
            Exception('Company information not available.');
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
      _pagingController.error = error;
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

  Future<void> _uploadCompanyBackground(
    WidgetRef ref,
    CompanyModel company,
  ) async {
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
          const SnackBar(
            content: Text('Failed to read file.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Set temporary path for preview
      setState(() {
        _tempBackgroundPath = file.path;
      });

      final formData = FormData.fromMap({
        'background':
            MultipartFile.fromBytes(file.bytes!, filename: file.name),
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
          const SnackBar(
            content: Text('Company background updated!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _tempBackgroundPath = null; // Clear temp path on error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error uploading background'),
            backgroundColor: Colors.red,
          ),
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
    if (widget.companyData != null) {
      return _buildCompanyContent(widget.companyData!);
    }

    final profileState = ref.watch(userStateProvider);
    if (profileState == null) {
      return _buildLoadingState();
    }

    if (profileState.company.isEmpty) {
      return _buildNoCompanyState();
    }

    return _buildCompanyContent(profileState.company.first);
  }

  Widget _buildCompanyContent(CompanyModel company) {
    final theme = widget.theme;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompanyHeader(company, theme),

          // ✅ Mobile: NO floating. Button is placed under the header.
          if (!widget.isCurrentUserCompany &&
              !_isCurrentUserMember(company)) ...[
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _goJoinToAssociation(company.id),
                icon: const Icon(Icons.group_add_rounded),
                label: Text('Join to association'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.themeColor,
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],

          SizedBox(height: 24.h),
          _buildCompanyStats(company, theme),
          SizedBox(height: 24.h),

          if (company.memberships.isNotEmpty)
            _buildMembersSection(company, theme),

          // if (company.memberships.isNotEmpty)
          //   _buildMembershipsSection(company, theme),

          SizedBox(height: 24.h),
          _buildAdsSection(theme),
        ],
      ),
    );
  }

  Widget _buildCompanyHeader(CompanyModel company, ThemeColors theme) {
    final bool hasBg =
        (company.companyBackgroundImage?.isNotEmpty == true) ||
            _tempBackgroundPath != null;

    return Container(
      width: double.infinity,
      height: 280.h,
      decoration: BoxDecoration(
        image: _tempBackgroundPath != null
            ? DecorationImage(
                image: kIsWeb
                    ? NetworkImage(_tempBackgroundPath!)
                    : FileImage(File(_tempBackgroundPath!)) as ImageProvider,
                fit: BoxFit.cover,
              )
            : (company.companyBackgroundImage?.isNotEmpty == true
                ? DecorationImage(
                    image: NetworkImage(company.companyBackgroundImage!),
                    fit: BoxFit.cover,
                  )
                : null),
        color: (!hasBg)
            ? theme.sideBarbackground
            : const Color.fromRGBO(79, 79, 79, 1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.textFieldColor.withAlpha(76),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Show centered button when no background image and user can manage
          if (!hasBg && widget.isCurrentUserCompany && _canManageCompany(company))
            Center(
              child: InkWell(
                onTap: _isUploadingBg
                    ? null
                    : () => _uploadCompanyBackground(ref, company),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(230),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: theme.textColor.withAlpha(76)),
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
                            color: theme.textColor,
                          ),
                        )
                      else
                        Icon(
                          Icons.add_photo_alternate,
                          color: theme.textColor,
                          size: 18.w,
                        ),
                      SizedBox(width: 6.w),
                      Text(
                        _isUploadingBg ? 'Uploading...' : 'Add Background',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: theme.textColor,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Company content in center
          Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80.w,
                    height: 80.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      color: theme.textFieldColor.withAlpha(26),
                    ),
                    child: company.companyLogo?.isNotEmpty == true
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: CachedNetworkImage(
                              imageUrl: company.companyLogo!,
                              width: 80.w,
                              height: 80.h,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Icon(
                                Icons.business,
                                color: theme.textColor.withAlpha(128),
                                size: 32.sp,
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.business,
                                color: theme.textColor.withAlpha(128),
                                size: 32.sp,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.business,
                            color: theme.textColor.withAlpha(128),
                            size: 32.sp,
                          ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    company.companyName ?? 'Unknown Company',
                    style: TextStyle(
                      color: hasBg ? Colors.white : theme.textColor,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  if (company.representativeName?.isNotEmpty == true) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'Representative: ${company.representativeName}',
                      style: TextStyle(
                        color: hasBg
                            ? Colors.white.withAlpha(204)
                            : theme.textColor.withAlpha(178),
                        fontSize: 12.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Upload icon in top right (only show when background exists and user can manage)
          if (widget.isCurrentUserCompany &&
              _canManageCompany(company) &&
              hasBg)
            Positioned(
              top: 12.h,
              right: 12.w,
              child: InkWell(
                onTap: _isUploadingBg
                    ? null
                    : () => _uploadCompanyBackground(ref, company),
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(128),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: _isUploadingBg
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
        ],
      ),
    );
  }

  Widget _buildCompanyStats(CompanyModel company, ThemeColors theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            'Members',
            '${company.memberships.length}',
            Icons.people,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            theme,
            'Memberships',
            '${company.memberships.length}',
            Icons.card_membership,
          ),
        ),
      ],
    );
  }

  Widget _buildMembersSection(CompanyModel company, ThemeColors theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team Members'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        ...company.memberships
            .map((membership) => _buildMemberCard(theme, membership.user)),
        SizedBox(height: 24.h),
      ],
    );
  }

  // Widget _buildMembershipsSection(CompanyModel company, ThemeColors theme) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         'Memberships'.tr,
  //         style: TextStyle(
  //           color: theme.textColor,
  //           fontSize: 18.sp,
  //           fontWeight: FontWeight.w600,
  //         ),
  //       ),
  //       SizedBox(height: 16.h),
  //       ...company.memberships
  //           .map((membership) => _buildMembershipCard(theme, membership)),
  //     ],
  //   );
  // }

  Widget _buildAdsSection(ThemeColors theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Company Advertisements'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        PagedGridView<int, AdsListViewModel>(
          pagingController: _pagingController,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          builderDelegate: PagedChildBuilderDelegate<AdsListViewModel>(
            itemBuilder: (context, ad, index) {
              return SelectedCardWidget(
                ad: ad,
                tag: 'company-mobile-ad-${ad.id}',
                mainImageUrl: ad.images.isNotEmpty ? ad.images.first : '',
                isPro: ad.isPro,
                isDefaultDarkSystem:
                    Theme.of(context).brightness == Brightness.dark,
                color: theme.sideBarbackground,
                textColor: theme.textColor,
                textFieldColor: theme.textFieldColor,
                buildShimmerPlaceholder: _buildShimmerPlaceholder(theme),
                buildPieMenuActions: _buildPieMenuActions(ref, ad, context),
                aspectRatio: 1.2,
                isMobile: true,
              );
            },
            firstPageProgressIndicatorBuilder: (_) => SizedBox(
              height: 300,
              child: ShimmerAdvertisementGrid(crossAxisCount: 1),
            ),
            newPageProgressIndicatorBuilder: (_) => SizedBox(
              height: 300,
              child: ShimmerAdvertisementGrid(crossAxisCount: 1),
            ),
            noItemsFoundIndicatorBuilder: (_) => Center(
              child: AppLottie.noResults(size: 150),
            ),
            firstPageErrorIndicatorBuilder: (_) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48.sp,
                    color: theme.textColor.withAlpha(153),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load company ads'.tr,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(204),
                      fontSize: 14.sp,
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
        ),
      ],
    );
  }

  Widget _buildNoCompanyState() {
    final theme = widget.theme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 64.sp,
              color: theme.textColor.withAlpha(128),
            ),
            SizedBox(height: 16.h),
            Text(
              'No Company Data Available'.tr,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'This user is not associated with any company.'.tr,
              style: TextStyle(
                color: theme.textColor.withAlpha(178),
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final theme = widget.theme;
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 200.h,
            decoration: BoxDecoration(
              color: theme.textFieldColor.withAlpha(76),
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 100.h,
                  decoration: BoxDecoration(
                    color: theme.textFieldColor.withAlpha(76),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Container(
                  height: 100.h,
                  decoration: BoxDecoration(
                    color: theme.textFieldColor.withAlpha(76),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Column(
            children: List.generate(
              4,
              (index) => Container(
                margin: EdgeInsets.only(bottom: 12.h),
                height: 80.h,
                decoration: BoxDecoration(
                  color: theme.textFieldColor.withAlpha(76),
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ThemeColors theme,
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.sideBarbackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.textFieldColor.withAlpha(76),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: theme.textColor.withAlpha(178),
            size: 24.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            style: TextStyle(
              color: theme.textColor.withAlpha(178),
              fontSize: 11.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(ThemeColors theme, MembershipUser member) {
    return InkWell(
      onTap: () {
        ref
            .read(navigationService)
            .pushNamedScreen('${Routes.profile}/${member.id}');
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: theme.sideBarbackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: theme.textFieldColor.withAlpha(76),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.r),
                color: theme.textFieldColor.withAlpha(76),
              ),
              child: member.avatar?.isNotEmpty == true
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18.r),
                      child: CachedNetworkImage(
                        imageUrl: member.avatar!,
                        width: 36.w,
                        height: 36.h,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Icon(
                          Icons.person,
                          color: theme.textColor.withAlpha(178),
                          size: 18.sp,
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.person,
                          color: theme.textColor.withAlpha(178),
                          size: 18.sp,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: theme.textColor.withAlpha(178),
                      size: 18.sp,
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
                      color: theme.textColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    member.email,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(178),
                      fontSize: 12.sp,
                    ),
                  ),
                  if (member.phoneNumber?.isNotEmpty == true) ...[
                    SizedBox(height: 2.h),
                    Text(
                      member.phoneNumber!,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(178),
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

  Widget _buildMembershipCard(ThemeColors theme, CompanyMembershipModel membership) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.sideBarbackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.textFieldColor.withAlpha(76),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.card_membership,
                color: theme.textColor.withAlpha(178),
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  membership.role,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: membership.status.toLowerCase() == 'active'
                      ? Colors.green.withAlpha(51)
                      : Colors.orange.withAlpha(51),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  membership.status,
                  style: TextStyle(
                    color: membership.status.toLowerCase() == 'active'
                        ? Colors.green
                        : Colors.orange,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '${membership.user.firstName} ${membership.user.lastName}',
            style: TextStyle(
              color: theme.textColor.withAlpha(204),
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            '${"Joined".tr}: ${membership.joinedAt}',
            style: TextStyle(
              color: theme.textColor.withAlpha(153),
              fontSize: 11.sp,
            ),
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
          size: 32,
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
