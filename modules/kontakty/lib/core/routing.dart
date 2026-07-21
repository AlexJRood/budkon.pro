import 'package:core/kernel/kernel.dart' hide AppModule;
import '../data/models/kontakty_model.dart';
import '../screens/lista/kontakty_list_screen.dart';
import '../screens/profil/kontrahent_profil_screen.dart';
import '../screens/form/kontrahent_form_screen.dart';

List<RouteSpec> kontaktyRoutes() => [
  RouteSpec(
    '/kontakty',
    (context, params, data) => const KontaktyListScreen(),
  ),
  RouteSpec(
    '/kontakty/nowy',
    (context, params, data) => const KontrahentFormScreen(),
  ),
  RouteSpec(
    '/kontakty/:id',
    (context, params, data) => KontrahentProfilScreen(
      kontrahentId: int.tryParse(params['id'] ?? '') ?? 0,
    ),
  ),
  RouteSpec(
    '/kontakty/:id/edit',
    (context, params, data) => KontrahentFormScreen(
      existing: (data as Map<String, dynamic>?)?['existing'] as KontrahentDetail?,
    ),
  ),
];
