import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Override this in app bootstrap if your API path is different.
///
/// Expected final URLs:
///   {baseUrl}/models/catalog/
///   {baseUrl}/models/{model_id}/
///   {baseUrl}/models/{model_id}/accept-license/
///   {baseUrl}/models/{model_id}/resolve-download/
final emmaLocalApiBaseUrlProvider = StateProvider<String>((ref) {
  return 'https://www.superbee.cloud/emma/local';
});