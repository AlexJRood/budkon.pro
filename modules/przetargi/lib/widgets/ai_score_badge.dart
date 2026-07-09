import 'package:flutter/material.dart';

class AiScoreBadge extends StatelessWidget {
  final int score;
  final bool compact;

  const AiScoreBadge({super.key, required this.score, this.compact = false});

  Color _color() {
    if (score >= 70) return Colors.green.shade700;
    if (score >= 45) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  Color _bg() {
    if (score >= 70) return Colors.green.shade50;
    if (score >= 45) return Colors.orange.shade50;
    return Colors.red.shade50;
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _bg(),
          shape: BoxShape.circle,
          border: Border.all(color: _color().withOpacity(0.4)),
        ),
        alignment: Alignment.center,
        child: Text(
          '$score',
          style: TextStyle(
            color: _color(),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _bg(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color().withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '✦',
            style: TextStyle(color: _color(), fontSize: 10),
          ),
          const SizedBox(width: 4),
          Text(
            '$score / 100',
            style: TextStyle(
              color: _color(),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
