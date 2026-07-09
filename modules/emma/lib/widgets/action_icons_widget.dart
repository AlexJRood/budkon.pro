import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';

class ActionIcons extends ConsumerWidget {
  const ActionIcons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    return  Padding(
      padding: const EdgeInsets.only(left: 18.0, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          AppIcons.like(color: theme.textColor.withAlpha((255 * 0.7).toInt()),
            height: 20,
            width: 20,),
          const SizedBox(width: 8),
          Icon(
            Icons.reply,
            color: theme.textColor.withAlpha((255 * 0.7).toInt()),
            size: 20,
          ),
          const SizedBox(width: 8),
           AppIcons.moreVertical(color: theme.textColor.withAlpha((255 * 0.7).toInt()),
            height: 20,
             width: 20,),
        ],
      ),
    );
  }
}
