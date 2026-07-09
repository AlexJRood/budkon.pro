import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';





class ClientPortalTabs extends ConsumerWidget {
  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const ClientPortalTabs({
    required this.tabs,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onChanged(i),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: i == currentIndex
                        ? theme.themeColor
                        : Colors.transparent,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tabs[i].tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: i == currentIndex
                          ? Colors.white
                          : theme.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            if (i != tabs.length - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}
