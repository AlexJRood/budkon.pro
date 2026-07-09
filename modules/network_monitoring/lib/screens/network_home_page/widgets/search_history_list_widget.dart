import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/providers/saved_search/last_searches_provider.dart';
import 'package:core/theme/apptheme.dart';
import 'dart:math' as math;

import 'package:core/theme/icons.dart';

import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/lottie.dart';

// State provider for hovered index
final hoveredIndexProvider = StateProvider<int?>((ref) => null);

class SearchHistoryList extends ConsumerStatefulWidget {
  const SearchHistoryList({super.key});

  @override
  _SearchHistoryListState createState() => _SearchHistoryListState();
}

class _SearchHistoryListState extends ConsumerState<SearchHistoryList> {
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    final hoveredIndex = ref.watch(hoveredIndexProvider);
    final theme = ref.watch(themeColorsProvider);
    final lastSearches = ref.watch(lastSearchProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
      child: Container(
        width: 280,
        height: math.max(screenHeight * 0.91, 400),
        decoration: BoxDecoration(
          color: theme.adPopBackground.withAlpha(75),
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Last Searches:'.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Expanded(
              child:
                  lastSearches.isEmpty
                      ? Center(child: AppLottie.noResults(size: 450))
                      : ListView.builder(
                        itemCount: lastSearches.length,
                        itemBuilder: (context, index) {
                          final data = lastSearches[index];
                          return MouseRegion(
                            onEnter: (_) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (hoveredIndex != index) {
                                  ref
                                      .read(hoveredIndexProvider.notifier)
                                      .state = index;
                                }
                              });
                            },
                            onExit: (_) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                ref.read(hoveredIndexProvider.notifier).state =
                                    null;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              color:
                                  hoveredIndex == index
                                      ? theme.themeColor
                                      : Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: ListTile(
                                leading: Icon(
                                  Icons.access_time_rounded,
                                  size: 15,
                                  color:
                                      hoveredIndex == index
                                          ? theme.dashboardContainer
                                          : theme.textColor,
                                ),
                                title: Text(
                                  data.description,
                                  style: TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    color:
                                        hoveredIndex == index
                                            ? theme.dashboardContainer
                                            : theme.textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                trailing:
                                    hoveredIndex == index
                                        ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: AppIcons.pencil(
                                                height: 16,
                                                width: 16,
                                                color: theme.dashboardContainer,
                                              ),
                                              onPressed: () {},
                                            ),
                                            Text(
                                              'Delete'.tr,
                                              style: TextStyle(
                                                color: theme.dashboardContainer,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        )
                                        : null,
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
