import 'package:core/kernel/kernel.dart';

List<DockContribution> harmonogramDockItems() => [
  const DockContribution(
    id: 'harmonogram-main',
    label: 'Harmonogram',
    iconKey: 'calendar_month',
    route: '/harmonogram',
    dock: 'budkon',
    section: DockSection.desktop,
    order: 40,
    requiresAuth: true,
  ),
];
