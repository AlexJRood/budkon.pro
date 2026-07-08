import 'package:core/kernel/kernel.dart';
import '../screens/list/budowa_list_screen.dart';
import '../screens/detail/budowa_detail_screen.dart';

List<RouteSpec> budowaRoutes() => [
  RouteSpec(
    '/budowa',
    (context, params, data) => const BudowaListScreen(),
  ),
  RouteSpec(
    '/budowa/:id',
    (context, params, data) => BudowaDetailScreen(
      budowaId: int.tryParse(params['id'] ?? '') ?? 0,
    ),
  ),
];
