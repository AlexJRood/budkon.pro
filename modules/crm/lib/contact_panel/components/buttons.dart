import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/platform/route_constant.dart';

import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:crm/crm/clients/sort_by.dart';
import 'package:crm/invoice_pdf_generator/model/invoise_model.dart';

class ClientsCrmSideButtons extends StatelessWidget {
  final WidgetRef ref;

  const ClientsCrmSideButtons({
    super.key,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: IntrinsicWidth(
        child: SizedBox(
          width: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SideButtonsDashboard(
                  onPressed: () {
                    showSortPopup(context, ref);
                  },
                  icon: Icons.sort,
                  text: 'sort_button'.tr),
              const SizedBox(height: 10),
              SideButtonsDashboard(
                  onPressed: () {
                    ref
                        .read(navigationService)
                        .pushNamedScreen(Routes.proAddClient);
                  },
                  icon: Icons.view_carousel_sharp,
                  text: 'new_client_button'.tr),
              const SizedBox(height: 10),
              SideButtonsDashboard(
                  onPressed: () {
                    Navigator.pushNamed(context, '/pro/finance/revenue/add');
                  },
                  icon: Icons.monetization_on_outlined,
                  text: 'add_button'.tr),
              const SizedBox(
                height: 10,
              ),
              SideButtonsDashboard(
                  onPressed: () {
                    Navigator.pushNamed(
                        context, '/pro/finance/revenue/add/AddViewerForm');
                  },
                  icon: Icons.add_box_outlined,
                  text: 'add_button'.tr),
              const SizedBox(
                height: 10,
              ),
              SideButtonsDashboard(
                  onPressed: () {
                    toggleBoolean(ref);
                  },
                  icon: Icons.add_box_outlined,
                  text: 'add_button'.tr),
            ],
          ),
        ),
      ),
    );
  }
}

class SideButtonsDashboard extends ConsumerWidget {
  final VoidCallback onPressed;
  final IconData icon;

  final String text;

  const SideButtonsDashboard({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context, ref) {
    final theme = ref.watch(themeColorsProvider);
    final colorscheme = ref.watch(colorSchemeProvider);
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 100,
        height: 66,
        decoration:  BoxDecoration(
          color: const Color.fromRGBO(33, 32, 32, 1),
          borderRadius: BorderRadius.circular(10)
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: colorscheme == FlexScheme.blackWhite
                  ? theme.textFieldColor
                  : Theme.of(context).iconTheme.color,
              size: 25,
            ),
            const SizedBox(
              height: 5,
            ),
            Text(text,
                style: AppTextStyles.interMedium10.copyWith(
                  color: colorscheme == FlexScheme.blackWhite
                      ? theme.textFieldColor
                      : Theme.of(context).iconTheme.color,
                ))
          ],
        ),
      ),
    );
  }
}

class FinanceCrmSideButtons extends StatelessWidget {
  final WidgetRef ref;

  const FinanceCrmSideButtons({
    super.key,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final nav = ref.read(navigationService);
    final path = nav.currentPath;

    return Align(
      alignment: Alignment.topRight,
      child: IntrinsicWidth(
        child: SizedBox(
          width: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SideButtonsDashboard(
                  onPressed: () {
                    nav.pushNamedScreen(
                          Routes.viewPopChanger,
                        );
                  },
                  icon: Icons.view_carousel_sharp,
                  text: 'view_button'.tr),
              const SizedBox(height: 10),
              SideButtonsDashboard(
                  onPressed: () {
                    ref
                        .read(navigationService)
                        .pushNamedScreen(Routes.proPlans);
                  },
                  icon: Icons.monetization_on_outlined,
                  text: 'financial_plans_button'.tr),
              const SizedBox(height: 10),
              SideButtonsDashboard(
                  onPressed: () {                    
                nav.pushNamedScreen(
                      '$path${Routes.statusPopRevenue}',
                      data:{
                        'isFilter': false,
                      }
                    );
                  },
                  icon: Icons.edit,
                  text: 'edit_statuses_button'.tr),
              const SizedBox(height: 10),
              SideButtonsDashboard(
                  onPressed: () {
                    Navigator.pushNamed(context, '/pro/finance/revenue/add');
                  },
                  icon: Icons.monetization_on_outlined,
                  text: 'add_button'.tr),
              const SizedBox(
                height: 10,
              ),
              SideButtonsDashboard(
                  onPressed: () {
                    Navigator.pushNamed(
                        context, '/pro/finance/revenue/add/AddViewerForm');
                  },
                  icon: Icons.add_box_outlined,
                  text: 'add_button'.tr),
            ],
          ),
        ),
      ),
    );
  }
}
