import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/apptheme.dart';

class SuccessPageWidget extends ConsumerWidget {
  const SuccessPageWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final sideMenuKey = GlobalKey<SideMenuState>();

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.agentCrm,
      childrenPc: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 120.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Ad Published !',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: theme.textColor,
                  fontSize: 40.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                'The post was published successfully on Hously.pro',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: theme.textColor,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Image.asset('assets/images/success_check.png'),

              SizedBox(height: 80.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 20.w,
                children: [
                  Container(
                    height: 48.h,
                    width: 240.w,
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.bordercolor),
                    ),
                    child: Center(
                      child: Text(
                        'Go to Home Page',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: theme.textColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 48.h,
                    width: 240.w,
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(87, 148, 221, 0.2),
                    ),
                    child: Center(
                      child: Text(
                        'View ad post',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: theme.textColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
