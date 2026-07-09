import 'package:flutter/material.dart';
import 'module.dart';

class PracownicyDockItem extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  const PracownicyDockItem(
      {super.key, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => NavigationDestination(
        icon: Icon(PracownicyModule.icon),
        selectedIcon:
            Icon(PracownicyModule.iconFilled, color: PracownicyModule.color),
        label: PracownicyModule.label,
      );
}
