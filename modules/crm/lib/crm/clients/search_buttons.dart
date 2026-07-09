import 'package:core/kernel/kernel.dart';
import 'dart:async';
import 'package:crm/data/clients/client_provider.dart';
import 'package:crm/data/clients/contact_type_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'emma/anchors_crm_clients.dart';


class StatusFilterWidget extends ConsumerStatefulWidget {
  const StatusFilterWidget({super.key});

  @override
  ConsumerState<StatusFilterWidget> createState() => _StatusFilterWidgetState();
}

class _StatusFilterWidgetState extends ConsumerState<StatusFilterWidget> {
  int? selectedStatus;
  final searchController = TextEditingController();
  String? selectedSort = 'last_viewed_asc';

  final Map<String, String> sortOptions = {
    'last_viewed_asc': 'Ostatnio widziany ↑',
    'last_viewed_desc': 'Ostatnio widziany ↓',
    'date_create_desc': 'Data utworzenia ↓',
    'date_create_asc': 'Data utworzenia ↑',
    'date_update_desc': 'Data aktualizacji ↓',
    'date_update_asc': 'Data aktualizacji ↑',
    'name_asc': 'Imię A→Z',
    'name_desc': 'Imię Z→A',
    'last_name_asc': 'Nazwisko A→Z',
    'last_name_desc': 'Nazwisko Z→A',
    'star_desc': 'Najpierw ulubione',
  }.map((k, v) => MapEntry(k, v.tr));

