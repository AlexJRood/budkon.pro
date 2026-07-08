import 'package:core/kernel/kernel.dart';

List<DockContribution> kosztorysyDockItems() => [
  const DockContribution(
    id: 'kosztorysy-main',
    label: 'Kosztorysy',
    iconKey: 'receipt',
    route: '/kosztorysy',
    dock: 'budkon',
    section: DockSection.desktop,
    order: 20,
    requiresAuth: true,
  ),
];
