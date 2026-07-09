import 'package:core/kernel/kernel.dart';
import '../screens/list/podwykonawcy_list_screen.dart';

List<RouteSpec> podwykonawcyRoutes() => [
      RouteSpec(
        '/podwykonawcy',
        (ctx, params, data) {
          final args = data as Map?;
          return PodwykonawcyListScreen(
            budowaId: int.tryParse(params['budowaId'] ?? '') ??
                args?['budowaId'] as int? ??
                0,
            budowaNazwa: args?['budowaNazwa'] as String? ?? 'Budowa',
          );
        },
      ),
    ];
