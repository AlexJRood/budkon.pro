import 'package:crm/data/clients/client_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:tms_app/todo/provider/task_filters_provider.dart';
import 'package:tms_app/todo/provider/task_management_provider.dart';

class AssignedClientFilterInline extends ConsumerWidget {
  const AssignedClientFilterInline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final isOpen = ref.watch(showAssignedClientSheetProvider);
    final selectedIds = ref.watch(selectedAssignedClientIdsProvider);
    final query = ref.watch(assignedClientSearchQueryProvider);

    final clientsAsync = ref.watch(clientProvider);

    // ✅ label on button
    final label =
    selectedIds.isEmpty
        ? 'Assigned to client'
        : 'Assigned: ${selectedIds.length}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ the filter button
        InkWell(
          onTap: () {
            ref.read(assignedClientFilterControllerProvider).toggleSheet();
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.textColor.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline, color: theme.textColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTextStyles.interMedium14.copyWith(
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: theme.textColor,
                ),
                if (selectedIds.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      ref.read(assignedClientFilterControllerProvider).clear();
                      // ✅ re-fetch tasks with cleared filter
                      ref.read(taskManagementProvider.notifier).fetchStories();
                    },
                    child: Icon(Icons.close, color: theme.textColor, size: 18),
                  ),
                ],
              ],
            ),
          ),
        ),

        // ✅ the sheet under the button
        if (isOpen) ...[
          const SizedBox(height: 8),
          Container(
            width: 320,
            constraints: const BoxConstraints(maxHeight: 320),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.adPopBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.textColor.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // ✅ search field
                TextField(
                  style: TextStyle(color: theme.textColor),
                  cursorColor: theme.textColor,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: theme.textFieldColor,
                    hintText: 'Search client name...',
                    hintStyle: TextStyle(
                      color: theme.textColor.withValues(alpha: 0.6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) {
                    ref.read(assignedClientSearchQueryProvider.notifier).state =
                        v.trim();
                  },
                ),
                const SizedBox(height: 10),

                // ✅ list
                Expanded(
                  child: clientsAsync.when(
                    loading: () => Center(
                      child: CircularProgressIndicator(
                        color: theme.themeColor,
                      ),
                    ),
                    error: (e, _) => Center(
                      child: Text(
                        'Failed to load clients',
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                    data: (clients) {
                      final filteredClients =
                      clients
                          .where((c) {
                        final name = (c.name ?? '').toString();
                        if (query.isEmpty) return true;
                        return name.toLowerCase().contains(
                          query.toLowerCase(),
                        );
                      })
                          .toList();

                      if (filteredClients.isEmpty) {
                        return Center(
                          child: Text(
                            'No clients found',
                            style: TextStyle(color: theme.textColor),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: filteredClients.length,
                        separatorBuilder: (_, __) => Divider(
                          color: theme.textColor.withValues(alpha: 0.08),
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final c = filteredClients[index];
                          final id = c.id;
                          final name = (c.name ?? '').toString();
                          final isSelected = id != null && selectedIds.contains(id);

                          return InkWell(
                            onTap: () {
                              if (id == null) return;
                              ref
                                  .read(assignedClientFilterControllerProvider)
                                  .toggleClient(id);

                              // ✅ trigger filtering immediately
                              ref
                                  .read(taskManagementProvider.notifier)
                                  .fetchStories();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 6,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    color:
                                    isSelected
                                        ? theme.themeColor
                                        : theme.textColor.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      name.isEmpty ? 'Unnamed client' : name,
                                      style: TextStyle(color: theme.textColor),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // ✅ bottom actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.textFieldColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          ref.read(assignedClientFilterControllerProvider).closeSheet();
                        },
                        child: Text(
                          'Close',
                          style: TextStyle(color: theme.textColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.themeColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          // ✅ keep selection, just apply filter (fetch)
                          ref.read(taskManagementProvider.notifier).fetchStories();
                          ref.read(assignedClientFilterControllerProvider).closeSheet();
                        },
                        child: Text(
                          'Apply',
                          style: TextStyle(color: theme.themeTextColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
