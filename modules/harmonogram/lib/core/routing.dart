import 'package:core/kernel/kernel.dart' hide AppModule;
import '../screens/timeline/harmonogram_screen.dart';
import '../screens/zadanie/zadanie_detail_screen.dart';
import '../screens/zadanie/zadanie_form_screen.dart';

List<RouteSpec> harmonogramRoutes() => [
  RouteSpec(
    '/harmonogram',
    (ctx, params, data) {
      final args = data as Map?;
      return HarmonogramScreen(
        budowaId: int.tryParse(params['budowaId'] ?? '') ??
            args?['budowaId'] as int? ??
            0,
        budowaNazwa: args?['budowaNazwa'] as String? ?? 'Budowa',
      );
    },
  ),
  RouteSpec(
    '/harmonogram/zadanie',
    (ctx, params, data) {
      final args = data as Map?;
      return ZadanieDetailScreen(
        zadanieId: args?['zadanieId'] as int? ?? 0,
        budowaId: args?['budowaId'] as int? ?? 0,
      );
    },
  ),
  RouteSpec(
    '/harmonogram/zadanie/form',
    (ctx, params, data) {
      final args = data as Map?;
      return ZadanieFormScreen(
        budowaId: args?['budowaId'] as int? ?? 0,
        budowaNazwa: args?['budowaNazwa'] as String? ?? 'Budowa',
        zadanieId: args?['zadanieId'] as int?,
        etapId: args?['etapId'] as int?,
      );
    },
  ),
];
