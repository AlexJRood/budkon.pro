
import 'package:flutter/material.dart';

class IdName {
  final int id;
  final String name;
  const IdName(this.id, this.name);
}

class PillDropdown extends StatelessWidget {
  final int? currentId;
  final List<IdName> items;
  final dynamic theme;
  final Future<void> Function(int newId) onChanged;

  final double? maxPillWidth;
  final double? menuMaxHeight;
  final double? menuMaxWidth;

  const PillDropdown({
    super.key,
    required this.currentId,
    required this.items,
  required this.theme,
    required this.onChanged,
    this.maxPillWidth,
    this.menuMaxHeight,
    this.menuMaxWidth,
  });

  @override
  Widget build(BuildContext context) { // zakładam, że masz .of; jeśli nie, podaj via Provider
    const horizontalPad = 12.0;

    return DropdownButtonHideUnderline(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxPillWidth ?? double.infinity),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 6),
          decoration: BoxDecoration(
            color: theme.textColor.withAlpha(50),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButton<int>(
            isDense: true,
            isExpanded: false,
            borderRadius: BorderRadius.circular(6),
            dropdownColor: theme.dashboardContainer,
            menuMaxHeight: menuMaxHeight,
            value: currentId,
            icon: const SizedBox.shrink(),
            items: items
                .map(
                  (e) => DropdownMenuItem<int>(
                    value: e.id,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: menuMaxWidth ?? 320),
                      child: Text(
                        e.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
            selectedItemBuilder: (_) => items
                .map(
                  (e) => Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: (maxPillWidth != null)
                            ? (maxPillWidth! - (horizontalPad * 2)).clamp(0, double.infinity)
                            : double.infinity,
                      ),
                      child: Text(
                        e.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) async {
              if (v == null || v == currentId) return;
              await onChanged(v);
            },
          ),
        ),
      ),
    );
  }
}
