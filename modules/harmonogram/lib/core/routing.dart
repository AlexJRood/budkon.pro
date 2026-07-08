import 'package:core/kernel/kernel.dart';
import 'package:flutter/material.dart';

List<RouteSpec> harmonogramRoutes() => [
  RouteSpec(
    '/harmonogram',
    (context, params, data) => const _HarmonogramPlaceholder(),
  ),
];

// TODO: replace with real screen
class _HarmonogramPlaceholder extends StatelessWidget {
  const _HarmonogramPlaceholder();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('Harmonogram — w budowie')),
  );
}
