import 'package:association/context.dart';
import 'package:association/providers/loyalty.dart';
import 'package:association/widgets/announcements.dart';
import 'package:association/widgets/dshb_overview.dart';
import 'package:association/widgets/members.dart';
import 'package:crm/dynamic_dashboard/models/dashboard_models.dart';
import 'package:crm/dynamic_dashboard/registry/dashboard_widget_spec.dart';
import 'package:crm/dynamic_dashboard/widgets/dashboard_widget_settings_panels.dart';
import 'package:core/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

List<DashboardWidgetSpec> associationDashboardSpecs() => const [
      AssociationWelcomeHeaderWidgetSpec(),
      AssociationOverviewWidgetSpec(),
      AssociationAnnouncementsWidgetSpec(),
      AssociationMembershipStatusWidgetSpec(),
      AssociationLoyaltyWidgetSpec(),
    ];

// ---------------------------------------------------------------------------
// Association Welcome Header
// ---------------------------------------------------------------------------

class AssociationWelcomeHeaderWidgetSpec extends DashboardWidgetSpec {
  const AssociationWelcomeHeaderWidgetSpec();

  @override
  String get type => 'association_welcome_header';

  @override
  String get title => 'Association Welcome Header';

  @override
  IconData get icon => Icons.handshake_rounded;

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) =>
      switch (breakpoint) {
        DashboardBreakpoint.desktop => const DashboardGridSize(w: 12, h: 1),
        DashboardBreakpoint.tablet  => const DashboardGridSize(w: 8, h: 1),
        DashboardBreakpoint.mobile  => const DashboardGridSize(w: 4, h: 1),
      };

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 2, maxW: 12, minH: 1, maxH: 2,
      );

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
  ) {
    final theme = ref.watch(themeColorsProvider);

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'welcome_back_association_admin'.tr,
            style: TextStyle(
              color: theme.textColor,
              fontSize: breakpoint == DashboardBreakpoint.mobile ? 20.sp : 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'association_management_dashboard'.tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(190),
              fontSize: breakpoint == DashboardBreakpoint.mobile ? 12.sp : 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Association Overview
// ---------------------------------------------------------------------------

class AssociationOverviewWidgetSpec extends DashboardWidgetSpec {
  const AssociationOverviewWidgetSpec();

  @override
  String get type => 'association_overview';

  @override
  String get title => 'Association Overview';

  @override
  IconData get icon => Icons.dashboard_rounded;

  @override
  bool get hasSettings => true;

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) =>
      switch (breakpoint) {
        DashboardBreakpoint.desktop => const DashboardGridSize(w: 8, h: 2),
        DashboardBreakpoint.tablet  => const DashboardGridSize(w: 8, h: 2),
        DashboardBreakpoint.mobile  => const DashboardGridSize(w: 4, h: 2),
      };

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 4, maxW: 12, minH: 2, maxH: 4,
      );

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
  ) {
    final theme = ref.watch(themeColorsProvider);
    final scope = ref.watch(associationDashboardScopeProvider);
    final rawDays = instance.settings['days'];
    final days = rawDays is num ? rawDays.toInt() : 30;

    return AssociationOverviewRow(
      theme: theme,
      associationId: scope.associationId,
      days: days,
    );
  }

  @override
  Widget buildSettingsPanel(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    ValueChanged<Map<String, dynamic>> onSettingsChanged,
  ) =>
      AssociationOverviewSettingsPanel(
        settings: instance.settings,
        onSettingsChanged: onSettingsChanged,
      );
}

// ---------------------------------------------------------------------------
// Association Announcements
// ---------------------------------------------------------------------------

class AssociationAnnouncementsWidgetSpec extends DashboardWidgetSpec {
  const AssociationAnnouncementsWidgetSpec();

  @override
  String get type => 'association_announcements';

  @override
  String get title => 'Announcements';

