import 'package:core/kernel/kernel.dart' hide AppModule;
import 'package:core/shell/manager/bar_manager.dart';
import '../screens/list/dziennik_list_screen.dart';
import '../screens/form/dziennik_form_screen.dart';
import '../screens/detail/dziennik_detail_screen.dart';
import '../screens/mapa/budowa_mapa_screen.dart';

List<RouteSpec> dziennikRoutes() => [
      RouteSpec(
        '/dziennik',
        (ctx, params, data) {
          final args = data as Map?;
          return BarManager(appModule: AppModule.budkon, childPc: DziennikListScreen(
              budowaId: int.tryParse(params['budowaId'] ?? '') ??
                  args?['budowaId'] as int? ??
                  0,
              budowaNazwa: args?['budowaNazwa'] as String? ?? 'Budowa',
            ),
          );
        },
      ),
      RouteSpec(
        '/dziennik/form',
        (ctx, params, data) {
          final args = data as Map?;
          return BarManager(appModule: AppModule.budkon, childPc: DziennikFormScreen(
              budowaId: args?['budowaId'] as int? ?? 0,
              budowaNazwa: args?['budowaNazwa'] as String? ?? 'Budowa',
              wpisId: args?['wpisId'] as int?,
            ),
          );
        },
      ),
      RouteSpec(
        '/dziennik/detail',
        (ctx, params, data) {
          final args = data as Map?;
          return BarManager(appModule: AppModule.budkon, childPc: DziennikDetailScreen(
              wpisId: args?['wpisId'] as int? ?? 0,
              budowaId: args?['budowaId'] as int? ?? 0,
              budowaNazwa: args?['budowaNazwa'] as String? ?? 'Budowa',
            ),
          );
        },
      ),
      RouteSpec(
        '/dziennik/mapa',
        (ctx, params, data) {
          final args = data as Map?;
          return BarManager(appModule: AppModule.budkon, childPc: BudowaMapaScreen(
              budowaId: args?['budowaId'] as int? ?? 0,
              budowaNazwa: args?['budowaNazwa'] as String? ?? 'Budowa',
            ),
          );
        },
      ),
    ];
