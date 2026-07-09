part of importer_field_mapper;

class _TargetModelsPanel extends StatefulWidget {
  final ThemeColors theme;
  final ImportOptions options;
  final List<String> modelNames;
  final String? selectedTargetModel;
  final List<String> previewColumns;
  final List<List<String>> previewData;
  final ImportFormState formState;
  final ImportFormNotifier formNotifier;
  final String targetSearch;
  final bool showOnlyUnmappedTargets;
  final String? selectedColumn;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool> onToggleOnlyUnmapped;
  final void Function(String model, String field) onAssignFromSelected;

  const _TargetModelsPanel({
    required this.theme,
    required this.options,
    required this.modelNames,
    required this.selectedTargetModel,
    required this.previewColumns,
    required this.previewData,
    required this.formState,
    required this.formNotifier,
    required this.targetSearch,
    required this.showOnlyUnmappedTargets,
    required this.selectedColumn,
    required this.onSearchChanged,
    required this.onToggleOnlyUnmapped,
    required this.onAssignFromSelected,
  });

  @override
  State<_TargetModelsPanel> createState() => _TargetModelsPanelState();
}

class _TargetModelsPanelState extends State<_TargetModelsPanel> {
  List<String> _modelOrder = [];

  @override
  void initState() {
    super.initState();
    _syncModelOrder();
  }

  @override
  void didUpdateWidget(covariant _TargetModelsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncModelOrder();
  }

  void _syncModelOrder() {
    final available = widget.modelNames.toSet();

    if (_modelOrder.isEmpty) {
      _modelOrder = widget.modelNames.toList();
      return;
    }

    _modelOrder = _modelOrder
        .where((modelName) => available.contains(modelName))
        .toList(growable: true);

    for (final modelName in widget.modelNames) {
      if (!_modelOrder.contains(modelName)) {
        _modelOrder.add(modelName);
      }
    }
  }

  void _moveModelBefore({
    required String draggedModel,
    required String targetModel,
  }) {
    if (draggedModel == targetModel) return;

    setState(() {
      _modelOrder.remove(draggedModel);

      final targetIndex = _modelOrder.indexOf(targetModel);
      if (targetIndex < 0) {
        _modelOrder.add(draggedModel);
      } else {
        _modelOrder.insert(targetIndex, draggedModel);
      }
    });
  }

