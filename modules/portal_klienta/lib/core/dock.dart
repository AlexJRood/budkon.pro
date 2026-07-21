import 'package:core/kernel/kernel.dart';

List<DockContribution> portal_klientaDockItems() => [
  const DockContribution(
    id: 'portal_klienta-main',
    label: 'PortalKlienta',
    iconKey: 'person',
    route: '/portal_klienta',
    dock: 'budkon',
    section: DockSection.center,
    order: 80,
    requiresAuth: true,
  ),
];

