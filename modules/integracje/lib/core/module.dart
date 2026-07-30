import 'package:core/kernel/kernel.dart';
import '../screens/integracje_screen.dart';

class IntegracjeModule extends AppModule {
  @override
  String get id => 'integracje';

  @override
  List<RouteSpec> routes() => [
        RouteSpec('/integracje', (context, params, data) => const IntegracjeScreen()),
      ];

  @override
  List<DockContribution> dockItems() => [
        const DockContribution(
          id: 'integracje-main',
          label: 'Integracje',
          iconKey: 'grid',
          route: '/integracje',
          dock: 'budkon',
          section: DockSection.center,
          order: 70,
          requiresAuth: true,
        ),
      ];
}
