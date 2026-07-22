import 'package:core/kernel/kernel.dart';
import '../screens/list/magazyn_list_screen.dart';
import '../screens/detail/pozycja_detail_screen.dart';
import '../screens/form/pozycja_form_screen.dart';

class MagazynModule extends AppModule {
  @override
  String get id => 'magazyn';

  @override
  List<DockContribution> dockItems() => [];

  @override
  Map<Pattern, dynamic Function(Object?, Object?, Object?)> routeMap() => {
        RegExp(r'^/budowy/(?<budowaId>\d+)/magazyn$'):
            (context, state, data) {
          final budowaId =
              int.tryParse((state as dynamic).pathParameters['budowaId'] ?? '') ?? 0;
          final extra = data as Map<String, dynamic>? ?? {};
          return MagazynListScreen(
            budowaId: budowaId,
            budowaNazwa: extra['nazwa'] ?? '',
          );
        },
        RegExp(r'^/magazyn/pozycja/(?<id>\d+)$'):
            (context, state, data) {
          final id =
              int.tryParse((state as dynamic).pathParameters['id'] ?? '') ?? 0;
          return PozycjaDetailScreen(pozycjaId: id);
        },
        RegExp(r'^/magazyn/(?<budowaId>\d+)/nowa-pozycja$'):
            (context, state, data) {
          final budowaId =
              int.tryParse((state as dynamic).pathParameters['budowaId'] ?? '') ?? 0;
          return PozycjaFormScreen(budowaId: budowaId);
        },
      };

  @override
  Future<void> init(ModuleScope scope) async {}
}
