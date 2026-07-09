import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'routing.dart';

class FakturyModule {
  static const id = 'faktury';
  static const label = 'Faktury';
  static const icon = Icons.receipt_long_outlined;
  static const iconFilled = Icons.receipt_long;
  static const color = Color(0xFF26A69A); // teal — jak Emma faktura_alert

  static List<RouteBase> get routes => fakturyRoutes;

  static void navigateToLista(BuildContext context, {int? budowaId}) =>
      context.push('/faktury');

  static void navigateToPodglad(BuildContext context, int id) =>
      context.push('/faktury/$id');

  static void navigateToNowa(BuildContext context,
          {int? budowaId, int? ofertaId}) =>
      context.push('/faktury/nowa');
}
