import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'block_descriptor.dart';

abstract class EmmaBlockDefinition {
  const EmmaBlockDefinition();

  String get key;

  bool supports(EmmaBlockDescriptor block);

  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  });
}