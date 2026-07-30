import 'package:core/kernel/kernel.dart';
import '../screens/analytics_screen.dart';

class AnalyticsModule extends AppModule {
  @override
  String get id => 'analytics';

  @override
  List<RouteSpec> routes() => [
        RouteSpec('/analytics', (context, params, data) => const AnalyticsScreen()),
      ];

  @override
  List<DockContribution> dockItems() => [
        const DockContribution(
          id: 'analytics-main',
          label: 'Analytics',
          iconKey: 'trend',
          route: '/analytics',
          dock: 'budkon',
          section: DockSection.center,
          order: 60,
          requiresAuth: true,
        ),
      ];
}
