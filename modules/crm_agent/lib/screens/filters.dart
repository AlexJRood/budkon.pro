import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:crm_agent/models/user_contact_status_model.dart';
import 'package:crm_agent/add_client_form/provider/contact_type_provider.dart';
import 'package:crm/data/clients/client_provider.dart';

class FilterSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  const FilterSheet({super.key, required this.scrollController});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  int? selectedStatus;
  final Set<int> selectedTypeIds = {};
  String? selectedSort = 'date_create_desc';

  final Map<String, String> sortOptions = {
    'date_create_desc': 'Data utworzenia ↓',
    'date_create_asc': 'Data utworzenia ↑',
    'date_update_desc': 'Data aktualizacji ↓',
    'date_update_asc': 'Data aktualizacji ↑',
    'name_asc': 'Imię A→Z',
    'name_desc': 'Imię Z→A',
    'last_name_asc': 'Nazwisko A→Z',
    'last_name_desc': 'Nazwisko Z→A',
    'star_desc': 'Najpierw ulubione',
  };

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final nav = ref.read(navigationService);
    final path = nav.currentPath;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: theme.adPopBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            controller: widget.scrollController,
            children: [
              // Grabber
              Align(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.textColor.withAlpha(90),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Filters'.tr,
                style: AppTextStyles.interSemiBold18.copyWith(
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 16),

              // STATUSY
              Text(
                'Status'.tr,
                style: AppTextStyles.interMedium14dark.copyWith(
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<UserContactStatusModel>>(
                future: ref.watch(clientProvider.notifier).fetchStatuses(ref),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _ShimmerChip(),
                        _ShimmerChip(),
                        _ShimmerChip(),
                      ],
                    );
                  }
                  if (snapshot.hasError) {
                    return Text(
                      'error_loading_statuses'.tr,
                      style: TextStyle(color: theme.textColor),
                    );
                  }
                  final statuses = snapshot.data ?? [];
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChipButton(
                          label: 'All'.tr,
                          selected: selectedStatus == null,
                          onTap: () => setState(() => selectedStatus = null),
                        ),
                        const SizedBox(width: 8),
                        ...statuses.map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: _FilterChipButton(
                              label: s.statusName,
                              selected: selectedStatus == s.statusId,
                              onTap:
                                  () => setState(
                                    () => selectedStatus = s.statusId,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _FilterChipButton(
                          icon: AppIcons.pencil(
                            color: theme.textColor,
                            width: 14,
                            height: 14,
                          ),
                          label: 'Edit'.tr,
                          selected: false,
                          onTap:
                              () => nav.pushNamedScreen(
                                '$path/${Routes.contactStatuses}',
                                data: {'isFilter': true},
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // TYPY KONTAKTÓW (MULTI)
              Row(
                children: [
                  Text(
                    'Contact type'.tr,
                    style: AppTextStyles.interMedium14dark.copyWith(
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, _) {
                  final typesFetch = ref.watch(contactTypesFetchProvider);
                  final meta = ref.watch(contactTypeProvider);

                  return typesFetch.when(
                    loading:
                        () => Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            _ShimmerChip(),
                            _ShimmerChip(),
                            _ShimmerChip(),
                          ],
                        ),
                    error:
                        (_, __) => Text(
                          'error_loading_types'.tr,
                          style: TextStyle(color: theme.textColor),
                        ),
                    data: (_) {
                      final types = meta.contactType;
                      if (types.isEmpty) {
                        return Text(
                          'no_types_available'.tr,
                          style: TextStyle(color: theme.textColor),
                        );
                      }
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChipButton(
                              label: 'All'.tr,
                              selected: selectedTypeIds.isEmpty,
                              onTap:
                                  () => setState(() => selectedTypeIds.clear()),
                            ),
                            const SizedBox(width: 8),
                            ...types.map((t) {
                              final id = t.id;
                              final isOn = selectedTypeIds.contains(id);
                              final label =
                                  (t.label.isNotEmpty
                                      ? t.label
                                      : t.contactType);
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: _FilterChipButton(
                                  label: label,
                                  selected: isOn,
                                  onTap: () {
                                    setState(() {
                                      if (isOn)
                                        selectedTypeIds.remove(id);
                                      else
                                        selectedTypeIds.add(id);
                                    });
                                  },
                                ),
                              );
                            }),
                            const SizedBox(width: 8),
                            _FilterChipButton(
                              icon: AppIcons.pencil(
                                color: theme.textColor,
                                width: 14,
                                height: 14,
                              ),
                              label: 'Edit'.tr,
                              selected: false,
                              onTap:
                                  () => nav.pushNamedScreen(
                                    '$path/${Routes.contactTypes}',
                                    data: {'isFilter': false},
                                  ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 20),

              // SORT
              Text(
                'Sort'.tr,
                style: AppTextStyles.interMedium14dark.copyWith(
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final popupWidth = constraints.maxWidth;

                  return Container(
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: theme.adPopBackground,
                      border: Border.all(color: theme.textColor.withAlpha(50)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        value: selectedSort,
                        isExpanded: true,
                        onChanged: (v) => setState(() => selectedSort = v),
                        style: AppTextStyles.interMedium14dark.copyWith(
                          color: theme.textColor,
                        ),
                        buttonStyleData: const ButtonStyleData(
                          height: 44,
                          padding: EdgeInsets.symmetric(horizontal: 14),
                        ),
                        iconStyleData: IconStyleData(
                          icon: AppIcons.iosArrowDown(color: theme.textColor),
                        ),
                        dropdownStyleData: DropdownStyleData(
                          width: popupWidth,
                          decoration: BoxDecoration(
                            color: theme.adPopBackground.withAlpha(255),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),

                        items:
                            sortOptions.entries
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                    value: e.key,
                                    child: Text(
                                      e.value,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // AKCJE
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          selectedStatus = null;
                          selectedTypeIds.clear();
                          selectedSort = 'date_create_desc';
                        });
                        // opcjonalnie – od razu fetch bez filtrów:
                        ref
                            .read(clientProvider.notifier)
                            .fetchClients(
                              status: null,
                              contactTypeIds: null,
                              sort: selectedSort,
                            );
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.textColor.withAlpha(80)),
                      ),
                      child: Text(
                        'Clear'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: buttonStyleRounded10ThemeRed,
                      onPressed: () {
                        ref
                            .read(clientProvider.notifier)
                            .fetchClients(
                              status: selectedStatus,
                              contactTypeIds:
                                  selectedTypeIds.isEmpty
                                      ? null
                                      : selectedTypeIds.toList(),
                              sort: selectedSort,
                            );
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'apply'.tr,
                        style: TextStyle(color: theme.themeTextColor),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChipButton extends ConsumerWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? icon;

  const _FilterChipButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final selectedBg = theme.themeColor;
    final unselectedBorder = theme.textColor.withAlpha(90);

    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: selected ? selectedBg : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? Colors.transparent : unselectedBorder,
          ),
        ),
      ),
      onPressed: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 8)],
          Text(
            label,
            style: AppTextStyles.interMedium14dark.copyWith(
              color: selected ? Colors.white : theme.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerChip extends StatelessWidget {
  const _ShimmerChip({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
