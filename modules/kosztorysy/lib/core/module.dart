import 'package:beamer/beamer.dart';
import 'package:core/kernel/kernel.dart';
import '../data/models/kosztorys_model.dart';
import '../screens/list/kosztorysy_list_screen.dart';
import '../screens/detail/kosztorys_detail_screen.dart';
import '../screens/form/kosztorys_form_screen.dart';
import 'dock.dart';

class KosztorysyModule extends AppModule {
  @override
  String get id => 'kosztorysy';

  @override
  List<DockContribution> dockItems() => kosztorysyDockItems();

  @override
  Map<Pattern, BeamRouteBuilder> routeMap() => {
        '/kosztorysy': (context, state, data) {
          final args = data as Map?;
          return KosztorysyListScreen(budowaId: args?['budowaId'] as int?);
        },
        '/kosztorysy/new': (context, state, data) {
          final args = data as Map?;
          return KosztorysFormScreen(
              defaultBudowaId: args?['budowaId'] as int?);
        },
        RegExp(r'^/kosztorysy/(?<id>\d+)$'): (context, state, data) =>
            KosztorysDetailScreen(
              kosztorysId:
                  int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
        RegExp(r'^/kosztorysy/(?<id>\d+)/edit$'): (context, state, data) =>
            KosztorysFormScreen(
              existing: (data as Map<String, dynamic>?)?['existing']
                  as KosztorysListItemModel?,
            ),
      };

  @override
  Future<void> init(ModuleScope scope) async {}
}
