import 'package:core/kernel/kernel.dart';
import 'package:flutter/material.dart';
import 'dock.dart';
import 'routing.dart';

class FakturyModule extends AppModule {
  @override
  String get id => 'faktury';

  @override
  List<DockContribution> dockItems() => fakturyDockItems();

  @override
  List<RouteSpec> routes() => fakturyRoutes();

  @override
  Future<void> init(ModuleScope scope) async {}

  static void navigateToLista(BuildContext context) =>
      navigateTo(context, '/faktury');

  static void navigateToPodglad(BuildContext context, int id) =>
      navigateTo(context, '/faktury/$id');

  static void navigateToNowa(BuildContext context) =>
      navigateTo(context, '/faktury/nowa');

  static void navigateTo(BuildContext context, String path) {
    final nav = Navigator.of(context, rootNavigator: true);
    nav.pushNamed(path);
  }
}
