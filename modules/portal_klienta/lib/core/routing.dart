import 'package:core/kernel/kernel.dart';
import 'package:flutter/material.dart';

List<RouteSpec> portal_klientaRoutes() => [
  RouteSpec(
    '/portal_klienta',
    (context, params, data) => const _PortalKlientaPlaceholder(),
  ),
];

// TODO: replace with real screen
class _PortalKlientaPlaceholder extends StatelessWidget {
  const _PortalKlientaPlaceholder();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('PortalKlienta — w budowie')),
  );
}
