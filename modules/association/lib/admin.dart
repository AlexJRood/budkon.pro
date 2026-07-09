import 'package:association/context.dart';
import 'package:association/screens/loyalty/loyalty.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:crm/dynamic_dashboard/dynamic_dashboard_page.dart';
import 'package:crm/dynamic_dashboard/widgets/dashboard_vertical_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';

class AssociationAdmin extends ConsumerStatefulWidget {
  final int assosiationId;

  const AssociationAdmin({
    super.key,
    required this.assosiationId,
  });

  @override
  ConsumerState<AssociationAdmin> createState() => _AssociationAdminState();
}

class _AssociationAdminState extends ConsumerState<AssociationAdmin> {
  final GlobalKey<SideMenuState> sideMenuKey = GlobalKey<SideMenuState>();

  static const String dashboardKey = 'association_dashboard';

  static const _baseUrl = 'https://www.superbee.cloud';

  Widget _buildDashboard(int loyaltyProgramId) {
    return ProviderScope(
      overrides: [
        associationDashboardScopeProvider.overrideWithValue(
          AssociationDashboardScope(
            associationId: widget.assosiationId,
            baseUrl: _baseUrl,
            loyaltyProgramId: loyaltyProgramId,
          ),
        ),
      ],
      child: const DynamicDashboardPage(
        dashboardKey: dashboardKey,
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final programsAsync = ref.watch(
      loyaltyProgramsProvider((
        baseUrl: _baseUrl,
        associationId: widget.assosiationId,
      )),
    );

    final loyaltyProgramId = programsAsync.whenOrNull(
          data: (programs) {
            if (programs.isEmpty) return null;
            try {
              return programs.firstWhere((p) => p.isActive).id;
            } catch (_) {
              return programs.first.id;
            }
          },
        ) ??
        1;

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.association,
      enableScrool: false,
      isTopAppBarHoveroverUI: true,
      paddingPc: 20,
      paddingTablet: 16,
      paddingMobile: 10,
      verticalButtonsPc: _AssociationDashboardFloatingBar(
        associationId: widget.assosiationId,
        dashboardKey: dashboardKey,
      ),
      verticalButtons: _AssociationDashboardFloatingBar(
        associationId: widget.assosiationId,
        dashboardKey: dashboardKey,
        compact: true,
      ),
      childPc: _buildDashboard(loyaltyProgramId),
      childTablet: _buildDashboard(loyaltyProgramId),
      childMobile: _buildDashboard(loyaltyProgramId),
    );
  }
}

class _AssociationDashboardFloatingBar extends ConsumerWidget {
  final int associationId;
  final String dashboardKey;
  final bool compact;

  const _AssociationDashboardFloatingBar({
    required this.associationId,
    required this.dashboardKey,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.read(navigationService);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 48,
          width: 48,
          child: ElevatedButton(
            style: buttonStyleRounded10ThemeRed,
            onPressed: () {
              nav.pushNamedScreen('${Routes.associationMember}/$associationId');
            },
            child: const Icon(
              Icons.swap_horiz_outlined,
              color: AppColors.white,
            ),
          ),
        ),
        SizedBox(height: compact ? 6 : 8),
        DashboardVerticalBar(
          dashboardKey: dashboardKey,
        ),
      ],
    );
  }
}