import 'dart:convert';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_fliper/sale/models/sale_document_model.dart';
import 'package:crm_fliper/sale/models/sale_document_response_model.dart';
import 'package:core/platform/api_services.dart';
import 'package:flutter/foundation.dart';

class SalesDocumentNotifier extends StateNotifier<List<SaleDocument>> {
  SalesDocumentNotifier() : super([]);

  Future<void> fetchSaleDocument(dynamic ref) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.fetchSaleDocument,
        ref: ref,
        hasToken: true,
      );
      if (response != null && response.statusCode == 200) {
        final responseString = utf8.decode(response.data);
        final jsonResponse = jsonDecode(responseString);
        final docResponse = SaleDocumentResponse.fromJson(jsonResponse);
        state = docResponse.results;
        if (kDebugMode) debugPrint('Sale documents fetched successfully. Count: ${state.length}');
        for (var doc in state) {
          if (kDebugMode) {
            debugPrint(
              'Document ID: ${doc.id}, Name: ${doc.documentName}, File: ${doc.fileUrl}');
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint(
            'Sale documents fetch failed. Status code: ${response?.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching sale documents: $e');
    }
  }

  Future<void> createSaleDocument(dynamic ref) async {
    try {
      final dummyBytes = <int>[0x89, 0x50, 0x4E, 0x47];

      final formData = FormData.fromMap({
        'sale': '1',
        'document_name': 'file',
        'file': MultipartFile.fromBytes(
          dummyBytes,
          filename: 'dummy.png',
        ),
      });

      final response = await ApiServices.post(
        CrmFliperUrls.createSaleDocument,
        hasToken: true,
        formData: formData,
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        if (kDebugMode) debugPrint('Sale document created successfully');
        await fetchSaleDocument(ref);
      } else {
        if (kDebugMode) {
          debugPrint(
            'Sale document creation failed. Status code: ${response?.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error creating sale document: $e');
    }
  }
}

final salesDocumentProvider =
    StateNotifierProvider<SalesDocumentNotifier, List<SaleDocument>>(
  (ref) => SalesDocumentNotifier(),
);
