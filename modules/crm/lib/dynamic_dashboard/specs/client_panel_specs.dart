import 'package:crm/contact_panel/mobile/new_client_card_mobile.dart';
import 'package:crm/contact_panel/mobile/new_client_details_mobile.dart';
import 'package:crm/contact_panel/panel_scope.dart';
import 'package:crm/contact_panel/tabs/dashboard/widgets/new_client_details.dart';
import 'package:crm/contact_panel/tabs/dashboard/widgets/new_client_photo_card.dart';
import 'package:crm/contact_panel/tabs/dashboard/widgets/new_client_todo.dart';
import 'package:crm/contact_panel/tabs/dashboard/widgets/new_client_transaction.dart';
import 'package:crm/dynamic_dashboard/models/dashboard_models.dart';
import 'package:crm/dynamic_dashboard/registry/dashboard_widget_spec.dart';
import 'package:crm/dynamic_dashboard/widgets/client_events_dashboard_widget.dart';
import 'package:crm/dynamic_dashboard/widgets/dashboard_widget_settings_panels.dart';
import 'package:core/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

List<DashboardWidgetSpec> clientPanelDashboardSpecs() => const [
      ClientProfileWidgetSpec(),
      ClientDetailsWidgetSpec(),
      ClientEventsWidgetSpec(),
      ClientTransactionsWidgetSpec(),
      ClientTodoWidgetSpec(),
    ];

// ---------------------------------------------------------------------------
// Client Profile
// ---------------------------------------------------------------------------

class ClientProfileWidgetSpec extends DashboardWidgetSpec {
  const ClientProfileWidgetSpec();

  @override
  String get type => 'client_profile';

  @override
  String get title => 'Client Profile';

  @override
  IconData get icon => Icons.perm_identity_rounded;

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) =>
      switch (breakpoint) {
        DashboardBreakpoint.desktop => const DashboardGridSize(w: 8, h: 2),
        DashboardBreakpoint.tablet  => const DashboardGridSize(w: 8, h: 2),
        DashboardBreakpoint.mobile  => const DashboardGridSize(w: 4, h: 3),
      };

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 3, maxW: 12, minH: 2, maxH: 4,
      );

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
  ) {
    final scope = ref.watch(clientDashboardScopeProvider);
    final client = scope.clientViewPop;

    if (breakpoint == DashboardBreakpoint.mobile) {
      return NewClientCardMobile(
        onTap: () {},
        id: client.id,
        avatar: client.avatar ?? '',
        name: client.name ?? '',
        lastName: client.lastName ?? '',
        email: client.email ?? '',
        phoneNumber: client.phoneNumber ?? '',
      );
    }

    return ClientPhotowidget(clientViewPop: client);
  }
}

// ---------------------------------------------------------------------------
// Client Details
// ---------------------------------------------------------------------------

class ClientDetailsWidgetSpec extends DashboardWidgetSpec {
  const ClientDetailsWidgetSpec();

  @override
  String get type => 'client_details';

  @override
  String get title => 'Client Details';

  @override
  IconData get icon => Icons.badge_rounded;

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) =>
      switch (breakpoint) {
        DashboardBreakpoint.desktop => const DashboardGridSize(w: 3, h: 3),
        DashboardBreakpoint.tablet  => const DashboardGridSize(w: 8, h: 3),
        DashboardBreakpoint.mobile  => const DashboardGridSize(w: 4, h: 3),
      };

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 3, maxW: 12, minH: 2, maxH: 5,
      );

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
  ) {
    final scope = ref.watch(clientDashboardScopeProvider);
    final clientIdRaw = scope.clientViewPop.id;

    if (breakpoint == DashboardBreakpoint.mobile) {
      return NewClientDetailsMobile(clientId: clientIdRaw);
    }

    return NewClientDetails(clientId: clientIdRaw);
  }
}

// ---------------------------------------------------------------------------
// Client Events
// ---------------------------------------------------------------------------

class ClientEventsWidgetSpec extends DashboardWidgetSpec {
  const ClientEventsWidgetSpec();

  @override
  String get type => 'client_events';

  @override
  String get title => 'Client Events';

  @override
  IconData get icon => Icons.event_note_rounded;

  @override
  bool get hasSettings => true;

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) =>
      switch (breakpoint) {
        DashboardBreakpoint.desktop => const DashboardGridSize(w: 5, h: 3),
        DashboardBreakpoint.tablet  => const DashboardGridSize(w: 8, h: 3),
        DashboardBreakpoint.mobile  => const DashboardGridSize(w: 4, h: 4),
      };

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 3, maxW: 12, minH: 3, maxH: 6,
      );

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
  ) {
    final scope = ref.watch(clientDashboardScopeProvider);
    final s = instance.settings;

    return DashboardClientEventsWidget(
      clientId: scope.clientId,
      isMobile: breakpoint == DashboardBreakpoint.mobile,
      layout: (s['layout'] ?? 'both').toString(),
      backgroundMode: (s['backgroundMode'] ?? 'card').toString(),
      showHeader: s['showHeader'] is bool ? s['showHeader'] as bool : true,
      compact: s['compact'] is bool ? s['compact'] as bool : false,
      isEditMode: isEditMode,
    );
  }

  @override
  Widget buildSettingsPanel(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    ValueChanged<Map<String, dynamic>> onSettingsChanged,
  ) =>
      ClientEventsSettingsPanel(
        settings: instance.settings,
        onSettingsChanged: onSettingsChanged,
      );
}

// ---------------------------------------------------------------------------
// Client Transactions
// ---------------------------------------------------------------------------

class ClientTransactionsWidgetSpec extends DashboardWidgetSpec {
  const ClientTransactionsWidgetSpec();

  @override
  String get type => 'client_transactions';

  @override
  String get title => 'Client Transactions';

  @override
  IconData get icon => Icons.receipt_long_rounded;

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) =>
      switch (breakpoint) {
        DashboardBreakpoint.desktop => const DashboardGridSize(w: 8, h: 4),
        DashboardBreakpoint.tablet  => const DashboardGridSize(w: 8, h: 4),
        DashboardBreakpoint.mobile  => const DashboardGridSize(w: 4, h: 5),
      };

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 4, maxW: 12, minH: 3, maxH: 8,
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
    final scope = ref.watch(clientDashboardScopeProvider);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: theme.dashboardBoarder),
        color: theme.dashboardContainer,
      ),
      child: NewClientTransaction(
        isMobile: breakpoint == DashboardBreakpoint.mobile,
        clientId: scope.clientId,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Client To-Do
// ---------------------------------------------------------------------------

class ClientTodoWidgetSpec extends DashboardWidgetSpec {
  const ClientTodoWidgetSpec();

  @override
  String get type => 'client_todo';

  @override
  String get title => 'Client To-Do';

  @override
  IconData get icon => Icons.fact_check_rounded;

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) =>
      switch (breakpoint) {
        DashboardBreakpoint.desktop => const DashboardGridSize(w: 4, h: 6),
        DashboardBreakpoint.tablet  => const DashboardGridSize(w: 8, h: 4),
        DashboardBreakpoint.mobile  => const DashboardGridSize(w: 4, h: 4),
      };

  @override
  DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
        minW: 3, maxW: 12, minH: 3, maxH: 10,
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
    final scope = ref.watch(clientDashboardScopeProvider);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: theme.dashboardBoarder),
        color: theme.dashboardContainer,
      ),
      child: NewClientTodo(clientId: scope.clientId),
    );
  }
}
