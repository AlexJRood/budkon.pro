import 'package:core/kernel/kernel.dart' hide AppModule;
import '../screens/lista/pracownicy_list_screen.dart';
import '../screens/profil/pracownik_profil_screen.dart';
import '../screens/umiejetnosci/nowy_pracownik_screen.dart';

List<RouteSpec> pracownicyRoutes() => [
  RouteSpec(
    '/pracownicy',
    (context, params, data) => const PracownicyListScreen(),
  ),
  RouteSpec(
    '/pracownicy/nowy',
    (context, params, data) => const NowyPracownikScreen(),
  ),
  RouteSpec(
    '/pracownicy/:id',
    (context, params, data) => PracownikProfilScreen(
      pracownikId: int.tryParse(params['id'] ?? '') ?? 0,
    ),
  ),
];
