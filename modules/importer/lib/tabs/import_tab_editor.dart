import 'dart:math' as math;

import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:importer/tabs/mapping/enum.dart';
import 'package:importer/tabs/mapping/models.dart';
import 'package:importer/tabs/mapping/overlay.dart';
import 'package:importer/tabs/mapping/selection.dart';
import 'package:importer/tabs/mapping/summit_row.dart';
import 'package:importer/tabs/transform_sheet.dart';
import 'package:core/theme/apptheme.dart';

// ignore: unused_import
import 'package:importer/emma/anchors/anchors_importer.dart';

import '../import_state.dart';

import 'dart:convert';
import 'package:flutter/services.dart';


class ImportEditorPaginationState {
  final int totalRows;
  final int currentPage;
  final int totalPages;
  final int pageSize;

  const ImportEditorPaginationState({
    required this.totalRows,
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ImportEditorPaginationState &&
            other.totalRows == totalRows &&
            other.currentPage == currentPage &&
            other.totalPages == totalPages &&
            other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(
        totalRows,
        currentPage,
        totalPages,
        pageSize,
      );
}

class ImportTabEditor extends ConsumerStatefulWidget {
  final AsyncValue<ImportOptions> optionsAsync;
  final ImportFormState formState;
  final ImportFormNotifier formNotifier;
  final bool isTablet;
  final ValueChanged<ImportEditorPaginationState>? onPaginationChanged;

  const ImportTabEditor({
    super.key,
    required this.optionsAsync,
    required this.formState,
    required this.formNotifier,
    this.isTablet=false,
    this.onPaginationChanged,
  });

  @override
  ConsumerState<ImportTabEditor> createState() => _ImportTabEditorState();
}

class _ImportTabEditorState extends ConsumerState<ImportTabEditor>
    with SelectionOverlayMixin {
  String _columnSearch = '';
  String _valueSearch = '';
  String? _selectedColumn;

  bool _showOnlyMappedColumns = false;
  bool _showOnlyTransformedColumns = false;
  bool _showOnlyColumnsWithValues = false;
  bool _showOnlySelectedRows = false;
  bool _isEmmaSuggesting = false;

  bool _isColumnsPanelOpen = false;
  bool _isInspectorPanelOpen = false;
  

  bool get _isCompact => MediaQuery.of(context).size.width < 750;
  bool get _isTablet =>
      MediaQuery.of(context).size.width >= 750 &&
          MediaQuery.of(context).size.width < 1400;

ImportEditorPaginationState? _lastPaginationState;

void _emitPaginationState({
  required int totalRows,
  required int currentPage,
  required int totalPages,
  required int pageSize,
}) {
  final callback = widget.onPaginationChanged;
  if (callback == null) return;

  final nextState = ImportEditorPaginationState(
    totalRows: totalRows,
    currentPage: currentPage,
    totalPages: totalPages,
    pageSize: pageSize,
  );

  if (_lastPaginationState == nextState) return;

  _lastPaginationState = nextState;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    callback(nextState);
  });
}



  @override
  void dispose() {
    disposeSelectionOverlay();
    super.dispose();
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.tr),
      ),
    );
  }

  Future<void> _copyEmmaPromptToClipboard(ImportFormState formState) async {
    final targetModel = formState.selectedTargetModel?.trim();

    if (targetModel == null || targetModel.isEmpty) {
      _showSnack('Najpierw wybierz model docelowy importu.');
      return;
    }

    final prompt = '''
Emma, podziel dane w importerze pod model $targetModel.

Najpierw użyj lokalnego narzędzia:
- importer_get_dataset_profile

Potem użyj backendowego narzędzia:
- importer_suggest_data_split

Pokaż mi plan podziału danych i zapytaj o zgodę przed zastosowaniem zmian.

Po mojej zgodzie zastosuj transformacje lokalnym narzędziem:
- importer_apply_transform_rules
''';

    await Clipboard.setData(ClipboardData(text: prompt.trim()));

    _showSnack('Skopiowano prompt dla Emmy.');
  }






  Future<void> _suggestSplitWithEmmaApi({
  required ThemeColors theme,
  required ImportFormState formState,
  required ImportFormNotifier formNotifier,
  String? selectedColumn,
}) async {
  final targetModel = formState.selectedTargetModel?.trim();

  if (targetModel == null || targetModel.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Najpierw wybierz model docelowy.'.tr)),
    );
    return;
  }

  setState(() {
    _isEmmaSuggesting = true;
  });

  try {
    final result = await formNotifier.requestEmmaSplitSuggestions(
      ref,
      targetModel: targetModel,
      focusColumns: const <String>[],
      maxRules: 30,
      selectedRowsOnly: false,
    );

    if (!mounted) return;

    if (result['ok'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['error']?.toString() ?? 'Emma nie zwróciła propozycji.'.tr,
          ),
        ),
      );
      return;
    }

    await _showEmmaSplitPlanSheet(
      theme: theme,
      formNotifier: formNotifier,
      result: result,
    );
  } finally {
    if (mounted) {
      setState(() {
        _isEmmaSuggesting = false;
      });
    }
  }
}



