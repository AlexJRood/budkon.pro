import 'package:core/kernel/kernel.dart';

List<DockContribution> materialyDockItems() => [
  const DockContribution(
    id: 'materialy-main',
    label: 'Materialy',
    iconKey: 'inventory_2',
    route: '/materialy',
    dock: 'budkon',
    section: DockSection.center,
    order: 50,
    requiresAuth: true,
  ),
];

