import 'package:core/kernel/kernel.dart' hide AppModule;
import '../screens/list/dziennik_list_screen.dart';
import '../screens/form/dziennik_form_screen.dart';
import '../screens/detail/dziennik_detail_screen.dart';
import '../screens/mapa/budowa_mapa_screen.dart';

List<RouteSpec> dziennikRoutes() => [
      RouteSpec(
        '/dziennik',
        (ctx, params, data) {
          final args = data as Map?;
          return DziennikListScreen(
            budowaId: int.tryParse(params['budowaId'] ?? '') ??
                args?['budowaId'] as int? ??
                0,
            budowaNazwa: args?['budowaNazwa'] as String? ?? 'Budowa',
          );
        },
      ),
      RouteSpec(
        '/dziennik/form',
        (ctx, params, data) {
          final args = data as Map?;
          return DziennikFormScreen(
            budowaId: args?['budowaId'] as int? ?? 0,
            budowaNazwa: args?['budowaNazwa'] as String? ?? 'Budowa',
            wpisId: args?['wpisId'] as int?,
          );
        },
      ),
      RouteSpec(
        '/dziennik/detail',
        (ctx, params, data) {
          final args = data as Map?;
          return DziennikDetailScreen(
            wpisId: args?['wpisId'] as int? ?? 0,
            budowaId: args?['budowaId'] as int? ?? 0,
            budowaNazwa: args?['budowaNazwa'] as String? ?? 'Budowa',
          );
        },
      ),
      RouteSpec(
        '/dziennik/mapa',
        (ctx, params, data) {
          final args = data as Map?;
          return BudowaMapaScreen(
            budowaId: args?['budowaId'] as int? ?? 0,
            budowaNazwa: args?['budowaNazwa'] as String? ?? 'Budowa',
          );
        },
      ),
    ];
