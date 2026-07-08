import 'package:core/kernel/kernel.dart';
import 'package:flutter/material.dart';

List<RouteSpec> budowaRoutes() => [
  RouteSpec(
    '/budowa',
    (context, params, data) => const _BudowaPlaceholder(),
  ),
];

// TODO: replace with real screen
class _BudowaPlaceholder extends StatelessWidget {
  const _BudowaPlaceholder();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('Budowa — w budowie')),
  );
}
