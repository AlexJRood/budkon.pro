import 'package:core/kernel/kernel.dart' hide AppModule;

import '../screens/bzp_szukaj/bzp_szukaj_screen.dart';
import '../screens/detail/przetarg_detail_screen.dart';
import '../screens/list/przetargi_list_screen.dart';
import '../screens/subskrypcje/subskrypcje_screen.dart';

List<RouteSpec> przetargiRoutes() => [
  RouteSpec(
    '/przetargi',
    (context, params, data) => PrzetargiListScreen(),
  ),
  RouteSpec(
    '/przetargi/subskrypcje',
    (context, params, data) => SubskrypcjeScreen(),
  ),
  RouteSpec(
    '/przetargi/bzp-szukaj',
    (context, params, data) => BzpSzukajScreen(),
  ),
  RouteSpec(
    '/przetargi/:id',
    (context, params, data) => PrzetargDetailScreen(
      przetargId: int.tryParse(params['id'] ?? '') ?? 0,
    ),
  ),
];
