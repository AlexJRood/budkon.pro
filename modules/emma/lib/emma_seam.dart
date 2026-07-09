import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/kernel/kernel.dart';
import 'package:core/theme/apptheme.dart';

import 'tools/emma_bubble.dart';
import 'settings/providers.dart';

class _EmmaGatewayImpl implements EmmaGateway {
  @override
  Future<void> openForDynamicWidget(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    return openEmmaForDynamicWidget(context: context, ref: ref, theme: theme);
  }

  @override
  Future<void> saveDynamicSettings(WidgetRef ref) =>
      ref.read(aiDynamicSettingsProvider.notifier).saveAll();
}

/// Installs the emma implementation of [emmaGatewayProvider]. Spread into every
/// entrypoint's overrides.
final List<Override> emmaSeamOverrides = [
  emmaGatewayProvider.overrideWith((ref) => _EmmaGatewayImpl()),
];
