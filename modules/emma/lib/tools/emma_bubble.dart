import 'package:emma/screens/emma_inline.dart';
import 'package:emma/screens/overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

// budkon: dynamic_app removed — openEmmaForDynamicWidget opens emma without page/node context.

Future<void> openEmmaForDynamicWidget({
  required BuildContext context,
  required WidgetRef ref,
  required ThemeColors theme,
  String? widgetLabel,
}) async {
  final container = ProviderScope.containerOf(context);
  await showGenericAiSheet(
    context: context,
    theme: theme,
    title: 'Emma',
    headerTag: widgetLabel,
    container: container,
    useScroll: false,
    child: const EmmaChatInline(),
  );
}
