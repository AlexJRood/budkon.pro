import 'package:core/kernel/kernel.dart' hide AppModule;
import '../screens/lista/faktury_list_screen.dart';
import '../screens/detail/faktura_detail_screen.dart';
import '../screens/form/faktura_form_screen.dart';

List<RouteSpec> fakturyRoutes() => [
  RouteSpec(
    '/faktury',
    (context, params, data) {
      final args = data as Map?;
      return FakturyListScreen(budowaId: args?['budowaId'] as int?);
    },
  ),
  RouteSpec(
    '/faktury/nowa',
    (context, params, data) {
      final args = data as Map?;
      return FakturaFormScreen(
        budowaId: args?['budowaId'] as int?,
        ofertaId: args?['ofertaId'] as int?,
      );
    },
  ),
  RouteSpec(
    '/faktury/:id',
    (context, params, data) => FakturaDetailScreen(
      fakturaId: int.tryParse(params['id'] ?? '') ?? 0,
    ),
  ),
];
