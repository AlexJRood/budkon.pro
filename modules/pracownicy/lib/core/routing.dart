import 'package:go_router/go_router.dart';
import '../screens/lista/pracownicy_list_screen.dart';
import '../screens/profil/pracownik_profil_screen.dart';
import '../screens/umiejetnosci/nowy_pracownik_screen.dart';

const _base = '/pracownicy';

List<RouteBase> pracownicyRoutes = [
  GoRoute(
    path: _base,
    builder: (_, __) => const PracownicyListScreen(),
    routes: [
      GoRoute(
        path: 'nowy',
        builder: (_, __) => const NowyPracownikScreen(),
      ),
      GoRoute(
        path: ':id',
        builder: (_, state) =>
            PracownikProfilScreen(pracownikId: int.parse(state.pathParameters['id']!)),
      ),
    ],
  ),
];
