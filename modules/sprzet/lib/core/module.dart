import 'package:core/kernel/kernel.dart';
import '../screens/list/sprzet_list_screen.dart';
import '../screens/detail/sprzet_detail_screen.dart';
import '../screens/form/sprzet_form_screen.dart';

class SprzetModule extends AppModule {
  @override
  String get id => 'sprzet';

  @override
  List<DockContribution> dockItems() => [];

  @override
  Map<Pattern, dynamic Function(Object?, Object?, Object?)> routeMap() => {
        RegExp(r'^/budowy/(?<budowaId>\d+)/sprzet$'): (context, state, data) {
          final budowaId =
              int.tryParse((state as dynamic).pathParameters['budowaId'] ?? '') ?? 0;
          final extra = data as Map<String, dynamic>? ?? {};
          return SprzetListScreen(
            budowaId: budowaId,
            budowaNazwa: extra['nazwa'],
          );
        },
        RegExp(r'^/sprzet$'): (context, state, data) =>
            const SprzetListScreen(),
        RegExp(r'^/sprzet/(?<id>\d+)$'): (context, state, data) {
          final id =
              int.tryParse((state as dynamic).pathParameters['id'] ?? '') ?? 0;
          return SprzetDetailScreen(sprzetId: id);
        },
        RegExp(r'^/sprzet/nowy$'): (context, state, data) {
          final budowaId = data as int?;
          return SprzetFormScreen(budowaId: budowaId);
        },
      };

  @override
  Future<void> init(ModuleScope scope) async {}
}
