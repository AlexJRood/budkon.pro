import 'package:core/kernel/kernel.dart';
import 'package:flutter/material.dart';

List<RouteSpec> ofertyRoutes() => [
  RouteSpec(
    '/oferty',
    (context, params, data) => const _OfertyPlaceholder(),
  ),
];

// TODO: replace with real screen
class _OfertyPlaceholder extends StatelessWidget {
  const _OfertyPlaceholder();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('Oferty — w budowie')),
  );
}
