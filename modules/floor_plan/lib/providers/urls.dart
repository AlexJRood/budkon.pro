// floor_plan/providers/urls.dart

import 'package:get/get_utils/get_utils.dart';

class URLsFloorPlan {
  static const httpOrHttps = 'https';
  static const wsOrWss = 'wss';

  // Keep this consistent for REST and WebSocket.
  static const host = 'www.superbee.cloud';

  // Your curl confirms this endpoint returns JSON:
  // https://www.superbee.cloud/floor-plans/
  static const apiBasePath = '/floor-plans/';
  static const wsBasePath = '/ws/floor-plans/';

  static const baseUrl = '$httpOrHttps://$host$apiBasePath';

  static String appendBaseUrl(String url) {
    final cleanUrl = url.startsWith('/') ? url.substring(1) : url;
    return '$baseUrl$cleanUrl';
  }

  static Uri floorPlanWebSocketUri({
    required String projectId,
    required String token,
  }) {
    final cleanProjectId = projectId.trim();
    final cleanToken = token.trim();

    if (cleanProjectId.isEmpty) {
      throw ArgumentError('missing_project_id_websocket_error'.tr);
    }

    if (cleanToken.isEmpty) {
      throw ArgumentError('missing_token_websocket_error'.tr);
    }

    return Uri(
      scheme: wsOrWss,
      host: host,
      path: '$wsBasePath$cleanProjectId/',
      queryParameters: {
        'token': cleanToken,
      },
    );
  }

  static String floorPlanWebSocketUrl({
    required String projectId,
    required String token,
  }) {
    return floorPlanWebSocketUri(
      projectId: projectId,
      token: token,
    ).toString();
  }
}