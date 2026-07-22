import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../data/models/dziennik_model.dart';

class PogodaBadge extends ConsumerWidget {
  final PogodaTyp? pogoda;
  final double? temperatura;
  final bool showLabel;

  const PogodaBadge({
    super.key,
    required this.pogoda,
    this.temperatura,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pogoda == null) return const SizedBox.shrink();
    final theme = ref.read(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.userTile,
        border: Border.all(color: theme.bordercolor.withAlpha(60)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(pogoda!.emoji, style: const TextStyle(fontSize: 14)),
          if (temperatura != null) ...[
            const SizedBox(width: 4),
            Text(
              '${temperatura!.round()}°C',
              style: TextStyle(color: theme.textColor, fontSize: 13),
            ),
          ],
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              pogoda!.label,
              style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
