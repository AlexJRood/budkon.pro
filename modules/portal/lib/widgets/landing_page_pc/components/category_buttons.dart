import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/apptheme.dart';

class CategorySelector extends ConsumerWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final List<String> tabs; // <- dodane
  final bool isMobile;
  final bool isTablet;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.tabs, // <- dodane,
    this.isMobile = false,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final widthPerCategory = constraints.maxWidth / tabs.length;

        return Stack(
          children: [
            // Line behind all tabs
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(height: 2, color: theme.textColor),
            ),

            // Moving underline
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: 0,
              left: tabs.indexOf(selectedCategory) * widthPerCategory,
              width: widthPerCategory,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: theme.themeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Category buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:
                  tabs.map((tab) {
                    final isSelected = tab == selectedCategory;
                    return Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: elevatedButtonStyleRounded10,
                          onPressed: () {
                            onCategorySelected(tab);
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: isTablet ? 4 : 8,
                            ),
                            child: Text(
                              tab,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? theme.textColor
                                        : theme.textColor.withAlpha(
                                          (255 * 0.5).toInt(),
                                        ),
                                fontSize:
                                    isMobile ? 12.0 : (isTablet ? 14.0 : 16.0),
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        );
      },
    );
  }
}
