import 'package:core/kernel/kernel.dart' hide AppModule;
import 'package:core/shell/manager/bar_manager.dart';
import 'package:flutter/material.dart';

import '../screens/detail/przetarg_detail_screen.dart';
import '../screens/list/przetargi_list_screen.dart';
import '../screens/subskrypcje/subskrypcje_screen.dart';

List<RouteSpec> przetargiRoutes() => [
      RouteSpec(
        '/przetargi',
        (context, params, data) => BarManager(appModule: AppModule.budkon, childPc: PrzetargiListScreen()),
      ),
      RouteSpec(
        '/przetargi/subskrypcje',
        (context, params, data) => BarManager(appModule: AppModule.budkon, childPc: SubskrypcjeScreen()),
      ),
      RouteSpec(
        '/przetargi/:id',
        (context, params, data) => BarManager(appModule: AppModule.budkon, childPc: PrzetargDetailScreen(
            przetargId: int.tryParse(params['id'] ?? '') ?? 0,
          ),
        ),
      ),
    ];
