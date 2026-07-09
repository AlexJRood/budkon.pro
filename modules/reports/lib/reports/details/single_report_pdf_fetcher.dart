import 'dart:convert';
import 'package:reports/reports_urls.dart';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

final singleReportPdfProvider = FutureProvider.family<Map<String, dynamic>, int>((
  ref,
  reportId,
) async {
  final response = await ApiServices.get(
    '${ReportsUrls.getReports}$reportId/pdf/',
    ref: ref,
    hasToken: true,
  );

  if (response == null || response.statusCode != 200) {
    throw Exception('Failed to load report details');
  }

  final raw = response.data;

  if (raw is Map<String, dynamic>) {
    return raw;
  }

  if (raw is Map) {
    return Map<String, dynamic>.from(raw);
  }

  if (raw is Uint8List) {
    return Map<String, dynamic>.from(json.decode(utf8.decode(raw)));
  }

  if (raw is List<int>) {
    return Map<String, dynamic>.from(json.decode(utf8.decode(raw)));
  }

  if (raw is String) {
    return Map<String, dynamic>.from(json.decode(raw));
  }

  log('Unsupported payload type: ${raw.runtimeType}');
  throw Exception('Unsupported response payload');
});