import 'package:core/kernel/kernel.dart' hide AppModule;
import 'package:core/shell/manager/bar_manager.dart';
import '../screens/lista/faktury_list_screen.dart';
import '../screens/detail/faktura_detail_screen.dart';
import '../screens/form/faktura_form_screen.dart';

List<RouteSpec> fakturyRoutes() => [
  RouteSpec(
    '/faktury',
    (context, params, data) => BarManager(appModule: AppModule.budkon, childPc: const FakturyListScreen()),
  ),
  RouteSpec(
    '/faktury/nowa',
    (context, params, data) => BarManager(appModule: AppModule.budkon, childPc: const FakturaFormScreen()),
  ),
  RouteSpec(
    '/faktury/:id',
    (context, params, data) => BarManager(
      appModule: AppModule.budkon,
      childPc: FakturaDetailScreen(fakturaId: int.tryParse(params['id'] ?? '') ?? 0),
    ),
  ),
];
