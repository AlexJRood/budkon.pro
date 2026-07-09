import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';
import 'package:tms_app/todo/provider/task_filters_provider.dart';
import 'package:tms_app/todo/provider/task_labels_provider.dart';
import 'package:tms_app/todo/view/widgets/task_filters/assigned_client_section_widget.dart';
import 'package:tms_app/todo/view/widgets/task_filters/filter_section_title_widget.dart';
import 'package:tms_app/todo/view/widgets/task_filters/selection_widgets.dart';
import 'package:tms_app/todo/view/widgets/task_filters/timestamp_range_section_widget.dart';

class FiltersBody extends ConsumerWidget {
  final bool isMobile;
  final dynamic theme;
  final dynamic filters;

  final TextEditingController nameCtrl;
  final Future<DateTime?> Function(BuildContext, DateTime?) pickDateTime;
  final String Function(DateTime?) fmt;

  final GlobalKey clientSearchKey;
  final GlobalKey labelSearchKey;
  final GlobalKey memberSearchKey;
  final void Function(GlobalKey key) onSearchFieldFocused;

  const FiltersBody({
    super.key,
    required this.isMobile,
    required this.theme,
    required this.filters,
    required this.nameCtrl,
    required this.pickDateTime,
    required this.fmt,
    required this.clientSearchKey,
    required this.labelSearchKey,
    required this.memberSearchKey,
    required this.onSearchFieldFocused,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterNameSection(theme: theme, nameCtrl: nameCtrl),
        const SizedBox(height: 14),

        FilterSectionTitle(theme: theme, title: 'Assigned To'.tr),
        const SizedBox(height: 8),
        AssignedClientSection(
          theme: theme,
          searchFieldKey: clientSearchKey,
          onSearchFieldFocused: onSearchFieldFocused,
        ),
        const SizedBox(height: 14),

        // ✅ NEW: Priority filter
        FilterSectionTitle(theme: theme, title: 'Priority'.tr),
        const SizedBox(height: 8),
        PriorityFilterSection(theme: theme),
        const SizedBox(height: 14),

        // ✅ NEW: is_completed filter
        FilterSectionTitle(theme: theme, title: 'Completion'.tr),
        const SizedBox(height: 8),
        IsCompletedFilterSection(theme: theme),
        const SizedBox(height: 14),

        // ✅ NEW: Label filter
        FilterSectionTitle(theme: theme, title: 'Labels'.tr),
        const SizedBox(height: 8),
        LabelsFilterSection(
          theme: theme,
          searchFieldKey: labelSearchKey,
          onSearchFieldFocused: onSearchFieldFocused,
        ),
        const SizedBox(height: 14),

        FilterSectionTitle(theme: theme, title: 'Task Timestamp Range'.tr),
        const SizedBox(height: 8),
        TimestampRangeSection(
          theme: theme,
          pickDateTime: pickDateTime,
          fmt: fmt,
        ),
        const SizedBox(height: 14),

        FilterSectionTitle(theme: theme, title: 'Deadline Range'.tr),
        const SizedBox(height: 8),
        DeadlineRangeSection(
          theme: theme,
          pickDateTime: pickDateTime,
          fmt: fmt,
        ),
        const SizedBox(height: 14),

        FilterSectionTitle(theme: theme, title: 'Members Filter'.tr),
        const SizedBox(height: 8),
        MembersSection(
          theme: theme,
          searchFieldKey: memberSearchKey,
          onSearchFieldFocused: onSearchFieldFocused,
        ),

        if (isMobile) const SizedBox(height: 80),
      ],
    );
  }
}

