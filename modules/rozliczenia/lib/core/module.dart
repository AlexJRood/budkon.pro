import 'package:core/kernel/kernel.dart';
import '../screens/list/rozliczenia_list_screen.dart';
import '../screens/detail/faktura_detail_screen.dart';
import '../screens/form/faktura_form_screen.dart';

class RozliczeniaModule extends AppModule {
  @override
  String get id => 'rozliczenia';

  @override
  List<DockContribution> dockItems() => [];

  @override
  Map<Pattern, dynamic Function(Object?, Object?, Object?)> routeMap() => {
        RegExp(r'^/budowy/(?<budowaId>\d+)/rozliczenia$'): (ctx, state, data) {
          final budowaId =
              int.tryParse((state as dynamic).pathParameters['budowaId'] ?? '') ?? 0;
          final extra = data as Map<String, dynamic>? ?? {};
          return RozliczeniaListScreen(
            budowaId: budowaId,
            budowaNazwa: extra['nazwa'] ?? '',
          );
        },
        RegExp(r'^/rozliczenia/faktura/(?<id>\d+)$'): (ctx, state, data) {
          final id =
              int.tryParse((state as dynamic).pathParameters['id'] ?? '') ?? 0;
          return FakturaDetailScreen(fakturaId: id);
        },
        RegExp(r'^/rozliczenia/(?<budowaId>\d+)/nowa-faktura$'): (ctx, state, data) {
          final budowaId =
              int.tryParse((state as dynamic).pathParameters['budowaId'] ?? '') ?? 0;
          return FakturaFormScreen(budowaId: budowaId);
        },
      };

  @override
  Future<void> init(ModuleScope scope) async {}
}
