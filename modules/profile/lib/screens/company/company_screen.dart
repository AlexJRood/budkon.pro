
import 'dart:developer';

import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profile/screens/company/company_mobile.dart';
import 'package:profile/screens/company/company_pc.dart';
import 'package:profile/screens/company/company_tablet.dart';
import 'package:core/user/user/user_model.dart';
import 'package:core/theme/apptheme.dart';

class CompanyScreen extends ConsumerWidget {
  final CompanyModel? companyData;
  final bool isCurrentUserCompany;
  const CompanyScreen({
    super.key,
    this.companyData,
    this.isCurrentUserCompany = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.watch(themeColorsProvider);

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.portal,
      enableScrool: true,
      childrenPc: [
        CompanyPc(
          theme: theme,
          companyData: companyData,
          isCurrentUserCompany: isCurrentUserCompany,
        ),
      ],
      childrenTablet:[CompanyTablet(
        theme: theme,
        companyData: companyData,
        isCurrentUserCompany: isCurrentUserCompany,
      ),] ,
      childrenMobile: [
        SizedBox(
          height: TopAppBarSize.resolve(context),
        ),
        CompanyMobile(
          theme: theme,
          companyData: companyData,
          isCurrentUserCompany: isCurrentUserCompany,
        ),
        SizedBox(
          height: TopAppBarSize.withTopAppBar(context),
        ),
      ],
    );
  }
}
