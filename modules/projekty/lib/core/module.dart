import 'package:core/kernel/kernel.dart';
import '../screens/list/projekty_list_screen.dart';
import '../screens/detail/projekt_detail_screen.dart';
import '../screens/upload/projekt_upload_screen.dart';

class ProjektyModule extends AppModule {
  @override
  String get id => 'projekty';

  @override
  List<DockContribution> dockItems() => [
        const DockContribution(
          id: 'projekty-main',
          label: 'Projekty',
          iconKey: 'document',
          route: '/projekty',
          dock: 'budkon',
          section: DockSection.center,
          order: 15,
          requiresAuth: true,
        ),
      ];

  @override
  Map<Pattern, BeamRouteBuilder> routeMap() => {
        '/projekty': (context, state, data) => const ProjektyListScreen(),
        '/projekty/upload': (context, state, data) =>
            const ProjektUploadScreen(),
        RegExp(r'^/projekty/(?!upload$)(?<id>[^/]+)$'): (context, state, data) =>
            ProjektDetailScreen(
              projektId: state.pathParameters['id'] ?? '',
            ),
      };

  @override
  Future<void> init(ModuleScope scope) async {}
}
