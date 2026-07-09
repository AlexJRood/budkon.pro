
import 'package:cloud/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


void refreshSidebarOnUploadComplete(ProviderContainer container) {
  Future.delayed(const Duration(seconds: 2), () => container.invalidate(cloudSidebarProvider));

  Future.delayed(const Duration(seconds: 5), () => container.invalidate(cloudSidebarProvider));
}
