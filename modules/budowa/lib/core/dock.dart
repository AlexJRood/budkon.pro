import 'package:core/kernel/kernel.dart';

List<DockContribution> budowaDockItems() => [
  const DockContribution(
    id: 'budowa-main',
    label: 'Budowa',
    iconKey: 'building',
    route: '/budowa',
    dock: 'budkon',
    section: DockSection.desktop,
    order: 10,
    requiresAuth: true,
  ),
];
