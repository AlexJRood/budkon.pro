import 'dart:convert';
import 'package:docs/docs_urls.dart';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:docs/models/document.dart';
import 'package:docs/models/document_temp.dart';
import 'package:docs/provider/cloud_doc_provider.dart';
import 'package:flutter/material.dart';
import 'package:core/platform/api_services.dart';
import 'package:path/path.dart' as p;

class DocumentService {
  const DocumentService();

  static dynamic _decodeResponseData(dynamic data) {
    if (data == null) return null;

    if (data is List<int>) {
      return jsonDecode(utf8.decode(data));
    }

    if (data is String) {
      if (data.trim().isEmpty) return null;
      return jsonDecode(data);
    }

    return data;
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    final decoded = _decodeResponseData(data);

    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);

    throw Exception('Invalid API response format');
  }

  static List<dynamic> _extractResults(dynamic decoded) {
    if (decoded is List) return decoded;

    if (decoded is Map) {
      final results = decoded['results'];
      if (results is List) return results;
    }

    return [];
  }

  static String _withQuery(
    String url,
    Map<String, dynamic>? queryParams,
  ) {
    if (queryParams == null || queryParams.isEmpty) {
      return url;
    }

    final cleanParams = <String, dynamic>{};

    queryParams.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      cleanParams[key] = value.toString();
    });

    if (cleanParams.isEmpty) return url;

    final queryString = Uri(queryParameters: cleanParams).query;
    return '$url?$queryString';
  }

  static Future<List<DocumentTemplate>> getTemplates(dynamic ref) async {
    return getTemplatesWithFilters(ref: ref);
  }

  static Future<List<DocumentTemplate>> getTemplatesWithFilters({
    required dynamic ref,
    Map<String, dynamic>? queryParams,
  }) async {
    final url = _withQuery(DocsUrls.templates, queryParams);

    final response = await ApiServices.get(
      url,
      hasToken: true,
      ref: ref,
    );

    if (response == null) {
      throw Exception('No response from server');
    }

    if (response.statusCode == 200) {
      final decoded = _decodeResponseData(response.data);
      final results = _extractResults(decoded);

      return results
          .whereType<Map>()
          .map((json) => DocumentTemplate.fromJson(
                Map<String, dynamic>.from(json),
              ))
          .toList();
    }

    throw Exception('Failed to load templates: ${response.statusCode}');
  }

  static Future<DocumentTemplate> getTemplate(
    String templateId,
    dynamic ref,
  ) async {
    final response = await ApiServices.get(
      DocsUrls.template(templateId),
      hasToken: true,
      ref: ref,
    );

    if (response == null) {
      throw Exception('No response from server');
    }

    if (response.statusCode == 200) {
      return DocumentTemplate.fromJson(_asMap(response.data));
    }

    throw Exception('Failed to load template: ${response.statusCode}');
  }

  static Future<DocumentTemplate> createTemplate({
    required String name,
    required String description,
    required Map<String, dynamic> deltaJson,
    required Map<String, dynamic> styleJson,
    bool isGlobal = false,
    List<dynamic> tags = const [],
    String? companyId,
    String? teamId,
    required dynamic ref,
  }) async {
    final data = {
      'name': name,
      'description': description,
      'delta_json': deltaJson,
      'style_json': styleJson,
      'is_global': isGlobal,
      'tags': tags,
      if (companyId != null) 'company': companyId,
      if (teamId != null) 'team': teamId,
    };

    final response = await ApiServices.post(
      DocsUrls.templates,
      data: data,
      hasToken: true,
      ref: ref,
    );

    if (response == null) {
      throw Exception('No response from server');
    }

    if (response.statusCode == 201) {
      return DocumentTemplate.fromJson(_asMap(response.data));
    }

    throw Exception(
      'Failed to create template: ${response.statusCode} - ${response.data}',
    );
  }

  static Future<DocumentTemplate> updateTemplate({
    required String templateId,
    String? name,
    String? description,
    Map<String, dynamic>? deltaJson,
    Map<String, dynamic>? styleJson,
    bool? isGlobal,
    List<dynamic>? tags,
    required dynamic ref,
  }) async {
    final data = {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (deltaJson != null) 'delta_json': deltaJson,
      if (styleJson != null) 'style_json': styleJson,
      if (isGlobal != null) 'is_global': isGlobal,
      if (tags != null) 'tags': tags,
    };

    final response = await ApiServices.patch(
      DocsUrls.template(templateId),
      data: data,
      hasToken: true,
      ref: ref,
    );

    if (response?.statusCode == 200) {
      return DocumentTemplate.fromJson(_asMap(response!.data));
    }

    throw Exception('Failed to update template: ${response?.statusCode}');
  }

  static Future<DocumentTemplate> forkTemplate({
    required String templateId,
    String? companyId,
    String? teamId,
    required dynamic ref,
  }) async {
    final response = await ApiServices.post(
      '${DocsUrls.template(templateId)}fork/',
      data: {
        if (companyId != null) 'company': companyId,
        if (teamId != null) 'team': teamId,
      },
      hasToken: true,
      ref: ref,
    );

    if (response?.statusCode == 201) {
      return DocumentTemplate.fromJson(_asMap(response!.data));
    }

    throw Exception('Failed to fork template: ${response?.statusCode}');
  }

  static Future<void> deleteTemplate({
    required String templateId,
    required dynamic ref,
  }) async {
    ref.read(documentLoadingProvider.notifier).state = true;

    try {
      final response = await ApiServices.delete(
        DocsUrls.template(templateId),
        hasToken: true,
      );

      if (response == null) {
        throw Exception('No response from server');
      }

      if (response.statusCode == 204) {
        ref.invalidate(documentTemplatesProvider);
        return;
      }

      throw Exception('Failed to delete template: ${response.statusCode}');
    } finally {
      ref.read(documentLoadingProvider.notifier).state = false;
    }
  }

  static Future<List<DocumentTemplateField>> getTemplateFields({
    required String templateId,
    required dynamic ref,
  }) async {
    final response = await ApiServices.get(
      _withQuery(
        DocsUrls.templateFields,
        {
          'template': templateId,
          'ordering': 'order',
        },
      ),
      hasToken: true,
      ref: ref,
    );

    if (response?.statusCode == 200) {
      final decoded = _decodeResponseData(response!.data);
      final results = _extractResults(decoded);

      return results
          .whereType<Map>()
          .map((json) => DocumentTemplateField.fromJson(
                Map<String, dynamic>.from(json),
              ))
          .toList();
    }

    throw Exception('Failed to load template fields: ${response?.statusCode}');
  }

  static Future<DocumentTemplateField> createTemplateField({
    required DocumentTemplateField field,
    required dynamic ref,
  }) async {
    final response = await ApiServices.post(
      DocsUrls.templateFields,
      data: field.toJson(),
      hasToken: true,
      ref: ref,
    );

    if (response?.statusCode == 201) {
      return DocumentTemplateField.fromJson(_asMap(response!.data));
    }

    throw Exception('Failed to create template field: ${response?.statusCode}');
  }

  static Future<DocumentTemplateField> updateTemplateField({
    required String fieldId,
    required Map<String, dynamic> data,
    required dynamic ref,
  }) async {
    final response = await ApiServices.patch(
      DocsUrls.templateField(fieldId),
      data: data,
      hasToken: true,
      ref: ref,
    );

    if (response?.statusCode == 200) {
      return DocumentTemplateField.fromJson(_asMap(response!.data));
    }

    throw Exception('Failed to update template field: ${response?.statusCode}');
  }

  static Future<void> deleteTemplateField({
    required String fieldId,
    required dynamic ref,
  }) async {
    final response = await ApiServices.delete(
      DocsUrls.templateField(fieldId),
      hasToken: true,
    );

    if (response?.statusCode != 204) {
      throw Exception('Failed to delete template field: ${response?.statusCode}');
    }
  }

  static Future<List<Documents>> getDocuments(dynamic ref) async {
    return getDocumentsWithFilters(ref: ref);
  }

  static Future<List<Documents>> getDocumentsWithFilters({
    required dynamic ref,
    Map<String, dynamic>? queryParams,
  }) async {
    final url = _withQuery(DocsUrls.documents, queryParams);

    final response = await ApiServices.get(
      url,
      hasToken: true,
      ref: ref,
    );

    if (response == null) {
      throw Exception('No response from server');
    }

    if (response.statusCode == 200) {
      final decoded = _decodeResponseData(response.data);
      final results = _extractResults(decoded);

      return results
          .whereType<Map>()
          .map((json) => Documents.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }

    throw Exception('Failed to load documents: ${response.statusCode}');
  }

  static Future<Documents> getDocument(
    String documentId,
    dynamic ref,
  ) async {
    final response = await ApiServices.get(
      DocsUrls.document(documentId),
      hasToken: true,
      ref: ref,
    );

    if (response == null) {
      throw Exception('No response from server');
    }

    if (response.statusCode == 200) {
      return Documents.fromJson(_asMap(response.data));
    }

    throw Exception('Failed to load document: ${response.statusCode}');
  }

  static Future<Documents> createDocument({
    required String? templateId,
    required String title,
    required Map<String, dynamic> currentDelta,
    required Map<String, dynamic> currentStyle,
    String? companyId,
    String? teamId,
    required dynamic ref,
  }) async {
    final data = {
      'template': templateId,
      'title': title,
      'current_delta': currentDelta,
      'current_style': currentStyle,
      if (companyId != null) 'company': companyId,
      if (teamId != null) 'team': teamId,
    };

    final response = await ApiServices.post(
      DocsUrls.documents,
      data: data,
      hasToken: true,
      ref: ref,
    );

    if (response == null) {
      throw Exception('No response from server');
    }

    if (response.statusCode == 201) {
      return Documents.fromJson(_asMap(response.data));
    }

    throw Exception(
      'Failed to create document: ${response.statusCode} - ${response.data}',
    );
  }

  static Future<Documents> updateDocument({
    required String documentId,
    String? title,
    Map<String, dynamic>? currentDelta,
    Map<String, dynamic>? currentStyle,
    String? status,
    bool? isFinalized,
    required dynamic ref,
  }) async {
    final data = {
      if (title != null) 'title': title,
      if (currentDelta != null) 'current_delta': currentDelta,
      if (currentStyle != null) 'current_style': currentStyle,
      if (status != null) 'status': status,
      if (isFinalized != null) 'is_finalized': isFinalized,
    };

    final response = await ApiServices.patch(
      DocsUrls.document(documentId),
      data: data,
      hasToken: true,
      ref: ref,
    );

    if (response?.statusCode == 200) {
      return Documents.fromJson(_asMap(response!.data));
    }

    throw Exception('Failed to update document: ${response?.statusCode}');
  }

  static Future<void> deleteDocument({
    required String documentId,
    required dynamic ref,
  }) async {
    ref.read(documentLoadingProvider.notifier).state = true;

    try {
      final response = await ApiServices.delete(
        DocsUrls.document(documentId),
        hasToken: true,
      );

      if (response == null) {
        throw Exception('No response from server');
      }

      if (response.statusCode == 204) {
        ref.invalidate(documentsProvider);

        ref.read(documentTitlesProvider.notifier).update((state) {
          final next = Map<String, String>.from(state);
          next.remove(documentId);
          return next;
        });

        return;
      }

      throw Exception('Failed to delete document: ${response.statusCode}');
    } finally {
      ref.read(documentLoadingProvider.notifier).state = false;
    }
  }

  static Future<Map<String, dynamic>> saveDocumentVersion({
    required String documentId,
    String comment = '',
    required dynamic ref,
  }) async {
    final response = await ApiServices.post(
      '${DocsUrls.document(documentId)}save_version/',
      data: {
        'comment': comment,
      },
      hasToken: true,
      ref: ref,
    );

    if (response?.statusCode == 200) {
      return _asMap(response!.data);
    }

    throw Exception('Failed to save version: ${response?.statusCode}');
  }

  static Future<Documents> restoreDocumentVersion({
    required String documentId,
    required int version,
    required dynamic ref,
  }) async {
    final response = await ApiServices.post(
      '${DocsUrls.document(documentId)}restore_version/',
      data: {
        'version': version,
      },
      hasToken: true,
      ref: ref,
    );

    if (response?.statusCode == 200) {
      return Documents.fromJson(_asMap(response!.data));
    }

    throw Exception('Failed to restore version: ${response?.statusCode}');
  }

  static Future<Documents> finalizeDocument({
    required String documentId,
    required dynamic ref,
  }) async {
    final response = await ApiServices.post(
      '${DocsUrls.document(documentId)}finalize/',
      data: {},
      hasToken: true,
      ref: ref,
    );

    if (response?.statusCode == 200) {
      return Documents.fromJson(_asMap(response!.data));
    }

    throw Exception('Failed to finalize document: ${response?.statusCode}');
  }

  static Future<List<DocumentVersion>> getDocumentVersions({
    required String documentId,
    required dynamic ref,
  }) async {
    final response = await ApiServices.get(
      _withQuery(
        DocsUrls.documentVersions,
        {
          'document': documentId,
          'ordering': '-version',
        },
      ),
      hasToken: true,
      ref: ref,
    );

    if (response?.statusCode == 200) {
      final decoded = _decodeResponseData(response!.data);
      final results = _extractResults(decoded);

      return results
          .whereType<Map>()
          .map((json) => DocumentVersion.fromJson(
                Map<String, dynamic>.from(json),
              ))
          .toList();
    }

    throw Exception('Failed to load document versions: ${response?.statusCode}');
  }

  static Future<List<DocumentComment>> getDocumentComments({
    required String documentId,
    required dynamic ref,
  }) async {
    final response = await ApiServices.get(
      _withQuery(
        DocsUrls.documentComments,
        {
          'document': documentId,
          'ordering': '-created_at',
        },
      ),
      hasToken: true,
      ref: ref,
    );

    if (response?.statusCode == 200) {
      final decoded = _decodeResponseData(response!.data);
      final results = _extractResults(decoded);

      return results
          .whereType<Map>()
          .map((json) => DocumentComment.fromJson(
                Map<String, dynamic>.from(json),
              ))
          .toList();
    }

    throw Exception('Failed to load document comments: ${response?.statusCode}');
  }

  static Future<DocumentComment> createDocumentComment({
    required String documentId,
    required String content,
    Map<String, dynamic> position = const {},
    required dynamic ref,
  }) async {
    final response = await ApiServices.post(
      DocsUrls.documentComments,
      data: {
        'document': documentId,
        'content': content,
        'position': position,
      },
      hasToken: true,
      ref: ref,
    );

    if (response?.statusCode == 201) {
      return DocumentComment.fromJson(_asMap(response!.data));
    }

    throw Exception('Failed to create comment: ${response?.statusCode}');
  }

  static Future<DocumentComment> resolveDocumentComment({
    required String commentId,
    required dynamic ref,
  }) async {
    final response = await ApiServices.post(
      '${DocsUrls.documentComment(commentId)}resolve/',
      data: {},
      hasToken: true,
      ref: ref,
    );

    if (response?.statusCode == 200) {
      return DocumentComment.fromJson(_asMap(response!.data));
    }

    throw Exception('Failed to resolve comment: ${response?.statusCode}');
  }

  static Future<DocumentFillSession> createFillSession({
    required String templateId,
    required String recipientEmail,
    String recipientName = '',
    String message = '',
    DateTime? expiresAt,
    Map<String, dynamic> values = const {},
    required dynamic ref,
  }) async {
    final response = await ApiServices.post(
      DocsUrls.fillSessions,
      data: {
        'template': templateId,
        'recipient_email': recipientEmail,
        'recipient_name': recipientName,
        'message': message,
        'values': values,
        if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
      },
      hasToken: true,
      ref: ref,
    );

    if (response?.statusCode == 201) {
      return DocumentFillSession.fromJson(_asMap(response!.data));
    }

    throw Exception('Failed to create fill session: ${response?.statusCode}');
  }

  static Future<DocumentFillSession> markFillSessionSent({
    required String sessionId,
    required dynamic ref,
  }) async {
    final response = await ApiServices.post(
      '${DocsUrls.fillSession(sessionId)}mark_sent/',
      data: {},
      hasToken: true,
      ref: ref,
    );

    if (response?.statusCode == 200) {
      return DocumentFillSession.fromJson(_asMap(response!.data));
    }

    throw Exception('Failed to mark fill session as sent: ${response?.statusCode}');
  }

  static Future<Documents> createDocumentFromFillSession({
    required String sessionId,
    required dynamic ref,
  }) async {
    final response = await ApiServices.post(
      '${DocsUrls.fillSession(sessionId)}create_document/',
      data: {},
      hasToken: true,
      ref: ref,
    );

    if (response?.statusCode == 201 || response?.statusCode == 200) {
      return Documents.fromJson(_asMap(response!.data));
    }

    throw Exception('Failed to create document from fill session: ${response?.statusCode}');
  }

  static Future<DocumentFillSession> getPublicFillSession({
    required String token,
    required dynamic ref,
  }) async {
    final response = await ApiServices.get(
      DocsUrls.publicFillSession(token),
      hasToken: false,
      ref: ref,
    );

    if (response?.statusCode == 200) {
      return DocumentFillSession.fromJson(_asMap(response!.data));
    }

    throw Exception('Failed to load public fill session: ${response?.statusCode}');
  }

  static Future<Map<String, dynamic>> submitPublicFillSession({
    required String token,
    required Map<String, dynamic> values,
    required dynamic ref,
  }) async {
    final response = await ApiServices.post(
      DocsUrls.publicFillSession(token),
      data: {
        'values': values,
      },
      hasToken: false,
      ref: ref,
    );

    if (response?.statusCode == 200) {
      return _asMap(response!.data);
    }

    throw Exception('Failed to submit public fill session: ${response?.statusCode}');
  }

  static Future<GeneratedDocument> generateDocument({
    required String documentId,
    required String filePath,
    required dynamic ref,
  }) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final formData = FormData.fromMap({
      'document': documentId,
      'document_file': await MultipartFile.fromFile(
        filePath,
        filename: p.basename(filePath),
      ),
    });

    final response = await ApiServices.post(
      DocsUrls.generatedDocuments,
      formData: formData,
      hasToken: true,
      ref: ref,
    );

    if (response == null) {
      throw Exception('No response from server');
    }

    if (response.statusCode == 201) {
      return GeneratedDocument.fromJson(_asMap(response.data));
    }

    final error = response.data is String ? response.data : 'Unknown error';
    throw Exception('Failed: ${response.statusCode} → $error');
  }
}