import 'dart:convert'; // <-- DODANE
import 'dart:typed_data';

import 'package:crm/invoices/models/templates.dart';
import 'package:crm/invoices/urls.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

/// Zwraca aktywny (domyślny) szablon faktury dla usera.
/// Jeśli backend zwróci 404 – zwracamy null.
final invoiceActiveTemplateProvider =
    FutureProvider.autoDispose<InvoiceTemplateModel?>((ref) async {
  final Response? resp = await ApiServices.get(
    URLsInvoice.invoiceTemplatesActive,
    hasToken: true,
    ref: ref,
  );

  if (resp == null) return null;

  if (resp.statusCode == 404) {
    // brak aktywnego szablonu
    return null;
  }

  if (resp.statusCode != 200) {
    throw Exception(
      'Failed to load active invoice template: ${resp.statusCode}',
    );
  }

  dynamic data = resp.data;
  if (data == null) return null;

  // --------- FIX NA Uint8List / raw bytes ----------
  if (data is Uint8List) {
    final decoded = utf8.decode(data);
    data = jsonDecode(decoded);
  }
  // --------------------------------------------------

  if (data is Map<String, dynamic>) {
    return InvoiceTemplateModel.fromJson(
      data.map((k, v) => MapEntry(k.toString(), v)),
    );
  }

  throw Exception(
    'Invalid active template payload root: ${data.runtimeType}',
  );
});
