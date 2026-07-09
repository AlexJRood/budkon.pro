import 'package:go_router/go_router.dart';
import '../screens/lista/faktury_list_screen.dart';
import '../screens/detail/faktura_detail_screen.dart';
import '../screens/form/faktura_form_screen.dart';

List<RouteBase> fakturyRoutes = [
  GoRoute(
    path: '/faktury',
    builder: (_, __) => const FakturyListScreen(),
    routes: [
      GoRoute(
        path: 'nowa',
        builder: (_, __) => const FakturaFormScreen(),
      ),
      GoRoute(
        path: ':id',
        builder: (_, state) => FakturaDetailScreen(
            fakturaId: int.parse(state.pathParameters['id']!)),
      ),
    ],
  ),
];
