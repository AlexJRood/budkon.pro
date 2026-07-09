import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emma/settings/emma_style_profile_service.dart';

final emmaStyleProfileProvider =
    FutureProvider.autoDispose<EmmaStyleProfile?>((ref) async {
  return EmmaStyleProfileService.fetch(ref);
});
