import 'package:core/kernel/kernel.dart';

List<DockContribution> pracownicyDockItems() => [
  const DockContribution(
    id: 'pracownicy-main',
    label: 'Zespol',
    iconKey: 'group',
    route: '/pracownicy',
    dock: 'budkon',
    section: DockSection.center,
    order: 80,
    requiresAuth: true,
  ),
];
