import 'package:beamer/beamer.dart';
import 'package:core/kernel/kernel.dart';
import '../data/models/budowa_model.dart';
import '../screens/list/budowa_list_screen.dart';
import '../screens/detail/budowa_detail_screen.dart';
import '../screens/form/budowa_form_screen.dart';
import 'dock.dart';

class BudowaModule extends AppModule {
  @override
  String get id => 'budowa';

  @override
  List<DockContribution> dockItems() => budowaDockItems();

  @override
  Map<Pattern, BeamRouteBuilder> routeMap() => {
        '/budowa': (context, state, data) => const BudowaListScreen(),
        '/budowa/new': (context, state, data) => const BudowaFormScreen(),
        RegExp(r'^/budowa/(?<id>\d+)$'): (context, state, data) =>
            BudowaDetailScreen(
              budowaId:
                  int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
        RegExp(r'^/budowa/(?<id>\d+)/edit$'): (context, state, data) =>
            BudowaFormScreen(
              existing: (data as Map<String, dynamic>?)?['existing']
                  as BudowaModel?,
            ),
      };

  @override
  Future<void> init(ModuleScope scope) async {}
}
