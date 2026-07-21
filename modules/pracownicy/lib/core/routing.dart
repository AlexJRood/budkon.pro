import 'package:core/kernel/kernel.dart' hide AppModule;
import 'package:core/shell/manager/bar_manager.dart';
import '../screens/lista/pracownicy_list_screen.dart';
import '../screens/profil/pracownik_profil_screen.dart';
import '../screens/umiejetnosci/nowy_pracownik_screen.dart';

List<RouteSpec> pracownicyRoutes() => [
  RouteSpec(
    '/pracownicy',
    (context, params, data) => BarManager(appModule: AppModule.budkon, childPc: const PracownicyListScreen()),
  ),
  RouteSpec(
    '/pracownicy/nowy',
    (context, params, data) => BarManager(appModule: AppModule.budkon, childPc: const NowyPracownikScreen()),
  ),
  RouteSpec(
    '/pracownicy/:id',
    (context, params, data) => BarManager(
      appModule: AppModule.budkon,
      childPc: PracownikProfilScreen(pracownikId: int.tryParse(params['id'] ?? '') ?? 0),
    ),
  ),
];
