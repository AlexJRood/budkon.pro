import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'routing.dart';

class PracownicyModule {
  static const id = 'pracownicy';
  static const label = 'Zespół';
  static const icon = Icons.groups_outlined;
  static const iconFilled = Icons.groups;
  static const color = Color(0xFF5C6BC0); // indigo

  static List<RouteBase> get routes => pracownicyRoutes;

  static void navigateToLista(BuildContext context, {int? budowaId}) =>
      context.push('/pracownicy', extra: budowaId);

  static void navigateToProfil(BuildContext context, int id) =>
      context.push('/pracownicy/$id');
}
