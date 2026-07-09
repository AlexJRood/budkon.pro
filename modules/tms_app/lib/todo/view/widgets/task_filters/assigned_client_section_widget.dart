import 'package:crm/data/clients/client_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:tms_app/todo/provider/filtered_tasks_provider.dart';
import 'package:tms_app/todo/provider/task_filters_provider.dart';
import 'package:tms_app/todo/view/widgets/task_filters/selection_widgets.dart';

class AssignedClientSection extends ConsumerWidget {
  final dynamic theme;
  final GlobalKey searchFieldKey;
  final void Function(GlobalKey key) onSearchFieldFocused;

  const AssignedClientSection({
    super.key,
    required this.theme,
    required this.searchFieldKey,
    required this.onSearchFieldFocused,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(taskFiltersProvider);

    final selectedIds = filters.assignedClientIds;
    final isOpen = ref.watch(showAssignedClientsSheetProvider);
    final query = ref.watch(assignedClientsSearchQueryProvider);
    final clientsAsync = ref.watch(clientProvider);

    final label =
        selectedIds.isEmpty
            ? 'Not selected'.tr
            : '${selectedIds.length} ${"Selected".tr}';

    return Column(
      children: [
        SelectionHeaderBar(
          theme: theme,
          label: label,
          isOpen: isOpen,
          onClear: () {
            ref
                .read(taskFiltersProvider.notifier)
                .setAssignedToClientIds(const []);
            ref.read(assignedClientsSearchQueryProvider.notifier).state = '';
          },
          onToggleOpen: () {
            ref.read(showAssignedClientsSheetProvider.notifier).state = !isOpen;
          },
        ),
        if (isOpen) ...[
          const SizedBox(height: 10),
          SelectionListContainer(
            theme: theme,
            child: Column(
              children: [
                KeyedSubtree(
                  key: searchFieldKey,
                  child: SelectionSearchField(
                    theme: theme,
                    hint: 'Search clients...'.tr,
                    onFocused: () => onSearchFieldFocused(searchFieldKey),
                    onChanged: (v) {
                      ref.read(assignedClientsSearchQueryProvider.notifier).state = v.trim();
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: clientsAsync.when(
                    loading:
                        () => Center(
                          child: CircularProgressIndicator(
                            color: theme.themeColor,
                          ),
                        ),
                    error:
                        (e, _) => Center(
                          child: Text(
                            'Failed to load clients'.tr,
                            style: TextStyle(
                              color: theme.textColor.withAlpha(
                                (255 * 0.7).toInt(),
                              ),
                            ),
                          ),
                        ),
                    data: (clients) {
                      final q = query.trim().toLowerCase();
                      final filtered =
                          q.isEmpty
                              ? clients
                              : clients.where((c) {
                                final name = (c.name).toString().toLowerCase();
                                final id = (c.id).toString().toLowerCase();
                                return name.contains(q) || id.contains(q);
                              }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            'No clients found'.tr,
                            style: TextStyle(
                              color: theme.textColor.withAlpha(
                                (255 * 0.7).toInt(),
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder:
                            (_, __) => Divider(
                              color: theme.textColor.withAlpha(
                                (255 * 0.08).toInt(),
                              ),
                            ),
                        itemBuilder: (_, i) {
                          final c = filtered[i];
                          final id = c.id;
                          final name = (c.name).toString();

                          final isSelected = selectedIds.contains(id);

                          return CheckboxListTile(
                            dense: true,
                            value: isSelected,
                            activeColor: theme.themeColor,
                            checkColor: theme.themeTextColor,
                            onChanged: (_) => _toggleAssignedClient(ref, id),
                            title: Text(
                              name.isEmpty ? 'Unnamed client'.tr : name,
                              style: TextStyle(color: theme.textColor),
                            ),
                            subtitle: Text(
                              'ID: $id',
                              style: TextStyle(
                                color: theme.textColor.withAlpha(
                                  (255 * 0.7).toInt(),
                                ),
                                fontSize: 12,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _toggleAssignedClient(WidgetRef ref, int id) {
    final filters = ref.read(taskFiltersProvider);
    final current = filters.assignedClientIds;
    final next = [...current];

    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }

    ref.read(taskFiltersProvider.notifier).setAssignedToClientIds(next);
  }
}

/// ===============================
/// ✅ MEMBERS SECTION
/// ===============================
class MembersSection extends ConsumerWidget {
  final dynamic theme;
  final GlobalKey searchFieldKey;
  final void Function(GlobalKey key) onSearchFieldFocused;

  const MembersSection({
    super.key,
    required this.theme,
    required this.searchFieldKey,
    required this.onSearchFieldFocused,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(taskFiltersProvider);

    final selectedIds = filters.memberIds;
    final isOpen = ref.watch(showMembersSheetProvider);
    final query = ref.watch(membersSearchQueryProvider);
    final membersAsync = ref.watch(filteredMembersProvider);

    final label =
        selectedIds.isEmpty
            ? 'Not selected'.tr
            : '${selectedIds.length} ${"Selected".tr}';

    return Column(
      children: [
        SelectionHeaderBar(
          theme: theme,
          label: label,
          isOpen: isOpen,
          onClear: () {
            ref.read(taskFiltersProvider.notifier).setMembers(const []);
            ref.read(membersSearchQueryProvider.notifier).state = '';
          },
          onToggleOpen: () {
            ref.read(showMembersSheetProvider.notifier).state = !isOpen;
          },
        ),
        if (isOpen) ...[
          const SizedBox(height: 10),
          SelectionListContainer(
            theme: theme,
            child: Column(
              children: [
                KeyedSubtree(
                  key: searchFieldKey,
                  child: SelectionSearchField(
                    theme: theme,
                    hint: 'Search members...'.tr,
                    onFocused: () => onSearchFieldFocused(searchFieldKey),
                    onChanged: (v) {
                      ref.read(membersSearchQueryProvider.notifier).state = v.trim();
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: membersAsync.when(
                    loading:
                        () => Center(
                          child: CircularProgressIndicator(
                            color: theme.themeColor,
                          ),
                        ),
                    error:
                        (e, _) => Center(
                          child: Text(
                            'Failed to load members'.tr,
                            style: TextStyle(
                              color: theme.textColor.withAlpha(
                                (255 * 0.7).toInt(),
                              ),
                            ),
                          ),
                        ),
                    data: (list) {
                      // we filter again by query in case filteredMembersProvider isn't wired
                      final q = query.trim().toLowerCase();
                      final filtered =
                          q.isEmpty
                              ? list
                              : list.where((m) {
                                final n = m.name.toLowerCase();
                                final e = (m.email ?? '').toLowerCase();
                                return n.contains(q) ||
                                    e.contains(q) ||
                                    m.id.toString().contains(q);
                              }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            'No members found'.tr,
                            style: TextStyle(
                              color: theme.textColor.withAlpha(
                                (255 * 0.7).toInt(),
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder:
                            (_, __) => Divider(
                              color: theme.textColor.withAlpha(
                                (255 * 0.08).toInt(),
                              ),
                            ),
                        itemBuilder: (_, i) {
                          final m = filtered[i];
                          final isSelected = selectedIds.contains(m.id);

                          return CheckboxListTile(
                            dense: true,
                            value: isSelected,
                            activeColor: theme.themeColor,
                            checkColor: theme.themeTextColor,
                            onChanged:
                                (_) => ref
                                    .read(taskFiltersProvider.notifier)
                                    .toggleMember(m.id),
                            title: Text(
                              m.name,
                              style: TextStyle(color: theme.textColor),
                            ),
                            subtitle: Text(
                              '${m.email ?? ''}  •  ID: ${m.id}',
                              style: TextStyle(
                                color: theme.textColor.withAlpha(
                                  (255 * 0.7).toInt(),
                                ),
                                fontSize: 12,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
