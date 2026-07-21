import 'package:core/kernel/kernel.dart' hide AppModule;
import 'package:core/shell/manager/bar_manager.dart';
import 'package:flutter/material.dart';
import '../screens/lista/portal_lista_screen.dart';

List<RouteSpec> portal_klientaRoutes() => [
  RouteSpec(
    '/budowy/:budowaId/portale',
    (context, params, data) => BarManager(appModule: AppModule.budkon, childPc: PortalListaScreen(
        budowaId: int.parse(params['budowaId'] ?? '0'),
        budowaNazwa: (data as Map<String, dynamic>?)?['budowaNazwa'] as String? ?? '',
      ),
    ),
  ),
];
