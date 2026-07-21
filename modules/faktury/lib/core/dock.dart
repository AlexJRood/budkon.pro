import 'package:core/kernel/kernel.dart';

List<DockContribution> fakturyDockItems() => [
  const DockContribution(
    id: 'faktury-main',
    label: 'Faktury',
    iconKey: 'receipt',
    route: '/faktury',
    dock: 'budkon',
    section: DockSection.center,
    order: 60,
    requiresAuth: true,
  ),
];
