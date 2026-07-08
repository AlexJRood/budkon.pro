import 'package:core/kernel/kernel.dart';
import 'package:flutter/material.dart';

List<RouteSpec> kosztorysyRoutes() => [
  RouteSpec(
    '/kosztorysy',
    (context, params, data) => const _KosztorysyPlaceholder(),
  ),
];

// TODO: replace with real screen
class _KosztorysyPlaceholder extends StatelessWidget {
  const _KosztorysyPlaceholder();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('Kosztorysy — w budowie')),
  );
}
