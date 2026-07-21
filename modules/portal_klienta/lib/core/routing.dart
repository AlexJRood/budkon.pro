import 'package:core/kernel/kernel.dart' hide AppModule;
import '../screens/lista/portal_lista_screen.dart';
import '../screens/form/portal_form_screen.dart';

List<RouteSpec> portal_klientaRoutes() => [
  RouteSpec(
    '/budowy/:budowaId/portale',
    (context, params, data) => PortalListaScreen(
      budowaId: int.parse(params['budowaId'] ?? '0'),
      budowaNazwa: (data as Map<String, dynamic>?)?['budowaNazwa'] as String? ?? '',
    ),
  ),
  RouteSpec(
    '/budowy/:budowaId/portale/nowy',
    (context, params, data) => PortalFormScreen(
      budowaId: int.parse(params['budowaId'] ?? '0'),
    ),
  ),
];
