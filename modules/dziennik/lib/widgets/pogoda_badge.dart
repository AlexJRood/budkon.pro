import 'package:flutter/material.dart';
import '../data/models/dziennik_model.dart';

class PogodaBadge extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (pogoda == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              pogoda!.label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}
