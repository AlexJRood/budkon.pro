import 'package:flutter/material.dart';

class PostepBar extends StatelessWidget {
  const PostepBar({super.key, required this.postep, this.height = 6});
  final int postep;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final clamped = postep.clamp(0, 100) / 100.0;
    final color = postep >= 100
        ? Colors.green
        : postep >= 50
            ? cs.primary
            : cs.tertiary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: clamped,
        minHeight: height,
        backgroundColor: cs.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}
