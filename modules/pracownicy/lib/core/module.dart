import 'package:core/kernel/kernel.dart';
import 'package:flutter/material.dart';
import 'dock.dart';
import 'routing.dart';

class PracownicyModule extends AppModule {
  @override
  String get id => 'pracownicy';

  @override
  List<DockContribution> dockItems() => pracownicyDockItems();

  @override
  List<RouteSpec> routes() => pracownicyRoutes();

  @override
  Future<void> init(ModuleScope scope) async {}

  static void navigateToLista(BuildContext context) =>
      navigateTo(context, '/pracownicy');

  static void navigateToProfil(BuildContext context, int id) =>
      navigateTo(context, '/pracownicy/$id');

  static void navigateTo(BuildContext context, String path) {
    final nav = Navigator.of(context, rootNavigator: true);
    nav.pushNamed(path);
  }
}
