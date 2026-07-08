import 'package:core/kernel/kernel.dart';
import 'package:flutter/material.dart';

List<RouteSpec> podwykonawcyRoutes() => [
  RouteSpec(
    '/podwykonawcy',
    (context, params, data) => const _PodwykonawcyPlaceholder(),
  ),
];

// TODO: replace with real screen
class _PodwykonawcyPlaceholder extends StatelessWidget {
  const _PodwykonawcyPlaceholder();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('Podwykonawcy — w budowie')),
  );
}
