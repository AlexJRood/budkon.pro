import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';

class AdViewIconsWidget extends StatelessWidget {
  final ThemeColors theme;
  const AdViewIconsWidget({super.key,required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      height: 700,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(height: 120.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,

            spacing: 10.w,
            children: [
              Text(
                'Edit',
                style: AppTextStyles.interBold.copyWith(
                  fontSize: 13.sp,
                  color: theme.textColor,
                ),
              ),
              AppIcons.pencil(color: theme.textColor),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,

            spacing: 10.w,
            children: [
              Text(
                'Draft',
                style: AppTextStyles.interBold.copyWith(
                  fontSize: 13.sp,
                  color: theme.textColor,
                ),
              ),
              AppIcons.visible(color: theme.textColor),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,

            spacing: 10.w,
            children: [
              Text(
                'Print',
                style: AppTextStyles.interBold.copyWith(
                  fontSize: 13.sp,
                  color: theme.textColor,
                ),
              ),
              AppIcons.printer(color: theme.textColor),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,

            spacing: 10.w,
            children: [
              Text(
                'Repost Listing',
                style: AppTextStyles.interBold.copyWith(
                  fontSize: 13.sp,
                  color: theme.textColor,
                ),
              ),
              AppIcons.refresh(color: theme.textColor),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,

            spacing: 10.w,
            children: [
              Text(
                'Promotion Package',
                style: AppTextStyles.interBold.copyWith(
                  fontSize: 13.sp,
                  color: theme.textColor,
                ),
              ),
              AppIcons.refresh(color: theme.textColor),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,

            spacing: 10.w,
            children: [
              Text(
                'Set Tag/Label',
                style: AppTextStyles.interBold.copyWith(
                  fontSize: 13.sp,
                  color: theme.textColor,
                ),
              ),
              Icon(Icons.label, color: theme.textColor),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,

            spacing: 10.w,
            children: [
              Text(
                'Highlight Listing',
                style: AppTextStyles.interBold.copyWith(
                  fontSize: 13.sp,
                  color: theme.textColor,
                ),
              ),
              AppIcons.star(color: theme.textColor),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,

            spacing: 10.w,
            children: [
              Text(
                'Set Booster',
                style: AppTextStyles.interBold.copyWith(
                  fontSize: 13.sp,
                  color: theme.textColor,
                ),
              ),
              AppIcons.star(color: theme.textColor),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,

            spacing: 10.w,
            children: [
              Text(
                'Post action history',
                style: AppTextStyles.interBold.copyWith(
                  fontSize: 13.sp,
                  color: theme.textColor,
                ),
              ),
              AppIcons.menu(color: theme.textColor),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,

            spacing: 10.w,
            children: [
              Text(
                'View statistics',
                style: AppTextStyles.interBold.copyWith(
                  fontSize: 13.sp,
                  color: theme.textColor,
                ),
              ),
              AppIcons.menu(color: theme.textColor),
            ],
          ),
        ],
      ),
    );
  }
}
