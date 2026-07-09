part of importer_field_mapper;

class _ImportTabFieldMapperState extends ConsumerState<ImportTabFieldMapper> {
  String _sourceSearch = '';
  String _targetSearch = '';
  String? _selectedColumn;

  bool _showOnlyUnmappedTargets = false;
  bool _isEmmaPlanning = false;

  MapperViewMode _viewMode = MapperViewMode.canvas;

  bool get _isCompact => MediaQuery.of(context).size.width < 980;

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message.tr)));
  }

  Future<void> _downloadTemplateCSV(List<String> columns) async {
    if (columns.isEmpty) {
      _showSnack('Brak kolumn do pobrania.');
      return;
    }
    final headerLine = columns.map((c) {
      final escaped = c.contains(',') || c.contains('"') || c.contains('\n')
          ? '"${c.replaceAll('"', '""')}"'
          : c;
      return escaped;
    }).join(',');
    final csv = '$headerLine\n';
    final bytes = Uint8List.fromList(utf8.encode(csv));
    await FileSaver.instance.saveAs(
      name: 'import_template',
      bytes: bytes,
      fileExtension: 'csv',
      mimeType: MimeType.other,
    );
  }

  static const _kTemplatePrefKey = 'importer_mapping_template_v1';

  Future<void> _saveMappingTemplate(ImportFormState formState) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = json.encode({
      'columns': formState.originalColumns,
      'mappings': formState.fieldMappings
          .map((m) => {
                'columnName': m.columnName,
                'targetModel': m.targetModel,
                'targetField': m.targetField,
              })
          .toList(),
    });
    await prefs.setString(_kTemplatePrefKey, payload);
    _showSnack('Szablon mapowania zapisany.');
  }

  Future<void> _loadMappingTemplate(
    ImportFormState formState,
    ImportFormNotifier formNotifier,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTemplatePrefKey);
    if (raw == null) {
      _showSnack('Brak zapisanego szablonu mapowania.');
      return;
    }
    try {
      final data = json.decode(raw) as Map<String, dynamic>;
      final mappingsRaw = data['mappings'] as List<dynamic>? ?? [];
      int applied = 0;
      for (final item in mappingsRaw) {
        final map = item as Map<String, dynamic>;
        final colName = map['columnName']?.toString() ?? '';
        final targetModel = map['targetModel']?.toString() ?? '';
        final targetField = map['targetField']?.toString() ?? '';
        if (colName.isEmpty ||
            targetModel.isEmpty ||
            targetField.isEmpty ||
            !formState.previewColumns.contains(colName)) {
          continue;
        }
        formNotifier.upsertFieldMappingForColumn(
          colName,
          targetModel: targetModel,
          targetField: targetField,
        );
        applied++;
      }
      _showSnack('Załadowano $applied mapowań z szablonu.');
    } catch (_) {
      _showSnack('Nie można wczytać szablonu — nieprawidłowy format.');
    }
  }

  Future<void> _suggestFullPlanWithEmma({
    required ThemeColors theme,
    required ImportFormState formState,
    required ImportFormNotifier formNotifier,
  }) async {
    final targetModel = formState.selectedTargetModel?.trim();

    if (targetModel == null || targetModel.isEmpty) {
      _showSnack('Najpierw wybierz model docelowy importu.');
      return;
    }

    if (formState.previewColumns.isEmpty || formState.previewData.isEmpty) {
      _showSnack('Brak danych w edytorze importu.');
      return;
    }

    setState(() {
      _isEmmaPlanning = true;
    });

    try {
      final result = await formNotifier.requestEmmaFullPlan(
        ref,
        targetModel: targetModel,
        maxRules: 40,
        maxEntities: 5,
        selectedRowsOnly: false,
      );

      if (!mounted) return;

      if (result['ok'] != true) {
        _showSnack(
          result['error']?.toString() ?? 'Emma nie zwróciła planu importu.',
        );
        return;
      }

      await _showEmmaFullPlanSheet(
        theme: theme,
        formNotifier: formNotifier,
        result: result,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isEmmaPlanning = false;
        });
      }
    }
  }

  Future<void> _showEmmaFullPlanSheet({
    required ThemeColors theme,
    required ImportFormNotifier formNotifier,
    required Map<String, dynamic> result,
  }) async {
    final split = _asStringMap(result['split']);
    final entityPlanResult = _asStringMap(result['entity_plan']);

    final rulesRaw = split['rules'] ?? result['rules'];
    final mappingHintsRaw = split['mapping_hints'] ?? result['mapping_hints'];
    final warningsRaw = split['warnings'] ?? result['warnings'];

    final entityPlan = _asStringMap(
      entityPlanResult['plan'] ?? result['entity_plan_object'],
    );

    final rules = rulesRaw is List ? rulesRaw : <dynamic>[];
    final mappingHints = mappingHintsRaw is List
        ? mappingHintsRaw
        : <dynamic>[];
    final warnings = warningsRaw is List ? warningsRaw : <dynamic>[];

    final entitiesRaw = entityPlan['entities'];
    final relationsRaw = entityPlan['relations'];

    final entities = entitiesRaw is List ? entitiesRaw : <dynamic>[];
    final relations = relationsRaw is List ? relationsRaw : <dynamic>[];

    final summary =
        result['summary']?.toString() ??
        split['summary']?.toString() ??
        entityPlanResult['summary']?.toString() ??
        'Emma przygotowała plan importu.';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(color: theme.dashboardBoarder.withAlpha(120)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: theme.themeColor.withAlpha(18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: theme.themeColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Plan Emmy'.tr,
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              summary.tr,
                              style: TextStyle(
                                color: theme.textColor.withAlpha(170),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: Icon(Icons.close_rounded, color: theme.textColor),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: theme.dashboardBoarder.withAlpha(120),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _EmmaMapperPlanSection(
                        theme: theme,
                        title: 'Transformacje / podział danych'.tr,
                        emptyText: 'Brak transformacji do zastosowania.'.tr,
                        items: rules,
                        itemBuilder: (item) {
                          final map = item is Map
                              ? Map<String, dynamic>.from(item)
                              : <String, dynamic>{};

                          final source =
                              map['source_column']?.toString() ?? '-';
                          final output =
                              map['output_column']?.toString() ?? '-';
                          final transform = map['transform']?.toString() ?? '-';
                          final confidence = _formatConfidence(
                            map['confidence'],
                          );
                          final reason = map['reason']?.toString() ?? '';

                          return _EmmaMapperPlanCard(
                            theme: theme,
                            icon: Icons.functions_rounded,
                            title: '$source → $output',
                            subtitle: confidence.isEmpty
                                ? 'Transformacja: $transform'
                                : 'Transformacja: $transform • confidence: $confidence',
                            description: reason,
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _EmmaMapperPlanSection(
                        theme: theme,
                        title: 'Mapowania pól'.tr,
                        emptyText: 'Brak sugestii mapowania.'.tr,
                        items: mappingHints,
                        itemBuilder: (item) {
                          final map = item is Map
                              ? Map<String, dynamic>.from(item)
                              : <String, dynamic>{};

                          final output =
                              map['output_column']?.toString() ?? '-';
                          final targetModel =
                              map['target_model']?.toString() ?? '-';
                          final targetField =
                              map['target_field']?.toString() ?? '-';
                          final confidence = _formatConfidence(
                            map['confidence'],
                          );
                          final reason = map['reason']?.toString() ?? '';

                          return _EmmaMapperPlanCard(
                            theme: theme,
                            icon: Icons.link_rounded,
                            title: '$output → $targetModel.$targetField',
                            subtitle: confidence.isEmpty
                                ? 'Mapowanie'
                                : 'Mapowanie • confidence: $confidence',
                            description: reason,
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _EmmaMapperPlanSection(
                        theme: theme,
                        title: 'Encje / modele'.tr,
                        emptyText:
                            'Brak planu relacyjnego — import zostanie wykonany klasycznie.'
                                .tr,
                        items: entities,
                        itemBuilder: (item) {
                          final map = item is Map
                              ? Map<String, dynamic>.from(item)
                              : <String, dynamic>{};

                          final alias = map['alias']?.toString() ?? '-';
                          final model = map['target_model']?.toString() ?? '-';
                          final mappings = map['mappings'];
                          final count = mappings is Map ? mappings.length : 0;

                          return _EmmaMapperPlanCard(
                            theme: theme,
                            icon: Icons.account_tree_rounded,
                            title: '$alias → $model',
                            subtitle: 'Pól w encji: $count',
                            description: map['reason']?.toString() ?? '',
                          );
                        },
                      ),
                      if (relations.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _EmmaMapperPlanSection(
                          theme: theme,
                          title: 'Relacje FK'.tr,
                          emptyText: '',
                          items: relations,
                          itemBuilder: (item) {
                            final map = item is Map
                                ? Map<String, dynamic>.from(item)
                                : <String, dynamic>{};

                            final from = map['from_alias']?.toString() ?? '-';
                            final field = map['field']?.toString() ?? '-';
                            final to = map['to_alias']?.toString() ?? '-';

                            return _EmmaMapperPlanCard(
                              theme: theme,
                              icon: Icons.call_split_rounded,
                              title: '$from.$field → $to',
                              subtitle: 'ForeignKey',
                              description: map['reason']?.toString() ?? '',
                            );
                          },
                        ),
                      ],
                      if (warnings.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _EmmaMapperPlanSection(
                          theme: theme,
                          title: 'Ostrzeżenia'.tr,
                          emptyText: '',
                          items: warnings,
                          itemBuilder: (item) {
                            return _EmmaMapperPlanCard(
                              theme: theme,
                              icon: Icons.warning_amber_rounded,
                              title: 'Uwaga'.tr,
                              subtitle: item.toString(),
                              description: '',
                              accentColor: Colors.orangeAccent,
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        OutlinedButton(
                          style: _outlinedActionStyle(theme),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            'Anuluj'.tr,
                            style: TextStyle(color: theme.textColor),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          style: _filledActionStyle(theme),
                          onPressed: () async {
                            final applyResult = await formNotifier
                                .applyEmmaFullPlanResult(
                                  result,
                                  applyTransforms: true,
                                  applyMappings: true,
                                  saveEntityPlan: true,
                                  minMappingConfidence: 0.35,
                                );

                            if (!ctx.mounted) return;

                            Navigator.of(ctx).pop();

                            final transformApplied = _emmaInt(
                              _asStringMap(
                                applyResult['transform_result'],
                              )['applied_count'],
                            );

                            final mappingApplied = _emmaInt(
                              _asStringMap(
                                applyResult['mapping_result'],
                              )['applied_count'],
                            );

                            final entityPlanSaved =
                                applyResult['entity_plan_saved'] == true;

                            _showSnack(
                              entityPlanSaved
                                  ? 'Emma zastosowała: transformacje $transformApplied, mapowania $mappingApplied i zapisała plan relacji.'
                                  : 'Emma zastosowała: transformacje $transformApplied, mapowania $mappingApplied.',
                            );
                          },
                          icon: const Icon(Icons.check_rounded),
                          label: Text('Zastosuj plan'.tr),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final formState = widget.formState;
    final formNotifier = widget.formNotifier;

    final previewColumns = formState.previewColumns;
    final previewData = formState.previewData;

    return widget.optionsAsync.when(
      data: (options) {
        if (formState.file == null) {
          return Center(
            child: Text(
              'Najpierw w zakładce "Plik" wybierz plik do importu.'.tr,
              style: TextStyle(color: theme.textColor.withAlpha(178)),
            ),
          );
        }

        if (formState.previewColumns.isEmpty) {
          return Center(
            child: Text(
              'Mapper pól wymaga podglądu kolumn (obsługiwany dla plików CSV).'
                  .tr,
              style: TextStyle(color: theme.textColor.withAlpha(178)),
            ),
          );
        }

        final allModelNames = options.targetModels.keys.toList()..sort();

        if (allModelNames.isEmpty) {
          return Center(
            child: Text(
              'Brak zdefiniowanych modeli docelowych po stronie backendu.'.tr,
              style: TextStyle(color: theme.textColor),
            ),
          );
        }

        final selectedTargetModel = formState.selectedTargetModel?.trim();

        final modelNames = [
          if (selectedTargetModel != null &&
              selectedTargetModel.isNotEmpty &&
              allModelNames.contains(selectedTargetModel))
            selectedTargetModel,
          ...allModelNames.where((m) => m != selectedTargetModel),
        ];

        final validSelectedColumn =
            _selectedColumn != null && previewColumns.contains(_selectedColumn)
            ? _selectedColumn
            : null;

        final mappedColumns = previewColumns
            .where((col) {
              return formState.fieldMappings.any((m) => m.columnName == col);
            })
            .toList(growable: false);

        final mappingSummary = formState.fieldMappings
            .where(
              (m) =>
                  previewColumns.contains(m.columnName) &&
                  m.targetModel.isNotEmpty &&
                  m.targetField.isNotEmpty,
            )
            .toList(growable: false);

        final sourceSearchLower = _sourceSearch.trim().toLowerCase();

        final filteredSourceColumns = previewColumns
            .where((col) {
              if (sourceSearchLower.isEmpty) return true;
              return col.toLowerCase().contains(sourceSearchLower);
            })
            .toList(growable: false);

        return EmmaUiAnchorTarget(
          // @emma-backend: ImporterEmmaAnchors.importMapperRoot
          anchorKey: 'importer.mapper.root',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EmmaUiAnchorTarget(
                // @emma-backend: ImporterEmmaAnchors.importMapperToolbar
                anchorKey: 'importer.mapper.toolbar',
                child: _MapperTopToolbar(
                  theme: theme,
                  viewMode: _viewMode,
                  selectedColumn: validSelectedColumn,
                  mappedCount: mappedColumns.length,
                  totalCount: previewColumns.length,
                  currentMappings: mappingSummary.length,
                  hasEntityPlan: _hasValidEmmaEntityPlan(
                    formState.emmaEntityPlan,
                  ),
                  isEmmaPlanning: _isEmmaPlanning,
                  targetModels: allModelNames,
                  selectedTargetModel: selectedTargetModel,
                  isTablet: widget.isTablet,
                  onTargetModelChanged: (model) {
                    formNotifier.setTargetModel(model);

                    setState(() {
                      _targetSearch = '';
                    });
                  },
                  onSuggestWithEmma: () {
                    _suggestFullPlanWithEmma(
                      theme: theme,
                      formState: formState,
                      formNotifier: formNotifier,
                    );
                  },
                  onChangeView: (mode) {
                    setState(() {
                      _viewMode = mode;
                    });
                  },
                  onClearSelected: () {
                    setState(() {
                      _selectedColumn = null;
                    });
                  },
                  onDownloadTemplate: () =>
                      _downloadTemplateCSV(previewColumns),
                  onSaveTemplate: () =>
                      _saveMappingTemplate(formState),
                  onLoadTemplate: () =>
                      _loadMappingTemplate(formState, formNotifier),
                  onShowSchema: () => showSchemaExplorer(
                    context: context,
                    theme: theme,
                    options: options,
                  ),
                ),
              ),
              Expanded(
                child: _viewMode == MapperViewMode.canvas
                    ? EmmaUiAnchorTarget(
                        // @emma-backend: ImporterEmmaAnchors.importMapperCanvas
                        anchorKey: 'importer.mapper.canvas_container',
                        child: MapperCanvasView(
                          rootAnchorKey: 'importer.mapper.canvas',
                          theme: theme,
                          options: options,
                          formState: formState,
                          formNotifier: formNotifier,
                          selectedColumn: validSelectedColumn,
                          selectedTargetModel: selectedTargetModel,
                          minScale: 0.16,
                          maxScale: 2.4,
                          showFullscreenButton: true,
                          isTablet: widget.isTablet,
                          onOpenFullscreen: () {
                            _openCanvasFullscreen(
                              context: context,
                              theme: theme,
                              options: options,
                              formNotifier: formNotifier,
                              initialSelectedColumn: validSelectedColumn,
                              initialSelectedTargetModel: selectedTargetModel,
                            );
                          },
                          onSelectColumn: (column) {
                            setState(() {
                              _selectedColumn = column;
                            });
                          },
                        ),
                      )
                    : (_isCompact
                          ? Column(
                              children: [
                                Expanded(
                                  child: EmmaUiAnchorTarget(
                                    // @emma-backend: ImporterEmmaAnchors.importMapperSourcePanel
                                    anchorKey:
                                        'importer.mapper.source_columns_panel',
                                    child: _SourceColumnsPanel(
                                      theme: theme,
                                      columns: filteredSourceColumns,
                                      previewColumns: previewColumns,
                                      previewData: previewData,
                                      formState: formState,
                                      selectedColumn: validSelectedColumn,
                                      sourceSearch: _sourceSearch,
                                      onSearchChanged: (value) {
                                        setState(() {
                                          _sourceSearch = value;
                                        });
                                      },
                                      onSelectColumn: (column) {
                                        setState(() {
                                          _selectedColumn = column;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: EmmaUiAnchorTarget(
                                    // @emma-backend: ImporterEmmaAnchors.importMapperTargetPanel
                                    anchorKey:
                                        'importer.mapper.target_models_panel',
                                    child: _TargetModelsPanel(
                                      theme: theme,
                                      options: options,
                                      modelNames: modelNames,
                                      selectedTargetModel: selectedTargetModel,
                                      previewColumns: previewColumns,
                                      previewData: previewData,
                                      formState: formState,
                                      formNotifier: formNotifier,
                                      targetSearch: _targetSearch,
                                      showOnlyUnmappedTargets:
                                          _showOnlyUnmappedTargets,
                                      selectedColumn: validSelectedColumn,
                                      onSearchChanged: (value) {
                                        setState(() {
                                          _targetSearch = value;
                                        });
                                      },
                                      onToggleOnlyUnmapped: (value) {
                                        setState(() {
                                          _showOnlyUnmappedTargets = value;
                                        });
                                      },
                                      onAssignFromSelected: (model, field) {
                                        if (validSelectedColumn == null) {
                                          return;
                                        }

                                        formNotifier.setMappingForTarget(
                                          columnName: validSelectedColumn,
                                          targetModel: model,
                                          targetField: field,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 11,
                                  child: EmmaUiAnchorTarget(
                                    // @emma-backend: ImporterEmmaAnchors.importMapperSourcePanel
                                    anchorKey:
                                        'importer.mapper.source_columns_panel',
                                    child: _SourceColumnsPanel(
                                      theme: theme,
                                      columns: filteredSourceColumns,
                                      previewColumns: previewColumns,
                                      previewData: previewData,
                                      formState: formState,
                                      selectedColumn: validSelectedColumn,
                                      sourceSearch: _sourceSearch,
                                      onSearchChanged: (value) {
                                        setState(() {
                                          _sourceSearch = value;
                                        });
                                      },
                                      onSelectColumn: (column) {
                                        setState(() {
                                          _selectedColumn = column;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 16,
                                  child: EmmaUiAnchorTarget(
                                    // @emma-backend: ImporterEmmaAnchors.importMapperTargetPanel
                                    anchorKey:
                                        'importer.mapper.target_models_panel',
                                    child: _TargetModelsPanel(
                                      theme: theme,
                                      options: options,
                                      modelNames: modelNames,
                                      selectedTargetModel: selectedTargetModel,
                                      previewColumns: previewColumns,
                                      previewData: previewData,
                                      formState: formState,
                                      formNotifier: formNotifier,
                                      targetSearch: _targetSearch,
                                      showOnlyUnmappedTargets:
                                          _showOnlyUnmappedTargets,
                                      selectedColumn: validSelectedColumn,
                                      onSearchChanged: (value) {
                                        setState(() {
                                          _targetSearch = value;
                                        });
                                      },
                                      onToggleOnlyUnmapped: (value) {
                                        setState(() {
                                          _showOnlyUnmappedTargets = value;
                                        });
                                      },
                                      onAssignFromSelected: (model, field) {
                                        if (validSelectedColumn == null) {
                                          return;
                                        }

                                        formNotifier.setMappingForTarget(
                                          columnName: validSelectedColumn,
                                          targetModel: model,
                                          targetField: field,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            )),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text(
          'Błąd pobierania opcji importu: $err',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }

  void _openBatchOverlay(BuildContext context, ThemeColors theme) {
    final isCompact = MediaQuery.of(context).size.width < 900;

    if (isCompact) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return SafeArea(
            child: Container(
              height: MediaQuery.of(ctx).size.height * 0.92,
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: const BatchImportOverlay(),
            ),
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: theme.dashboardContainer,
          insetPadding: const EdgeInsets.all(24),
          child: const SizedBox(
            width: 800,
            height: 520,
            child: BatchImportOverlay(),
          ),
        );
      },
    );
  }

  void _openCanvasFullscreen({
    required BuildContext context,
    required ThemeColors theme,
    required ImportOptions options,
    required ImportFormNotifier formNotifier,
    required String? initialSelectedColumn,
    required String? initialSelectedTargetModel,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withAlpha(220),
      builder: (dialogContext) {
        String? fullscreenSelectedColumn = initialSelectedColumn;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Consumer(
              builder: (context, ref, _) {
                final latestFormState = ref.watch(importFormProvider);
                final latestSelectedTargetModel = latestFormState
                    .selectedTargetModel
                    ?.trim();

                return EmmaUiAnchorTarget(
                  // @emma-backend: ImporterEmmaAnchors.importMapperCanvasFullscreen
                  anchorKey: 'importer.mapper.canvas_fullscreen',
                  child: Dialog(
                    insetPadding: EdgeInsets.zero,
                    backgroundColor: Colors.transparent,
                    child: Material(
                      color: theme.dashboardContainer,
                      child: SafeArea(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: theme.dashboardBoarder.withAlpha(
                                      110,
                                    ),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.open_in_full_rounded,
                                    color: theme.themeColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Mapper canvas — fullscreen'.tr,
                                      style: TextStyle(
                                        color: theme.textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (latestSelectedTargetModel != null &&
                                      latestSelectedTargetModel.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.themeColor.withAlpha(24),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: theme.themeColor.withAlpha(
                                            120,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Model: $latestSelectedTargetModel',
                                        style: TextStyle(
                                          color: theme.textColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  if (fullscreenSelectedColumn != null) ...[
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.themeColor.withAlpha(24),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: theme.themeColor.withAlpha(
                                            120,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Aktywna: $fullscreenSelectedColumn',
                                        style: TextStyle(
                                          color: theme.textColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 10),
                                  IconButton(
                                    tooltip: 'Zamknij'.tr,
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(),
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: MapperCanvasView(
                                  rootAnchorKey:
                                      'importer.mapper.canvas_fullscreen.body',
                                  theme: theme,
                                  options: options,
                                  formState: latestFormState,
                                  formNotifier: formNotifier,
                                  selectedColumn: fullscreenSelectedColumn,
                                  selectedTargetModel:
                                      latestSelectedTargetModel ??
                                      initialSelectedTargetModel,
                                  minScale: 0.06,
                                  maxScale: 3.2,
                                  showFullscreenButton: false,
                                  isTablet: widget.isTablet,
                                  onOpenFullscreen: null,
                                  onSelectColumn: (column) {
                                    setModalState(() {
                                      fullscreenSelectedColumn = column;
                                    });

                                    setState(() {
                                      _selectedColumn = column;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
