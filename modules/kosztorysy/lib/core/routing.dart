import 'package:core/kernel/kernel.dart';
import '../screens/list/kosztorysy_list_screen.dart';
import '../screens/detail/kosztorys_detail_screen.dart';

List<RouteSpec> kosztorysyRoutes() => [
  RouteSpec(
    '/kosztorysy',
    (context, params, data) => KosztorysyListScreen(
      budowaId: data?['budowaId'] as int?,
    ),
  ),
  RouteSpec(
    '/kosztorysy/:id',
    (context, params, data) => KosztorysDetailScreen(
      kosztorysId: int.tryParse(params['id'] ?? '') ?? 0,
    ),
  ),
];
