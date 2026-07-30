import 'package:core/kernel/kernel.dart';
import '../screens/ai_asystent_screen.dart';

class AiAsystentModule extends AppModule {
  @override
  String get id => 'ai_asystent';

  @override
  List<RouteSpec> routes() => [
        RouteSpec(
          '/budowy/:budowaId/ai-asystent',
          (context, params, data) => AiAsystentScreen(
            budowaId: int.tryParse(params['budowaId'] ?? '') ?? 0,
          ),
        ),
      ];

  @override
  List<DockContribution> dockItems() => const [];
}
