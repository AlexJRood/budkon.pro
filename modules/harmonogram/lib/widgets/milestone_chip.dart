import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:intl/intl.dart';
import '../data/models/harmonogram_model.dart';

class MilestoneChip extends ConsumerWidget {
  final MilestoneModel milestone;

  const MilestoneChip({super.key, required this.milestone});

  static final _fmt = DateFormat('dd.MM.yy');

  Color _parseColor() {
    try {
      final hex = milestone.kolor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final color = _parseColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: milestone.osiagniety
            ? color.withAlpha(40)
            : color.withAlpha(25),
        border: Border.all(
          color: milestone.osiagniety ? color : color.withAlpha(100),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            milestone.osiagniety
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            milestone.nazwa,
            style: TextStyle(color: theme.textColor, fontSize: 11),
          ),
          const SizedBox(width: 4),
          Text(
            _fmt.format(milestone.data),
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
