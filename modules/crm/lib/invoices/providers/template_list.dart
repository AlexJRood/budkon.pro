import 'dart:convert';

import 'package:crm/invoices/models/templates.dart';
import 'package:crm/invoices/urls.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

final invoiceTemplateListProvider =
    FutureProvider.autoDispose<List<InvoiceTemplateModel>>((ref) async {
  final Response? resp = await ApiServices.get(
    URLsInvoice.invoiceTemplates,
    hasToken: true,
    ref: ref,
  );

  if (resp == null) {
    throw Exception('No response from server');
  }

  if (resp.statusCode != 200) {
    throw Exception('Failed to load templates: ${resp.statusCode}');
  }

  dynamic data = resp.data;

  // Jeśli przyszły bajty (Uint8List) -> dekodujemy do JSON-a
  if (data is Uint8List) {
    final text = utf8.decode(data);
    try {
      data = jsonDecode(text);
    } catch (e) {
      throw Exception('Failed to decode templates JSON: $e');
    }
  }

  // DRF paginated: {count, next, previous, results: [...]}
  // albo bez paginacji: [ {...}, {...} ]
  List listData;

  if (data is Map) {
    final results = data['results'];
    if (results is! List) {
      throw Exception('Invalid "results" field type: ${results.runtimeType}');
    }
    listData = results;
  } else if (data is List) {
    listData = data;
  } else {
    throw Exception('Invalid templates payload root: ${data.runtimeType}');
  }

  return listData.map<InvoiceTemplateModel>((e) {
    if (e is Map<String, dynamic>) {
      return InvoiceTemplateModel.fromJson(e);
    } else if (e is Map) {
      return InvoiceTemplateModel.fromJson(
        e.map((k, v) => MapEntry(k.toString(), v)),
      );
    } else {
      debugPrint(
        'invoiceTemplateListProvider: skipping invalid element type: '
        '${e.runtimeType} value=$e',
      );
      throw Exception('Invalid element in templates list: ${e.runtimeType}');
    }
  }).toList();
});
