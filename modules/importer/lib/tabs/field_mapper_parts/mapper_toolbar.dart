part of importer_field_mapper;

const double _mapperToolbarControlHeight = 34.0;

const double _mapperToolbarOneLineHeight = 46.0;

const double _mapperToolbarIconButtonWidth = 36.0;

const double _mapperToolbarRadius = 12.0;

class _MapperTopToolbar extends StatelessWidget {
  final ThemeColors theme;
  final MapperViewMode viewMode;
  final String? selectedColumn;
  final int mappedCount;
  final int totalCount;
  final int currentMappings;
  final bool hasEntityPlan;
  final bool isEmmaPlanning;
  final bool isTablet;

  final List<String> targetModels;
  final String? selectedTargetModel;
  final ValueChanged<String?> onTargetModelChanged;

  final ValueChanged<MapperViewMode> onChangeView;
  final VoidCallback onClearSelected;
  final VoidCallback onSuggestWithEmma;
  final VoidCallback? onDownloadTemplate;
  final VoidCallback? onSaveTemplate;
  final VoidCallback? onLoadTemplate;
  final VoidCallback? onShowSchema;

  const _MapperTopToolbar({
    required this.theme,
    required this.viewMode,
    required this.selectedColumn,
    required this.mappedCount,
    required this.totalCount,
    required this.currentMappings,
    required this.hasEntityPlan,
    required this.isEmmaPlanning,
    required this.targetModels,
    required this.selectedTargetModel,
    required this.onTargetModelChanged,
    required this.onChangeView,
    required this.onClearSelected,
    required this.onSuggestWithEmma,
    required this.isTablet,
    this.onDownloadTemplate,
    this.onSaveTemplate,
    this.onLoadTemplate,
    this.onShowSchema,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final oneLine = constraints.maxWidth >= 1100 && !isTablet;

        final toolbarChildren = <Widget>[
          Row(
            spacing: 6,
            children: [
              EmmaUiAnchorTarget(
                anchorKey: 'importer.mapper.emma_suggest_full_plan',
                child: _MapperToolbarPrimaryButton(
                  theme: theme,
                  isLoading: isEmmaPlanning,
                  onPressed: isEmmaPlanning ? null : onSuggestWithEmma,
                ),
              ),
              _MapperTargetModelSelect(
                theme: theme,
                width: oneLine ? 250 : 280,
                models: targetModels,
                selectedModel: selectedTargetModel,
                onChanged: onTargetModelChanged,
              ),
            ],
          ),

          _MapperToolbarStatsStrip(
            theme: theme,
            mappedCount: mappedCount,
            totalCount: totalCount,
            currentMappings: currentMappings,
            hasEntityPlan: hasEntityPlan,
          ),

          Row(
            spacing: 6,
            children: [
              if (onDownloadTemplate != null)
                _MapperTemplateButtons(
                  theme: theme,
                  onDownloadTemplate: onDownloadTemplate!,
                  onSaveTemplate: onSaveTemplate,
                  onLoadTemplate: onLoadTemplate,
                ),
              if (onShowSchema != null)
                EmmaUiAnchorTarget(
                  anchorKey: 'importer.mapper.schema_explorer',
                  child: _SchemaButton(theme: theme, onTap: onShowSchema!),
                ),
              if (selectedColumn != null)
                EmmaUiAnchorTarget(
                  anchorKey: 'importer.mapper.active_column_chip',
                  child: _MapperActiveColumnChip(
                    theme: theme,
                    selectedColumn: selectedColumn!,
                    onClearSelected: onClearSelected,
                  ),
                ),
              EmmaUiAnchorTarget(
                anchorKey: 'importer.mapper.view_mode_switch',
                child: _MapperToolbarViewModeSwitch(
                  theme: theme,
                  viewMode: viewMode,
                  onChangeView: onChangeView,
                ),
              ),
            ],
          ),
        ];

        return SizedBox(
          width: double.infinity,
          child: Container(
            width: double.infinity,
            height: oneLine ? _mapperToolbarOneLineHeight : null,
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: oneLine ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: theme.adPopBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dashboardBoarder.withAlpha(90)),
            ),
            child: isTablet
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          spacing: 6,
                          children: [
                            EmmaUiAnchorTarget(
                              anchorKey:
                                  'importer.mapper.emma_suggest_full_plan',
                              child: _MapperToolbarPrimaryButton(
                                theme: theme,
                                isLoading: isEmmaPlanning,
                                onPressed: isEmmaPlanning
                                    ? null
                                    : onSuggestWithEmma,
                              ),
                            ),
                            _MapperTargetModelSelect(
                              theme: theme,
                              width: 250,
                              models: targetModels,
                              selectedModel: selectedTargetModel,
                              onChanged: onTargetModelChanged,
                            ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: _MapperToolbarStatsStrip(
                          theme: theme,
                          mappedCount: mappedCount,
                          totalCount: totalCount,
                          currentMappings: currentMappings,
                          hasEntityPlan: hasEntityPlan,
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          spacing: 6,
                          children: [
                            if (onDownloadTemplate != null)
                              _MapperTemplateButtons(
                                theme: theme,
                                onDownloadTemplate: onDownloadTemplate!,
                                onSaveTemplate: onSaveTemplate,
                                onLoadTemplate: onLoadTemplate,
                              ),
                            if (onShowSchema != null)
                              _SchemaButton(theme: theme, onTap: onShowSchema!),
                            if (selectedColumn != null)
                              EmmaUiAnchorTarget(
                                anchorKey: 'importer.mapper.active_column_chip',
                                child: _MapperActiveColumnChip(
                                  theme: theme,
                                  selectedColumn: selectedColumn!,
                                  onClearSelected: onClearSelected,
                                ),
                              ),
                            EmmaUiAnchorTarget(
                              anchorKey: 'importer.mapper.view_mode_switch',
                              child: _MapperToolbarViewModeSwitch(
                                theme: theme,
                                viewMode: viewMode,
                                onChangeView: onChangeView,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : (oneLine
                      ? SizedBox(
                          height: _mapperToolbarControlHeight,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: math.max(
                                  0,
                                  constraints.maxWidth - 16,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  for (
                                    var i = 0;
                                    i < toolbarChildren.length;
                                    i++
                                  ) ...[
                                    toolbarChildren[i],
                                    if (i != toolbarChildren.length - 1)
                                      const SizedBox(width: 7),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: toolbarChildren,
                        )),
          ),
        );
      },
    );
  }
}

class _MapperTargetModelSelect extends StatelessWidget {
  final ThemeColors theme;
  final double width;
  final List<String> models;
  final String? selectedModel;
  final ValueChanged<String?> onChanged;

  const _MapperTargetModelSelect({
    required this.theme,
    required this.width,
    required this.models,
    required this.selectedModel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeSelected = selectedModel != null && models.contains(selectedModel)
        ? selectedModel
        : null;

    return SizedBox(
      width: width,
      height: _mapperToolbarControlHeight,
      child: EmmaUiAnchorTarget(
        anchorKey: 'importer.mapper.target_model_picker',
        child: DropdownButtonFormField<String>(
          value: safeSelected,
          dropdownColor: theme.dashboardContainer,
          isDense: true,
          iconSize: 18,
          iconEnabledColor: theme.textColor.withAlpha(145),
          iconDisabledColor: theme.textColor.withAlpha(80),
          hint: Text(
            'Wybierz model'.tr,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.textColor.withAlpha(120),
              fontSize: 11.5,
              height: 1.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: TextStyle(
            color: theme.textColor,
            fontSize: 11.5,
            height: 1.0,
            fontWeight: FontWeight.w600,
          ),
          decoration: _mapperToolbarInputDecoration(
            theme: theme,
            hint: '',
            icon: Icons.account_tree_rounded,
          ).copyWith(hintText: null, hintStyle: null),
          selectedItemBuilder: (context) {
            return models.map((model) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  model,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 11.5,
                    height: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList();
          },
          items: models.map((model) {
            final active = model == safeSelected;

            return DropdownMenuItem<String>(
              value: model,
              child: Row(
                children: [
                  Icon(
                    Icons.table_chart_rounded,
                    size: 15,
                    color: active
                        ? theme.themeColor
                        : theme.textColor.withAlpha(150),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      model,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 12,
                        height: 1.0,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _MapperToolbarPrimaryButton extends StatelessWidget {
  final ThemeColors theme;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _MapperToolbarPrimaryButton({
    required this.theme,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _mapperToolbarControlHeight,
      child: ElevatedButton.icon(
        style: _mapperToolbarFilledStyle(theme),
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.auto_awesome_rounded, size: 15),
        label: Text(
          isLoading ? 'Analizuje...'.tr : 'Emma: mapowanie'.tr,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _MapperToolbarStatsStrip extends StatelessWidget {
  final ThemeColors theme;
  final int mappedCount;
  final int totalCount;
  final int currentMappings;
  final bool hasEntityPlan;

  const _MapperToolbarStatsStrip({
    required this.theme,
    required this.mappedCount,
    required this.totalCount,
    required this.currentMappings,
    required this.hasEntityPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _mapperToolbarControlHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: theme.dashboardContainer.withAlpha(165),
        borderRadius: BorderRadius.circular(_mapperToolbarRadius),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(85)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MapperToolbarStatText(
            theme: theme,
            label: 'Mapowania'.tr,
            value: '$currentMappings',
            icon: Icons.link_rounded,
            accent: currentMappings > 0,
          ),
          _MapperToolbarMiniDivider(theme: theme),
          _MapperToolbarStatText(
            theme: theme,
            label: 'Zmapowane'.tr,
            value: '$mappedCount/$totalCount',
            icon: Icons.check_circle_outline,
            accent: mappedCount > 0,
          ),
          _MapperToolbarMiniDivider(theme: theme),
          _MapperToolbarStatText(
            theme: theme,
            label: 'Plan FK'.tr,
            value: hasEntityPlan ? 'OK'.tr : 'Brak'.tr,
            icon: Icons.account_tree_rounded,
            accent: hasEntityPlan,
          ),
        ],
      ),
    );
  }
}

class _MapperToolbarStatText extends StatelessWidget {
  final ThemeColors theme;
  final String label;
  final String value;
  final IconData icon;
  final bool accent;

  const _MapperToolbarStatText({
    required this.theme,
    required this.label,
    required this.value,
    required this.icon,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$label: $value',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: accent ? theme.themeColor : theme.textColor.withAlpha(135),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor.withAlpha(145),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: accent ? theme.themeColor : theme.textColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapperActiveColumnChip extends StatelessWidget {
  final ThemeColors theme;
  final String selectedColumn;
  final VoidCallback onClearSelected;

  const _MapperActiveColumnChip({
    required this.theme,
    required this.selectedColumn,
    required this.onClearSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _mapperToolbarControlHeight,
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(22),
        borderRadius: BorderRadius.circular(_mapperToolbarRadius),
        border: Border.all(color: theme.themeColor.withAlpha(130)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.ads_click_rounded, size: 15, color: theme.themeColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${'Aktywna'.tr}: $selectedColumn',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onClearSelected,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: theme.textColor.withAlpha(170),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapperToolbarViewModeSwitch extends StatelessWidget {
  final ThemeColors theme;
  final MapperViewMode viewMode;
  final ValueChanged<MapperViewMode> onChangeView;

  const _MapperToolbarViewModeSwitch({
    required this.theme,
    required this.viewMode,
    required this.onChangeView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _mapperToolbarControlHeight,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.dashboardContainer.withAlpha(190),
        borderRadius: BorderRadius.circular(_mapperToolbarRadius),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(95)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MapperViewModeSegment(
            anchorKey: 'importer.mapper.view_mode.list',
            theme: theme,
            label: 'Lista'.tr,
            icon: Icons.view_list_rounded,
            isActive: viewMode == MapperViewMode.list,
            onTap: () => onChangeView(MapperViewMode.list),
          ),
          const SizedBox(width: 3),
          _MapperViewModeSegment(
            anchorKey: 'importer.mapper.view_mode.canvas',
            theme: theme,
            label: 'Canvas'.tr,
            icon: Icons.hub_rounded,
            isActive: viewMode == MapperViewMode.canvas,
            onTap: () => onChangeView(MapperViewMode.canvas),
          ),
        ],
      ),
    );
  }
}

class _MapperViewModeSegment extends StatelessWidget {
  final String anchorKey;
  final ThemeColors theme;
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _MapperViewModeSegment({
    required this.anchorKey,
    required this.theme,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return EmmaUiAnchorTarget(
      anchorKey: anchorKey,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: _mapperToolbarControlHeight - 8,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: isActive
                ? theme.themeColor.withAlpha(24)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: isActive
                  ? theme.themeColor.withAlpha(130)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive
                    ? theme.themeColor
                    : theme.textColor.withAlpha(170),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapperToolbarMiniDivider extends StatelessWidget {
  final ThemeColors theme;

  const _MapperToolbarMiniDivider({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: theme.dashboardBoarder.withAlpha(80),
    );
  }
}

class _MapperTemplateButtons extends StatelessWidget {
  final ThemeColors theme;
  final VoidCallback onDownloadTemplate;
  final VoidCallback? onSaveTemplate;
  final VoidCallback? onLoadTemplate;

  const _MapperTemplateButtons({
    required this.theme,
    required this.onDownloadTemplate,
    this.onSaveTemplate,
    this.onLoadTemplate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _mapperToolbarControlHeight,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.dashboardContainer.withAlpha(190),
        borderRadius: BorderRadius.circular(_mapperToolbarRadius),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(95)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TemplateIconBtn(
            tooltip: 'Pobierz szablon CSV'.tr,
            icon: Icons.download_rounded,
            theme: theme,
            onTap: onDownloadTemplate,
          ),
          if (onSaveTemplate != null) ...[
            const SizedBox(width: 2),
            _TemplateIconBtn(
              tooltip: 'Zapisz szablon mapowania'.tr,
              icon: Icons.save_rounded,
              theme: theme,
              onTap: onSaveTemplate,
            ),
          ],
          if (onLoadTemplate != null) ...[
            const SizedBox(width: 2),
            _TemplateIconBtn(
              tooltip: 'Wczytaj szablon mapowania'.tr,
              icon: Icons.folder_open_rounded,
              theme: theme,
              onTap: onLoadTemplate,
            ),
          ],
        ],
      ),
    );
  }
}

class _TemplateIconBtn extends StatelessWidget {
  final ThemeColors theme;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _TemplateIconBtn({
    required this.theme,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: _mapperToolbarControlHeight - 8,
          height: _mapperToolbarControlHeight - 8,
          child: Icon(
            icon,
            size: 15,
            color: theme.textColor.withAlpha(180),
          ),
        ),
      ),
    );
  }
}

class _SchemaButton extends StatelessWidget {
  final ThemeColors theme;
  final VoidCallback onTap;

  const _SchemaButton({required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Schema Explorer — przegląd modeli i relacji'.tr,
      child: InkWell(
        borderRadius: BorderRadius.circular(_mapperToolbarRadius),
        onTap: onTap,
        child: Container(
          height: _mapperToolbarControlHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: theme.dashboardContainer.withAlpha(190),
            borderRadius: BorderRadius.circular(_mapperToolbarRadius),
            border: Border.all(color: theme.dashboardBoarder.withAlpha(95)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_tree_rounded,
                size: 14,
                color: theme.textColor.withAlpha(180),
              ),
              const SizedBox(width: 5),
              Text(
                'Schema'.tr,
                style: TextStyle(
                  color: theme.textColor.withAlpha(180),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _mapperToolbarInputDecoration({
  required ThemeColors theme,
  required String hint,
  required IconData icon,
}) {
  return InputDecoration(
    hintText: hint.trim().isEmpty ? null : hint,
    hintStyle: TextStyle(
      color: theme.textColor.withAlpha(120),
      fontSize: 11.5,
      height: 1.0,
    ),
    isDense: true,
    filled: true,
    fillColor: theme.dashboardContainer.withAlpha(190),
    constraints: const BoxConstraints.tightFor(
      height: _mapperToolbarControlHeight,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    prefixIcon: Icon(icon, color: theme.textColor.withAlpha(145), size: 15),
    prefixIconConstraints: const BoxConstraints(
      minWidth: 30,
      minHeight: _mapperToolbarControlHeight,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_mapperToolbarRadius),
      borderSide: BorderSide(color: theme.dashboardBoarder.withAlpha(90)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_mapperToolbarRadius),
      borderSide: BorderSide(color: theme.dashboardBoarder.withAlpha(90)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_mapperToolbarRadius),
      borderSide: BorderSide(color: theme.themeColor.withAlpha(155)),
    ),
  );
}

ButtonStyle _mapperToolbarFilledStyle(ThemeColors theme) {
  return ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: theme.themeColor,
    minimumSize: const Size(0, _mapperToolbarControlHeight),
    maximumSize: const Size(double.infinity, _mapperToolbarControlHeight),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 0),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_mapperToolbarRadius),
    ),
    elevation: 0,
  );
}