  @override
  IconData get icon => Icons.campaign_rounded;

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) =>
      switch (breakpoint) {
        DashboardBreakpoint.desktop => const DashboardGridSize(w: 4, h: 4),
        DashboardBreakpoint.tablet  => const DashboardGridSize(w: 4, h: 4),
        DashboardBreakpoint.mobile  => const DashboardGridSize(w: 4, h: 4),
      };

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 2, maxW: 8, minH: 3, maxH: 8,
      );

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
  ) {
    final theme = ref.watch(themeColorsProvider);
    final scope = ref.watch(associationDashboardScopeProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final rawHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 420.0;
        final height = rawHeight < 260 ? 260.0 : rawHeight;

        return DashboardNewsAndAnnouncements(
          theme: theme,
          associationId: scope.associationId,
          baseUrl: scope.baseUrl,
          height: height,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Association Membership Status
// ---------------------------------------------------------------------------

class AssociationMembershipStatusWidgetSpec extends DashboardWidgetSpec {
  const AssociationMembershipStatusWidgetSpec();

  @override
  String get type => 'association_membership_status';

  @override
  String get title => 'Membership Status';

  @override
  IconData get icon => Icons.badge_rounded;

  @override
  bool get hasSettings => true;

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) =>
      switch (breakpoint) {
        DashboardBreakpoint.desktop => const DashboardGridSize(w: 4, h: 4),
        DashboardBreakpoint.tablet  => const DashboardGridSize(w: 8, h: 4),
        DashboardBreakpoint.mobile  => const DashboardGridSize(w: 4, h: 5),
      };

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 2, maxW: 12, minH: 3, maxH: 10,
      );

  bool _bool(Map<String, dynamic> s, String key, {bool def = true}) {
    final raw = s[key];
    return raw is bool ? raw : def;
  }

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
  ) {
    final theme = ref.watch(themeColorsProvider);
    final scope = ref.watch(associationDashboardScopeProvider);
    final s = instance.settings;

    return LayoutBuilder(
      builder: (context, constraints) {
        final rawHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 520.0;
        final height = rawHeight < 320 ? 320.0 : rawHeight;

        return MembershipStatusSection(
          theme: theme,
          associationId: scope.associationId,
          height: height,
          showHeader: _bool(s, 'showHeader'),
          showPaymentsBanner: _bool(s, 'showPaymentsBanner'),
          showPagination: _bool(s, 'showPagination'),
          onManagePayments: () {},
          onViewDetails: (_) {},
          onEdit: (_) {},
          onSendInvoice: (_) {},
          onSendReminder: (_) {},
        );
      },
    );
  }

  @override
  Widget buildSettingsPanel(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    ValueChanged<Map<String, dynamic>> onSettingsChanged,
  ) =>
      AssociationMembershipStatusSettingsPanel(
        settings: instance.settings,
        onSettingsChanged: onSettingsChanged,
      );
}

// ---------------------------------------------------------------------------
// Association Loyalty
// ---------------------------------------------------------------------------

class AssociationLoyaltyWidgetSpec extends DashboardWidgetSpec {
  const AssociationLoyaltyWidgetSpec();

  @override
  String get type => 'association_loyalty';

  @override
  String get title => 'Loyalty';

  @override
  IconData get icon => Icons.military_tech_rounded;

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) =>
      switch (breakpoint) {
        DashboardBreakpoint.desktop => const DashboardGridSize(w: 4, h: 1),
        DashboardBreakpoint.tablet  => const DashboardGridSize(w: 4, h: 1),
        DashboardBreakpoint.mobile  => const DashboardGridSize(w: 4, h: 1),
      };

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 2, maxW: 4, minH: 1, maxH: 2,
      );

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
  ) =>
      _AssociationLoyaltyCard(instance: instance);
}

class _AssociationLoyaltyCard extends ConsumerWidget {
  final DashboardWidgetInstance instance;

  const _AssociationLoyaltyCard({required this.instance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final scope = ref.watch(associationDashboardScopeProvider);

    final rawProgramId = instance.settings['programId'];
    final programId = rawProgramId is num ? rawProgramId.toInt() : scope.loyaltyProgramId;

    final balanceAsync = ref.watch(
      balanceProv((programId: programId, baseUrl: scope.baseUrl)),
    );

    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        border: Border.all(color: theme.dashboardBoarder),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: balanceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, size: 16, color: theme.textColor.withAlpha(140)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'error_message'.trParams({'error': e.toString()}),
                  style: TextStyle(color: theme.textColor.withAlpha(160), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        data: (b) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.themeColor.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.military_tech_rounded, color: theme.themeColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.points.toString(),
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'points_label'.tr,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(140),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.themeColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: theme.themeColor.withAlpha(80), width: 0.5),
                    ),
                    child: Text(
                      b.tier,
                      style: TextStyle(
                        color: theme.themeColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (b.nextTier != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    color: theme.themeColor,
                    backgroundColor: theme.dashboardBoarder.withAlpha(80),
                    value: (b.progressPercent / 100).clamp(0.0, 1.0),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'next_threshold'.trParams({
                    'nextTier': b.nextTier ?? '',
                    'nextThreshold': b.nextThreshold.toString(),
                  }),
                  style: TextStyle(color: theme.textColor.withAlpha(140), fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