/// ===============================
/// ✅ PRIORITY FILTER SECTION
/// ===============================
class PriorityFilterSection extends ConsumerWidget {
  final ThemeColors theme;
  const PriorityFilterSection({super.key, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(taskFiltersProvider);
    final current = filters.priority;

    Widget chip(String label, String? value) {
      final selected = current == value;
      return ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: selected == true ? theme.themeTextColor : theme.textColor,
          ),
        ),
        selected: selected,
        selectedColor: theme.themeColor,
        checkmarkColor: theme.themeTextColor,
        backgroundColor: theme.dashboardContainer,
        onSelected: (_) {
          ref.read(taskFiltersProvider.notifier).setPriority(value);
        },
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('Any'.tr, null),
        chip('High'.tr, 'H'),
        chip('Medium'.tr, 'M'),
        chip('Low'.tr, 'L'),
      ],
    );
  }
}

/// ===============================
/// ✅ IS_COMPLETED FILTER SECTION
/// ===============================
class IsCompletedFilterSection extends ConsumerWidget {
  final ThemeColors theme;
  const IsCompletedFilterSection({super.key, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(taskFiltersProvider);
    final current = filters.isCompleted;

    Widget chip(String label, bool? value) {
      final selected = current == value;
      return ChoiceChip(
        label: Text(label, style: TextStyle(
          color: selected == true ? theme.themeTextColor : theme.textColor,
        ),),
        selected: selected,
        selectedColor: theme.themeColor,
        checkmarkColor: theme.themeTextColor,
        backgroundColor: theme.dashboardContainer,
        onSelected: (_) {
          ref.read(taskFiltersProvider.notifier).setIsCompleted(value);
        },
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          chip('Any'.tr, null),
          const SizedBox(width: 8),
          chip('Completed'.tr, true),
          const SizedBox(width: 8),
          chip('Not completed'.tr, false),
        ],
      ),
    );
  }
}

/// ===============================
/// ✅ LABELS FILTER SECTION (MULTI-SELECT)
/// ===============================
class LabelsFilterSection extends ConsumerWidget {
  final ThemeColors theme;
  final GlobalKey searchFieldKey;
  final void Function(GlobalKey key) onSearchFieldFocused;

  const LabelsFilterSection({
    super.key,
    required this.theme,
    required this.searchFieldKey,
    required this.onSearchFieldFocused,
  });

  Color _parseHexColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    return Color(int.parse(value, radix: 16));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(taskFiltersProvider);

    final selectedIds = filters.labelIds;
    final isOpen = ref.watch(showLabelsSheetProvider);
    final query = ref.watch(labelsSearchQueryProvider);

    final labelsResp = ref.watch(taskLabelsProvider);
    final allLabels = labelsResp?.results ?? const [];

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
            ref.read(taskFiltersProvider.notifier).setLabelIds(const []);
            ref.read(labelsSearchQueryProvider.notifier).state = '';
          },
          onToggleOpen: () {
            ref.read(showLabelsSheetProvider.notifier).state = !isOpen;
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
                    hint: 'Search labels...'.tr,
                    onFocused: () => onSearchFieldFocused(searchFieldKey),
                    onChanged: (v) {
                      ref.read(labelsSearchQueryProvider.notifier).state = v.trim();
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: () {
                    final q = query.trim().toLowerCase();
                    final filtered =
                        q.isEmpty
                            ? allLabels
                            : allLabels.where((l) {
                              final title = (l.name).toString().toLowerCase();
                              final id = (l.id).toString().toLowerCase();
                              return title.contains(q) || id.contains(q);
                            }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          'No labels found'.tr,
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
                        final l = filtered[i];
                        final title = (l.name).toString();
                        final color = _parseHexColor(l.color.toString());
                        final rawId = l.id;
                        final id = rawId;
                        if (id == 0) return const SizedBox.shrink();

                        final isSelected = selectedIds.contains(id);

                        return CheckboxListTile(
                          dense: true,
                          value: isSelected,
                          activeColor: theme.themeColor,
                          checkColor: theme.themeTextColor,
                          onChanged: (_) {
                            ref
                                .read(taskFiltersProvider.notifier)
                                .toggleLabel(id);
                          },
                          title: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.black.withAlpha(38),
                                    width: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  title.isEmpty ? 'Unnamed'.tr : title,
                                  style: TextStyle(color: theme.textColor),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
                  }(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
