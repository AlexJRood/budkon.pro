import 'package:core/kernel/kernel.dart' hide AppModule;
import 'package:core/shell/manager/bar_manager.dart';
import '../screens/lista/materialy_list_screen.dart';
import '../screens/historia_cen/historia_cen_screen.dart';

List<RouteSpec> materialyRoutes() => [
  RouteSpec(
    '/materialy',
    (ctx, params, data) {
      final args = data as Map?;
      return BarManager(appModule: AppModule.budkon, childPc: MaterialyListScreen(
          budowaId: int.tryParse(params['budowaId'] ?? '') ??
              args?['budowaId'] as int? ??
              0,
          budowaNazwa: args?['budowaNazwa'] as String? ?? 'Budowa',
        ),
      );
    },
  ),
  RouteSpec(
    '/materialy/trendy',
    (ctx, params, data) => BarManager(appModule: AppModule.budkon, childPc: TrendyCenScreen()),
  ),
];