  Timer? _searchDebounce; // 🔹 NEW

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel(); // 🔹 NEW
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {}); // only to update clear icon

    // 🔹 debounce API calls – 300ms after last key
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      ref
          .read(clientProvider.notifier)
          .fetchClients(
            status: selectedStatus,
            searchQuery: searchController.text,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final selectedTextColor = AppColors.white;
    final unselectedTextColor = theme.textColor;
    final nav = ref.read(navigationService);
    final path = nav.currentPath;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ───── Top row: contact type dropdown + search + add ─────
            SizedBox(
              height: 50,
              width: double.infinity,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 200,
                      maxWidth: 320,
                    ),
                    child: const SizedBox(
                      height: 46,
                      child: ContactTypeMultiDropdown(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      style: AppTextStyles.interMedium16.copyWith(
                        color: theme.textColor,
                      ),
                      controller: searchController,
                      cursorColor: theme.textColor,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search, color: theme.textColor),
                        suffixIcon:
                            searchController.text.isNotEmpty
                                ? IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: theme.textColor,
                                  ),
                                  onPressed: () {
                                    searchController.clear();
                                    // 🔹 also clear search filter immediately
                                    ref
                                        .read(clientProvider.notifier)
                                        .fetchClients(
                                          status: selectedStatus,
                                          searchQuery: '',
                                        );
                                  },
                                )
                                : null,
                        filled: true,
                        fillColor: theme.dashboardContainer,
                        hintText: 'Search clients'.tr,
                        hintStyle: AppTextStyles.interMedium14.copyWith(
                          color: theme.textColor.withAlpha(
                            (255 * 0.75).toInt(),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  EmmaUiAnchorTarget(
                    anchorKey: 'crm.clients.filterbar.add_client_button',
                    spec: CrmClientsEmmaAnchors.addClientButton,
                    child: PieMenu(
                      theme: PieTheme.of(context).copyWith(
                        overlayColor: (() {
                          final theme = ref.watch(themeColorsProvider);
                          final bool uiIsDark =
                              theme.textColor.computeLuminance() > 0.5;

                          final base =
                              uiIsDark ? Colors.black : Colors.white;
                          return base.withValues(alpha: 0.70);
                        })(),
                      ),
                      onPressedWithDevice: (kind) {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder:
                                (_, __, ___) =>
                                    (moduleRegistry.slot('crm.addClientForm')?.call(context, {'isClientView': true}) ?? const SizedBox.shrink()),
                            transitionsBuilder:
                                (_, anim, __, child) =>
                                    FadeTransition(opacity: anim, child: child),
                          ),
                        );
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.dashboardContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: AppIcons.add(
                            height: 24,
                            width: 24,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                    ),
                  ),


                ],
              ),
            ),

            const SizedBox(height: 15),

            // ───── Status chips + sort dropdown ─────
            SizedBox(
              width: double.infinity,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildStatusesRow(
                      theme: theme,
                      selectedTextColor: selectedTextColor,
                      unselectedTextColor: unselectedTextColor,
                      nav: nav,
                      path: path,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildSortDropdown(theme),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // 🔹 Uses clientStatusesProvider instead of manual FutureBuilder
  Widget _buildStatusesRow({
    required ThemeColors theme,
    required Color selectedTextColor,
    required Color unselectedTextColor,
    required NavigationService nav,
    required String path,
  }) {
    final statusesAsync = ref.watch(clientStatusesProvider);

    return statusesAsync.when(
      loading:
          () => const Row(
            children: [
              ShimmerPlaceholder(width: 60, height: 30, radius: 5),
              SizedBox(width: 5),
              ShimmerPlaceholder(width: 60, height: 30, radius: 5),
              SizedBox(width: 5),
              ShimmerPlaceholder(width: 80, height: 30, radius: 5),
              SizedBox(width: 5),
              ShimmerPlaceholder(width: 80, height: 30, radius: 5),
            ],
          ),
      error: (_, __) => Center(child: AppLottie.error(size: 50)),
      data: (statuses) {
        if (statuses.isEmpty) {
          return Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 100,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                    side: BorderSide(
                      color: theme.textColor.withAlpha((255 * 0.5).toInt()),
                    ),
                  ),
                ),
                onPressed: () {
                  nav.pushNamedScreen(
                    '$path/${Routes.contactStatuses}',
                    data: {'isFilter': true},
                  );
                },
                child: Row(
                  children: [
                    AppIcons.pencil(
                      color: unselectedTextColor,
                      width: 15,
                      height: 15,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Edit'.tr,
                      style: AppTextStyles.interMedium14dark.copyWith(
                        color: unselectedTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor:
                      selectedStatus == null
                          ? theme.themeColor
                          : Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                    side: BorderSide(
                      color: theme.textColor.withAlpha((255 * 0.5).toInt()),
                    ),
                  ),
                ),
                onPressed: () {
                  setState(() => selectedStatus = null);
                  ref.read(clientProvider.notifier).fetchClients(status: null);
                },
                child: Text(
                  'All'.tr,
                  style: AppTextStyles.interMedium14dark.copyWith(
                    color:
                        selectedStatus == null
                            ? selectedTextColor
                            : unselectedTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ...statuses.map((s) {
                final isOn = selectedStatus == s.statusId;
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor:
                          isOn ? theme.themeColor : Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(5),
                        ),
                        side: BorderSide(
                          color: theme.textColor.withAlpha((255 * 0.5).toInt()),
                        ),
                      ),
                    ),
                    onPressed: () {
                      setState(() => selectedStatus = s.statusId);
                      ref
                          .read(clientProvider.notifier)
                          .fetchClients(status: selectedStatus);
                    },
                    child: Text(
                      s.statusName,
                      style: AppTextStyles.interMedium14dark.copyWith(
                        color: isOn ? selectedTextColor : unselectedTextColor,
                      ),
                    ),
                  ),
                );
              }),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                    side: BorderSide(
                      color: theme.textColor.withAlpha((255 * 0.5).toInt()),
                    ),
                  ),
                ),
                onPressed: () {
                  nav.pushNamedScreen(
                    '$path/${Routes.contactStatuses}',
                    data: {'isFilter': true},
                  );
                },
                child: Row(
                  children: [
                    AppIcons.pencil(
                      color: unselectedTextColor,
                      width: 15,
                      height: 15,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Edit'.tr,
                      style: AppTextStyles.interMedium14dark.copyWith(
                        color: unselectedTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortDropdown(ThemeColors theme) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 260),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: theme.adPopBackground,
        ),
        child: DropdownButton<String>(
          value: selectedSort,
          dropdownColor: theme.adPopBackground,
          style: AppTextStyles.interRegular10.copyWith(color: theme.textColor),
          underline: const SizedBox(),
          icon: AppIcons.iosArrowDown(color: theme.textColor),
          onChanged: (String? newValue) {
            setState(() => selectedSort = newValue);
            ref
                .read(clientProvider.notifier)
                .fetchClients(
                  status: selectedStatus,
                  searchQuery: searchController.text,
                  sort: selectedSort,
                );
          },
          items:
              sortOptions.entries
                  .map(
                    (entry) => DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.interMedium14dark.copyWith(
                          color: theme.textColor,
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  DROPDOWN TYPÓW – wizualnie spójny z sortem (Container + InkWell)
// ──────────────────────────────────────────────────────────────────────────────

class ContactTypeMultiDropdown extends ConsumerStatefulWidget {
  const ContactTypeMultiDropdown({super.key});

  @override
  ConsumerState<ContactTypeMultiDropdown> createState() =>
      _ContactTypeMultiDropdownState();
}

class _ContactTypeMultiDropdownState
    extends ConsumerState<ContactTypeMultiDropdown> {
  final Set<int> _selectedIds = {};

  Future<void> _openMenu(BuildContext context) async {
    final theme = ref.read(themeColorsProvider);

    // 1) bezpiecznie dociągamy typy
    List<dynamic> types;
    try {
      await ref.read(contactTypesFetchProvider.future);
      final meta = ref.read(contactTypeProvider);
      types = meta.contactType;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('failed_to_load_types'.tr)),
        );
      }
      return;
    }

    // 2) pozycja menu — fallback jeśli RenderBox niedostępny
    RelativeRect position;
    final renderObj = context.findRenderObject();
    if (renderObj is RenderBox && renderObj.hasSize) {
      final box = renderObj;
      final offset = box.localToGlobal(Offset.zero);
      position = RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + box.size.height,
        offset.dx,
        0,
      );
    } else {
      position = const RelativeRect.fromLTRB(16, kToolbarHeight + 8, 16, 0);
    }

    final result = await showMenu<_MenuAction>(
      context: context,
      position: position,
      color: theme.dashboardContainer, // spójny kolor jak reszta
      shape: RoundedRectangleBorder(
        // ten sam radius co inputy
        borderRadius: BorderRadius.circular(5),
        side: BorderSide.none,
      ),
      items: <PopupMenuEntry<_MenuAction>>[
        PopupMenuItem<_MenuAction>(
          value: const _MenuAction.all(),
          child: Row(
            children: [
              Icon(Icons.select_all, size: 18, color: theme.textColor),
              const SizedBox(width: 10),
              Text(
                'all_types'.tr,
                style: AppTextStyles.interMedium14dark.copyWith(
                  color: theme.textColor,
                ),
              ),
              const Spacer(),
              if (_selectedIds.isEmpty)
                Icon(Icons.check, size: 18, color: theme.themeColor),
            ],
          ),
        ),
        const PopupMenuDivider(),
        ...types.map((t) {
          final int id = t.id as int;
          final String label =
              (t.label?.isNotEmpty == true ? t.label : t.contactType) as String;
          final selected = _selectedIds.contains(id);
          return PopupMenuItem<_MenuAction>(
            value: _MenuAction.type(id),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 18,
                  color: selected ? theme.themeColor : theme.textColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.interMedium14dark.copyWith(
                      color: theme.textColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const PopupMenuDivider(),
        PopupMenuItem<_MenuAction>(
          value: const _MenuAction.edit(),
          child: Row(
            children: [
              AppIcons.pencil(color: theme.textColor, width: 16, height: 16),
              const SizedBox(width: 10),
              Text(
                'Edit'.tr,
                style: AppTextStyles.interMedium14dark.copyWith(
                  color: theme.textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!mounted || result == null) return;

    result.when(
      all: () {
        setState(() => _selectedIds.clear());
        ref.read(clientProvider.notifier).fetchClients(contactTypeIds: null);
      },
      type: (id) {
        setState(() {
          if (_selectedIds.contains(id)) {
            _selectedIds.remove(id);
          } else {
            _selectedIds.add(id);
          }
        });
        final ids = _selectedIds.toList();
        ref
            .read(clientProvider.notifier)
            .fetchClients(contactTypeIds: ids.isEmpty ? null : ids);
      },
      edit: () {
        final nav = ref.read(navigationService);
        final path = nav.currentPath;
        nav.pushNamedScreen(
          '$path/${Routes.contactTypes}',
          data: {'isFilter': false},
        );
      },
    );
  }

  String _buttonLabel(List<dynamic> types) {
    if (_selectedIds.isEmpty) return 'Typ kontaktu: Wszystkie';
    final Map<int, String> map = {
      for (final t in types)
        (t.id as int):
            (t.label?.isNotEmpty == true ? t.label : t.contactType) as String,
    };
    final labels =
        _selectedIds.map((id) => map[id] ?? '$id').toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return labels.length <= 2
        ? 'Typ kontaktu: ${labels.join(', ')}'
        : 'Typ kontaktu: ${labels.take(2).join(', ')} +${labels.length - 2}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final typesAsync = ref.watch(contactTypesFetchProvider);
    final meta = ref.watch(contactTypeProvider);

    // zamiast OutlinedButton -> Container + InkWell jak sort box
    return typesAsync.when(
      loading:
          () => _ShellBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'loading_label'.tr,
                  style: AppTextStyles.interMedium14dark.copyWith(
                    color: theme.textColor,
                  ),
                ),
                AppIcons.iosArrowDown(color: theme.textColor),
              ],
            ),
          ),
      error:
          (_, __) => _ShellBox(
            onTap: () => _openMenu(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'error_try_again_label'.tr,
                  style: AppTextStyles.interMedium14dark.copyWith(
                    color: theme.textColor,
                  ),
                ),
                Icon(Icons.refresh, color: theme.textColor),
              ],
            ),
          ),
      data: (_) {
        final types = meta.contactType;
        return _ShellBox(
          onTap: () => _openMenu(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  _buttonLabel(types),
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.interMedium14dark.copyWith(
                    color: theme.textColor,
                  ),
                ),
              ),
              AppIcons.iosArrowDown(color: theme.textColor),
            ],
          ),
        );
      },
    );
  }
}

/// Kontener wejściowy 1:1 jak sort box (40px, borderRadius 6, background = theme.adPopBackground)
class _ShellBox extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _ShellBox({required this.child, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

// Union type do akcji menu
class _MenuAction {
  final int? typeId;
  final _Kind kind;
  const _MenuAction._(this.kind, this.typeId);
  const _MenuAction.all() : this._(_Kind.all, null);
  const _MenuAction.edit() : this._(_Kind.edit, null);
  const _MenuAction.type(int id) : this._(_Kind.type, id);

  T when<T>({
    required T Function() all,
    required T Function(int id) type,
    required T Function() edit,
  }) {
    switch (kind) {
      case _Kind.all:
        return all();
      case _Kind.type:
        return type(typeId!);
      case _Kind.edit:
        return edit();
    }
  }
}

enum _Kind { all, type, edit }
