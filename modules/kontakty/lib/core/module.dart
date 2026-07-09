import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'routing.dart';

class KontaktyModule {
  static const id = 'kontakty';
  static const label = 'Kontakty';
  static const icon = Icons.contacts_outlined;
  static const iconFilled = Icons.contacts;
  static const color = Color(0xFF26A69A); // teal

  static List<RouteBase> get routes => kontaktyRoutes;

  static void navigateToLista(BuildContext context) =>
      context.push('/kontakty');

  static void navigateToProfil(BuildContext context, int id) =>
      context.push('/kontakty/$id');
}
