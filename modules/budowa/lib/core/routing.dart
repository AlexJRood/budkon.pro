import 'package:core/kernel/kernel.dart' hide AppModule;
import '../screens/list/budowa_list_screen.dart';
import '../screens/detail/budowa_detail_screen.dart';
import '../screens/form/budowa_form_screen.dart';
import '../data/models/budowa_model.dart';

List<RouteSpec> budowaRoutes() => [
  RouteSpec('/budowa', (context, params, data) => const BudowaListScreen()),
  RouteSpec('/budowa/new', (context, params, data) => const BudowaFormScreen()),
  RouteSpec(
    '/budowa/:id',
    (context, params, data) => BudowaDetailScreen(
      budowaId: int.tryParse(params['id'] ?? '') ?? 0,
    ),
  ),
  RouteSpec(
    '/budowa/:id/edit',
    (context, params, data) => BudowaFormScreen(
      existing: (data as Map<String, dynamic>?)?['existing'] as BudowaModel?,
    ),
  ),
];
