import 'package:core/kernel/kernel.dart' hide AppModule;
import 'package:core/shell/manager/bar_manager.dart';
import '../screens/list/budowa_list_screen.dart';
import '../screens/detail/budowa_detail_screen.dart';

List<RouteSpec> budowaRoutes() => [
  RouteSpec(
    '/budowa',
    (context, params, data) => BarManager(
      appModule: AppModule.budkon,
      childPc: const BudowaListScreen(),
    ),
  ),
  RouteSpec(
    '/budowa/:id',
    (context, params, data) => BarManager(
      appModule: AppModule.budkon,
      childPc: BudowaDetailScreen(
        budowaId: int.tryParse(params['id'] ?? '') ?? 0,
      ),
    ),
  ),
];
