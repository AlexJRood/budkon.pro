import 'package:core/kernel/kernel.dart';
import 'package:flutter/material.dart';
import 'dock.dart';
import 'routing.dart';

class KontaktyModule extends AppModule {
  @override
  String get id => 'kontakty';

  @override
  List<DockContribution> dockItems() => kontaktyDockItems();

  @override
  List<RouteSpec> routes() => kontaktyRoutes();

  @override
  Future<void> init(ModuleScope scope) async {}

  static void navigateToLista(BuildContext context) =>
      navigateTo(context, '/kontakty');

  static void navigateToProfil(BuildContext context, int id) =>
      navigateTo(context, '/kontakty/$id');

  static void navigateTo(BuildContext context, String path) {
    final nav = Navigator.of(context, rootNavigator: true);
    nav.pushNamed(path);
  }
}
