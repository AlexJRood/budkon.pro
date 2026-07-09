import 'package:go_router/go_router.dart';
import '../screens/lista/kontakty_list_screen.dart';
import '../screens/profil/kontrahent_profil_screen.dart';
import '../screens/form/kontrahent_form_screen.dart';

List<RouteBase> kontaktyRoutes = [
  GoRoute(
    path: '/kontakty',
    builder: (_, __) => const KontaktyListScreen(),
    routes: [
      GoRoute(
        path: 'nowy',
        builder: (_, __) => const KontrahentFormScreen(),
      ),
      GoRoute(
        path: ':id',
        builder: (_, state) => KontrahentProfilScreen(
            kontrahentId: int.parse(state.pathParameters['id']!)),
      ),
    ],
  ),
];
