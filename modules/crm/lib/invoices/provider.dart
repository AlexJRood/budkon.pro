// lib/finance/providers/invoice_template_provider.dart

import 'dart:convert';

import 'package:crm/invoices/models/templates.dart';          // InvoiceTemplateModel
import 'package:crm/invoices/urls.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';


/// Zwraca aktywny szablon faktury dla zalogowanego usera:
/// - null, jeśli API zwróci 404 (brak domyślnego szablonu)
/// - rzuca wyjątek przy innych błędach
final activeInvoiceTemplateProvider =
    FutureProvider<InvoiceTemplateModel?>((ref) async {
  // używamy Twojego ApiServices.get, tak jak w ClientNotifier
  final response = await ApiServices.get(
    URLsInvoice.invoiceTemplatesActive, // np. "/api/invoice-templates/active/"
    hasToken: true,
    ref: ref,
    responseType: ResponseType.bytes, // spójnie z resztą appki
  );

  if (response == null) {
    throw Exception('No response from /invoice-templates/active/');
  }

  if (response.statusCode == 404) {
    // brak aktywnego szablonu – np. user nic nie skonfigurował
    return null;
  }

  if (response.statusCode != 200) {
    throw Exception(
      'Unexpected status code: ${response.statusCode} while fetching active invoice template',
    );
  }

  // Dekodowanie jak w ClientNotifier.fetchClients
  final raw = response.data is String
      ? response.data as String
      : utf8.decode(response.data as List<int>);

  final data = json.decode(raw) as Map<String, dynamic>;
  return InvoiceTemplateModel.fromJson(data);
});
