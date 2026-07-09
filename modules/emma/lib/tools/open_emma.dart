import 'package:core/ui/device_type_util.dart';
import 'package:emma/screens/emma_inline.dart';
import 'package:emma/screens/overlay.dart';
import 'package:emma/tools/emma_overlay_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';

BuildContext _resolveDisplayContext({
  required WidgetRef ref,
  required BuildContext fallbackContext,
}) {
  try {
    final nav = ref.read(navigationService);

    final navContext = nav.navigatorKey.currentContext;
    if (navContext != null) return navContext;

    final stateContext = nav.navigatorKey.currentState?.context;
    if (stateContext != null) return stateContext;
  } catch (_) {}

  return fallbackContext;
}

Future<void> openEmmaOverlay({
  required BuildContext context,
  required WidgetRef ref,
  Map<String, dynamic>? data,
  String title = 'Emma',
}) async {
  // If a module (e.g. docs) has registered a side-panel interceptor,
  // delegate to it instead of opening a floating overlay.
  final intercept = EmmaOverlayManager.interceptor;
  if (intercept != null) {
    intercept();
    return;
  }

  final theme = ref.read(themeColorsProvider);

  final sourceContext = context;
  final displayContext = _resolveDisplayContext(
    ref: ref,
    fallbackContext: sourceContext,
  );

  final container = ProviderScope.containerOf(sourceContext, listen: false);
  final isMobile = DeviceTypeUtil.isMobile(sourceContext);

  await Future<void>.delayed(Duration.zero);

  if (!sourceContext.mounted || !displayContext.mounted) return;

  await showGenericAiSheet<void>(
    context: sourceContext,
    presentationContext: displayContext,
    theme: theme,
    title: title,
    useScroll: false,
    cancelRow: false,
    container: container,
    isMobileOverride: isMobile,
    child: const EmmaChatInline(),
  );
}