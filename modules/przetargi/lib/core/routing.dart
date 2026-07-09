import 'package:core/platform/routing/route_spec.dart';
import 'package:flutter/material.dart';

import '../screens/detail/przetarg_detail_screen.dart';
import '../screens/list/przetargi_list_screen.dart';
import '../screens/subskrypcje/subskrypcje_screen.dart';

List<RouteSpec> przetargiRoutes() => [
      RouteSpec(
        '/przetargi',
        (context, params, data) => const PrzetargiListScreen(),
      ),
      RouteSpec(
        '/przetargi/subskrypcje',
        (context, params, data) => const SubskrypcjeScreen(),
      ),
      RouteSpec(
        '/przetargi/:id',
        (context, params, data) => PrzetargDetailScreen(
          przetargId: int.tryParse(params['id'] ?? '') ?? 0,
        ),
      ),
    ];
