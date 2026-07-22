import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../data/models/magazyn_model.dart';

class RuchTile extends ConsumerWidget {
  final MagazynRuchModel ruch;
  const RuchTile({super.key, required this.ruch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final isIn = ruch.typ.isIn;
    final color = isIn ? const Color(0xFF1E7A3A) : theme.themeColor;
    final sign = isIn ? '+' : '−';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIn ? Icons.arrow_downward : Icons.arrow_upward,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ruch.typ.label,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textColor)),
                if (ruch.uwaga != null)
                  Text(ruch.uwaga!,
                      style: TextStyle(fontSize: 11, color: theme.textColor.withAlpha(120))),
                Text(ruch.dataFmt,
                    style: TextStyle(fontSize: 11, color: theme.textColor.withAlpha(100))),
              ],
            ),
          ),
          Text(
            '$sign${ruch.ilosc.toStringAsFixed(1)}',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
