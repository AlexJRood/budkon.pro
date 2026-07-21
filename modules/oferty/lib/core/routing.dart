import 'package:core/kernel/kernel.dart' hide AppModule;
import 'package:core/shell/manager/bar_manager.dart';
import '../screens/lista/oferty_list_screen.dart';
import '../screens/podglad/oferta_detail_screen.dart';
import '../screens/formularz/oferta_formularz_screen.dart';

List<RouteSpec> ofertyRoutes() => [
  RouteSpec(
    '/oferty',
    (ctx, params, data) {
      final args = data as Map?;
      return BarManager(appModule: AppModule.budkon, childPc: OfertyListScreen(
          budowaId: int.tryParse(params['budowaId'] ?? '') ??
              args?['budowaId'] as int?,
          budowaNazwa: args?['budowaNazwa'] as String? ?? 'Wszystkie oferty',
        ),
      );
    },
  ),
  RouteSpec(
    '/oferty/new',
    (ctx, params, data) {
      final args = data as Map?;
      return BarManager(appModule: AppModule.budkon, childPc: OfertyFormularzScreen(
          budowaId: args?['budowaId'] as int?,
          budowaNazwa: args?['budowaNazwa'] as String? ?? '',
          kosztorysId: args?['kosztorysId'] as int?,
        ),
      );
    },
  ),
  RouteSpec(
    '/oferty/detail',
    (ctx, params, data) {
      final args = data as Map?;
      final id = int.tryParse(params['id'] ?? '') ??
          args?['ofertaId'] as int? ?? 0;
      return BarManager(appModule: AppModule.budkon, childPc: OfertyDetailScreen(ofertaId: id));
    },
  ),
];