Future<void> _showEmmaSplitPlanSheet({
  required ThemeColors theme,
  required ImportFormNotifier formNotifier,
  required Map<String, dynamic> result,
}) async {
  final rulesRaw = result['rules'];
  final rules = rulesRaw is List ? rulesRaw : <dynamic>[];

  final hintsRaw = result['mapping_hints'];
  final mappingHints = hintsRaw is List ? hintsRaw : <dynamic>[];

  final warningsRaw = result['warnings'];
  final warnings = warningsRaw is List ? warningsRaw : <dynamic>[];

  final summary = result['summary']?.toString() ??
      'Emma przygotowała propozycję podziału danych.';

  final prettyRaw = const JsonEncoder.withIndent('  ').convert(result);


  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return FractionallySizedBox(
        heightFactor: 0.88,
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
                            'Propozycja Emmy'.tr,
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
              Divider(height: 1, color: theme.dashboardBoarder.withAlpha(120)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _EmmaPlanSection(
                      theme: theme,
                      title: 'Reguły podziału'.tr,
                      emptyText: 'Brak reguł do zastosowania.'.tr,
                      items: rules,
                      itemBuilder: (item) {
                        final map = item is Map
                            ? Map<String, dynamic>.from(item)
                            : <String, dynamic>{};

                        final source = map['source_column']?.toString() ?? '-';
                        final output = map['output_column']?.toString() ?? '-';
                        final transform = map['transform']?.toString() ?? '-';
                        final reason = map['reason']?.toString() ?? '';

                        return _EmmaPlanCard(
                          theme: theme,
                          title: '$source → $output',
                          subtitle: 'Transformacja: $transform',
                          description: reason,
                          icon: Icons.functions_rounded,
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _EmmaPlanSection(
                      theme: theme,
                      title: 'Sugestie mapowania'.tr,
                      emptyText: 'Brak sugestii mapowania.'.tr,
                      items: mappingHints,
                      itemBuilder: (item) {
                        final map = item is Map
                            ? Map<String, dynamic>.from(item)
                            : <String, dynamic>{};

                        final output = map['output_column']?.toString() ?? '-';
                        final targetModel =
                            map['target_model']?.toString() ?? '-';
                        final targetField =
                            map['target_field']?.toString() ?? '-';
                        final reason = map['reason']?.toString() ?? '';

                        return _EmmaPlanCard(
                          theme: theme,
                          title: '$output → $targetModel.$targetField',
                          subtitle: 'Mapowanie pola',
                          description: reason,
                          icon: Icons.link_rounded,
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    if (warnings.isNotEmpty)
                      _EmmaPlanSection(
                        theme: theme,
                        title: 'Ostrzeżenia'.tr,
                        emptyText: '',
                        items: warnings,
                        itemBuilder: (item) {
                          return _EmmaPlanCard(
                            theme: theme,
                            title: 'Uwaga'.tr,
                            subtitle: item.toString(),
                            description: '',
                            icon: Icons.warning_amber_rounded,
                            accentColor: Colors.orangeAccent,
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                    _EmmaPlanSection(
                      theme: theme,
                      title: 'Debug response'.tr,
                      emptyText: '',
                      items: [prettyRaw],
                      itemBuilder: (item) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.dashboardBoarder.withAlpha(90),
                            ),
                          ),
                          child: SelectableText(
                            item.toString(),
                            style: TextStyle(
                              color: theme.textColor.withAlpha(210),
                              fontSize: 10,
                              height: 1.35,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
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
                        onPressed: rules.isEmpty && mappingHints.isEmpty
                            ? null
                            : () async {
                                final applyRulesResult = rules.isEmpty
                                    ? {'applied_count': 0, 'skipped_count': 0}
                                    : await formNotifier.applyEmmaTransformRules(
                                        rules,
                                        clearExisting: false,
                                        replaceSameOutputColumn: true,
                                      );

                                final applyMappingResult = mappingHints.isEmpty
                                    ? {'applied_count': 0, 'skipped_count': 0}
                                    : await formNotifier.applyEmmaMappingHints(
                                        mappingHints,
                                        replaceExistingForTargetField: true,
                                        minConfidence: 0.70,
                                      );

                                if (!ctx.mounted) return;

                                Navigator.of(ctx).pop();

                                final appliedRules = applyRulesResult['applied_count']?.toString() ?? '0';
                                final appliedMappings = applyMappingResult['applied_count']?.toString() ?? '0';

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Emma zastosowała reguły: $appliedRules, mapowania: $appliedMappings.'.tr,
                                    ),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.check_rounded),
                        label: Text('Zastosuj podział'.tr),
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



  Future<void> _openEmmaDatasetProfileSheet({
    required ThemeColors theme,
    required ImportFormNotifier formNotifier,
  }) async {
    final profile = formNotifier.buildEmmaDatasetProfile(
      maxRows: 30,
      maxSamplesPerColumn: 12,
      selectedRowsOnly: false,
    );

    final prettyJson = const JsonEncoder.withIndent('  ').convert(profile);

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
              border: Border.all(
                color: theme.dashboardBoarder.withAlpha(120),
              ),
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
                              'Profil danych dla Emmy'.tr,
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Ten JSON frontend przekazuje Emmie jako kontekst aktualnego importu.'
                                  .tr,
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
                        icon: Icon(
                          Icons.close_rounded,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: theme.dashboardBoarder.withAlpha(120),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.dashboardBoarder.withAlpha(110),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          prettyJson,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(220),
                            fontSize: 11,
                            height: 1.35,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        OutlinedButton.icon(
                          style: _outlinedActionStyle(theme),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: prettyJson),
                            );

                            if (!ctx.mounted) return;

                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Skopiowano profil danych.'.tr),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.copy_rounded,
                            color: theme.textColor,
                            size: 16,
                          ),
                          label: Text(
                            'Kopiuj JSON'.tr,
                            style: TextStyle(color: theme.textColor),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          style: _filledActionStyle(theme),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text('Zamknij'.tr),
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

  Future<void> _openApplyEmmaRulesSheet({
    required ThemeColors theme,
    required ImportFormNotifier formNotifier,
  }) async {
    final controller = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.82,
          child: Container(
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(
                color: theme.dashboardBoarder.withAlpha(120),
              ),
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
                          Icons.functions_rounded,
                          color: theme.themeColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Wklej reguły Emmy'.tr,
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Wklej listę rules albo obiekt z polem rules z narzędzia importer_suggest_data_split.'
                                  .tr,
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
                        icon: Icon(
                          Icons.close_rounded,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: theme.dashboardBoarder.withAlpha(120),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: controller,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      keyboardType: TextInputType.multiline,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        height: 1.35,
                      ),
                      decoration: _inputDecoration(
                        theme: theme,
                        label: 'JSON rules'.tr,
                      ).copyWith(
                        alignLabelWithHint: true,
                        hintText: '''
{
  "rules": [
    {
      "source_column": "Kontakt",
      "output_column": "email",
      "transform": "regex",
      "regex_pattern": "[A-Za-z0-9._%+\\\\-]+@[A-Za-z0-9.\\\\-]+\\\\.[A-Za-z]{2,}",
      "regex_group": 0,
      "skip_if_no_match": true
    }
  ]
}
'''
                            .trim(),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        OutlinedButton.icon(
                          style: _outlinedActionStyle(theme),
                          onPressed: () => controller.clear(),
                          icon: Icon(
                            Icons.clear_rounded,
                            color: theme.textColor,
                            size: 16,
                          ),
                          label: Text(
                            'Wyczyść'.tr,
                            style: TextStyle(color: theme.textColor),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          style: _filledActionStyle(theme),
                          onPressed: () async {
                            final raw = controller.text.trim();

                            if (raw.isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text('Wklej JSON z regułami.'.tr),
                                ),
                              );
                              return;
                            }

                            try {
                              final decoded = jsonDecode(raw);
                              final rules = _extractEmmaRules(decoded);

                              final result =
                                  await formNotifier.applyEmmaTransformRules(
                                rules,
                                clearExisting: false,
                                replaceSameOutputColumn: true,
                              );

                              if (!ctx.mounted) return;

                              Navigator.of(ctx).pop();

                              final applied = result['applied_count'] ?? 0;
                              final skipped = result['skipped_count'] ?? 0;

                              _showSnack(
                                'Zastosowano reguły Emmy: $applied, pominięto: $skipped.',
                              );
                            } catch (e) {
                              if (!ctx.mounted) return;

                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Nie udało się zastosować reguł: $e',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_rounded),
                          label: Text('Zastosuj reguły'.tr),
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
    ).whenComplete(controller.dispose);
  }

  List<dynamic> _extractEmmaRules(dynamic decoded) {
    if (decoded is List) {
      return decoded;
    }

    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);

      final rawRules = map['rules'] ??
          map['transform_rules'] ??
          map['transformRules'] ??
          map['data'];

      if (rawRules is List) {
        return rawRules;
      }

      if (map.containsKey('source_column') ||
          map.containsKey('sourceColumn') ||
          map.containsKey('output_column') ||
          map.containsKey('outputColumn')) {
        return [map];
      }
    }

    throw const FormatException(
      'JSON musi być listą reguł albo obiektem z polem rules.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final optionsAsync = widget.optionsAsync;
    final formState = widget.formState;
    final formNotifier = widget.formNotifier;
    final leftPanelWidth = widget.isTablet ? 200.0: 300.0;
    final rightPanelWidth = widget.isTablet ? 240.0 : 300.0;

    return optionsAsync.when(
      data: (options) {
        final targetModelKeys = options.targetModels.keys.toList()..sort();
        final selectedModel = formState.selectedTargetModel;

        if (formState.file == null) {
          return Center(
            child: Text(
              'Najpierw wybierz plik do importu w kroku 1.'.tr,
              style: TextStyle(
                color: theme.textColor.withAlpha(178),
              ),
            ),
          );
        }

        if (formState.previewColumns.isEmpty) {
          return Center(
            child: Text(
              'Edytor wymaga podglądu danych (obsługiwany dla plików CSV).'.tr,
              style: TextStyle(
                color: theme.textColor.withAlpha(178),
              ),
            ),
          );
        }

        final allColumns = formState.previewColumns;
        final allRows = formState.previewData;
        final selectedRowIndexes = formState.selectedRowIndexes.toSet();

        final filteredColumns = allColumns.where((column) {
          final query = _columnSearch.trim().toLowerCase();

          final matchesSearch =
              query.isEmpty || column.toLowerCase().contains(query);

          if (!matchesSearch) return false;

          if (_showOnlyMappedColumns && !_isColumnMapped(formState, column)) {
            return false;
          }

          if (_showOnlyTransformedColumns && !_hasTransforms(formState, column)) {
            return false;
          }

          if (_showOnlyColumnsWithValues &&
              _emptyCountForColumn(
                    previewColumns: allColumns,
                    previewData: allRows,
                    columnName: column,
                  ) >=
                  allRows.length) {
            return false;
          }

          return true;
        }).toList(growable: false);

        final effectiveSelectedColumn = _resolveSelectedColumn(
          currentSelected: _selectedColumn,
          filteredColumns: filteredColumns,
          allColumns: allColumns,
        );

        final filteredRowIndexes = <int>[];
        final valueQuery = _valueSearch.trim().toLowerCase();

        for (var rowIndex = 0; rowIndex < allRows.length; rowIndex++) {
          final row = allRows[rowIndex];

          if (_showOnlySelectedRows && !selectedRowIndexes.contains(rowIndex)) {
            continue;
          }

          if (valueQuery.isNotEmpty) {
            var matched = false;

            for (final column in filteredColumns) {
              final colIndex = allColumns.indexOf(column);
              if (colIndex == -1) continue;

              final value = colIndex < row.length ? row[colIndex] : '';
              if (value.toLowerCase().contains(valueQuery)) {
                matched = true;
                break;
              }
            }

            if (!matched) continue;
          }

          filteredRowIndexes.add(rowIndex);
        }

        final totalRows = filteredRowIndexes.length;
        final pageSize = formState.pageSize;
        final totalPages =
            totalRows == 0 ? 1 : ((totalRows - 1) ~/ pageSize) + 1;
        final currentPage =
            math.min(formState.currentPage, math.max(0, totalPages - 1));
        final start = currentPage * pageSize;
        final end = math.min(start + pageSize, totalRows);

        final pageRowIndexes = (totalRows == 0 || start >= totalRows)
            ? <int>[]
            : filteredRowIndexes.sublist(start, end);

        final pageRows = pageRowIndexes
            .map((rowIndex) => allRows[rowIndex])
            .toList(growable: false);

        final filteredPagedRows = pageRows
            .map(
              (row) => filteredColumns.map((column) {
                final originalIndex = allColumns.indexOf(column);

                if (originalIndex == -1 || originalIndex >= row.length) {
                  return '';
                }

                return row[originalIndex];
              }).toList(growable: false),
            )
            .toList(growable: false);

        final pagedFormState = formState.copyWith(
          previewColumns: filteredColumns,
          previewData: filteredPagedRows,
        );

        final mappedCols = filteredColumns.where((col) {
          return formState.fieldMappings.any((m) => m.columnName == col);
        }).length;

        final selectedVisibleCount = filteredRowIndexes
            .where((rowIndex) => selectedRowIndexes.contains(rowIndex))
            .length;

        final selectedOnPageCount = pageRowIndexes
            .where((rowIndex) => selectedRowIndexes.contains(rowIndex))
            .length;
        
        _emitPaginationState(
            totalRows: totalRows,
            currentPage: currentPage,
            totalPages: totalPages,
            pageSize: pageSize,
          );

        return EmmaUiAnchorTarget(
          anchorKey: 'importer.editor.root',
          child: Stack(
            children: [
               Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EmmaUiAnchorTarget(
                        anchorKey: 'importer.editor.toolbar',
                        child: _EditorTopToolbar(
                          isEmmaSuggesting: _isEmmaSuggesting,
                          onSuggestSplitWithEmma: () {
                            _suggestSplitWithEmmaApi(
                              theme: theme,
                              formState: formState,
                              formNotifier: formNotifier,
                              selectedColumn: null,
                            );
                          },

                          isColumnsPanelOpen: _isColumnsPanelOpen,
                          isInspectorPanelOpen: _isInspectorPanelOpen,
                          onToggleColumnsPanel: (value) {
                            setState(() {
                              _isColumnsPanelOpen = value;
                            });
                          },
                          onToggleInspectorPanel: (value) {
                            setState(() {
                              _isInspectorPanelOpen = value;
                            });
                          },



                          theme: theme,
                          totalColumns: formState.previewColumns.length,
                          visibleColumns: filteredColumns.length,
                          mappedColumns: mappedCols,
                          totalVisibleRows: filteredRowIndexes.length,
                          selectedRowsCount: formState.selectedRowIndexes.length,
                          selectedVisibleRowsCount: selectedVisibleCount,
                          selectedModel: selectedModel,
                          targetModelKeys: targetModelKeys,
                          showOnlyMappedColumns: _showOnlyMappedColumns,
                          showOnlyTransformedColumns:
                              _showOnlyTransformedColumns,
                          showOnlyColumnsWithValues:
                              _showOnlyColumnsWithValues,
                          showOnlySelectedRows: _showOnlySelectedRows,
                          onColumnSearchChanged: (value) {
                            setState(() {
                              _columnSearch = value;
                            });
                          },
                          onValueSearchChanged: (value) {
                            setState(() {
                              _valueSearch = value;
                            });
                          },
                          onToggleMapped: (value) {
                            setState(() {
                              _showOnlyMappedColumns = value;
                            });
                          },
                          onToggleTransformed: (value) {
                            setState(() {
                              _showOnlyTransformedColumns = value;
                            });
                          },
                          onToggleWithValues: (value) {
                            setState(() {
                              _showOnlyColumnsWithValues = value;
                            });
                          },
                          onToggleOnlySelectedRows: (value) {
                            setState(() {
                              _showOnlySelectedRows = value;
                            });
                          },
                          onSelectedModelChanged: formNotifier.setTargetModel,
                          onSelectAllRows: formNotifier.selectAllRows,
                          onClearAllRows: formNotifier.clearSelectedRows,
                          onSelectVisibleRows: () {
                            formNotifier.selectAllRows(filteredRowIndexes);
                          },
                          onClearVisibleRows: () {
                            formNotifier.clearSelectedRows(filteredRowIndexes);
                          },
                          onCopyEmmaPrompt: () {
                            _copyEmmaPromptToClipboard(formState);
                          },
                          onOpenEmmaDatasetProfile: () {
                            _openEmmaDatasetProfileSheet(
                              theme: theme,
                              formNotifier: formNotifier,
                            );
                          },
                          onApplyEmmaRules: () {
                            _openApplyEmmaRulesSheet(
                              theme: theme,
                              formNotifier: formNotifier,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),

                      Expanded(
                        child: _isCompact
                            ? Column(
                                children: [
                                  if (_isColumnsPanelOpen) ...[
                                    SizedBox(
                                      height: 210,
                                      child: EmmaUiAnchorTarget(
                                        anchorKey: 'importer.editor.columns_panel',
                                        child: _EditorColumnsPanel(
                                          theme: theme,
                                          formState: formState,
                                          filteredColumns: filteredColumns,
                                          selectedColumn: effectiveSelectedColumn,
                                          onSelectColumn: (column) {
                                            setState(() {
                                              _selectedColumn = column;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  Expanded(
                                    child: EmmaUiAnchorTarget(
                                      anchorKey: 'importer.editor.grid_panel',
                                      child: _EditorGridPanel(
                                        theme: theme,
                                        formState: formState,
                                        pagedFormState: pagedFormState,
                                        options: options,
                                        formNotifier: formNotifier,
                                        selectionSamples: selectionSamples,
                                        stripFromSource:
                                            selectionOutputMode != OutputMode.replaceSource &&
                                                (stripSourceValue || stripSourceKey),
                                        highlightAllMatches: highlightAllMatches,
                                        regex: selectionRegex,
                                        stripSourceValue: stripSourceValue,
                                        stripSourceKey: stripSourceKey,
                                        selectionKey: selectionKey,
                                        stripLeadingSeparator: stripLeadingSeparator,
                                        stripTrailingSeparator: stripTrailingSeparator,
                                        onSelection: handleCellSelection,
                                        selectedTotalCount: formState.selectedRowIndexes.length,
                                        pageRowIndexes: pageRowIndexes,
                                        selectedOnPageCount: selectedOnPageCount,
                                        isRowSelected: formNotifier.isRowSelected,
                                        onToggleRowSelection: (rowIndex) {
                                          formNotifier.toggleRowSelection(rowIndex);
                                        },
                                        onSelectAllOnPage: () {
                                          formNotifier.selectAllRows(pageRowIndexes);
                                        },
                                        onClearAllOnPage: () {
                                          formNotifier.clearSelectedRows(pageRowIndexes);
                                        },
                                        onPageSizeChanged: (value) {
                                          formNotifier.setPageSize(value);
                                        },
                                        onPreviousPage: currentPage > 0
                                            ? () {
                                                formNotifier.setPage(currentPage - 1);
                                              }
                                            : null,
                                        onNextPage: currentPage < totalPages - 1
                                            ? () {
                                                formNotifier.setPage(currentPage + 1);
                                              }
                                            : null,
                                        totalRows: totalRows,
                                        currentPage: currentPage,
                                        totalPages: totalPages,
                                        pageSize: pageSize,
                                      ),
                                    ),
                                  ),
                                  if (_isInspectorPanelOpen) ...[
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 250,
                                      child: EmmaUiAnchorTarget(
                                        anchorKey: 'importer.editor.inspector_panel',
                                        child: _EditorInspectorPanel(
                                          theme: theme,
                                          options: options,
                                          formState: formState,
                                          formNotifier: formNotifier,
                                          selectedColumn: effectiveSelectedColumn,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_isColumnsPanelOpen) ...[
                                    SizedBox(
                                      width: 300,
                                      child: EmmaUiAnchorTarget(
                                        anchorKey: 'importer.editor.columns_panel',
                                        child: _EditorColumnsPanel(
                                          theme: theme,
                                          formState: formState,
                                          filteredColumns: filteredColumns,
                                          selectedColumn: effectiveSelectedColumn,
                                          onSelectColumn: (column) {
                                            setState(() {
                                              _selectedColumn = column;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  Expanded(
                                    child: EmmaUiAnchorTarget(
                                      anchorKey: 'importer.editor.grid_panel',
                                      child: _EditorGridPanel(
                                        
                                        theme: theme,
                                        formState: formState,
                                        pagedFormState: pagedFormState,
                                        options: options,
                                        formNotifier: formNotifier,
                                        selectionSamples: selectionSamples,
                                        stripFromSource:
                                            selectionOutputMode != OutputMode.replaceSource &&
                                                (stripSourceValue || stripSourceKey),
                                        highlightAllMatches: highlightAllMatches,
                                        regex: selectionRegex,
                                        stripSourceValue: stripSourceValue,
                                        stripSourceKey: stripSourceKey,
                                        selectionKey: selectionKey,
                                        stripLeadingSeparator: stripLeadingSeparator,
                                        stripTrailingSeparator: stripTrailingSeparator,
                                        onSelection: handleCellSelection,
                                        selectedTotalCount: formState.selectedRowIndexes.length,
                                        pageRowIndexes: pageRowIndexes,
                                        selectedOnPageCount: selectedOnPageCount,
                                        isRowSelected: formNotifier.isRowSelected,
                                        onToggleRowSelection: (rowIndex) {
                                          formNotifier.toggleRowSelection(rowIndex);
                                        },
                                        onSelectAllOnPage: () {
                                          formNotifier.selectAllRows(pageRowIndexes);
                                        },
                                        onClearAllOnPage: () {
                                          formNotifier.clearSelectedRows(pageRowIndexes);
                                        },
                                        onPageSizeChanged: (value) {
                                          formNotifier.setPageSize(value);
                                        },
                                        onPreviousPage: currentPage > 0
                                            ? () {
                                                formNotifier.setPage(currentPage - 1);
                                              }
                                            : null,
                                        onNextPage: currentPage < totalPages - 1
                                            ? () {
                                                formNotifier.setPage(currentPage + 1);
                                              }
                                            : null,
                                        totalRows: totalRows,
                                        currentPage: currentPage,
                                        totalPages: totalPages,
                                        pageSize: pageSize,
                                        isTablet: widget.isTablet,
                                      ),
                                    ),
                                  ),
                                  if (_isInspectorPanelOpen) ...[
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      width: 300,
                                      child: EmmaUiAnchorTarget(
                                        anchorKey: 'importer.editor.inspector_panel',
                                        child: _EditorInspectorPanel(
                                          theme: theme,
                                          options: options,
                                          formState: formState,
                                          formNotifier: formNotifier,
                                          selectedColumn: effectiveSelectedColumn,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ],
                  
              ),
              buildSelectionOverlay(context, theme),
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

  String? _resolveSelectedColumn({
    required String? currentSelected,
    required List<String> filteredColumns,
    required List<String> allColumns,
  }) {
    if (currentSelected != null && filteredColumns.contains(currentSelected)) {
      return currentSelected;
    }

    if (filteredColumns.isNotEmpty) {
      return filteredColumns.first;
    }

    if (allColumns.isNotEmpty) {
      return allColumns.first;
    }

    return null;
  }
}













const double _editorToolbarControlHeight = 40.0;
const double _editorToolbarOneLineHeight = 50.0;
const double _editorToolbarIconButtonWidth = 36.0;
const double _editorToolbarRadius = 12.0;

class _EditorTopToolbar extends StatelessWidget {
  final ThemeColors theme;
  final int totalColumns;
  final int visibleColumns;
  final int mappedColumns;
  final int totalVisibleRows;
  final int selectedRowsCount;
  final int selectedVisibleRowsCount;
  final String? selectedModel;
  final List<String> targetModelKeys;
  final bool showOnlyMappedColumns;
  final bool showOnlyTransformedColumns;
  final bool showOnlyColumnsWithValues;
  final bool showOnlySelectedRows;
  final ValueChanged<String> onColumnSearchChanged;
  final ValueChanged<String> onValueSearchChanged;
  final ValueChanged<bool> onToggleMapped;
  final ValueChanged<bool> onToggleTransformed;
  final ValueChanged<bool> onToggleWithValues;
  final ValueChanged<bool> onToggleOnlySelectedRows;
  final ValueChanged<String?> onSelectedModelChanged;
  final VoidCallback onSelectAllRows;
  final VoidCallback onClearAllRows;
  final VoidCallback onSelectVisibleRows;
  final VoidCallback onClearVisibleRows;
  final VoidCallback onCopyEmmaPrompt;
  final VoidCallback onOpenEmmaDatasetProfile;
  final VoidCallback onApplyEmmaRules;
  final bool isEmmaSuggesting;
  final VoidCallback onSuggestSplitWithEmma;

  final bool isColumnsPanelOpen;
  final bool isInspectorPanelOpen;
  final ValueChanged<bool> onToggleColumnsPanel;
  final ValueChanged<bool> onToggleInspectorPanel;

  const _EditorTopToolbar({
    required this.isEmmaSuggesting,
    required this.onSuggestSplitWithEmma,
    required this.theme,
    required this.totalColumns,
    required this.visibleColumns,
    required this.mappedColumns,
    required this.totalVisibleRows,
    required this.selectedRowsCount,
    required this.selectedVisibleRowsCount,
    required this.selectedModel,
    required this.targetModelKeys,
    required this.showOnlyMappedColumns,
    required this.showOnlyTransformedColumns,
    required this.showOnlyColumnsWithValues,
    required this.showOnlySelectedRows,
    required this.onColumnSearchChanged,
    required this.onValueSearchChanged,
    required this.onToggleMapped,
    required this.onToggleTransformed,
    required this.onToggleWithValues,
    required this.onToggleOnlySelectedRows,
    required this.onSelectedModelChanged,
    required this.onSelectAllRows,
    required this.onClearAllRows,
    required this.onSelectVisibleRows,
    required this.onClearVisibleRows,
    required this.onCopyEmmaPrompt,
    required this.onOpenEmmaDatasetProfile,
    required this.onApplyEmmaRules,
    required this.isColumnsPanelOpen,
    required this.isInspectorPanelOpen,
    required this.onToggleColumnsPanel,
    required this.onToggleInspectorPanel,
  });

  int get _activeFiltersCount {
    return [
      showOnlyMappedColumns,
      showOnlyTransformedColumns,
      showOnlyColumnsWithValues,
      showOnlySelectedRows,
    ].where((v) => v).length;
  }

  @override
  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final oneLine = constraints.maxWidth >= 1100;

        final toolbarChildren = <Widget>[
          Row(
            spacing: 6,
            children: [
              
          EmmaUiAnchorTarget(
            anchorKey: 'importer.editor.emma_panel',
            child: _EditorToolbarPrimaryButton(
              theme: theme,
              isLoading: isEmmaSuggesting,
              onPressed: isEmmaSuggesting ? null : onSuggestSplitWithEmma,
            ),
          ),
          _EditorToolbarSearchField(
            theme: theme,
            width: oneLine ? 165 : 220,
            icon: Icons.view_column_rounded,
            hint: 'Kolumny'.tr,
            onChanged: onColumnSearchChanged,
            anchorKey: 'importer.editor.column_search',
          ),
          _EditorToolbarSearchField(
            theme: theme,
            width: oneLine ? 190 : 240,
            icon: Icons.search_rounded,
            hint: 'Szukaj danych'.tr,
            onChanged: onValueSearchChanged,
            anchorKey: 'importer.editor.value_search',
          ),
          _EditorToolbarModelSelect(
            theme: theme,
            width: oneLine ? 210 : 260,
            selectedModel: selectedModel,
            targetModelKeys: targetModelKeys,
            onChanged: onSelectedModelChanged,
          ),
            ],
          ),
          _EditorToolbarStatsStrip(
            theme: theme,
            visibleColumns: visibleColumns,
            totalColumns: totalColumns,
            mappedColumns: mappedColumns,
            totalVisibleRows: totalVisibleRows,
            selectedRowsCount: selectedRowsCount,
            selectedVisibleRowsCount: selectedVisibleRowsCount,
          ),

          Row(
            spacing: 6,
            children: [
              
          _EditorPanelsMenu(
            theme: theme,
            isColumnsPanelOpen: isColumnsPanelOpen,
            isInspectorPanelOpen: isInspectorPanelOpen,
            onToggleColumnsPanel: onToggleColumnsPanel,
            onToggleInspectorPanel: onToggleInspectorPanel,
          ),
          _EditorToolbarFiltersMenu(
            theme: theme,
            activeCount: _activeFiltersCount,
            showOnlyMappedColumns: showOnlyMappedColumns,
            showOnlyTransformedColumns: showOnlyTransformedColumns,
            showOnlyColumnsWithValues: showOnlyColumnsWithValues,
            showOnlySelectedRows: showOnlySelectedRows,
            onToggleMapped: onToggleMapped,
            onToggleTransformed: onToggleTransformed,
            onToggleWithValues: onToggleWithValues,
            onToggleOnlySelectedRows: onToggleOnlySelectedRows,
          ),
          EmmaUiAnchorTarget(
            anchorKey: 'importer.editor.selection_actions',
            child: _EditorToolbarSelectionMenu(
              theme: theme,
              onSelectAllRows: onSelectAllRows,
              onClearAllRows: onClearAllRows,
              onSelectVisibleRows: onSelectVisibleRows,
              onClearVisibleRows: onClearVisibleRows,
            ),
          ),
          _EditorToolbarMoreMenu(
            theme: theme,
            onCopyEmmaPrompt: onCopyEmmaPrompt,
            onOpenEmmaDatasetProfile: onOpenEmmaDatasetProfile,
            onApplyEmmaRules: onApplyEmmaRules,
          ),
          
            ],
          )
        ];

        return SizedBox(
          width: double.infinity,
          child: Container(
            width: double.infinity,
            height: oneLine ? _editorToolbarOneLineHeight : null,
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: oneLine ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: theme.adPopBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.dashboardBoarder.withAlpha(90),
              ),
            ),
            child: oneLine
                ? SizedBox(
                    height: _editorToolbarControlHeight,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: math.max(0, constraints.maxWidth - 16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            for (var i = 0;
                                i < toolbarChildren.length;
                                i++) ...[
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
                  ),
          ),
        );
      },
    );
  }
}

class _EditorPanelsMenu extends StatelessWidget {
  final ThemeColors theme;
  final bool isColumnsPanelOpen;
  final bool isInspectorPanelOpen;
  final ValueChanged<bool> onToggleColumnsPanel;
  final ValueChanged<bool> onToggleInspectorPanel;

  const _EditorPanelsMenu({
    required this.theme,
    required this.isColumnsPanelOpen,
    required this.isInspectorPanelOpen,
    required this.onToggleColumnsPanel,
    required this.onToggleInspectorPanel,
  });

  int get _hiddenCount {
    var count = 0;
    if (!isColumnsPanelOpen) count++;
    if (!isInspectorPanelOpen) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final hiddenCount = _hiddenCount;
    final active = hiddenCount > 0;

    return PopupMenuButton<String>(
      tooltip: 'Widoczność paneli'.tr,
      color: theme.dashboardContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) {
        switch (value) {
          case 'toggle_columns':
            onToggleColumnsPanel(!isColumnsPanelOpen);
            break;
          case 'toggle_inspector':
            onToggleInspectorPanel(!isInspectorPanelOpen);
            break;
          case 'open_all':
            onToggleColumnsPanel(true);
            onToggleInspectorPanel(true);
            break;
          case 'close_all':
            onToggleColumnsPanel(false);
            onToggleInspectorPanel(false);
            break;
        }
      },
      itemBuilder: (context) => [
        _panelMenuItem(
          theme: theme,
          value: 'toggle_columns',
          selected: isColumnsPanelOpen,
          icon: Icons.view_column_rounded,
          label: 'Panel kolumn'.tr,
        ),
        _panelMenuItem(
          theme: theme,
          value: 'toggle_inspector',
          selected: isInspectorPanelOpen,
          icon: Icons.manage_search_rounded,
          label: 'Inspector'.tr,
        ),
        const PopupMenuDivider(),
        _toolbarMenuItem(
          theme: theme,
          value: 'open_all',
          icon: Icons.open_in_full_rounded,
          label: 'Pokaż oba panele'.tr,
        ),
        _toolbarMenuItem(
          theme: theme,
          value: 'close_all',
          icon: Icons.close_fullscreen_rounded,
          label: 'Ukryj oba panele'.tr,
        ),
      ],
      child: _EditorToolbarPillButton(
        theme: theme,
        icon: Icons.dashboard_customize_rounded,
        label: 'Panele'.tr,
        badge: hiddenCount > 0 ? '-$hiddenCount' : null,
        active: active,
      ),
    );
  }

  PopupMenuItem<String> _panelMenuItem({
    required ThemeColors theme,
    required String value,
    required bool selected,
    required IconData icon,
    required String label,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: _editorToolbarControlHeight,
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_circle_rounded : icon,
            size: 16,
            color: selected ? theme.themeColor : theme.textColor.withAlpha(185),
          ),
          const SizedBox(width: 9),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            selected ? 'Widoczny'.tr : 'Ukryty'.tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(135),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorToolbarPrimaryButton extends StatelessWidget {
  final ThemeColors theme;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _EditorToolbarPrimaryButton({
    required this.theme,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _editorToolbarControlHeight,
      child: ElevatedButton.icon(
        style: _editorToolbarFilledStyle(theme),
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(
                Icons.auto_awesome_rounded,
                size: 15,
              ),
        label: Text(
          isLoading ? 'Analizuje...'.tr : 'Emma'.tr,
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

class _EditorToolbarSearchField extends StatelessWidget {
  final ThemeColors theme;
  final double width;
  final IconData icon;
  final String hint;
  final ValueChanged<String> onChanged;
  final String anchorKey;

  const _EditorToolbarSearchField({
    required this.theme,
    required this.width,
    required this.icon,
    required this.hint,
    required this.onChanged,
    required this.anchorKey,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: _editorToolbarControlHeight,
      child: EmmaUiAnchorTarget(
        anchorKey: anchorKey,
        child: TextField(
          onChanged: onChanged,
          textAlignVertical: TextAlignVertical.center,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 11.5,
            height: 1.0,
          ),
          decoration: _editorToolbarInputDecoration(
            theme: theme,
            hint: hint,
            icon: icon,
          ),
        ),
      ),
    );
  }
}

class _EditorToolbarModelSelect extends StatelessWidget {
  final ThemeColors theme;
  final double width;
  final String? selectedModel;
  final List<String> targetModelKeys;
  final ValueChanged<String?> onChanged;

  const _EditorToolbarModelSelect({
    required this.theme,
    required this.width,
    required this.selectedModel,
    required this.targetModelKeys,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: _editorToolbarControlHeight,
      child: EmmaUiAnchorTarget(
        anchorKey: 'importer.editor.target_model_select',
        child: DropdownButtonFormField<String>(
          value: selectedModel,
          dropdownColor: theme.dashboardContainer,
          isDense: true,
          iconSize: 18,
          iconEnabledColor: theme.textColor.withAlpha(145),
          iconDisabledColor: theme.textColor.withAlpha(80),

          hint: Text(
            'Model'.tr,
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

          decoration: _editorToolbarInputDecoration(
            theme: theme,
            hint: '', // ważne: nie używamy hintText tutaj
            icon: Icons.account_tree_rounded,
          ).copyWith(
            hintText: null,
            hintStyle: null,
          ),

          selectedItemBuilder: (context) {
            return targetModelKeys.map((m) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  m,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 11.5,
                    height: 1.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList();
          },

          items: targetModelKeys
              .map(
                (m) => DropdownMenuItem(
                  value: m,
                  child: Text(
                    m,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 11.5,
                      height: 1.0,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _EditorToolbarStatsStrip extends StatelessWidget {
  final ThemeColors theme;
  final int visibleColumns;
  final int totalColumns;
  final int mappedColumns;
  final int totalVisibleRows;
  final int selectedRowsCount;
  final int selectedVisibleRowsCount;

  const _EditorToolbarStatsStrip({
    required this.theme,
    required this.visibleColumns,
    required this.totalColumns,
    required this.mappedColumns,
    required this.totalVisibleRows,
    required this.selectedRowsCount,
    required this.selectedVisibleRowsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _editorToolbarControlHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: theme.dashboardContainer.withAlpha(165),
        borderRadius: BorderRadius.circular(_editorToolbarRadius),
        border: Border.all(
          color: theme.dashboardBoarder.withAlpha(85),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _EditorToolbarStatText(
            theme: theme,
            label: 'Kolumny'.tr,
            value: '$visibleColumns/$totalColumns',
            icon: Icons.table_chart_outlined,
          ),
          _EditorToolbarMiniDivider(theme: theme),
          _EditorToolbarStatText(
            theme: theme,
            label: 'Mapowania'.tr,
            value: '$mappedColumns',
            icon: Icons.link_rounded,
            accent: mappedColumns > 0,
          ),
          _EditorToolbarMiniDivider(theme: theme),
          _EditorToolbarStatText(
            theme: theme,
            label: 'Wiersze'.tr,
            value: '$totalVisibleRows',
            icon: Icons.dataset_linked_outlined,
          ),
          _EditorToolbarMiniDivider(theme: theme),
          _EditorToolbarStatText(
            theme: theme,
            label: 'Zaznaczone'.tr,
            value: '$selectedRowsCount',
            icon: Icons.check_circle_rounded,
            accent: selectedRowsCount > 0,
          ),
          if (selectedVisibleRowsCount != selectedRowsCount) ...[
            const SizedBox(width: 5),
            Tooltip(
              message: 'Zaznaczone z aktualnie widocznych'.tr,
              child: Text(
                '($selectedVisibleRowsCount)',
                style: TextStyle(
                  color: theme.textColor.withAlpha(145),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditorToolbarStatText extends StatelessWidget {
  final ThemeColors theme;
  final String label;
  final String value;
  final IconData icon;
  final bool accent;

  const _EditorToolbarStatText({
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

class _EditorToolbarFiltersMenu extends StatelessWidget {
  final ThemeColors theme;
  final int activeCount;
  final bool showOnlyMappedColumns;
  final bool showOnlyTransformedColumns;
  final bool showOnlyColumnsWithValues;
  final bool showOnlySelectedRows;
  final ValueChanged<bool> onToggleMapped;
  final ValueChanged<bool> onToggleTransformed;
  final ValueChanged<bool> onToggleWithValues;
  final ValueChanged<bool> onToggleOnlySelectedRows;

  const _EditorToolbarFiltersMenu({
    required this.theme,
    required this.activeCount,
    required this.showOnlyMappedColumns,
    required this.showOnlyTransformedColumns,
    required this.showOnlyColumnsWithValues,
    required this.showOnlySelectedRows,
    required this.onToggleMapped,
    required this.onToggleTransformed,
    required this.onToggleWithValues,
    required this.onToggleOnlySelectedRows,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Filtry widoku'.tr,
      color: theme.dashboardContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) {
        switch (value) {
          case 'mapped':
            onToggleMapped(!showOnlyMappedColumns);
            break;
          case 'transformed':
            onToggleTransformed(!showOnlyTransformedColumns);
            break;
          case 'with_values':
            onToggleWithValues(!showOnlyColumnsWithValues);
            break;
          case 'selected_rows':
            onToggleOnlySelectedRows(!showOnlySelectedRows);
            break;
          case 'clear':
            if (showOnlyMappedColumns) onToggleMapped(false);
            if (showOnlyTransformedColumns) onToggleTransformed(false);
            if (showOnlyColumnsWithValues) onToggleWithValues(false);
            if (showOnlySelectedRows) onToggleOnlySelectedRows(false);
            break;
        }
      },
      itemBuilder: (context) => [
        _filterMenuItem(
          theme: theme,
          value: 'mapped',
          selected: showOnlyMappedColumns,
          icon: Icons.link_rounded,
          label: 'Tylko zmapowane'.tr,
        ),
        _filterMenuItem(
          theme: theme,
          value: 'transformed',
          selected: showOnlyTransformedColumns,
          icon: Icons.functions_rounded,
          label: 'Tylko z transformacjami'.tr,
        ),
        _filterMenuItem(
          theme: theme,
          value: 'with_values',
          selected: showOnlyColumnsWithValues,
          icon: Icons.filter_alt_rounded,
          label: 'Tylko z wartościami'.tr,
        ),
        _filterMenuItem(
          theme: theme,
          value: 'selected_rows',
          selected: showOnlySelectedRows,
          icon: Icons.check_circle_rounded,
          label: 'Tylko zaznaczone wiersze'.tr,
        ),
        if (activeCount > 0) const PopupMenuDivider(),
        if (activeCount > 0)
          _toolbarMenuItem(
            theme: theme,
            value: 'clear',
            icon: Icons.clear_all_rounded,
            label: 'Wyczyść filtry'.tr,
          ),
      ],
      child: _EditorToolbarPillButton(
        theme: theme,
        icon: Icons.tune_rounded,
        label: 'Filtry'.tr,
        badge: activeCount > 0 ? '$activeCount' : null,
        active: activeCount > 0,
      ),
    );
  }

  PopupMenuItem<String> _filterMenuItem({
    required ThemeColors theme,
    required String value,
    required bool selected,
    required IconData icon,
    required String label,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: _editorToolbarControlHeight,
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_circle_rounded : icon,
            size: 16,
            color: selected ? theme.themeColor : theme.textColor.withAlpha(185),
          ),
          const SizedBox(width: 9),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorToolbarSelectionMenu extends StatelessWidget {
  final ThemeColors theme;
  final VoidCallback onSelectAllRows;
  final VoidCallback onClearAllRows;
  final VoidCallback onSelectVisibleRows;
  final VoidCallback onClearVisibleRows;

  const _EditorToolbarSelectionMenu({
    required this.theme,
    required this.onSelectAllRows,
    required this.onClearAllRows,
    required this.onSelectVisibleRows,
    required this.onClearVisibleRows,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Akcje zaznaczenia'.tr,
      color: theme.dashboardContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) {
        switch (value) {
          case 'select_all':
            onSelectAllRows();
            break;
          case 'clear_all':
            onClearAllRows();
            break;
          case 'select_visible':
            onSelectVisibleRows();
            break;
          case 'clear_visible':
            onClearVisibleRows();
            break;
        }
      },
      itemBuilder: (context) => [
        _toolbarMenuItem(
          theme: theme,
          value: 'select_all',
          icon: Icons.done_all_rounded,
          label: 'Zaznacz wszystko'.tr,
        ),
        _toolbarMenuItem(
          theme: theme,
          value: 'clear_all',
          icon: Icons.remove_done_rounded,
          label: 'Odznacz wszystko'.tr,
        ),
        _toolbarMenuItem(
          theme: theme,
          value: 'select_visible',
          icon: Icons.visibility_rounded,
          label: 'Zaznacz widoczne'.tr,
        ),
        _toolbarMenuItem(
          theme: theme,
          value: 'clear_visible',
          icon: Icons.visibility_off_rounded,
          label: 'Odznacz widoczne'.tr,
        ),
      ],
      child: _EditorToolbarIconButton(
        theme: theme,
        icon: Icons.checklist_rounded,
        tooltip: 'Zaznaczenie'.tr,
      ),
    );
  }
}

class _EditorToolbarMoreMenu extends StatelessWidget {
  final ThemeColors theme;
  final VoidCallback onCopyEmmaPrompt;
  final VoidCallback onOpenEmmaDatasetProfile;
  final VoidCallback onApplyEmmaRules;

  const _EditorToolbarMoreMenu({
    required this.theme,
    required this.onCopyEmmaPrompt,
    required this.onOpenEmmaDatasetProfile,
    required this.onApplyEmmaRules,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Więcej akcji'.tr,
      color: theme.dashboardContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) {
        switch (value) {
          case 'copy_prompt':
            onCopyEmmaPrompt();
            break;
          case 'dataset_profile':
            onOpenEmmaDatasetProfile();
            break;
          case 'apply_rules':
            onApplyEmmaRules();
            break;
        }
      },
      itemBuilder: (context) => [
        _toolbarMenuItem(
          theme: theme,
          value: 'copy_prompt',
          icon: Icons.content_copy_rounded,
          label: 'Kopiuj prompt Emmy'.tr,
        ),
        _toolbarMenuItem(
          theme: theme,
          value: 'dataset_profile',
          icon: Icons.data_object_rounded,
          label: 'Profil danych'.tr,
        ),
        _toolbarMenuItem(
          theme: theme,
          value: 'apply_rules',
          icon: Icons.functions_rounded,
          label: 'Wklej reguły'.tr,
        ),
      ],
      child: _EditorToolbarIconButton(
        theme: theme,
        icon: Icons.more_horiz_rounded,
        tooltip: 'Więcej akcji'.tr,
      ),
    );
  }
}

class _EditorToolbarPillButton extends StatelessWidget {
  final ThemeColors theme;
  final IconData icon;
  final String label;
  final String? badge;
  final bool active;

  const _EditorToolbarPillButton({
    required this.theme,
    required this.icon,
    required this.label,
    this.badge,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _editorToolbarControlHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: active
            ? theme.themeColor.withAlpha(22)
            : theme.dashboardContainer.withAlpha(190),
        borderRadius: BorderRadius.circular(_editorToolbarRadius),
        border: Border.all(
          color: active
              ? theme.themeColor.withAlpha(130)
              : theme.dashboardBoarder.withAlpha(95),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: active ? theme.themeColor : theme.textColor.withAlpha(170),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: theme.themeColor.withAlpha(40),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  color: theme.themeColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ),
          ],
          const SizedBox(width: 2),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 15,
            color: theme.textColor.withAlpha(130),
          ),
        ],
      ),
    );
  }
}

class _EditorToolbarIconButton extends StatelessWidget {
  final ThemeColors theme;
  final IconData icon;
  final String tooltip;

  const _EditorToolbarIconButton({
    required this.theme,
    required this.icon,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        height: _editorToolbarControlHeight,
        width: _editorToolbarIconButtonWidth,
        decoration: BoxDecoration(
          color: theme.dashboardContainer.withAlpha(190),
          borderRadius: BorderRadius.circular(_editorToolbarRadius),
          border: Border.all(
            color: theme.dashboardBoarder.withAlpha(95),
          ),
        ),
        child: Icon(
          icon,
          size: 17,
          color: theme.textColor.withAlpha(210),
        ),
      ),
    );
  }
}

class _EditorToolbarMiniDivider extends StatelessWidget {
  final ThemeColors theme;

  const _EditorToolbarMiniDivider({
    required this.theme,
  });

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

PopupMenuItem<String> _toolbarMenuItem({
  required ThemeColors theme,
  required String value,
  required IconData icon,
  required String label,
}) {
  return PopupMenuItem<String>(
    value: value,
    height: _editorToolbarControlHeight,
    child: Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.textColor.withAlpha(190),
        ),
        const SizedBox(width: 9),
        Text(
          label,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 12,
            height: 1.0,
          ),
        ),
      ],
    ),
  );
}
InputDecoration _editorToolbarInputDecoration({
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
      height: _editorToolbarControlHeight,
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 0,
    ),
    prefixIcon: Icon(
      icon,
      color: theme.textColor.withAlpha(145),
      size: 15,
    ),
    prefixIconConstraints: const BoxConstraints(
      minWidth: 30,
      minHeight: _editorToolbarControlHeight,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_editorToolbarRadius),
      borderSide: BorderSide(
        color: theme.dashboardBoarder.withAlpha(90),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_editorToolbarRadius),
      borderSide: BorderSide(
        color: theme.dashboardBoarder.withAlpha(90),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_editorToolbarRadius),
      borderSide: BorderSide(
        color: theme.themeColor.withAlpha(155),
      ),
    ),
  );
}

ButtonStyle _editorToolbarFilledStyle(ThemeColors theme) {
  return ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: theme.themeColor,
    minimumSize: const Size(0, _editorToolbarControlHeight),
    maximumSize: const Size(double.infinity, _editorToolbarControlHeight),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 0),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_editorToolbarRadius),
    ),
    elevation: 0,
  );
}















class _EditorColumnsPanel extends StatelessWidget {
  final ThemeColors theme;
  final ImportFormState formState;
  final List<String> filteredColumns;
  final String? selectedColumn;
  final ValueChanged<String> onSelectColumn;

  const _EditorColumnsPanel({
    required this.theme,
    required this.formState,
    required this.filteredColumns,
    required this.selectedColumn,
    required this.onSelectColumn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(110)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _EditorSectionHeader(
            theme: theme,
            title: 'Kolumny'.tr,
            subtitle:
                'Kliknij kolumnę, żeby zobaczyć szczegóły i szybkie akcje.'.tr,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filteredColumns.isEmpty
                ? Center(
                    child: Text(
                      'Brak kolumn po filtrach.'.tr,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(170),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredColumns.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final column = filteredColumns[index];
                      final mapped = _isColumnMapped(formState, column);
                      final transformed = _hasTransforms(formState, column);
                      final emptyCount = _emptyCountForColumn(
                        previewColumns: formState.previewColumns,
                        previewData: formState.previewData,
                        columnName: column,
                      );

                      return _EditorColumnTile(
                        theme: theme,
                        columnName: column,
                        isSelected: selectedColumn == column,
                        isMapped: mapped,
                        hasTransforms: transformed,
                        emptyCount: emptyCount,
                        onTap: () => onSelectColumn(column),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EditorColumnTile extends StatelessWidget {
  final ThemeColors theme;
  final String columnName;
  final bool isSelected;
  final bool isMapped;
  final bool hasTransforms;
  final int emptyCount;
  final VoidCallback onTap;

  const _EditorColumnTile({
    required this.theme,
    required this.columnName,
    required this.isSelected,
    required this.isMapped,
    required this.hasTransforms,
    required this.emptyCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.themeColor.withAlpha(22)
              : theme.dashboardContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.themeColor
                : theme.dashboardBoarder.withAlpha(110),
            width: isSelected ? 1.3 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              columnName,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _TinyBadge(
                  theme: theme,
                  label: isMapped ? 'Mapped'.tr : 'Unmapped'.tr,
                  active: isMapped,
                ),
                _TinyBadge(
                  theme: theme,
                  label: hasTransforms ? 'Transform'.tr : 'Raw'.tr,
                  active: hasTransforms,
                ),
                _TinyBadge(
                  theme: theme,
                  label: 'Puste: $emptyCount',
                  active: emptyCount == 0,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  final ThemeColors theme;
  final String label;
  final bool active;

  const _TinyBadge({
    required this.theme,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? theme.themeColor.withAlpha(24)
            : theme.dashboardContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active
              ? theme.themeColor.withAlpha(130)
              : theme.dashboardBoarder.withAlpha(100),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EditorGridPanel extends StatelessWidget {
  final ThemeColors theme;
  final ImportFormState formState;
  final ImportFormState pagedFormState;
  final ImportOptions options;
  final ImportFormNotifier formNotifier;
  final List<RegexSelectionSample> selectionSamples;
  final bool stripFromSource;
  final bool highlightAllMatches;
  final RegExp? regex;
  final bool stripSourceValue;
  final bool stripSourceKey;
  final String? selectionKey;
  final bool stripLeadingSeparator;
  final bool stripTrailingSeparator;
  final void Function(
    String columnName,
    String cellText,
    TextSelection selection,
  ) onSelection;

  
  final int selectedTotalCount;
  
  final List<int> pageRowIndexes;
  final int selectedOnPageCount;
  final bool Function(int rowIndex) isRowSelected;
  final ValueChanged<int> onToggleRowSelection;
  final VoidCallback onSelectAllOnPage;
  final VoidCallback onClearAllOnPage;
  final ValueChanged<int> onPageSizeChanged;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final int totalRows;
  final int currentPage;
  final int totalPages;
  final int pageSize;
  
  final bool isTablet;

  const _EditorGridPanel({
    required this.theme,
    required this.formState,
    required this.pagedFormState,
    required this.options,
    required this.formNotifier,
    required this.selectionSamples,
    required this.stripFromSource,
    required this.highlightAllMatches,
    required this.regex,
    required this.stripSourceValue,
    required this.stripSourceKey,
    required this.selectionKey,
    required this.stripLeadingSeparator,
    required this.stripTrailingSeparator,
    required this.onSelection,
    required this.selectedTotalCount,
    required this.pageRowIndexes,
    required this.selectedOnPageCount,
    required this.isRowSelected,
    required this.onToggleRowSelection,
    required this.onSelectAllOnPage,
    required this.onClearAllOnPage,
    required this.onPageSizeChanged,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.totalRows,
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    return isTablet
        ? Container(
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(110)),
      ),
      padding: EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          _EditorSectionHeader(
            theme: theme,
            title: 'Podgląd danych'.tr,
            subtitle: 'Checkbox przy każdym wierszu decyduje, czy rekord trafi do importu.'.tr,
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dashboardBoarder.withAlpha(100)),
              ),
              child: Row(
                children: [
                  _TinyBadge(
                    theme: theme,
                    label: 'Do importu: $selectedTotalCount / ${formState.previewData.length}',
                    active: selectedTotalCount > 0,
                  ),
                  const SizedBox(width: 8),
                  _TinyBadge(
                    theme: theme,
                    label: 'Na stronie: $selectedOnPageCount / ${pageRowIndexes.length}',
                    active: selectedOnPageCount > 0,
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    style: _outlinedActionStyle(theme),
                    onPressed: onSelectAllOnPage,
                    icon: Icon(Icons.done_all_rounded, size: 14, color: theme.textColor),
                    label: Text('Zaznacz stronę'.tr, style: TextStyle(color: theme.textColor, fontSize: isTablet ? 11 : 12)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: _outlinedActionStyle(theme),
                    onPressed: onClearAllOnPage,
                    icon: Icon(Icons.remove_done_rounded, size: 14, color: theme.textColor),
                    label: Text('Odznacz stronę'.tr, style: TextStyle(color: theme.textColor, fontSize: isTablet ? 11 : 12)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
                Flexible(
                  flex: 7,
                  child: MappingGrid(
                    theme: theme,
                    formState: pagedFormState,
                    options: options,
                    formNotifier: formNotifier,
                    onSelection: onSelection,
                    selectionSamples: selectionSamples,
                    stripFromSource: stripFromSource,
                    highlightAllMatches: highlightAllMatches,
                    regex: regex,
                    stripSourceValue: stripSourceValue,
                    stripSourceKey: stripSourceKey,
                    selectionKey: selectionKey,
                    stripLeadingSeparator: stripLeadingSeparator,
                    stripTrailingSeparator: stripTrailingSeparator,
                    showRowSelection: true,
                    pageRowIndexes: pageRowIndexes,
                    isRowSelected: isRowSelected,
                    onToggleRowSelection: onToggleRowSelection,
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  flex: 2,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Wiersze: $totalRows • Strona ${currentPage + 1} / $totalPages'.tr,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(178),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text('Na stronę:'.tr, style: TextStyle(color: theme.textColor.withAlpha(178), fontSize: 10)),
                      const SizedBox(width: 4),
                      DropdownButton<int>(
                        value: pageSize,
                        underline: const SizedBox(),
                        dropdownColor: theme.dashboardContainer,
                        items: const [50, 100, 200, 500]
                            .map((v) => DropdownMenuItem(
                          value: v,
                          child: Text('$v', style: TextStyle(color: theme.textColor, fontSize: 10)),
                        ))
                            .toList(),
                        onChanged: (v) => v != null ? onPageSizeChanged(v) : null,
                      ),
                      IconButton(
                        onPressed: onPreviousPage,
                        icon: Icon(Icons.chevron_left_rounded, color: theme.textColor, size: 20),
                      ),
                      IconButton(
                        onPressed: onNextPage,
                        icon: Icon(Icons.chevron_right_rounded, color: theme.textColor, size: 20),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    )
        : Container(
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(110)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _EditorSectionHeader(
            theme: theme,
            title: 'Podgląd danych'.tr,
            subtitle:
                'Checkbox przy każdym wierszu decyduje, czy rekord trafi do importu.'
                    .tr,
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dashboardBoarder.withAlpha(100),
              ),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _TinyBadge(
                  theme: theme,
                  label: 'Do importu: $selectedTotalCount / ${formState.previewData.length}',
                  active: selectedTotalCount > 0,
                ),
                _TinyBadge(
                  theme: theme,
                  label: 'Na stronie: $selectedOnPageCount / ${pageRowIndexes.length}',
                  active: selectedOnPageCount > 0,
                ),
                OutlinedButton.icon(
                  style: _outlinedActionStyle(theme),
                  onPressed: onSelectAllOnPage,
                  icon: Icon(Icons.done_all_rounded,
                      size: 16, color: theme.textColor),
                  label: Text(
                    'Zaznacz stronę'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
                OutlinedButton.icon(
                  style: _outlinedActionStyle(theme),
                  onPressed: onClearAllOnPage,
                  icon: Icon(Icons.remove_done_rounded,
                      size: 16, color: theme.textColor),
                  label: Text(
                    'Odznacz stronę'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: MappingGrid(
              theme: theme,
              formState: pagedFormState,
              options: options,
              formNotifier: formNotifier,
              onSelection: onSelection,
              selectionSamples: selectionSamples,
              stripFromSource: stripFromSource,
              highlightAllMatches: highlightAllMatches,
              regex: regex,
              stripSourceValue: stripSourceValue,
              stripSourceKey: stripSourceKey,
              selectionKey: selectionKey,
              stripLeadingSeparator: stripLeadingSeparator,
              stripTrailingSeparator: stripTrailingSeparator,
              showRowSelection: true,
              pageRowIndexes: pageRowIndexes,
              isRowSelected: isRowSelected,
              onToggleRowSelection: onToggleRowSelection,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Wiersze: $totalRows • Strona ${currentPage + 1} / $totalPages'
                    .tr,
                style: TextStyle(
                  color: theme.textColor.withAlpha(178),
                  fontSize: 11,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Na stronę:'.tr,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(178),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  DropdownButton<int>(
                    value: pageSize,
                    dropdownColor: theme.dashboardContainer,
                    items: const [50, 100, 200, 500]
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(
                              '$v',
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        onPageSizeChanged(v);
                      }
                    },
                  ),
                ],
              ),
              IconButton(
                onPressed: onPreviousPage,
                icon: Icon(Icons.chevron_left_rounded, color: theme.textColor),
                tooltip: 'Poprzednia strona'.tr,
              ),
              IconButton(
                onPressed: onNextPage,
                icon: Icon(Icons.chevron_right_rounded, color: theme.textColor),
                tooltip: 'Następna strona'.tr,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditorInspectorPanel extends StatelessWidget {
  final ThemeColors theme;
  final ImportOptions options;
  final ImportFormState formState;
  final ImportFormNotifier formNotifier;
  final String? selectedColumn;
  final bool isTablet;

  const _EditorInspectorPanel({
    required this.theme,
    required this.options,
    required this.formState,
    required this.formNotifier,
    required this.selectedColumn,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedColumn == null) {
      return Container(
        decoration: BoxDecoration(
          color: theme.adPopBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dashboardBoarder.withAlpha(110)),
        ),
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Text(
            'Wybierz kolumnę po lewej stronie, aby zobaczyć jej szczegóły.'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textColor.withAlpha(178),
            ),
          ),
        ),
      );
    }

    final samples = _samplesForColumn(
      previewColumns: formState.previewColumns,
      previewData: formState.previewData,
      columnName: selectedColumn!,
      maxItems: 6,
    );

    final mappings = formState.fieldMappings
        .where((m) => m.columnName == selectedColumn)
        .toList(growable: false);

    final transforms = formState.transforms
        .where(
          (t) =>
              t.sourceColumn == selectedColumn ||
              t.outputColumn == selectedColumn,
        )
        .toList(growable: false);

    final emptyCount = _emptyCountForColumn(
      previewColumns: formState.previewColumns,
      previewData: formState.previewData,
      columnName: selectedColumn!,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(110)),
      ),
      padding: const EdgeInsets.all(12),
      child:isTablet
          ?SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EditorSectionHeader(
              theme: theme,
              title: 'Inspector'.tr,
              subtitle: 'Szczegóły i szybkie akcje dla wybranej kolumny.'.tr,
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.dashboardBoarder.withAlpha(100),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedColumn!,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _TinyBadge(
                        theme: theme,
                        label: 'Mapowania: ${mappings.length}',
                        active: mappings.isNotEmpty,
                      ),
                      _TinyBadge(
                        theme: theme,
                        label: 'Transformacje: ${transforms.length}',
                        active: transforms.isNotEmpty,
                      ),
                      _TinyBadge(
                        theme: theme,
                        label: 'Puste: $emptyCount',
                        active: emptyCount == 0,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  style: _outlinedActionStyle(theme),
                  onPressed: () {
                    _openEditorColumnManagerSheet(
                      context: context,
                      theme: theme,
                      options: options,
                      formState: formState,
                      formNotifier: formNotifier,
                      columnName: selectedColumn!,
                    );
                  },
                  icon: Icon(Icons.link_rounded, color: theme.textColor, size: 16),
                  label: Text(
                    'Mapuj pole'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
                OutlinedButton.icon(
                  style: _outlinedActionStyle(theme),
                  onPressed: () {
                    openTransformDraggableSheet(
                      context: context,
                      columnName: selectedColumn!,
                      theme: theme,
                      formState: formState,
                      formNotifier: formNotifier,
                    );
                  },
                  icon: Icon(Icons.functions_rounded,
                      color: theme.textColor, size: 16),
                  label: Text(
                    'Transformacje'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Aktualne mapowania'.tr,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            if (mappings.isEmpty)
              Text(
                'Brak mapowań dla tej kolumny.'.tr,
                style: TextStyle(
                  color: theme.textColor.withAlpha(170),
                  fontSize: 11,
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: mappings.map((m) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: theme.dashboardContainer,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: theme.dashboardBoarder.withAlpha(110),
                      ),
                    ),
                    child: Text(
                      '${m.targetModel}.${m.targetField}',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 10,
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 12),
            Text(
              'Przykładowe wartości'.tr,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 180,
              child: samples.isEmpty
                  ? Center(
                child: Text(
                  'Brak niepustych wartości w podglądzie.'.tr,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(170),
                    fontSize: 11,
                  ),
                ),
              )
                  : ListView.separated(
                itemCount: samples.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final sample = samples[index];
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.dashboardContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.dashboardBoarder.withAlpha(90),
                      ),
                    ),
                    child: Text(
                      sample,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(220),
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        )
      )
      :Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EditorSectionHeader(
            theme: theme,
            title: 'Inspector'.tr,
            subtitle: 'Szczegóły i szybkie akcje dla wybranej kolumny.'.tr,
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dashboardBoarder.withAlpha(100),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedColumn!,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _TinyBadge(
                      theme: theme,
                      label: 'Mapowania: ${mappings.length}',
                      active: mappings.isNotEmpty,
                    ),
                    _TinyBadge(
                      theme: theme,
                      label: 'Transformacje: ${transforms.length}',
                      active: transforms.isNotEmpty,
                    ),
                    _TinyBadge(
                      theme: theme,
                      label: 'Puste: $emptyCount',
                      active: emptyCount == 0,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              EmmaUiAnchorTarget(
                // @emma-backend: ImporterEmmaAnchors.importEditorMapFieldButton
                anchorKey: 'importer.editor.map_field_button',
                child: OutlinedButton.icon(
                  style: _outlinedActionStyle(theme),
                  onPressed: () {
                    _openEditorColumnManagerSheet(
                      context: context,
                      theme: theme,
                      options: options,
                      formState: formState,
                      formNotifier: formNotifier,
                      columnName: selectedColumn!,
                    );
                  },
                  icon: Icon(
                    Icons.link_rounded,
                    color: theme.textColor,
                    size: 16,
                  ),
                  label: Text(
                    'Mapuj pole'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
              ),
              EmmaUiAnchorTarget(
                // @emma-backend: ImporterEmmaAnchors.importEditorTransformsButton
                anchorKey: 'importer.editor.transforms_button',
                child: OutlinedButton.icon(
                  style: _outlinedActionStyle(theme),
                  onPressed: () {
                    openTransformDraggableSheet(
                      context: context,
                      columnName: selectedColumn!,
                      theme: theme,
                      formState: formState,
                      formNotifier: formNotifier,
                    );
                  },
                  icon: Icon(
                    Icons.functions_rounded,
                    color: theme.textColor,
                    size: 16,
                  ),
                  label: Text(
                    'Transformacje'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Aktualne mapowania'.tr,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          if (mappings.isEmpty)
            Text(
              'Brak mapowań dla tej kolumny.'.tr,
              style: TextStyle(
                color: theme.textColor.withAlpha(170),
                fontSize: 11,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: mappings.map((m) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.dashboardContainer,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: theme.dashboardBoarder.withAlpha(110),
                    ),
                  ),
                  child: Text(
                    '${m.targetModel}.${m.targetField}',
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 10,
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          Text(
            'Przykładowe wartości'.tr,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: samples.isEmpty
                ? Center(
                    child: Text(
                      'Brak niepustych wartości w podglądzie.'.tr,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(170),
                        fontSize: 11,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: samples.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final sample = samples[index];

                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.dashboardContainer,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.dashboardBoarder.withAlpha(90),
                          ),
                        ),
                        child: Text(
                          sample,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(220),
                            fontSize: 11,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EditorBottomActionBar extends StatelessWidget {
  final ThemeColors theme;
  final String? selectedColumn;
  final ImportOptions options;
  final ImportFormState formState;
  final ImportFormNotifier formNotifier;
  final WidgetRef ref;

  const _EditorBottomActionBar({
    required this.theme,
    required this.selectedColumn,
    required this.options,
    required this.formState,
    required this.formNotifier,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(110)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (selectedColumn != null) ...[
            EmmaUiAnchorTarget(
              // @emma-backend: ImporterEmmaAnchors.importEditorMapFieldButton
              anchorKey: 'importer.editor.map_field_button',
              child: OutlinedButton.icon(
                style: _outlinedActionStyle(theme),
                onPressed: () {
                  _openEditorColumnManagerSheet(
                    context: context,
                    theme: theme,
                    options: options,
                    formState: formState,
                    formNotifier: formNotifier,
                    columnName: selectedColumn!,
                  );
                },
                icon: Icon(Icons.link_rounded, color: theme.textColor),
                label: Text(
                  'Mapuj "${selectedColumn!}"'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            ),
            EmmaUiAnchorTarget(
              // @emma-backend: ImporterEmmaAnchors.importEditorTransformsButton
              anchorKey: 'importer.editor.transforms_button',
              child: OutlinedButton.icon(
                style: _outlinedActionStyle(theme),
                onPressed: () {
                  openTransformDraggableSheet(
                    context: context,
                    columnName: selectedColumn!,
                    theme: theme,
                    formState: formState,
                    formNotifier: formNotifier,
                  );
                },
                icon: Icon(Icons.functions_rounded, color: theme.textColor),
                label: Text(
                  'Transformacje "${selectedColumn!}"'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            ),
          ],
          const SizedBox(width: 4),
          SizedBox(
            width: 340,
            child: SubmitRow(
              ref: ref,
              theme: theme,
              formState: formState,
              formNotifier: formNotifier,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorSectionHeader extends StatelessWidget {
  final ThemeColors theme;
  final String title;
  final String subtitle;

  const _EditorSectionHeader({
    required this.theme,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: theme.textColor.withAlpha(170),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

void _openEditorColumnManagerSheet({
  required BuildContext context,
  required ThemeColors theme,
  required ImportOptions options,
  required ImportFormState formState,
  required ImportFormNotifier formNotifier,
  required String columnName,
}) {
  final allModelNames = options.targetModels.keys.toList()..sort();

  final existing = formNotifier.getFieldMappingForColumn(columnName);
  String? selectedModel =
      existing?.targetModel ?? formState.selectedTargetModel;
  String? selectedField = existing?.targetField;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.dashboardContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocalState) {
          final fields = selectedModel == null
              ? <String>[]
              : _extractFieldNamesFromRawSpec(
                  options.targetModels[selectedModel],
                );

          if (selectedField != null && !fields.contains(selectedField)) {
            selectedField = null;
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zarządzaj kolumną "$columnName"'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  style: _outlinedActionStyle(theme),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    openTransformDraggableSheet(
                      context: context,
                      columnName: columnName,
                      theme: theme,
                      formState: formState,
                      formNotifier: formNotifier,
                    );
                  },
                  icon: Icon(Icons.functions_rounded, color: theme.textColor),
                  label: Text(
                    'Otwórz transformacje'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedModel,
                  dropdownColor: theme.dashboardContainer,
                  decoration: _inputDecoration(
                    theme: theme,
                    label: 'Model docelowy'.tr,
                  ),
                  items: allModelNames
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(
                            m,
                            style: TextStyle(color: theme.textColor),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setLocalState(() {
                      selectedModel = val;
                      selectedField = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedField,
                  dropdownColor: theme.dashboardContainer,
                  decoration: _inputDecoration(
                    theme: theme,
                    label: 'Pole docelowe'.tr,
                  ),
                  items: fields
                      .map(
                        (f) => DropdownMenuItem(
                          value: f,
                          child: Text(
                            f,
                            style: TextStyle(color: theme.textColor),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: fields.isEmpty
                      ? null
                      : (val) {
                          setLocalState(() {
                            selectedField = val;
                          });
                        },
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton(
                      style: _outlinedActionStyle(theme),
                      onPressed: () {
                        formNotifier.upsertFieldMappingForColumn(
                          columnName,
                          targetModel: null,
                          targetField: null,
                        );
                        Navigator.of(ctx).pop();
                      },
                      child: Text(
                        'Usuń mapowanie'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: _filledActionStyle(theme),
                      onPressed: () {
                        formNotifier.upsertFieldMappingForColumn(
                          columnName,
                          targetModel: selectedModel,
                          targetField: selectedField,
                        );
                        Navigator.of(ctx).pop();
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: Text('Zapisz'.tr),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

bool _isColumnMapped(ImportFormState state, String columnName) {
  return state.fieldMappings.any((m) => m.columnName == columnName);
}

bool _hasTransforms(ImportFormState state, String columnName) {
  return state.transforms.any(
    (t) => t.sourceColumn == columnName || t.outputColumn == columnName,
  );
}

int _emptyCountForColumn({
  required List<String> previewColumns,
  required List<List<String>> previewData,
  required String columnName,
}) {
  final colIndex = previewColumns.indexOf(columnName);
  if (colIndex == -1) return 0;

  var count = 0;
  for (final row in previewData) {
    final value = colIndex < row.length ? row[colIndex] : '';
    if (value.trim().isEmpty) {
      count += 1;
    }
  }

  return count;
}

List<String> _samplesForColumn({
  required List<String> previewColumns,
  required List<List<String>> previewData,
  required String columnName,
  int maxItems = 5,
}) {
  final colIndex = previewColumns.indexOf(columnName);
  if (colIndex == -1) return [];

  final out = <String>[];

  for (final row in previewData) {
    final value = colIndex < row.length ? row[colIndex] : '';
    if (value.trim().isNotEmpty) {
      out.add(value);
      if (out.length >= maxItems) break;
    }
  }

  return out;
}

List<String> _extractFieldNamesFromRawSpec(dynamic rawSpec) {
  if (rawSpec is! List) return [];

  return rawSpec
      .whereType<Map<String, dynamic>>()
      .map((f) => (f['field_name'] ?? '').toString())
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
}

InputDecoration _inputDecoration({
  required ThemeColors theme,
  required String label,
  bool dense = false,
}) {
  return InputDecoration(
    isDense: dense,
    filled: true,
    fillColor: theme.dashboardContainer,
    labelText: label.isEmpty ? null : label,
    hintStyle: TextStyle(
      color: theme.textColor.withAlpha(130),
      fontSize: 12,
    ),
    labelStyle: TextStyle(
      color: theme.textColor.withAlpha(150),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    contentPadding: dense
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: theme.dashboardBoarder.withAlpha(120),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: theme.dashboardBoarder.withAlpha(120),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: theme.themeColor,
        width: 1.3,
      ),
    ),
  );
}

ButtonStyle _outlinedActionStyle(ThemeColors theme) {
  return OutlinedButton.styleFrom(
    foregroundColor: theme.textColor,
    backgroundColor: theme.dashboardContainer,
    side: BorderSide(
      color: theme.dashboardBoarder.withAlpha(130),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

ButtonStyle _filledActionStyle(ThemeColors theme) {
  return ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: theme.themeColor,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
  );
}









class _EmmaPlanSection extends StatelessWidget {
  final ThemeColors theme;
  final String title;
  final String emptyText;
  final List<dynamic> items;
  final Widget Function(dynamic item) itemBuilder;

  const _EmmaPlanSection({
    required this.theme,
    required this.title,
    required this.emptyText,
    required this.items,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(110)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(
              emptyText,
              style: TextStyle(
                color: theme.textColor.withAlpha(160),
                fontSize: 12,
              ),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: itemBuilder(item),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmmaPlanCard extends StatelessWidget {
  final ThemeColors theme;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color? accentColor;

  const _EmmaPlanCard({
    required this.theme,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? theme.themeColor;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withAlpha(70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(185),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(160),
                      fontSize: 11,
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