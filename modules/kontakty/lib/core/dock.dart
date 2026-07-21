import 'package:core/kernel/kernel.dart';

List<DockContribution> kontaktyDockItems() => [
  const DockContribution(
    id: 'kontakty-main',
    label: 'Kontakty',
    iconKey: 'contacts',
    route: '/kontakty',
    dock: 'budkon',
    section: DockSection.center,
    order: 70,
    requiresAuth: true,
  ),
];
