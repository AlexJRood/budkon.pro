import 'package:core/kernel/kernel.dart';
import 'package:flutter/material.dart';

List<RouteSpec> dziennikRoutes() => [
  RouteSpec(
    '/dziennik',
    (context, params, data) => const _DziennikPlaceholder(),
  ),
];

// TODO: replace with real screen
class _DziennikPlaceholder extends StatelessWidget {
  const _DziennikPlaceholder();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('Dziennik — w budowie')),
  );
}
