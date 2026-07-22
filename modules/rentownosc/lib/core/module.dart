import 'package:core/kernel/kernel.dart';
import '../screens/rentownosc_screen.dart';

class RentownoscModule extends AppModule {
  @override
  String get id => 'rentownosc';

  @override
  List<DockContribution> dockItems() => [];

  @override
  Map<Pattern, dynamic Function(Object?, Object?, Object?)> routeMap() => {
        RegExp(r'^/budowy/(?<budowaId>\d+)/rentownosc$'): (ctx, state, data) {
          final budowaId =
              int.tryParse((state as dynamic).pathParameters['budowaId'] ?? '') ?? 0;
          final extra = data as Map<String, dynamic>? ?? {};
          return RentownoscScreen(
            budowaId: budowaId,
            budowaNazwa: extra['nazwa'] ?? '',
          );
        },
      };

  @override
  Future<void> init(ModuleScope scope) async {}
}
