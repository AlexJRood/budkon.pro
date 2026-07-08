import 'package:core/kernel/kernel.dart';

List<DockContribution> dziennikDockItems() => [
  const DockContribution(
    id: 'dziennik-main',
    label: 'Dziennik',
    iconKey: 'menu_book',
    route: '/dziennik',
    dock: 'budkon',
    section: DockSection.desktop,
    order: 70,
    requiresAuth: true,
  ),
];
