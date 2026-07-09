import 'dart:async';

import 'package:emma/library/emma_installed_models_panel.dart';
import 'package:emma/library/emma_local_model_manager_provider.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/text_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

import 'emma_local_models_models.dart';
import 'emma_local_models_providers.dart';

Future<void> showEmmaLocalModelsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return const Dialog(
        insetPadding: EdgeInsets.all(18),
        backgroundColor: Colors.transparent,
        child: EmmaLocalModelsDialog(),
      );
    },
  );
}

Future<void> showEmmaLocalModelsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.98,
        expand: false,
        builder: (sheetContext, scrollController) {
          return const EmmaLocalModelsSheet();
        },
      );
    },
  );
}

class EmmaLocalModelsDialog extends ConsumerWidget {
  const EmmaLocalModelsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 1120,
        maxHeight: 780,
      ),
      child: Material(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: const _EmmaLocalModelsPanelBody(),
      ),
    );
  }
}

class EmmaLocalModelsSheet extends ConsumerWidget {
  const EmmaLocalModelsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Material(
      color: theme.adPopBackground,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: theme.dashboardBoarder.withAlpha(140),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const Expanded(
            child: _EmmaLocalModelsPanelBody(),
          ),
        ],
      ),
    );
  }
}

class _EmmaLocalModelsPanelBody extends ConsumerWidget {
  const _EmmaLocalModelsPanelBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return DefaultTextStyle(
      style: TextStyle(
        color: theme.textColor,
        fontSize: 13,
      ),
      child: IconTheme(
        data: IconThemeData(
          color: theme.textColor,
        ),
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              const _DialogHeader(),
              _DialogTabs(theme: theme),
              const Expanded(
                child: TabBarView(
                  children: [
                    _CatalogTab(),
                    EmmaInstalledModelsPanel(),
                    _EmmaLocalEngineSettingsPanel(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends ConsumerWidget {
  const _DialogHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final catalogState = ref.watch(emmaLocalCatalogProvider);
    final managerState = ref.watch(emmaLocalModelManagerProvider);

    final isLoading = catalogState.isLoading || managerState.isLoading;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
      decoration: BoxDecoration(
        color: theme.dashboardContainer.withOpacity(0.55),
        border: Border(
          bottom: BorderSide(
            color: theme.dashboardBoarder.withOpacity(0.45),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.themeColor.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.dashboardBoarder.withOpacity(0.6),
              ),
            ),
            child: Icon(
              Icons.memory_rounded,
              color: theme.textColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'local_models_library_title'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'local_models_library_subtitle'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor.withOpacity(0.72),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'refresh_tooltip'.tr,
            child: isLoading
                ? SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.themeColor,
                        ),
                      ),
                    ),
                  )
                : CoreIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: () {
                      ref
                          .read(emmaLocalCatalogProvider.notifier)
                          .load(force: true);
                      ref
                          .read(emmaLocalModelManagerProvider.notifier)
                          .load();
                    },
                  ),
          ),
          Tooltip(
            message: 'close_tooltip'.tr,
            child: CoreIconButton(
              icon: Icons.close_rounded,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogTabs extends StatelessWidget {
  const _DialogTabs({
    required this.theme,
  });

  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.dashboardContainer.withOpacity(0.32),
      child: TabBar(
        indicatorColor: theme.themeColor,
        labelColor: theme.textColor,
        unselectedLabelColor: theme.textColor.withOpacity(0.58),
        dividerColor: theme.dashboardBoarder.withOpacity(0.35),
        tabs:[
          Tab(
            icon: Icon(Icons.storefront_rounded, size: 18),
            text: 'catalog_tab'.tr,
          ),
          Tab(
            icon: Icon(Icons.inventory_2_rounded, size: 18),
            text: 'installed_tab'.tr,
          ),
          Tab(
            icon: Icon(Icons.tune_rounded, size: 18),
            text: 'settings_tab'.tr,
          ),
        ],
      ),
    );
  }
}

class _CatalogTab extends ConsumerStatefulWidget {
  const _CatalogTab();

  @override
  ConsumerState<_CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends ConsumerState<_CatalogTab> {
  String? _selectedModelId;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(emmaLocalCatalogProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emmaLocalCatalogProvider);
    final theme = ref.watch(themeColorsProvider);
    final models = state.filteredModels;

    final selectedStillExists =
        _selectedModelId != null && models.any((m) => m.modelId == _selectedModelId);

    if (!selectedStillExists && _selectedModelId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedModelId = null;
          });
        }
      });
    }

