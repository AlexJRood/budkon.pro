import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:portal/bars/onHoverPortal/onhover_buttons.dart';

enum ColumnSetType { buy, rent, manage, sell }

class ManagePopupContentWidget extends ConsumerWidget {
  final Color color;
  final ColumnSetType type;

  const ManagePopupContentWidget({
    super.key,
    required this.color,
    this.type = ColumnSetType.manage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final textColor = theme.textColor;

    // Wybór kolumn na podstawie typu
    final visibleColumns = switch (type) {
      ColumnSetType.buy => _buildBuyColumns(textColor),
      ColumnSetType.rent => _buildRentColumns(textColor),
      ColumnSetType.sell => _buildSellColumns(textColor),
      ColumnSetType.manage => _buildManageColumns(textColor),
    };

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(6, (index) {
          return Expanded(
            child: index < visibleColumns.length
                ? visibleColumns[index]
                : const SizedBox.shrink(), // Puste miejsce, ale zachowuje układ
          );
        }),
      ),
    );
  }

  Widget _buildColumn({
    required String title,
    required List<Widget> buttons,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              title,
              style: AppTextStyles.interMedium14.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...buttons,
        ],
      ),
    );
  }

  List<Widget> _buildBuyColumns(Color color) => [
        _buildColumn(
          title: 'Buy Category 1',
          color: color,
          buttons: [
            PopupHoverButton(label: 'Buy Option 1', route: '/feed', color: color),
            PopupHoverButton(label: 'Buy Option 2', route: '/feed', color: color),
          ],
        ),
        _buildColumn(
          title: 'Buy Category 2',
          color: color,
          buttons: [
            PopupHoverButton(label: 'Buy Option A', route: '/feed', color: color),
          ],
        ),
      ];

  List<Widget> _buildRentColumns(Color color) => [
        _buildColumn(
          title: 'Rent Category 1',
          color: color,
          buttons: [
            PopupHoverButton(label: 'Rent Option 1', route: '/feed', color: color),
            PopupHoverButton(label: 'Rent Option 2', route: '/feed', color: color),
          ],
        ),
      ];

  List<Widget> _buildSellColumns(Color color) => [
      _buildColumn(
        title: 'Category 1',
          color: color,
        buttons: [
          PopupHoverButton(label: 'Sell Option 1', route: '/feed', color: color),
          PopupHoverButton(label: 'Sell Option 2', route: '/feed', color: color),
          PopupHoverButton(label: 'Sell Option 3', route: '/feed', color: color),
        ],
      ),
      _buildColumn(
        title: 'Category 2',
          color: color,
        buttons: [
          PopupHoverButton(label: 'Sell Option A', route: '/feed', color: color),
          PopupHoverButton(label: 'Sell Option B', route: '/feed', color: color),
          PopupHoverButton(label: 'Sell Option C', route: '/feed', color: color),
        ],
      ),
      _buildColumn(
        title: 'Category 3',
          color: color,
        buttons: [
          PopupHoverButton(label: 'Sell Action X', route: '/feed', color: color),
          PopupHoverButton(label: 'Sell Action Y', route: '/feed', color: color),
          PopupHoverButton(label: 'Sell Action Z', route: '/feed', color: color),
        ],
      ),
    ];

  List<Widget> _buildManageColumns(Color color) => [
        _buildColumn(
          title: 'Manage Category 1',
          color: color,
          buttons: [
            PopupHoverButton(label: 'Manage Option 1', route: '/feed', color: color),
            PopupHoverButton(label: 'Manage Option 2', route: '/feed', color: color),
          ],
        ),
        _buildColumn(
          title: 'Manage Category 2',
          color: color,
          buttons: [
            PopupHoverButton(label: 'Manage Option A', route: '/feed', color: color),
            PopupHoverButton(label: 'Manage Option B', route: '/feed', color: color),
          ],
        ),
        _buildColumn(
          title: 'Manage Category 3',
          color: color,
          buttons: [
            PopupHoverButton(label: 'Manage Action X', route: '/feed', color: color),
          ],
        ),
      ];
}
