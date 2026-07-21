import 'package:core/kernel/kernel.dart' hide AppModule;
import '../data/models/podwykonawcy_model.dart';
import '../screens/list/podwykonawcy_list_screen.dart';
import '../screens/detail/kontrahent_detail_screen.dart';

List<RouteSpec> podwykonawcyRoutes() => [
  RouteSpec(
    '/podwykonawcy',
    (ctx, params, data) {
      final args = data as Map?;
      return PodwykonawcyListScreen(
        budowaId: int.tryParse(params['budowaId'] ?? '') ??
            args?['budowaId'] as int? ??
            0,
        budowaNazwa: args?['budowaNazwa'] as String? ?? 'Budowa',
      );
    },
  ),
  RouteSpec(
    '/podwykonawcy/detail',
    (ctx, params, data) {
      final args = data as Map?;
      return KontrahentDetailScreen(
        powiazanie: args?['powiazanie'] as PowiazanieModel,
        budowaId: args?['budowaId'] as int? ?? 0,
      );
    },
  ),
];
