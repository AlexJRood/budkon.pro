import 'package:core/kernel/kernel.dart';
import '../screens/dokumentacja_screen.dart';

class DokumentacjaModule extends AppModule {
  @override
  String get id => 'dokumentacja';

  @override
  List<DockContribution> dockItems() => [];

  @override
  Map<Pattern, dynamic Function(Object?, Object?, Object?)> routeMap() => {
        RegExp(r'^/budowy/(?<budowaId>\d+)/dokumentacja$'): (ctx, state, data) {
          final budowaId =
              int.tryParse((state as dynamic).pathParameters['budowaId'] ?? '') ?? 0;
          final extra = data as Map<String, dynamic>? ?? {};
          return DokumentacjaScreen(
            budowaId: budowaId,
            budowaNazwa: extra['nazwa'] ?? '',
          );
        },
      };

  @override
  Future<void> init(ModuleScope scope) async {}
}
