import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/navigation_history_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:crm/crm/finance/features/expenses/add_expenses.dart';

class DashboardSideButtons extends StatelessWidget {
  final WidgetRef ref;

  const DashboardSideButtons({
    super.key,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SideButtonsDashboard(
                onPressed: () {
                  Navigator.pushNamed(context, '/pro/finance/costs/add');
                },
                icon: Icons.search,
                text: 'Search'.tr),
            const SizedBox(height: 10),
            SideButtonsDashboard(
                onPressed: () {
                  Navigator.pushNamed(context, '/pro/finance/costs/add');
                },
                icon: Icons.sort,
                text: 'Sort'.tr),
            const SizedBox(height: 10),
            SideButtonsDashboard(
                onPressed: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (_, __, ___) => const CrmAddExpensesPopPc(),
                        transitionsBuilder: (_, anim, __, child) {
                          return FadeTransition(opacity: anim, child: child);
                        },
                      ),
                    );
                },
                icon: Icons.money_off,
                text: 'add_expense_button'.tr),
            const SizedBox(height: 10),
            SideButtonsDashboard(
                onPressed: () {
                  Navigator.pushNamed(context, '/pro/finance/revenue/add');
                },
                icon: Icons.monetization_on_outlined,
                text: 'add'.tr),
            const SizedBox(
              height: 10,
            ),
            SideButtonsDashboard(
                onPressed: () {},
                icon: Icons.view_carousel_sharp,
                text: 'view'.tr),
            const SizedBox(
              height: 10,
            ),
            SideButtonsDashboard(
                onPressed: () {
                  ref.read(navigationHistoryProvider.notifier)
                      .addPage(Routes.addClientForm);
                  ref.read(navigationService)
                      .pushNamedScreen(Routes.addClientFormDashboard);
                },
                icon: Icons.add_box_outlined,
                text: 'Add'.tr),
          ],
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
    return ElevatedButton(
      style: buttonSideDashboard.copyWith(
          backgroundColor: WidgetStatePropertyAll(
              colorscheme == FlexScheme.blackWhite
                  ? Theme.of(context).colorScheme.onSecondary.withAlpha((255 * 0.5).toInt())
                  : theme.textFieldColor.withAlpha((255 * 0.5).toInt()),),), // Użycie przekazanego lub domyślnego stylu
      onPressed: onPressed,
      child: Column(
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
    );
  }
}
