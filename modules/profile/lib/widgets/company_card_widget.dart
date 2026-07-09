import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/user/user/user_provider.dart';
import 'package:core/user/user/user_model.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui' as ui;
import 'package:get/get_utils/get_utils.dart';

class CompanyCardWidget extends ConsumerWidget {
  final UserModel? userModel;
  final bool isCurrentUser;

  const CompanyCardWidget({
    super.key,
    this.userModel,
    this.isCurrentUser = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    // Use provided userModel if available, otherwise fetch from provider
    if (userModel != null) {
      return _buildCompanyCard(context, ref, userModel!, theme);
    }

    final profileState = ref.watch(userStateProvider);
    if (profileState != null) {
      return _buildCompanyCard(context, ref, profileState, theme);
    }
    return _buildLoadingCard(theme);
  }

  Widget _buildCompanyCard(
    BuildContext context,
    WidgetRef ref,
    UserModel profile,
    ThemeColors theme,
  ) {
    // Don't show the card if there's no company data
    if (profile.company.isEmpty) {
      return const SizedBox.shrink();
    }

    final company = profile.company.first;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: theme.dashboardBoarder, width: 1),
      ),
      child: InkWell(
        onTap: () {
          if (isCurrentUser) {
            ref.read(navigationService).pushNamedScreen(Routes.company);
          } else {
            ref
                .read(navigationService)
                .pushNamedScreen('${Routes.company}/${company.id}');
          }
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Row(
          children: [
            Container(
              width: 60.w,
              height: 60.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: theme.textFieldColor.withAlpha(26),
              ),
              child:
                  company.companyLogo?.isNotEmpty == true
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: CachedNetworkImage(
                          imageUrl: company.companyLogo!,
                          width: 60.w,
                          height: 60.h,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                color: theme.textFieldColor.withAlpha(76),
                                child: Icon(
                                  Icons.business,
                                  color: theme.textColor.withAlpha(128),
                                  size: 24.sp,
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: theme.textFieldColor.withAlpha(76),
                                child: Icon(
                                  Icons.business,
                                  color: theme.textColor.withAlpha(128),
                                  size: 24.sp,
                                ),
                              ),
                        ),
                      )
                      : Icon(
                        Icons.business,
                        color: theme.textColor.withAlpha(128),
                        size: 24.sp,
                      ),
            ),

            SizedBox(width: 12.w),

            // Company Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.companyName ?? 'Unknown Company'.tr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: theme.textColor,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 4.h),

                  if (company.memberships.isNotEmpty)
                    Text(
                      '${company.memberships.length} ${"team members".tr}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: theme.textColor.withAlpha(178),
                        fontSize: 12.sp,
                      ),
                    ),

                  SizedBox(height: 4.h),

                  Text(
                    'View company details'.tr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios,
              color: theme.textColor.withAlpha(128),
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(ThemeColors theme) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.sideBarbackground,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              color: theme.textFieldColor.withAlpha(76),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16.h,
                  width: 120.w,
                  decoration: BoxDecoration(
                    color: theme.textFieldColor.withAlpha(76),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  height: 12.h,
                  width: 80.w,
                  decoration: BoxDecoration(
                    color: theme.textFieldColor.withAlpha(76),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AssociationCardWidget extends ConsumerWidget {
  final UserModel? userModel;
  final bool isCurrentUser;

  const AssociationCardWidget({
    super.key,
    this.userModel,
    this.isCurrentUser = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    // Use provided userModel if available, otherwise fetch from provider
    if (userModel != null) {
      return _buildCompanyCard(context, ref, userModel!, theme);
    }

    final profileState = ref.watch(userStateProvider);
    if (profileState != null) {
      return _buildCompanyCard(context, ref, profileState, theme);
    }
    return _buildLoadingCard(theme);
  }

  Widget _buildCompanyCard(
    BuildContext context,
    WidgetRef ref,
    UserModel profile,
    ThemeColors theme,
  ) {
    // Don't show the card if there's no company data
    if (profile.associations.isEmpty) {
      return const SizedBox.shrink();
    }

    final company = profile.associations.first;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 35, sigmaY: 35),
        child: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: theme.dashboardContainer.withAlpha(80),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: theme.dashboardBoarder, width: 1),
          ),
          child: ElevatedButton(
            style: elevatedButtonStyleRounded10,
            onPressed: () {
              ref.read(navigationService).pushNamedScreen(
                    Routes.associationOf(company.id),
                  );
            },
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
          decoration: BoxDecoration(
            color: theme.dashboardContainer.withAlpha(80),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: theme.dashboardBoarder, width: 1),
          ),
                  child:
                      company.companyLogo?.isNotEmpty == true
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: CachedNetworkImage(
                              imageUrl: company.companyLogo!,
                              width: 60.w,
                              height: 60.h,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Container(
                                    color: theme.textFieldColor.withAlpha(((0.3 as num).clamp(0, 1) * 255).round()),
                                    child: Icon(
                                      Icons.business,
                                      color: theme.textColor.withAlpha(128),
                                      size: 24.sp,
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    color: theme.textFieldColor.withAlpha(((0.3 as num).clamp(0, 1) * 255).round()),
                                    child: Icon(
                                      Icons.business,
                                      color: theme.textColor.withAlpha(128),
                                      size: 24.sp,
                                    ),
                                  ),
                            ),
                          )
                          : Icon(
                            Icons.business,
                            color: theme.textColor.withAlpha(128),
                            size: 24.sp,
                          ),
                ),

                SizedBox(width: 12.w),

                // Company Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.companyName ?? 'Unknown Company'.tr,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: theme.textColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 4.h),

                      if (company.memberships.isNotEmpty)
                        Text(
                          '${company.memberships.length} team members'.tr,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: theme.textColor.withAlpha(178),
                            fontSize: 12.sp,
                          ),
                        ),

                      SizedBox(height: 4.h),

                      Text(
                        'View association details'.tr,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: theme.textColor.withAlpha(128),
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard(ThemeColors theme) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.sideBarbackground,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            width: 60.w,
            height: 60.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              color: theme.textFieldColor.withAlpha(76),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16.h,
                  width: 120.w,
                  decoration: BoxDecoration(
                    color: theme.textFieldColor.withAlpha(76),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  height: 12.h,
                  width: 80.w,
                  decoration: BoxDecoration(
                    color: theme.textFieldColor.withAlpha(76),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
