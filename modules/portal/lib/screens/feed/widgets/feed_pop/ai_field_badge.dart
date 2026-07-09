import 'package:flutter/material.dart';

/// Small badge shown next to field values that were extracted by Emma AI.
class AiFieldBadge extends StatelessWidget {
  const AiFieldBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Uzupełnione przez Emma AI',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 9, color: Colors.white),
            SizedBox(width: 2),
            Text(
              'AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
