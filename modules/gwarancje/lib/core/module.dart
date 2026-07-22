import 'package:core/kernel/kernel.dart';
import '../screens/gwarancje_screen.dart';

class GwarancjeModule extends AppModule {
  @override
  String get id => 'gwarancje';

  @override
  List<DockContribution> dockItems() => [];

  @override
  Map<Pattern, dynamic Function(Object?, Object?, Object?)> routeMap() => {
        RegExp(r'^/budowy/(?<budowaId>\d+)/gwarancje$'): (ctx, state, data) {
          final budowaId =
              int.tryParse((state as dynamic).pathParameters['budowaId'] ?? '') ?? 0;
          final extra = data as Map<String, dynamic>? ?? {};
          return GwarancjeScreen(
            budowaId: budowaId,
            budowaNazwa: extra['nazwa'] ?? '',
          );
        },
      };

  @override
  Future<void> init(ModuleScope scope) async {}
}
