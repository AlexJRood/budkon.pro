import 'package:core/kernel/kernel.dart';

List<DockContribution> ofertyDockItems() => [
  const DockContribution(
    id: 'oferty-main',
    label: 'Oferty',
    iconKey: 'description',
    route: '/oferty',
    dock: 'budkon',
    section: DockSection.center,
    order: 30,
    requiresAuth: true,
  ),
];

