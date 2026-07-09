import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:portal/bars/onHoverPortal/onhover_buttons.dart';

enum ColumnSetType { buy, rent, manage }

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
      ColumnSetType.manage => _buildManageColumns(textColor),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10.0),
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
    return Column(
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
        Expanded(
  child: SingleChildScrollView(
    child: Column(children: buttons),
  ),
),

      ],
    );
  }

  List<Widget> _buildBuyColumns(Color color) => [
        _buildColumn(
          title: 'Estate types'.tr,
          color: color,
          buttons: [
            PopupHoverButton(route: '/feed', label: 'Houses'.tr, color: color, filters: {'estate_type': ['Dom']}),
            PopupHoverButton(route: '/feed', label: 'Flats'.tr, color: color, filters: {'estate_type': ['Flat']}),    
            PopupHoverButton(route: '/feed', label: 'Studio apartment'.tr, color: color, filters: {'estate_type': ['Studio']}),
          ],
        ),
        _buildColumn(
          title: 'Cities'.tr,
          color: color,
          buttons: [
            PopupHoverButton(route: '/feed', label: 'Warszawa', color: color, filters: {'city': ['Warszawa']}),
            PopupHoverButton(route: '/feed', label: 'Kraków', color: color, filters: {'city': ['Kraków']}),
            PopupHoverButton(route: '/feed', label: 'Poznań', color: color, filters: {'city': ['Poznań']}),
            PopupHoverButton(route: '/feed', label: 'Szczecin', color: color, filters: {'city': ['Szczecin']}),
            PopupHoverButton(route: '/feed', label: 'Gdańsk', color: color, filters: {'city': ['Gdańsk']}),
            PopupHoverButton(route: '/feed', label: 'Gdynia', color: color, filters: {'city': ['Gdynia']}),
            PopupHoverButton(route: '/feed', label: 'Wrocław', color: color, filters: {'city': ['Wrocław']}),
            PopupHoverButton(route: '/feed', label: 'Łódź', color: color, filters: {'city': ['Łódź']}),
          ],
        ),
      ];

  

  List<Widget> _buildRentColumns(Color color) => [
            _buildColumn(
          title: 'Estate types'.tr,
          color: color,
          buttons: [
            PopupHoverButton(route: '/feed', label: 'Houses'.tr, color: color, filters: {'estate_type': ['Houses']}),
            PopupHoverButton(route: '/feed', label: 'Flats'.tr, color: color, filters: {'estate_type': ['Flat']}),    
            PopupHoverButton(route: '/feed', label: 'Studio apartment'.tr, color: color, filters: {'estate_type': ['Studio']}),
          ],
        ),
        _buildColumn(
          title: 'Cities'.tr,
          color: color,
          buttons: [
            PopupHoverButton(route: '/feed', label: 'Warszawa', color: color, filters: {'city': ['Warszawa']}),
            PopupHoverButton(route: '/feed', label: 'Kraków', color: color, filters: {'city': ['Kraków']}),
            PopupHoverButton(route: '/feed', label: 'Poznań', color: color, filters: {'city': ['Poznań']}),
            PopupHoverButton(route: '/feed', label: 'Szczecin', color: color, filters: {'city': ['Szczecin']}),
            PopupHoverButton(route: '/feed', label: 'Gdańsk', color: color, filters: {'city': ['Gdańsk']}),
            PopupHoverButton(route: '/feed', label: 'Gdynia', color: color, filters: {'city': ['Gdynia']}),
            PopupHoverButton(route: '/feed', label: 'Wrocław', color: color, filters: {'city': ['Wrocław']}),
            PopupHoverButton(route: '/feed', label: 'Łódź', color: color, filters: {'city': ['Łódź']}),
          ],
        ),
      ];

  List<Widget> _buildManageColumns(Color color) => [
        _buildColumn(
          title: 'Manage Category 1',
          color: color,
          buttons: [
            PopupHoverButton(route: '/feed', label: 'Manage Option 1', color: color),
            PopupHoverButton(route: '/feed', label: 'Manage Option 2', color: color),
          ],
        ),
        _buildColumn(
          title: 'Manage Category 2',
          color: color,
          buttons: [
            PopupHoverButton(route: '/feed', label: 'Manage Option A', color: color),
            PopupHoverButton(route: '/feed', label: 'Manage Option B', color: color),
          ],
        ),
        _buildColumn(
          title: 'Manage Category 3',
          color: color,
          buttons: [
            PopupHoverButton(route: '/feed', label: 'Manage Action X', color: color),
          ],
        ),
      ];
}