    return Column(
      children: [
        if (kIsWeb)
           _InfoBanner(
            icon: Icons.cloud_queue_rounded,
            text:
                'web_catalog_info'.tr,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
          child: _FiltersBar(
            onSearchChanged: (value) {
              _searchDebounce?.cancel();
              _searchDebounce = Timer(
                const Duration(milliseconds: 160),
                () {
                  ref
                      .read(emmaLocalCatalogProvider.notifier)
                      .setSearch(value);
                },
              );
            },
          ),
        ),
        if (state.error != null)
          _InfoBanner(
            icon: Icons.error_outline_rounded,
            text: state.error!,
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 860;

              if (state.isLoading && state.models.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(
                    color: theme.themeColor,
                  ),
                );
              }

              if (models.isEmpty) {
                return const _EmptyState();
              }

              if (wide) {
                return Row(
                  children: [
                    SizedBox(
                      width: 420,
                      child: _ModelsList(
                        models: models,
                        selectedModelId: _selectedModelId,
                        onSelected: (model) {
                          setState(() {
                            _selectedModelId = model.modelId;
                          });
                        },
                      ),
                    ),
                    VerticalDivider(
                      width: 1,
                      color: theme.dashboardBoarder.withOpacity(0.6),
                    ),
                    Expanded(
                      child: _selectedModelId == null
                          ? const _SelectModelState()
                          : EmmaLocalModelDetailsPanel(
                              modelId: _selectedModelId!,
                            ),
                    ),
                  ],
                );
              }

              if (_selectedModelId != null) {
                return EmmaLocalModelDetailsPanel(
                  modelId: _selectedModelId!,
                  onBack: () {
                    setState(() {
                      _selectedModelId = null;
                    });
                  },
                );
              }

              return _ModelsList(
                models: models,
                selectedModelId: _selectedModelId,
                onSelected: (model) {
                  setState(() {
                    _selectedModelId = model.modelId;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FiltersBar extends ConsumerStatefulWidget {
  const _FiltersBar({
    required this.onSearchChanged,
  });

  final ValueChanged<String> onSearchChanged;

  @override
  ConsumerState<_FiltersBar> createState() => _FiltersBarState();
}

class _FiltersBarState extends ConsumerState<_FiltersBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();

    final state = ref.read(emmaLocalCatalogProvider);
    _searchController = TextEditingController(text: state.search);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emmaLocalCatalogProvider);
    final notifier = ref.read(emmaLocalCatalogProvider.notifier);
    final theme = ref.watch(themeColorsProvider);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: CoreTextField(
            label: 'search_label'.tr,
            hintText: 'search_hint'.tr,
            controller: _searchController,
            onChanged: widget.onSearchChanged,
            prefixIcon: Icon(
              Icons.search_rounded,
              color: theme.textColor,
            ),
          ),
        ),
        _FilterDropdown(
          label:'type_filter'.tr,
          value: state.taskType ?? '',
          values: state.taskTypes,
          onChanged: notifier.setTaskType,
        ),
        _FilterDropdown(
          label: 'runtime_filter'.tr,
          value: state.runtime ?? '',
          values: state.runtimes,
          onChanged: notifier.setRuntime,
        ),
        _FilterDropdown(
          label: 'format_filter'.tr,
          value: state.modelFormat ?? '',
          values: state.modelFormats,
          onChanged: notifier.setModelFormat,
        ),
        _FilterDropdown(
          label: 'source_filter'.tr,
          value: state.sourceType ?? '',
          values: state.sourceTypes,
          onChanged: notifier.setSourceType,
        ),
        state.featuredOnly
            ? CoreFilledButton(
                onPressed: () => notifier.setFeaturedOnly(false),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: theme.themeColorText,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'featured_filter'.tr,
                      style: TextStyle(
                        color: theme.themeColorText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            : CoreOutlinedButton(
                onPressed: () => notifier.setFeaturedOnly(true),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_border_rounded,
                      size: 18,
                      color: theme.textColor,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'featured_filter'.tr,
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
        if (state.hasFilters)
          CoreOutlinedButton(
            onPressed: () {
              _searchController.clear();
              notifier.clearFilters();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_alt_off_rounded,
                  size: 18,
                  color: theme.textColor,
                ),
                const SizedBox(width: 7),
                Text(
                 'clear_filters_button'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = ['', ...values];

    return SizedBox(
      width: 150,
      child: CoreDropdown<String>(
        label: label,
        value: value,
        options: options,
        display: (item) => item.isEmpty ? 'all_option'.tr : item,
        onChanged: (next) {
          onChanged(next == null || next.isEmpty ? null : next);
        },
      ),
    );
  }
}

class _ModelsList extends StatelessWidget {
  const _ModelsList({
    required this.models,
    required this.selectedModelId,
    required this.onSelected,
  });

  final List<EmmaLocalModelDto> models;
  final String? selectedModelId;
  final ValueChanged<EmmaLocalModelDto> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      itemCount: models.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final model = models[index];

        return _ModelCard(
          model: model,
          selected: model.modelId == selectedModelId,
          onTap: () => onSelected(model),
        );
      },
    );
  }
}

class _ModelCard extends ConsumerWidget {
  const _ModelCard({
    required this.model,
    required this.selected,
    required this.onTap,
  });

  final EmmaLocalModelDto model;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final installedById = ref.watch(emmaLocalInstalledModelsByIdProvider);
    final installed = installedById.containsKey(model.modelId);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? theme.themeColor.withOpacity(0.14)
              : theme.dashboardContainer.withOpacity(0.35),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? theme.themeColor.withOpacity(0.75)
                : theme.dashboardBoarder.withOpacity(0.55),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    model.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (installed) ...[
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: theme.themeColor,
                  ),
                  const SizedBox(width: 6),
                ],
                if (model.isFeatured)
                  Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: theme.textColor,
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              model.shortDescription.isEmpty
                  ? model.modelId
                  : model.shortDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: theme.textColor.withOpacity(0.72),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _TinyChip(model.taskType),
                _TinyChip(model.runtime),
                _TinyChip(model.modelFormat),
                if (model.quantization.isNotEmpty)
                  _TinyChip(model.quantization),
                if (model.primaryFile?.sizeBytes != null)
                  _TinyChip(formatEmmaLocalBytes(model.primaryFile!.sizeBytes)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  installed
                      ? Icons.inventory_2_rounded
                      : model.canDownload
                          ? Icons.download_done_rounded
                          : Icons.lock_outline_rounded,
                  size: 16,
                  color: model.canDownload || installed
                      ? theme.themeColor
                      : theme.textColor.withOpacity(0.75),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    installed
                        ? 'installed_locally'.tr
                        : model.canDownload
                            ? model.displayRequirements
                            : model.requiresLicenseAcceptance &&
                                    !model.licenseAccepted
                                ? 'license_required'.tr
                                : 'no_access'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: theme.textColor.withOpacity(0.75),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EmmaLocalModelDetailsPanel extends ConsumerWidget {
  const EmmaLocalModelDetailsPanel({
    super.key,
    required this.modelId,
    this.onBack,
  });

  final String modelId;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncModel = ref.watch(emmaLocalModelDetailProvider(modelId));
    final theme = ref.watch(themeColorsProvider);

    return asyncModel.when(
      loading: () => Center(
        child: CircularProgressIndicator(
          color: theme.themeColor,
        ),
      ),
      error: (error, stack) => _InfoBanner(
        icon: Icons.error_outline_rounded,
        text: error.toString(),
      ),
      data: (model) {
        final files = model.files.isNotEmpty
            ? model.files
            : [
                if (model.primaryFile != null) model.primaryFile!,
              ];

        final progress = ref.watch(emmaLocalInstallProvider)[model.modelId] ??
            const EmmaLocalInstallProgress.idle();

        return Column(
          children: [
            if (onBack != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CoreOutlinedButton(
                    onPressed: onBack,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_rounded,
                          size: 18,
                          color: theme.textColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'back_to_list'.tr,
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                children: [
                  _DetailsTitle(model: model),
                  const SizedBox(height: 16),
                  if (model.deprecationMessage.isNotEmpty)
                    _InfoBanner(
                      icon: Icons.warning_amber_rounded,
                      text: model.deprecationMessage,
                    ),
                  if (model.description.isNotEmpty) ...[
                    Text(
                      model.description,
                      style: TextStyle(
                        color: theme.textColor,
                        height: 1.38,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  _RequirementsBox(model: model),
                  const SizedBox(height: 18),
                  if (model.requiresLicenseAcceptance &&
                      !model.licenseAccepted)
                    _LicenseBox(model: model),
                  if (progress.phase != EmmaLocalInstallPhase.idle) ...[
                    const SizedBox(height: 12),
                    _InstallProgressBox(progress: progress),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    'model_files_title'.tr,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...files.map(
                    (file) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _FileTile(
                        model: model,
                        file: file,
                        isBusy: progress.isBusy,
                        progress: progress,
                      ),
                    ),
                  ),
                  if (model.releaseNotes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'release_notes_title'.tr,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      model.releaseNotes,
                      style: TextStyle(
                        color: theme.textColor.withOpacity(0.82),
                        height: 1.35,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DetailsTitle extends ConsumerWidget {
  const _DetailsTitle({
    required this.model,
  });

  final EmmaLocalModelDto model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final installedById = ref.watch(emmaLocalInstalledModelsByIdProvider);
    final installed = installedById[model.modelId];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: theme.themeColor.withOpacity(0.16),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.dashboardBoarder.withOpacity(0.6),
            ),
          ),
          child: Icon(
            Icons.memory_rounded,
            color: theme.textColor,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      model.name,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (installed != null)
                    _StatusPill(
                      icon: Icons.check_circle_rounded,
                      label: installed.isActive
                          ? 'active_status'.tr
                          : 'installed_status'.tr,
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                model.modelId,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textColor.withOpacity(0.62),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _TinyChip(model.taskType),
                  _TinyChip(model.runtime),
                  _TinyChip(model.modelFormat),
                  if (model.family.isNotEmpty) _TinyChip(model.family),
                  if (model.version.isNotEmpty) _TinyChip(model.version),
                  if (model.quantization.isNotEmpty)
                    _TinyChip(model.quantization),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RequirementsBox extends ConsumerWidget {
  const _RequirementsBox({
    required this.model,
  });

  final EmmaLocalModelDto model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SectionBox(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _RequirementItem(
            icon: Icons.memory_rounded,
            label: 'ram_label'.tr,
            value: model.recommendedRamGb != null
                ? '${model.recommendedRamGb} GB'
                : model.minRamGb != null
                    ? 'min. ${model.minRamGb} GB'
                    : '—',
          ),
          _RequirementItem(
            icon: Icons.developer_board_rounded,
            label: 'vram_label'.tr,
            value: model.recommendedVramGb != null
                ? '${model.recommendedVramGb} GB'
                : model.minVramGb != null
                    ? 'min. ${model.minVramGb} GB'
                    : '—',
          ),
          _RequirementItem(
            icon: Icons.integration_instructions_rounded,
            label: 'context_label'.tr,
            value: model.contextLength != null ? '${model.contextLength}' : '—',
          ),
          _RequirementItem(
            icon: Icons.computer_rounded,
            label:'platforms_label'.tr,
            value: [
              if (model.supportsMacos) 'macOS',
              if (model.supportsWindows) 'Windows',
              if (model.supportsLinux) 'Linux',
            ].join(', ').trim().isEmpty
                ? '—'
                : [
                    if (model.supportsMacos) 'macOS',
                    if (model.supportsWindows) 'Windows',
                    if (model.supportsLinux) 'Linux',
                  ].join(', '),
          ),
        ],
      ),
    );
  }
}

class _LicenseBox extends ConsumerWidget {
  const _LicenseBox({
    required this.model,
  });

  final EmmaLocalModelDto model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return _SectionBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.gavel_rounded,
                size: 18,
                color: theme.textColor,
              ),
              const SizedBox(width: 8),
              Text(
                'license_acceptance_required'.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (model.licenseName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              model.licenseName,
              style: TextStyle(
                color: theme.textColor.withOpacity(0.88),
              ),
            ),
          ],
          if (model.licenseText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              model.licenseText,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor.withOpacity(0.78),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          CoreFilledButton(
            onPressed: () async {
              try {
                await ref
                    .read(emmaLocalModelActionsProvider)
                    .acceptLicense(model.modelId);

                ref.invalidate(emmaLocalModelDetailProvider(model.modelId));

                await ref
                    .read(emmaLocalCatalogProvider.notifier)
                    .load(force: true);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('license_accepted_message'.tr),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                    ),
                  );
                }
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_rounded,
                  color: theme.themeColorText,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'accept_license_button'.tr,
                  style: TextStyle(
                    color: theme.themeColorText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FileTile extends ConsumerWidget {
  const _FileTile({
    required this.model,
    required this.file,
    required this.isBusy,
    required this.progress,
  });

  final EmmaLocalModelDto model;
  final EmmaLocalModelFileDto file;
  final bool isBusy;
  final EmmaLocalInstallProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final installedById = ref.watch(emmaLocalInstalledModelsByIdProvider);
    final installed = installedById[model.modelId];

    final fileReady = file.status.toLowerCase().trim() == 'ready';
    final canInstall = !kIsWeb && model.canDownload && fileReady;
    final isDone = progress.isDone || installed != null;

    return _SectionBox(
      child: Row(
        children: [
          Icon(
            file.isPrimary
                ? Icons.file_download_done_rounded
                : Icons.insert_drive_file_rounded,
            color: theme.textColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.fileName.isEmpty ? file.fileId : file.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${file.sourceType} · ${formatEmmaLocalBytes(file.sizeBytes)} · ${file.status}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor.withOpacity(0.72),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isDone)
            CoreOutlinedButton(
              onPressed: null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: theme.textColor.withOpacity(0.62),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    installed?.isActive == true ? 'Aktywny' : 'Zainstalowany',
                    style: TextStyle(
                      color: theme.textColor.withOpacity(0.62),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            CoreFilledButton(
              onPressed: canInstall && !isBusy
                  ? () {
                      ref.read(emmaLocalInstallProvider.notifier).install(
                            model: model,
                            fileId: file.fileId,
                          );
                    }
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isBusy) ...[
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.themeColorText,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.download_rounded,
                      size: 18,
                      color: theme.themeColorText,
                    ),
                  ],
                  const SizedBox(width: 8),
                  Text(
                    isBusy ? 'installing_progress'.tr : 'install_button'.tr,
                    style: TextStyle(
                      color: theme.themeColorText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InstallProgressBox extends ConsumerWidget {
  const _InstallProgressBox({
    required this.progress,
  });

  final EmmaLocalInstallProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final icon = progress.isDone
        ? Icons.check_circle_rounded
        : progress.isError
            ? Icons.error_outline_rounded
            : Icons.info_outline_rounded;

    final color = progress.isDone
        ? theme.themeColor
        : progress.isError
            ? Colors.redAccent
            : theme.textColor;

    return _SectionBox(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (progress.isBusy)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.themeColor,
              ),
            )
          else
            Icon(
              icon,
              color: color,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progress.message,
                  style: TextStyle(
                    color: theme.textColor,
                    height: 1.35,
                  ),
                ),
                if (progress.progress != null) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress.progress!.clamp(0, 1),
                    color: theme.themeColor,
                    backgroundColor: theme.dashboardBoarder.withOpacity(0.35),
                  ),
                ],
                if (progress.installed != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    progress.installed!.localPath,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor.withOpacity(0.65),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementItem extends ConsumerWidget {
  const _RequirementItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return SizedBox(
      width: 145,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.textColor,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: theme.textColor.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value.isEmpty ? '—' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionBox extends ConsumerWidget {
  const _SectionBox({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.dashboardContainer.withOpacity(0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dashboardBoarder.withOpacity(0.35),
        ),
      ),
      child: child,
    );
  }
}

class _TinyChip extends ConsumerWidget {
  const _TinyChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (label.trim().isEmpty) return const SizedBox.shrink();

    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.themeColor.withOpacity(0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.themeColor.withOpacity(0.18),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: theme.textColor,
        ),
      ),
    );
  }
}

class _StatusPill extends ConsumerWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: theme.themeColor.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.themeColor.withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: theme.textColor,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends ConsumerWidget {
  const _InfoBanner({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.themeColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dashboardBoarder.withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.textColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'no_models_found'.tr,
          style: TextStyle(
            color: theme.textColor.withOpacity(0.75),
          ),
        ),
      ),
    );
  }
}

class _SelectModelState extends ConsumerWidget {
  const _SelectModelState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'select_model_prompt'.tr,
          style: TextStyle(
            color: theme.textColor.withOpacity(0.75),
          ),
        ),
      ),
    );
  }
}

class _EmmaLocalEngineSettingsPanel extends ConsumerStatefulWidget {
  const _EmmaLocalEngineSettingsPanel();

  @override
  ConsumerState<_EmmaLocalEngineSettingsPanel> createState() =>
      _EmmaLocalEngineSettingsPanelState();
}

class _EmmaLocalEngineSettingsPanelState
    extends ConsumerState<_EmmaLocalEngineSettingsPanel> {
  late final TextEditingController _baseUrlController;
  late final TextEditingController _tokenController;
  late final TextEditingController _nCtxController;
  late final TextEditingController _nGpuLayersController;
  late final TextEditingController _nThreadsController;
  late final TextEditingController _temperatureController;
  late final TextEditingController _maxTokensController;
  late final TextEditingController _chatFormatController;

  bool _settingsApplied = false;

  @override
  void initState() {
    super.initState();

    _baseUrlController = TextEditingController(
      text: ref.read(emmaLocalEngineBaseUrlProvider),
    );
    _tokenController = TextEditingController(
      text: ref.read(emmaLocalEngineTokenProvider),
    );
    _nCtxController = TextEditingController();
    _nGpuLayersController = TextEditingController();
    _nThreadsController = TextEditingController();
    _temperatureController = TextEditingController();
    _maxTokensController = TextEditingController();
    _chatFormatController = TextEditingController();

    Future.microtask(() {
      ref.read(emmaLocalModelManagerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _tokenController.dispose();
    _nCtxController.dispose();
    _nGpuLayersController.dispose();
    _nThreadsController.dispose();
    _temperatureController.dispose();
    _maxTokensController.dispose();
    _chatFormatController.dispose();
    super.dispose();
  }

  void _applySettingsOnce(Map<String, dynamic> settings) {
    if (_settingsApplied || settings.isEmpty) return;

    _settingsApplied = true;

    _nCtxController.text = (settings['n_ctx'] ?? '').toString();
    _nGpuLayersController.text = (settings['n_gpu_layers'] ?? '').toString();
    _nThreadsController.text = (settings['n_threads'] ?? '').toString();
    _temperatureController.text = (settings['temperature'] ?? '').toString();
    _maxTokensController.text = (settings['max_tokens'] ?? '').toString();
    _chatFormatController.text = (settings['chat_format'] ?? '').toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final state = ref.watch(emmaLocalModelManagerProvider);
    final notifier = ref.read(emmaLocalModelManagerProvider.notifier);

    _applySettingsOnce(state.settings);

    if (kIsWeb) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'engine_settings_desktop_only'.tr,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      children: [
        _SectionBox(
          child: Row(
            children: [
              Icon(
                state.engineReachable
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: state.engineReachable ? theme.themeColor : Colors.redAccent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  state.engineReachable
                      ? 'engine_running_status'.tr
                      : 'engine_not_responding_status'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CoreOutlinedButton(
                onPressed: state.isActionRunning
                    ? null
                    : () {
                        ref
                            .read(emmaLocalEngineBaseUrlProvider.notifier)
                            .state = _baseUrlController.text.trim();

                        ref
                            .read(emmaLocalEngineTokenProvider.notifier)
                            .state = _tokenController.text.trim();

                        notifier.load();
                      },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi_tethering_rounded,
                      size: 18,
                      color: theme.textColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'test_connection_button'.tr,
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (state.error != null) ...[
          _InfoBanner(
            icon: Icons.error_outline_rounded,
            text: state.error!,
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'connection_section_title'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        _SectionBox(
          child: Column(
            children: [
              CoreTextField(
                label: 'engine_url_label'.tr,
                hintText: 'http://127.0.0.1:43890',
                controller: _baseUrlController,
                prefixIcon: Icon(
                  Icons.link_rounded,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 10),
              CoreTextField(
                label: 'token_label'.tr,
                hintText: 'dev-superbee-token',
                controller: _tokenController,
                obscureText: true,
                prefixIcon: Icon(
                  Icons.key_rounded,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'llm_parameters_title'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        _SectionBox(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 170,
                child: CoreTextField(
                  label: 'n_ctx',
                  controller: _nCtxController,
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(
                width: 170,
                child: CoreTextField(
                  label: 'n_gpu_layers',
                  controller: _nGpuLayersController,
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(
                width: 170,
                child: CoreTextField(
                  label: 'n_threads',
                  controller: _nThreadsController,
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(
                width: 170,
                child: CoreTextField(
                  label: 'temperature',
                  controller: _temperatureController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              SizedBox(
                width: 170,
                child: CoreTextField(
                  label: 'max_tokens',
                  controller: _maxTokensController,
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(
                width: 220,
                child: CoreTextField(
                  label: 'chat_format',
                  hintText: 'np. chatml, llama-3, gemma',
                  controller: _chatFormatController,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            CoreFilledButton(
              onPressed: state.isActionRunning
                  ? null
                  : () async {
                      ref
                          .read(emmaLocalEngineBaseUrlProvider.notifier)
                          .state = _baseUrlController.text.trim();

                      ref
                          .read(emmaLocalEngineTokenProvider.notifier)
                          .state = _tokenController.text.trim();

                      await notifier.patchEngineSettings({
                        if (_intOrNull(_nCtxController.text) != null)
                          'n_ctx': _intOrNull(_nCtxController.text),
                        if (_intOrNull(_nGpuLayersController.text) != null)
                          'n_gpu_layers':
                              _intOrNull(_nGpuLayersController.text),
                        if (_intOrNull(_nThreadsController.text) != null)
                          'n_threads': _intOrNull(_nThreadsController.text),
                        if (_doubleOrNull(_temperatureController.text) != null)
                          'temperature':
                              _doubleOrNull(_temperatureController.text),
                        if (_intOrNull(_maxTokensController.text) != null)
                          'max_tokens':
                              _intOrNull(_maxTokensController.text),
                        'chat_format': _chatFormatController.text.trim(),
                      });

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('settings_saved_message'.tr),
                          ),
                        );
                      }
                    },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.isActionRunning)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.themeColorText,
                      ),
                    )
                  else
                    Icon(
                      Icons.save_rounded,
                      size: 18,
                      color: theme.themeColorText,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    'save_settings_button'.tr,
                    style: TextStyle(
                      color: theme.themeColorText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            CoreOutlinedButton(
              onPressed: state.isActionRunning
                  ? null
                  : () async {
                      await notifier.unloadLlm();
                    },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.power_settings_new_rounded,
                    size: 18,
                    color: theme.textColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'unload_llm_button'.tr,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (state.settings.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'active_paths_title'.tr,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _SectionBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SettingsPathRow(
                  label: 'llm_path_label'.tr,
                  value: state.settings['llm_model_path'] ??
                      state.settings['model_path'] ??
                      '',
                ),
                _SettingsPathRow(
                  label: 'stt_path_label'.tr,
                  value: state.settings['stt_model_path'] ?? '',
                ),
                _SettingsPathRow(
                  label: 'tts_path_label'.tr,
                  value: state.settings['tts_model_path'] ?? '',
                ),
                _SettingsPathRow(
                  label: 'manifest_path_label'.tr,
                  value: state.settings['models_manifest_path'] ?? '',
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SettingsPathRow extends ConsumerWidget {
  const _SettingsPathRow({
    required this.label,
    required this.value,
  });

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final text = value?.toString().trim() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text.isEmpty ? '—' : text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor.withOpacity(0.72),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

int? _intOrNull(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;
  return int.tryParse(text);
}

double? _doubleOrNull(String value) {
  final text = value.trim().replaceAll(',', '.');
  if (text.isEmpty) return null;
  return double.tryParse(text);
}