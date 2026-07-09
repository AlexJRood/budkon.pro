import 'package:core/kernel/kernel.dart';

List<DockContribution> przetargiDockItems() => [
  const DockContribution(
    id: 'przetargi-main',
    label: 'Przetargi',
    iconKey: 'search',
    route: '/przetargi',
    dock: 'budkon',
    section: DockSection.desktop,
    order: 25,
    requiresAuth: true,
  ),
];
