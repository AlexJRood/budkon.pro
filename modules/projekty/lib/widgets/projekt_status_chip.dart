import 'package:flutter/material.dart';

class ProjektStatusChip extends StatelessWidget {
  const ProjektStatusChip({
    super.key,
    required this.icon,
    required this.label,
    required this.theme,
    this.color,
  });

  final IconData icon;
  final String label;
  final dynamic theme;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? theme.themeColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
