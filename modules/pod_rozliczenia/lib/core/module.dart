import 'package:core/kernel/kernel.dart';
import '../screens/pod_rozliczenia_screen.dart';

class PodRozliczeniaModule extends AppModule {
  @override
  String get id => 'pod_rozliczenia';

  @override
  List<DockContribution> dockItems() => [];

  @override
  Map<Pattern, dynamic Function(Object?, Object?, Object?)> routeMap() => {
        RegExp(r'^/budowy/(?<budowaId>\d+)/pod-rozliczenia$'): (ctx, state, data) {
          final budowaId =
              int.tryParse((state as dynamic).pathParameters['budowaId'] ?? '') ?? 0;
          final extra = data as Map<String, dynamic>? ?? {};
          return PodRozliczeniaScreen(
            budowaId: budowaId,
            budowaNazwa: extra['nazwa'] ?? '',
          );
        },
      };

  @override
  Future<void> init(ModuleScope scope) async {}
}
