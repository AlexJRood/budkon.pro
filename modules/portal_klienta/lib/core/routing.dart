import 'package:core/kernel/kernel.dart';
import 'package:flutter/material.dart';
import '../screens/lista/portal_lista_screen.dart';

List<RouteSpec> portal_klientaRoutes() => [
  RouteSpec(
    '/budowy/:budowaId/portale',
    (context, params, data) => PortalListaScreen(
      budowaId: int.parse(params['budowaId'] ?? '0'),
      budowaNazwa: data?['budowaNazwa'] as String? ?? '',
    ),
  ),
];
