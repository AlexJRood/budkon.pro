import 'package:core/kernel/kernel.dart';
import '../screens/list/odbiory_list_screen.dart';
import '../screens/detail/protokol_detail_screen.dart';
import 'dart:ui';

class OdbioryModule extends AppModule {
  @override
  String get id => 'odbiory';

  @override
  List<DockContribution> dockItems() => [];

  @override
  Map<Pattern, dynamic Function(Object?, Object?, Object?)> routeMap() => {
        RegExp(r'^/budowy/(?<budowaId>\d+)/odbiory$'): (context, state, data) {
          final budowaId = int.tryParse(
                  (state as dynamic).pathParameters['budowaId'] ?? '') ??
              0;
          final extra = data as Map<String, dynamic>? ?? {};
          return OdbioryListScreen(
            budowaId: budowaId,
            budowaNazwa: extra['nazwa'] ?? '',
          );
        },
        RegExp(r'^/odbiory/(?<id>\d+)$'): (context, state, data) {
          final id =
              int.tryParse((state as dynamic).pathParameters['id'] ?? '') ?? 0;
          final extra = data as Map<String, dynamic>? ?? {};
          return ProtokolDetailScreen(
            protokolId: id,
            tytul: extra['tytul'] ?? 'Protokół',
          );
        },
      };

  @override
  Future<void> init(ModuleScope scope) async {}
}
