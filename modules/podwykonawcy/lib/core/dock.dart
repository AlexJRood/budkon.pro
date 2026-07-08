import 'package:core/kernel/kernel.dart';

List<DockContribution> podwykonawcyDockItems() => [
  const DockContribution(
    id: 'podwykonawcy-main',
    label: 'Podwykonawcy',
    iconKey: 'groups',
    route: '/podwykonawcy',
    dock: 'budkon',
    section: DockSection.desktop,
    order: 60,
    requiresAuth: true,
  ),
];
