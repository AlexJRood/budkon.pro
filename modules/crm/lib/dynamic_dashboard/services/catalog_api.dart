import 'dart:convert';
import 'dart:typed_data';

import 'package:crm/dynamic_dashboard/models/catalog_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

import '../utils/urls_dashboard.dart';

final dashboardCatalogApiProvider = Provider<DashboardCatalogApi>((ref) {
  return DashboardCatalogApi(ref);
});

class DashboardCatalogApi {
  DashboardCatalogApi(this.ref);

  final Ref ref;

  String _catalogEndpoint({
    required String dashboardKey,
    required String zoneKey,
    String? source,
    String? category,
    String? search,
    bool installedOnly = false,
  }) {
    final params = <String, String>{
      'dashboard_key': dashboardKey,
      'zone_key': zoneKey,
      if (source != null && source.isNotEmpty) 'source': source,
      if (category != null && category.isNotEmpty) 'category': category,
      if (search != null && search.isNotEmpty) 'search': search,
      if (installedOnly) 'installed_only': '1',
    };

    final query = params.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');

    return '${DashboardURLs.dashboardWidgetCatalogBase}?$query';
  }

  String _installEndpoint(String slug) =>
      '${DashboardURLs.dashboardWidgetCatalogBase}$slug/install/';

  String _uninstallEndpoint(String slug) =>
      '${DashboardURLs.dashboardWidgetCatalogBase}$slug/uninstall/';

  String _previewUploadEndpoint(String slug) =>
      '${DashboardURLs.dashboardWidgetCatalogBase}$slug/preview-image/';

  Future<List<DashboardCatalogItem>> fetchCatalog({
    required String dashboardKey,
    required String zoneKey,
    String? source,
    String? category,
    String? search,
    bool installedOnly = false,
  }) async {
    final response = await ApiServices.get(
      _catalogEndpoint(
        dashboardKey: dashboardKey,
        zoneKey: zoneKey,
        source: source,
        category: category,
        search: search,
        installedOnly: installedOnly,
      ),
      hasToken: true,
      ref: ref,
      responseType: ResponseType.json,
    );

    final raw = _normalizeResponse(response);
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((e) => DashboardCatalogItem.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<void> installWidget(String slug) async {
    await ApiServices.post(
      _installEndpoint(slug),
      hasToken: true,
      ref: ref,
      data: const <String, dynamic>{},
      headers: const {'Content-Type': 'application/json'},
    );
  }

  Future<void> uninstallWidget(String slug) async {
    await ApiServices.post(
      _uninstallEndpoint(slug),
      hasToken: true,
      ref: ref,
      data: const <String, dynamic>{},
      headers: const {'Content-Type': 'application/json'},
    );
  }

  Future<void> uploadPreviewImage(
    String slug,
    Uint8List pngBytes, {
    String variant = 'dark_desktop',
    String? label,
    int? gridW,
    int? gridH,
  }) async {
    final formData = FormData.fromMap({
      'image':   MultipartFile.fromBytes(pngBytes, filename: '${slug}_$variant.png'),
      'variant': variant,
      if (label != null) 'label': label,
      if (gridW != null) 'grid_w': gridW.toString(),
      if (gridH != null) 'grid_h': gridH.toString(),
    });
    await ApiServices.post(
      _previewUploadEndpoint(slug),
      hasToken: true,
      ref: ref,
      formData: formData,
    );
  }

  dynamic _normalizeResponse(dynamic response) {
    final raw = response is Response ? response.data : response;
    if (raw == null) return null;

    try {
      if (raw is List) return raw;
      if (raw is List<int>) return jsonDecode(utf8.decode(raw));
      if (raw is String) return jsonDecode(raw);
      return raw;
    } catch (_) {
      return null;
    }
  }
}

final dashboardCatalogProvider =
    FutureProvider.family<List<DashboardCatalogItem>, DashboardCatalogQuery>(
  (ref, query) async {
    return ref.read(dashboardCatalogApiProvider).fetchCatalog(
          dashboardKey: query.dashboardKey,
          zoneKey: query.zoneKey,
          source: query.source,
          category: query.category,
          search: query.search,
          installedOnly: query.installedOnly,
        );
  },
);