  void _moveModelBy(String modelName, int delta) {
    final index = _modelOrder.indexOf(modelName);
    if (index < 0) return;

    final nextIndex = (index + delta).clamp(0, _modelOrder.length - 1).toInt();
    if (nextIndex == index) return;

    setState(() {
      final item = _modelOrder.removeAt(index);
      _modelOrder.insert(nextIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final searchLower = widget.targetSearch.trim().toLowerCase();

    final orderedModels = _modelOrder
        .where((modelName) => widget.modelNames.contains(modelName))
        .toList(growable: false);

    final visibleModels = orderedModels.where((modelName) {
      final rawSpec = widget.options.targetModels[modelName];
      final fieldSpecs = _extractFieldSpecsFromRawSpec(rawSpec);

      final filteredSpecs = _filterFieldSpecs(
        modelName: modelName,
        fieldSpecs: fieldSpecs,
        searchLower: searchLower,
      );

      return filteredSpecs.isNotEmpty;
    }).toList(growable: false);

    return Container(
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(100)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _PanelHeader(
            theme: theme,
            title: 'Pola docelowe'.tr,
            subtitle:
                'Model główny jest podświetlony. Pola FK pokazują powiązany model.'
                    .tr,
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;

              final searchField = EmmaUiAnchorTarget(
                // @emma-backend: ImporterEmmaAnchors.importMapperTargetSearch
                anchorKey: 'importer.mapper.target_search',
                child: TextField(
                  onChanged: widget.onSearchChanged,
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: theme.dashboardContainer,
                    labelText: 'Szukaj modelu, pola lub relacji'.tr,
                    labelStyle: TextStyle(
                      color: theme.textColor.withAlpha(160),
                      fontSize: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );

              final onlyUnmappedChip = EmmaUiAnchorTarget(
                // @emma-backend: ImporterEmmaAnchors.importMapperOnlyUnmappedToggle
                anchorKey: 'importer.mapper.only_unmapped_toggle',
                child: FilterChip(
                  selected: widget.showOnlyUnmappedTargets,
                  label: Text(
                    'Tylko wolne'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onSelected: widget.onToggleOnlyUnmapped,
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    searchField,
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: onlyUnmappedChip,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 0,
                    child: onlyUnmappedChip,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: visibleModels.isEmpty
                ? Center(
                    child: Text(
                      'Brak pól pasujących do filtrów.'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(170),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: visibleModels.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final modelName = visibleModels[index];
                      final rawSpec = widget.options.targetModels[modelName];
                      final fieldSpecs = _extractFieldSpecsFromRawSpec(rawSpec);

                      final filteredSpecs = _filterFieldSpecs(
                        modelName: modelName,
                        fieldSpecs: fieldSpecs,
                        searchLower: searchLower,
                      );

                      final sortedSpecs = _sortFieldSpecsBySelectedColumn(
                        fieldSpecs: filteredSpecs,
                      );

                      return DragTarget<String>(
                        onWillAcceptWithDetails: (details) {
                          return details.data != modelName &&
                              visibleModels.contains(details.data);
                        },
                        onAcceptWithDetails: (details) {
                          _moveModelBefore(
                            draggedModel: details.data,
                            targetModel: modelName,
                          );
                        },
                        builder: (context, candidateData, rejectedData) {
                          final isReorderHover = candidateData.isNotEmpty;

                          return LongPressDraggable<String>(
                            data: modelName,
                            feedback: Material(
                              color: Colors.transparent,
                              child: SizedBox(
                                width: 320,
                                child: _TargetModelDragFeedback(
                                  theme: theme,
                                  modelName: modelName,
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.35,
                              child: _TargetModelCard(
                                theme: theme,
                                modelName: modelName,
                                fieldSpecs: sortedSpecs,
                                previewColumns: widget.previewColumns,
                                previewData: widget.previewData,
                                formState: widget.formState,
                                formNotifier: widget.formNotifier,
                                selectedColumn: widget.selectedColumn,
                                isSelectedTargetModel:
                                    widget.selectedTargetModel == modelName,
                                isReorderHover: false,
                                onMoveUp: () => _moveModelBy(modelName, -1),
                                onMoveDown: () => _moveModelBy(modelName, 1),
                                onAssignFromSelected: (field) {
                                  widget.onAssignFromSelected(modelName, field);
                                },
                              ),
                            ),
                            child: _TargetModelCard(
                              theme: theme,
                              modelName: modelName,
                              fieldSpecs: sortedSpecs,
                              previewColumns: widget.previewColumns,
                              previewData: widget.previewData,
                              formState: widget.formState,
                              formNotifier: widget.formNotifier,
                              selectedColumn: widget.selectedColumn,
                              isSelectedTargetModel:
                                  widget.selectedTargetModel == modelName,
                              isReorderHover: isReorderHover,
                              onMoveUp: () => _moveModelBy(modelName, -1),
                              onMoveDown: () => _moveModelBy(modelName, 1),
                              onAssignFromSelected: (field) {
                                widget.onAssignFromSelected(modelName, field);
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<_TargetFieldSpec> _filterFieldSpecs({
    required String modelName,
    required List<_TargetFieldSpec> fieldSpecs,
    required String searchLower,
  }) {
    return fieldSpecs.where((spec) {
      final matchesSearch = searchLower.isEmpty ||
          spec.name.toLowerCase().contains(searchLower) ||
          spec.type.toLowerCase().contains(searchLower) ||
          modelName.toLowerCase().contains(searchLower) ||
          (spec.relatedModel?.toLowerCase().contains(searchLower) ?? false);

      if (!matchesSearch) return false;

      if (!widget.showOnlyUnmappedTargets) return true;

      final current = widget.formNotifier.getMappingForTarget(
        modelName,
        spec.name,
      );

      return current == null;
    }).toList(growable: false);
  }

  List<_TargetFieldSpec> _sortFieldSpecsBySelectedColumn({
    required List<_TargetFieldSpec> fieldSpecs,
  }) {
    final selectedColumn = widget.selectedColumn;

    if (selectedColumn == null || selectedColumn.trim().isEmpty) {
      return fieldSpecs;
    }

    final sorted = fieldSpecs.toList();

    sorted.sort((a, b) {
      final aScore = _targetPanelSimilarityPercent(selectedColumn, a.name);
      final bScore = _targetPanelSimilarityPercent(selectedColumn, b.name);
      return bScore.compareTo(aScore);
    });

    return sorted;
  }
}

class _TargetModelDragFeedback extends StatelessWidget {
  final ThemeColors theme;
  final String modelName;

  const _TargetModelDragFeedback({
    required this.theme,
    required this.modelName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.dashboardContainer.withAlpha(246),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.themeColor.withAlpha(140),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.drag_indicator_rounded,
            size: 18,
            color: theme.themeColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              modelName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetModelCard extends StatelessWidget {
  final ThemeColors theme;
  final String modelName;
  final List<_TargetFieldSpec> fieldSpecs;
  final List<String> previewColumns;
  final List<List<String>> previewData;
  final ImportFormState formState;
  final ImportFormNotifier formNotifier;
  final String? selectedColumn;
  final bool isSelectedTargetModel;
  final bool isReorderHover;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final ValueChanged<String> onAssignFromSelected;

  const _TargetModelCard({
    required this.theme,
    required this.modelName,
    required this.fieldSpecs,
    required this.previewColumns,
    required this.previewData,
    required this.formState,
    required this.formNotifier,
    required this.selectedColumn,
    required this.isSelectedTargetModel,
    required this.isReorderHover,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onAssignFromSelected,
  });

  @override
  Widget build(BuildContext context) {
    final mappedCount = fieldSpecs.where((spec) {
      return formNotifier.getMappingForTarget(modelName, spec.name) != null;
    }).length;

    final relationCount = fieldSpecs.where((spec) => spec.isRelation).length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isReorderHover
              ? theme.themeColor
              : isSelectedTargetModel
                  ? theme.themeColor.withAlpha(180)
                  : theme.dashboardBoarder.withAlpha(110),
          width: isReorderHover
              ? 2
              : isSelectedTargetModel
                  ? 1.5
                  : 1,
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: selectedColumn != null || isSelectedTargetModel,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 430;

            return Row(
              children: [
                Icon(
                  Icons.drag_indicator_rounded,
                  size: 17,
                  color: theme.textColor.withAlpha(120),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    modelName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (!compact && isSelectedTargetModel) ...[
                  const SizedBox(width: 8),
                  _TargetPanelHeaderBadge(
                    theme: theme,
                    label: 'GŁÓWNY'.tr,
                    isPrimary: true,
                  ),
                ],
                const SizedBox(width: 4),
                _TargetPanelSmallIconButton(
                  theme: theme,
                  tooltip: 'Przenieś wyżej'.tr,
                  icon: Icons.keyboard_arrow_up_rounded,
                  onTap: onMoveUp,
                ),
                _TargetPanelSmallIconButton(
                  theme: theme,
                  tooltip: 'Przenieś niżej'.tr,
                  icon: Icons.keyboard_arrow_down_rounded,
                  onTap: onMoveDown,
                ),
              ],
            );
          },
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            'Pól: ${fieldSpecs.length} • FK: $relationCount • zmapowane: $mappedCount'
                .tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.textColor.withAlpha(170),
              fontSize: 11,
            ),
          ),
        ),
        children: fieldSpecs.map((spec) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _TargetFieldTile(
              theme: theme,
              modelName: modelName,
              fieldSpec: spec,
              previewColumns: previewColumns,
              previewData: previewData,
              formState: formState,
              formNotifier: formNotifier,
              selectedColumn: selectedColumn,
              onAssignFromSelected: () => onAssignFromSelected(spec.name),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TargetFieldTile extends StatelessWidget {
  final ThemeColors theme;
  final String modelName;
  final _TargetFieldSpec fieldSpec;
  final List<String> previewColumns;
  final List<List<String>> previewData;
  final ImportFormState formState;
  final ImportFormNotifier formNotifier;
  final String? selectedColumn;
  final VoidCallback onAssignFromSelected;

  const _TargetFieldTile({
    required this.theme,
    required this.modelName,
    required this.fieldSpec,
    required this.previewColumns,
    required this.previewData,
    required this.formState,
    required this.formNotifier,
    required this.selectedColumn,
    required this.onAssignFromSelected,
  });

  @override
  Widget build(BuildContext context) {
    final fieldName = fieldSpec.name;

    final current = formNotifier.getMappingForTarget(modelName, fieldName);
    final currentColumn = current?.columnName;
    final isAssignedFromSelected =
        selectedColumn != null && currentColumn == selectedColumn;

    final matchScore = selectedColumn == null || selectedColumn!.trim().isEmpty
        ? 0
        : _targetPanelSimilarityPercent(selectedColumn!, fieldName);

    String dropdownValue = '';
    if (currentColumn != null && previewColumns.contains(currentColumn)) {
      dropdownValue = currentColumn;
    }

    final samples = <String>[];

    if (dropdownValue.isNotEmpty) {
      final colIndex = previewColumns.indexOf(dropdownValue);

      if (colIndex != -1) {
        for (final row in previewData.take(4)) {
          final value = colIndex < row.length ? row[colIndex] : '';

          if (value.trim().isNotEmpty) {
            samples.add(value);
          }
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isAssignedFromSelected
            ? theme.themeColor.withAlpha(20)
            : matchScore >= 75
                ? theme.themeColor.withAlpha(12)
                : fieldSpec.isRelation
                    ? theme.themeColor.withAlpha(8)
                    : theme.adPopBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAssignedFromSelected
              ? theme.themeColor.withAlpha(150)
              : matchScore >= 75
                  ? theme.themeColor.withAlpha(120)
                  : fieldSpec.isRelation
                      ? theme.themeColor.withAlpha(90)
                      : theme.dashboardBoarder.withAlpha(100),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                fieldSpec.isRelation
                    ? Icons.account_tree_rounded
                    : Icons.label_outline_rounded,
                size: 15,
                color: fieldSpec.isRelation
                    ? theme.themeColor
                    : theme.textColor.withAlpha(160),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  fieldName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (fieldSpec.required)
                _FieldMetaBadge(
                  theme: theme,
                  label: 'required'.tr,
                  accent: Colors.redAccent,
                ),
              if (fieldSpec.isRelation)
                _FieldMetaBadge(
                  theme: theme,
                  label: fieldSpec.relatedModel == null
                      ? 'FK'
                      : 'FK → ${fieldSpec.relatedModel}',
                  accent: theme.themeColor,
                ),
              if (matchScore > 0)
                _FieldMetaBadge(
                  theme: theme,
                  label: '$matchScore%',
                  accent: matchScore >= 45
                      ? theme.themeColor
                      : theme.textColor.withAlpha(150),
                ),
              if (selectedColumn != null)
                OutlinedButton.icon(
                  style: _outlinedActionStyle(theme),
                  onPressed: onAssignFromSelected,
                  icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                  label: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 82),
                    child: Text(
                      selectedColumn == currentColumn
                          ? 'Przypięte'.tr
                          : 'Przypnij'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: theme.textColor),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            fieldSpec.type.isEmpty
                ? 'Typ pola nie został określony'.tr
                : fieldSpec.type,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.textColor.withAlpha(145),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: dropdownValue,
            isExpanded: true,
            dropdownColor: theme.dashboardContainer,
            selectedItemBuilder: (context) {
              return [
                Text(
                  '— brak —'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(204),
                    fontSize: 12,
                  ),
                ),
                ...previewColumns.map(
                  (col) => Text(
                    col,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ];
            },
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: theme.dashboardContainer,
              labelText: 'Kolumna źródłowa'.tr,
              labelStyle: TextStyle(
                color: theme.textColor.withAlpha(180),
                fontSize: 11,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.dashboardBoarder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.themeColor,
                  width: 1.5,
                ),
              ),
            ),
            items: [
              DropdownMenuItem(
                value: '',
                child: Text(
                  '— brak —'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(204),
                    fontSize: 12,
                  ),
                ),
              ),
              ...previewColumns.map(
                (col) => DropdownMenuItem(
                  value: col,
                  child: Text(
                    col,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
            onChanged: (val) {
              if (val == null || val.isEmpty) {
                formNotifier.setMappingForTarget(
                  columnName: null,
                  targetModel: modelName,
                  targetField: fieldName,
                );
              } else {
                formNotifier.setMappingForTarget(
                  columnName: val,
                  targetModel: modelName,
                  targetField: fieldName,
                );
              }
            },
          ),
          if (currentColumn != null) ...[
            const SizedBox(height: 8),
            Text(
              'Aktualnie z: $currentColumn'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor.withAlpha(175),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (samples.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: samples.map((s) {
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 170),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.dashboardBoarder.withAlpha(120),
                      ),
                    ),
                    child: Text(
                      s,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(204),
                        fontSize: 10,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TargetPanelSmallIconButton extends StatelessWidget {
  final ThemeColors theme;
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _TargetPanelSmallIconButton({
    required this.theme,
    required this.tooltip,
    required this.icon,
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
          width: 26,
          height: 26,
          child: Icon(
            icon,
            size: 17,
            color: theme.textColor.withAlpha(155),
          ),
        ),
      ),
    );
  }
}

class _TargetPanelHeaderBadge extends StatelessWidget {
  final ThemeColors theme;
  final String label;
  final bool isPrimary;

  const _TargetPanelHeaderBadge({
    required this.theme,
    required this.label,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 86),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isPrimary
              ? theme.themeColor.withAlpha(22)
              : theme.adPopBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isPrimary
                ? theme.themeColor.withAlpha(120)
                : theme.dashboardBoarder.withAlpha(80),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isPrimary ? theme.themeColor : theme.textColor.withAlpha(190),
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _FieldMetaBadge extends StatelessWidget {
  final ThemeColors theme;
  final String label;
  final Color accent;

  const _FieldMetaBadge({
    required this.theme,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 130),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: accent.withAlpha(18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: accent.withAlpha(100),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: accent,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

int _targetPanelSimilarityPercent(String left, String right) {
  final a = _targetPanelNormalizeKey(left);
  final b = _targetPanelNormalizeKey(right);

  if (a.isEmpty || b.isEmpty) return 0;
  if (a == b) return 100;

  final leftTokens = _targetPanelTokens(left);
  final rightTokens = _targetPanelTokens(right);

  int tokenScore = 0;

  if (leftTokens.isNotEmpty && rightTokens.isNotEmpty) {
    final intersection = leftTokens.intersection(rightTokens).length;
    final union = leftTokens.union(rightTokens).length;

    if (union > 0) {
      tokenScore = ((intersection / union) * 100).round();
    }
  }

  int containsScore = 0;

  if (a.contains(b) || b.contains(a)) {
    final shorter = math.min(a.length, b.length);
    final longer = math.max(a.length, b.length);
    containsScore = ((shorter / longer) * 92).round();
  }

  final distance = _targetPanelLevenshteinDistance(a, b);
  final maxLength = math.max(a.length, b.length);
  final editScore = maxLength == 0
      ? 0
      : (((maxLength - distance) / maxLength) * 100).round();

  final score = math.max(
    tokenScore,
    math.max(containsScore, editScore),
  );

  return score.clamp(0, 100).toInt();
}

String _targetPanelNormalizeKey(String value) {
  return _targetPanelStripDiacritics(value)
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

Set<String> _targetPanelTokens(String value) {
  final spacedCamel = value.trim().replaceAllMapped(
        RegExp(r'([a-ząćęłńóśźż0-9])([A-Z])', unicode: true),
        (match) => '${match.group(1)} ${match.group(2)}',
      );

  final normalized = _targetPanelStripDiacritics(spacedCamel)
      .toLowerCase()
      .replaceAll(RegExp(r'[_\-.]+'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ');

  return normalized
      .split(RegExp(r'\s+'))
      .map((token) => token.trim())
      .where((token) => token.length >= 2)
      .toSet();
}

String _targetPanelStripDiacritics(String value) {
  const replacements = {
    'ą': 'a',
    'ć': 'c',
    'ę': 'e',
    'ł': 'l',
    'ń': 'n',
    'ó': 'o',
    'ś': 's',
    'ź': 'z',
    'ż': 'z',
    'Ą': 'A',
    'Ć': 'C',
    'Ę': 'E',
    'Ł': 'L',
    'Ń': 'N',
    'Ó': 'O',
    'Ś': 'S',
    'Ź': 'Z',
    'Ż': 'Z',
  };

  final buffer = StringBuffer();

  for (final codePoint in value.runes) {
    final char = String.fromCharCode(codePoint);
    buffer.write(replacements[char] ?? char);
  }

  return buffer.toString();
}

int _targetPanelLevenshteinDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  final previous = List<int>.generate(b.length + 1, (index) => index);
  final current = List<int>.filled(b.length + 1, 0);

  for (int i = 0; i < a.length; i++) {
    current[0] = i + 1;

    for (int j = 0; j < b.length; j++) {
      final insertCost = current[j] + 1;
      final deleteCost = previous[j + 1] + 1;
      final replaceCost =
          previous[j] + (a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1);

      current[j + 1] = math.min(
        insertCost,
        math.min(deleteCost, replaceCost),
      );
    }

    for (int j = 0; j < previous.length; j++) {
      previous[j] = current[j];
    }
  }

  return previous[b.length];
}