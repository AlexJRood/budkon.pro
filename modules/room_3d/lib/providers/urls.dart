// room_3d/providers/urls.dart — mirrors floor_plan/providers/urls.dart
// exactly (same host, same base-URL shape) since both live on the same
// hously.cloud backend.

class URLsRoom3d {
  static const httpOrHttps = 'https';
  static const host = 'www.superbee.cloud';
  static const apiBasePath = '/room-3d/';

  static const baseUrl = '$httpOrHttps://$host$apiBasePath';
}
