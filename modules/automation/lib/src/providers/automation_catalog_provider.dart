import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/automation_catalog.dart';
import 'automation_api_provider.dart';

final automationCatalogProvider = FutureProvider<AutomationCatalog>((ref) async {
  return ref.watch(automationApiServiceProvider).fetchCatalog();
});
