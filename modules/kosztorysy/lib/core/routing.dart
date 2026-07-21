import 'package:core/kernel/kernel.dart' hide AppModule;
import 'package:core/shell/manager/bar_manager.dart';
import '../screens/list/kosztorysy_list_screen.dart';
import '../screens/detail/kosztorys_detail_screen.dart';

List<RouteSpec> kosztorysyRoutes() => [
  RouteSpec(
    '/kosztorysy',
    (context, params, data) => BarManager(appModule: AppModule.budkon, childPc: KosztorysyListScreen(
        budowaId: (data as Map<String, dynamic>?)?['budowaId'] as int?,
      ),
    ),
  ),
  RouteSpec(
    '/kosztorysy/:id',
    (context, params, data) => BarManager(appModule: AppModule.budkon, childPc: KosztorysDetailScreen(
        kosztorysId: int.tryParse(params['id'] ?? '') ?? 0,
      ),
    ),
  ),
];
