import 'package:core/kernel/kernel.dart' hide AppModule;
import 'package:core/shell/manager/bar_manager.dart';
import '../screens/lista/kontakty_list_screen.dart';
import '../screens/profil/kontrahent_profil_screen.dart';
import '../screens/form/kontrahent_form_screen.dart';

List<RouteSpec> kontaktyRoutes() => [
  RouteSpec(
    '/kontakty',
    (context, params, data) => BarManager(appModule: AppModule.budkon, childPc: const KontaktyListScreen()),
  ),
  RouteSpec(
    '/kontakty/nowy',
    (context, params, data) => BarManager(appModule: AppModule.budkon, childPc: const KontrahentFormScreen()),
  ),
  RouteSpec(
    '/kontakty/:id',
    (context, params, data) => BarManager(
      appModule: AppModule.budkon,
      childPc: KontrahentProfilScreen(kontrahentId: int.tryParse(params['id'] ?? '') ?? 0),
    ),
  ),
];
