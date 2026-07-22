import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

class PostepBar extends ConsumerWidget {
  const PostepBar({super.key, required this.postep, this.height = 6});
  final int postep;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final clamped = postep.clamp(0, 100) / 100.0;
    final color = postep >= 100
        ? Colors.green
        : postep >= 50
            ? theme.themeColor
            : theme.themeColor.withAlpha(160);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: clamped,
        minHeight: height,
        backgroundColor: theme.bordercolor.withAlpha(60),
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}
