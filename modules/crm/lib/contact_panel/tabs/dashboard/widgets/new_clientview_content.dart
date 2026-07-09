import 'package:crm/shared/models/clients_model.dart';
import 'package:crm/contact_panel/panel_scope.dart';
import 'package:crm/contact_panel/navigation/enum.dart';
import 'package:crm/contact_panel/data/client_view_db_calendar_provider.dart';
import 'package:crm/dynamic_dashboard/dynamic_dashboard_page.dart';
import 'package:crm/dynamic_dashboard/widgets/dashboard_vertical_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClientDashboardSection extends StatelessWidget {
  const ClientDashboardSection({
    super.key,
    required this.clientViewPop,
    this.contactType = ContactType.client,
  });

  final UserContactModel clientViewPop;
  final ContactType contactType;

  @override
  Widget build(BuildContext context) {
    final clientId = clientViewPop.id.toString();

    final dashboardKey = contactPanelDashboardKeyForContactType(contactType);
    final panelMode = contactPanelModeForContactType(contactType);

    return ProviderScope(
      overrides: [
        clientDashboardScopeProvider.overrideWithValue(
          ClientDashboardScope(
            clientViewPop: clientViewPop,
            clientId: clientId,
            contactType: contactType,
            panelMode: panelMode,
          ),
        ),
      ],
      child: _ClientDashboardBootstrap(
        clientId: clientId,
        contactType: contactType,
        child: Stack(
          children: [
            Positioned.fill(
              child: DynamicDashboardPage(
                dashboardKey: dashboardKey,
                useShellSpacing: false,
              ),
            ),
            _ClientDashboardFloatingControls(
              dashboardKey: dashboardKey,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientDashboardBootstrap extends ConsumerStatefulWidget {
  const _ClientDashboardBootstrap({
    required this.clientId,
    required this.contactType,
    required this.child,
  });

  final String clientId;
  final ContactType contactType;
  final Widget child;

  @override
  ConsumerState<_ClientDashboardBootstrap> createState() =>
      _ClientDashboardBootstrapState();
}

class _ClientDashboardBootstrapState
    extends ConsumerState<_ClientDashboardBootstrap> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void didUpdateWidget(covariant _ClientDashboardBootstrap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final clientChanged = oldWidget.clientId != widget.clientId;
    final modeChanged = oldWidget.contactType != widget.contactType;

    if (clientChanged || modeChanged) {
      Future.microtask(_load);
    }
  }

  void _load() {
    if (!mounted) return;

    // crm-user nie powinien odpalać providerów typowo klientowych,
    // chyba że backendowo świadomie używasz tych samych endpointów.
    if (widget.contactType == ContactType.crmUser) {
      return;
    }

    ref
        .read(calendarTransActionByClientProvider.notifier)
        .getTransActionByClient(widget.clientId);

    ref
        .read(filterTaskByClientProvider.notifier)
        .filterTaskByClient(widget.clientId);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _ClientDashboardFloatingControls extends StatelessWidget {
  const _ClientDashboardFloatingControls({
    required this.dashboardKey,
  });

  final String dashboardKey;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 10,
      right: 10,
      child: SafeArea(
        child: DashboardVerticalBar(
          dashboardKey: dashboardKey,
        ),
      ),
    );
  }
}