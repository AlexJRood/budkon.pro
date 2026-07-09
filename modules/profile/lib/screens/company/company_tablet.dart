import 'dart:io';
import 'package:profile/profile_urls.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:pie_menu/pie_menu.dart';

import 'package:portal/models/ad_list_view_model.dart';
import 'package:portal/screens/feed/components/cards/selected_card.dart';
import 'package:profile/providers/company_ads_provider.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/lottie.dart';
import 'package:core/user/user/user_model.dart';
import 'package:core/user/user/user_provider.dart';

class CompanyTablet extends ConsumerStatefulWidget {
  final ThemeColors theme;
  final CompanyModel? companyData;
  final bool isCurrentUserCompany;

  const CompanyTablet({
    super.key,
    required this.theme,
    this.companyData,
    this.isCurrentUserCompany = true,
  });

  @override
  ConsumerState<CompanyTablet> createState() => _CompanyTabletState();
}

class _CompanyTabletState extends ConsumerState<CompanyTablet> {
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
        companyId =
            widget.companyData?.id ??
            (profileState?.company.isNotEmpty == true
                ? profileState!.company.first.id
                : null);
      }

      if (companyId == null) {
        if (mounted) {
          _pagingController.error = Exception(
            'Company information not available.',
          );
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

  bool _canManageCompany(CompanyModel company) {
    final currentUser = ref.read(userStateProvider);
    if (currentUser == null) return false;
    final currentUserId = int.tryParse(currentUser.userId ?? '0') ?? 0;
    final membership =
        company.memberships
            .where((m) => m.user.id == currentUserId)
            .firstOrNull;
    if (membership == null) return false;
    final role = membership.role.toLowerCase();
    return role == 'admin' || role == 'manager';
  }

  bool _isCurrentUserMember(CompanyModel company) {
    final currentUser = ref.read(userStateProvider);
    if (currentUser == null) return false;
    final currentUserId = int.tryParse(currentUser.userId ?? '0') ?? 0;
    return company.memberships.any((m) => m.user.id == currentUserId);
  }

  Future<void> _uploadCompanyBackground(CompanyModel company) async {
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
        ref.invalidate(userStateProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Company background updated!'),
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
    CompanyModel? company;
    if (widget.companyData != null) {
      company = widget.companyData;
    } else {
      final profileState = ref.watch(userStateProvider);
      if (profileState != null && profileState.company.isNotEmpty) {
        company = profileState.company.first;
      }
    }

    if (company == null) {
      return Center(child: AppLottie.loading(size: 300));
    }

    // Tablet specific geometries (Fixed sizes as requested)
    const double horizontalPad = 24.0; // Reduced pad slightly to fix overflow
    const double bannerH = 220.0;
    const double logoSize = 100.0;
    const double bannerOverlap = 30.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1) HEADER (Banner)
        _CompanyTabletHeader(
          theme: widget.theme,
          isUploadingBg: _isUploadingBg,
          tempBackgroundPath: _tempBackgroundPath,
          backgroundImage: company.companyBackgroundImage,
          onUpload: () => _uploadCompanyBackground(company!),
          bannerH: bannerH,
          canManage: _canManageCompany(company),
          isCurrentUserCompany: widget.isCurrentUserCompany,
        ),

        // 2) PROFILE INFO (Logo & Name row)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPad),
          child: _CompanyTabletProfileInfo(
            theme: widget.theme,
            company: company,
            logoSize: logoSize,
            bannerOverlap: bannerOverlap,
            onJoin:
                () => ref
                    .read(navigationService)
                    .pushNamedScreen(
                      '/association/${company!.id}/join-to-association',
                    ),
            isMember: _isCurrentUserMember(company),
            isCurrentUserCompany: widget.isCurrentUserCompany,
          ),
        ),

        // 3) STATS PILLS
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: horizontalPad,
            vertical: 24.0,
          ),
          child: Row(
            children: [
              _buildStatPill(
                widget.theme,
                'Members',
                '${company.memberships.length}',
                Icons.people,
              ),
              const SizedBox(width: 16.0),
              _buildStatPill(
                widget.theme,
                'Memberships',
                '${company.memberships.length}',
                Icons.card_giftcard,
              ),
            ],
          ),
        ),

        // 4) CONTENT SPLIT (Side-by-Side on wide, Staked on narrow)
        MediaQuery.of(context).size.width > 1000
            ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontalPad),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT COLUMN: Team Members (Expanded flex 2)
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            'Team Members',
                            style: TextStyle(
                              color: widget.theme.textColor,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (company.memberships.isEmpty)
                          Text(
                            'No members found.',
                            style: TextStyle(
                              color: widget.theme.textColor.withAlpha(128),
                            ),
                          )
                        else
                          ...company.memberships.map(
                            (m) => _buildMemberCard(ref, widget.theme, m.user),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 24.0),

                  // RIGHT COLUMN: Advertisements Grid (Expanded flex 5)
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            'Company Advertisements',
                            style: TextStyle(
                              color: widget.theme.textColor,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _CompanyTabletAdsGrid(
                          pagingController: _pagingController,
                          theme: widget.theme,
                          ref: ref,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
            : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Team Members (Full width)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Team Members',
                      style: TextStyle(
                        color: widget.theme.textColor,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (company.memberships.isEmpty)
                    Text(
                      'No members found.',
                      style: TextStyle(
                        color: widget.theme.textColor.withAlpha(128),
                      ),
                    )
                  else
                    ...company.memberships.map(
                      (m) => _buildMemberCard(ref, widget.theme, m.user),
                    ),

                  const SizedBox(height: 32.0),

                  // Advertisements Grid (Full width)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Company Advertisements',
                      style: TextStyle(
                        color: widget.theme.textColor,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _CompanyTabletAdsGrid(
                    pagingController: _pagingController,
                    theme: widget.theme,
                    ref: ref,
                  ),
                ],
              ),
            ),

        const SizedBox(height: 60.0),
      ],
    );
  }

  Widget _buildStatPill(
    ThemeColors theme,
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: theme.sideBarbackground,
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(color: theme.textFieldColor.withAlpha(76), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: theme.textColor.withAlpha(178), size: 16.0),
          const SizedBox(width: 8.0),
          Text(
            value,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6.0),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: theme.textColor.withAlpha(128),
              fontSize: 9.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(
    WidgetRef ref,
    ThemeColors theme,
    MembershipUser member,
  ) {
    return InkWell(
      onTap: () {
        ref
            .read(navigationService)
            .pushNamedScreen('${Routes.profile}/${member.id}');
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: theme.sideBarbackground,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: theme.textFieldColor.withAlpha(76),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32.0,
              height: 32.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                color: theme.textFieldColor.withAlpha(76),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child:
                    member.avatar?.isNotEmpty == true
                        ? CachedNetworkImage(
                          imageUrl: member.avatar!,
                          fit: BoxFit.cover,
                          errorWidget:
                              (context, url, error) =>
                                  const Icon(Icons.person, size: 20),
                        )
                        : const Icon(Icons.person, size: 20),
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${member.firstName} ${member.lastName}',
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    member.email ?? '',
                    style: TextStyle(
                      color: theme.textColor.withAlpha(128),
                      fontSize: 11.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyTabletHeader extends StatelessWidget {
  final ThemeColors theme;
  final bool isUploadingBg;
  final String? tempBackgroundPath;
  final String? backgroundImage;
  final VoidCallback onUpload;
  final double bannerH;
  final bool canManage;
  final bool isCurrentUserCompany;

  const _CompanyTabletHeader({
    required this.theme,
    required this.isUploadingBg,
    this.tempBackgroundPath,
    this.backgroundImage,
    required this.onUpload,
    required this.bannerH,
    required this.canManage,
    required this.isCurrentUserCompany,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: bannerH,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        image:
            tempBackgroundPath != null
                ? DecorationImage(
                  image:
                      kIsWeb
                          ? NetworkImage(tempBackgroundPath!)
                          : FileImage(File(tempBackgroundPath!))
                              as ImageProvider,
                  fit: BoxFit.cover,
                )
                : (backgroundImage?.isNotEmpty == true
                    ? DecorationImage(
                      image: NetworkImage(backgroundImage!),
                      fit: BoxFit.cover,
                    )
                    : null),
      ),
      child:
          isCurrentUserCompany && canManage
              ? Stack(
                children: [
                  Positioned(
                    top: 20.0,
                    right: 20.0,
                    child: InkWell(
                      onTap: isUploadingBg ? null : onUpload,
                      child: Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(160),
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        child:
                            isUploadingBg
                                ? const SizedBox(
                                  width: 20.0,
                                  height: 20.0,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20.0,
                                ),
                      ),
                    ),
                  ),
                ],
              )
              : null,
    );
  }
}

class _CompanyTabletProfileInfo extends StatelessWidget {
  final ThemeColors theme;
  final CompanyModel company;
  final double logoSize;
  final double bannerOverlap;
  final VoidCallback onJoin;
  final bool isMember;
  final bool isCurrentUserCompany;

  const _CompanyTabletProfileInfo({
    required this.theme,
    required this.company,
    required this.logoSize,
    required this.bannerOverlap,
    required this.onJoin,
    required this.isMember,
    required this.isCurrentUserCompany,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(top: bannerOverlap + 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Company Info Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.companyName ?? 'Unknown Company',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 26.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (company.representativeName?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Representative: ${company.representativeName}',
                          style: TextStyle(
                            color: theme.textColor.withAlpha(153),
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Join Button
              if (!isCurrentUserCompany && !isMember)
                ElevatedButton(
                  style: elevatedButtonStyleRounded10withoutPadding,
                  onPressed: onJoin,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 16.0,
                    ),
                    decoration: BoxDecoration(
                      color: theme.dashboardContainer,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: theme.dashboardBoarder,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.group_add_rounded,
                          color: theme.textColor,
                          size: 18.0,
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          'Join Company'.tr,
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 13.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Logo Inset
        Positioned(
          top: -bannerOverlap - 25.0,
          left: 0,
          child: Container(
            height: logoSize,
            width: logoSize,
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: Colors.black, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(64),
                  blurRadius: 10.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child:
                company.companyLogo?.isNotEmpty == true
                    ? CachedNetworkImage(
                      imageUrl: company.companyLogo!,
                      fit: BoxFit.cover,
                      errorWidget:
                          (context, error, stackTrace) =>
                              const Icon(Icons.business, size: 40.0),
                    )
                    : const Icon(Icons.business, size: 40.0),
          ),
        ),
      ],
    );
  }
}

class _CompanyTabletAdsGrid extends StatelessWidget {
  final PagingController<int, AdsListViewModel> pagingController;
  final ThemeColors theme;
  final WidgetRef ref;

  const _CompanyTabletAdsGrid({
    required this.pagingController,
    required this.theme,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return PagedGridView<int, AdsListViewModel>(
      pagingController: pagingController,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.82, // Balanced for Tablet card content
      ),
      builderDelegate: PagedChildBuilderDelegate<AdsListViewModel>(
        itemBuilder: (context, ad, index) {
          final img =
              (ad.images.isNotEmpty ? (ad.images.first ?? '') : '')
                  .toString()
                  .trim();
          return SelectedCardWidget(
            ad: ad,
            tag: 'company-tablet-ad-${ad.id}',
            mainImageUrl: img,
            isPro: ad.isPro,
            isDefaultDarkSystem:
                Theme.of(context).brightness == Brightness.dark,
            color: theme.sideBarbackground,
            textColor: theme.textColor,
            textFieldColor: theme.textFieldColor,
            aspectRatio: 1.0,
            isMobile: false,
            buildShimmerPlaceholder: _buildShimmerPlaceholder(theme),
            buildPieMenuActions: _buildPieMenuActions(ref, ad, context),
          );
        },
        firstPageProgressIndicatorBuilder:
            (_) => const Center(child: CircularProgressIndicator()),
        noItemsFoundIndicatorBuilder:
            (_) => Center(child: AppLottie.noResults(size: 150)),
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
          size: 40,
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
        tooltip: const Text("Favorite"),
        onSelect: () {},
        child: const FaIcon(FontAwesomeIcons.solidHeart, size: 20.0),
      ),
      PieAction(
        tooltip: Text('Add to viewing list'.tr),
        onSelect: () {},
        child: const FaIcon(FontAwesomeIcons.list, size: 20.0),
      ),
      PieAction(
        tooltip: Text('Hide advertisement'.tr),
        onSelect: () {},
        child: const FaIcon(FontAwesomeIcons.eyeSlash, size: 20.0),
      ),
      PieAction(
        tooltip: Text('Share advertisement'.tr),
        onSelect: () {},
        child: const FaIcon(FontAwesomeIcons.shareNodes, size: 20.0),
      ),
    ];
  }
}
