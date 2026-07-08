import 'package:core/kernel/kernel.dart';
import 'package:flutter/material.dart';

List<RouteSpec> materialyRoutes() => [
  RouteSpec(
    '/materialy',
    (context, params, data) => const _MaterialyPlaceholder(),
  ),
];

// TODO: replace with real screen
class _MaterialyPlaceholder extends StatelessWidget {
  const _MaterialyPlaceholder();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('Materialy — w budowie')),
  );
}
