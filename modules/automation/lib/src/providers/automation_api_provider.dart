import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/automation_studio_config.dart';
import '../services/automation_api_service.dart';

final automationStudioConfigProvider = Provider<AutomationStudioConfig>((ref) {
  return AutomationStudioDefaults.defaultConfig;
});

final automationApiServiceProvider = Provider<AutomationApiService>((ref) {
  final config = ref.watch(automationStudioConfigProvider);

  return AutomationApiService(
    config: config,
    ref: ref,
  );
});