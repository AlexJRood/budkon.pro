import 'package:core/kernel/kernel.dart' hide AppModule;
import '../data/models/materialy_model.dart';
import '../screens/lista/materialy_list_screen.dart';
import '../screens/historia_cen/historia_cen_screen.dart';

List<RouteSpec> materialyRoutes() => [
  RouteSpec(
    '/materialy',
    (ctx, params, data) {
      final args = data as Map?;
      return MaterialyListScreen(
        budowaId: int.tryParse(params['budowaId'] ?? '') ??
            args?['budowaId'] as int? ??
            0,
        budowaNazwa: args?['budowaNazwa'] as String? ?? 'Budowa',
      );
    },
  ),
  RouteSpec(
    '/materialy/trendy',
    (ctx, params, data) => const TrendyCenScreen(),
  ),
  RouteSpec(
    '/materialy/historia',
    (ctx, params, data) {
      final args = data as Map?;
      return HistoriaCenScreen(material: args?['material'] as MaterialModel);
    },
  ),
];
