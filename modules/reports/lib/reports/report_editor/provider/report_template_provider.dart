import 'dart:convert';
import 'package:reports/reports_urls.dart';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

import '../model/report_template_model.dart';

// ── List of all templates ────────────────────────────────────────────────────

final reportTemplateListProvider =
    AsyncNotifierProvider<ReportTemplateListNotifier, List<ReportTemplateModel>>(
  ReportTemplateListNotifier.new,
);

class ReportTemplateListNotifier
    extends AsyncNotifier<List<ReportTemplateModel>> {
  @override
  Future<List<ReportTemplateModel>> build() async {
    return _fetchAll();
  }

  Future<List<ReportTemplateModel>> _fetchAll() async {
    final response = await ApiServices.get(
      ReportsUrls.reportTemplates,
      hasToken: true,
      ref: ref,
    );
    if (response == null || response.statusCode != 200) return [];
    final decoded = _decode(response.data);
    final list = decoded is List ? decoded : (decoded['results'] as List? ?? []);
    return list
        .map((e) => ReportTemplateModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  dynamic _decode(dynamic raw) {
    if (raw is Map || raw is List) return raw;
    if (raw is String) return jsonDecode(raw);
    if (raw is Uint8List || raw is List<int>) {
      return jsonDecode(utf8.decode(raw as List<int>));
    }
    return raw;
  }

  Future<ReportTemplateModel?> create(ReportTemplateModel template) async {
    final response = await ApiServices.post(
      ReportsUrls.reportTemplates,
      data: template.toJson(),
      hasToken: true,
      ref: ref,
    );
    if (response == null || response.statusCode != 201) {
      log('create template error: ${response?.statusCode} ${response?.data}');
      return null;
    }
    final created =
        ReportTemplateModel.fromJson(_decode(response.data) as Map<String, dynamic>);
    state = AsyncData([...state.valueOrNull ?? [], created]);
    return created;
  }

  Future<ReportTemplateModel?> updateTemplate(
      int id, ReportTemplateModel template) async {
    final response = await ApiServices.patch(
      ReportsUrls.reportTemplate(id),
      data: template.toJson(),
      hasToken: true,
      ref: ref,
    );
    if (response == null ||
        (response.statusCode != 200 && response.statusCode != 201)) {
      log('update template error: ${response?.statusCode} ${response?.data}');
      return null;
    }
    final updated =
        ReportTemplateModel.fromJson(_decode(response.data) as Map<String, dynamic>);
    state = AsyncData(
      (state.valueOrNull ?? [])
          .map((t) => t.id == id ? updated : t)
          .toList(),
    );
    return updated;
  }

  Future<bool> delete(int id) async {
    final response = await ApiServices.delete(
      ReportsUrls.reportTemplate(id),
      hasToken: true,
    );
    final ok =
        response != null && (response.statusCode == 204 || response.statusCode == 200);
    if (ok) {
      state = AsyncData(
        (state.valueOrNull ?? []).where((t) => t.id != id).toList(),
      );
    }
    return ok;
  }

  Future<ReportTemplateModel?> uploadLogo(int id, File file) async {
    final formData = FormData.fromMap({
      'logo': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
    });
    final response = await ApiServices.post(
      ReportsUrls.reportTemplateLogo(id),
      formData: formData,
      hasToken: true,
      ref: ref,
    );
    if (response == null || response.statusCode != 200) {
      log('upload logo error: ${response?.statusCode} ${response?.data}');
      return null;
    }
    final updated =
        ReportTemplateModel.fromJson(_decode(response.data) as Map<String, dynamic>);
    state = AsyncData(
      (state.valueOrNull ?? [])
          .map((t) => t.id == id ? updated : t)
          .toList(),
    );
    return updated;
  }

  Future<bool> removeLogo(int id) async {
    final response = await ApiServices.delete(
      ReportsUrls.reportTemplateLogo(id),
      hasToken: true,
    );
    final ok = response != null && response.statusCode == 204;
    if (ok) {
      state = AsyncData(
        (state.valueOrNull ?? [])
            .map((t) => t.id == id ? t.copyWith(clearLogo: true) : t)
            .toList(),
      );
    }
    return ok;
  }

  Future<ReportTemplateModel?> setDefault(int id) async {
    final response = await ApiServices.post(
      ReportsUrls.reportTemplateSetDefault(id),
      hasToken: true,
      ref: ref,
    );
    if (response == null || response.statusCode != 200) return null;
    // Refresh full list so is_default flags are correct
    final fresh = await _fetchAll();
    state = AsyncData(fresh);
    return fresh.firstWhere((t) => t.id == id, orElse: () => fresh.first);
  }

  void refresh() {
    ref.invalidateSelf();
  }
}

// ── Default / active template ────────────────────────────────────────────────

final activeReportTemplateProvider =
    FutureProvider<ReportTemplateModel?>((ref) async {
  final templateState = ref.watch(reportTemplateListProvider);
  final list = templateState.valueOrNull ?? [];
  if (list.isEmpty) return null;
  return list.firstWhere((t) => t.isDefault, orElse: () => list.first);
});
