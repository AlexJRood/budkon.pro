import 'package:core/kernel/kernel.dart';

List<DockContribution> dziennikDockItems() => [
  const DockContribution(
    id: 'dziennik-main',
    label: 'Dziennik',
    iconKey: 'menu_book',
    route: '/dziennik',
    dock: 'budkon',
    section: DockSection.center,
    order: 70,
    requiresAuth: true,
  ),
];

