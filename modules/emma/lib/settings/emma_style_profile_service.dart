import 'dart:convert';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';

class EmmaStyleProfile {
  final String status; // pending | generating | ready | failed
  final String? styleText;
  final List<int> exampleAdIds;
  final String? generatedAt;
  final int adsAvailable;

  const EmmaStyleProfile({
    required this.status,
    this.styleText,
    required this.exampleAdIds,
    this.generatedAt,
    required this.adsAvailable,
  });

  factory EmmaStyleProfile.fromJson(Map<String, dynamic> json) => EmmaStyleProfile(
        status: json['status'] as String? ?? 'pending',
        styleText: json['style_text'] as String?,
        exampleAdIds: (json['example_ad_ids'] as List<dynamic>? ?? []).cast<int>(),
        generatedAt: json['generated_at'] as String?,
        adsAvailable: json['ads_available_for_analysis'] as int? ?? 0,
      );

  bool get isReady => status == 'ready';
  bool get isGenerating => status == 'generating';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
  bool get canGenerate => adsAvailable >= 3;
}

class EmmaStyleProfileService {
  static const _base = '${URLs.baseUrl}/portal/emma/style-profile';

  static Future<EmmaStyleProfile?> fetch(dynamic ref) async {
    final res = await ApiServices.get('$_base/', hasToken: true, ref: ref);
    if (res == null || res.statusCode != 200) return null;
    return EmmaStyleProfile.fromJson(json.decode(utf8.decode(res.data)));
  }

  static Future<EmmaStyleProfile?> update({
    required dynamic ref,
    String? styleText,
  }) async {
    final res = await ApiServices.patch(
      '$_base/update/',
      data: {'style_text': styleText},
      hasToken: true,
      ref: ref,
    );
    if (res == null || res.statusCode != 200) return null;
    return EmmaStyleProfile.fromJson(json.decode(utf8.decode(res.data)));
  }

  static Future<bool> generate(dynamic ref) async {
    final res = await ApiServices.post(
      '$_base/generate/',
      data: {},
      hasToken: true,
      ref: ref,
    );
    return res != null && res.statusCode == 202;
  }

  static Future<EmmaStyleProfile?> reset(dynamic ref) async {
    final res = await ApiServices.post(
      '$_base/reset/',
      data: {},
      hasToken: true,
      ref: ref,
    );
    if (res == null || res.statusCode != 200) return null;
    return EmmaStyleProfile.fromJson(json.decode(utf8.decode(res.data)));
  }
}
