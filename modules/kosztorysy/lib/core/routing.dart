import 'package:core/kernel/kernel.dart' hide AppModule;
import '../screens/list/kosztorysy_list_screen.dart';
import '../screens/detail/kosztorys_detail_screen.dart';
import '../screens/form/kosztorys_form_screen.dart';
import '../data/models/kosztorys_model.dart';

List<RouteSpec> kosztorysyRoutes() => [
  RouteSpec(
    '/kosztorysy',
    (context, params, data) {
      final args = data as Map?;
      return KosztorysyListScreen(
        budowaId: args?['budowaId'] as int?,
      );
    },
  ),
  RouteSpec(
    '/kosztorysy/new',
    (context, params, data) {
      final args = data as Map?;
      return KosztorysFormScreen(
        defaultBudowaId: args?['budowaId'] as int?,
      );
    },
  ),
  RouteSpec(
    '/kosztorysy/:id',
    (context, params, data) => KosztorysDetailScreen(
      kosztorysId: int.tryParse(params['id'] ?? '') ?? 0,
    ),
  ),
  RouteSpec(
    '/kosztorysy/:id/edit',
    (context, params, data) => KosztorysFormScreen(
      existing: (data as Map<String, dynamic>?)?['existing'] as KosztorysListItemModel?,
    ),
  ),
];
