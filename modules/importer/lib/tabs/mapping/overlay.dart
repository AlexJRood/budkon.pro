import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:importer/import_state.dart';
import 'package:importer/tabs/mapping/models.dart';
import 'package:importer/tabs/transform_sheet.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

// ========================
// GRID z podglądem + mappingiem + zaznaczanie tekstu +
// highlight / strip + wybór wierszy do importu
// ========================

class MappingGrid extends StatelessWidget {
  final ThemeColors theme;
  final ImportFormState formState;
  final ImportOptions options;
  final ImportFormNotifier formNotifier;

  final void Function(
    String columnName,
    String cellText,
    TextSelection selection,
  ) onSelection;

  final List<RegexSelectionSample> selectionSamples;
  final bool stripFromSource;
  final bool highlightAllMatches;
  final RegExp? regex;
  final bool stripSourceValue;
  final bool stripSourceKey;
  final String? selectionKey;
  final bool stripLeadingSeparator;
  final bool stripTrailingSeparator;

  // Row selection
  final bool showRowSelection;
  final List<int> pageRowIndexes;
  final bool Function(int rowIndex)? isRowSelected;
  final ValueChanged<int>? onToggleRowSelection;

  const MappingGrid({
    super.key,
    required this.theme,
    required this.formState,
    required this.options,
    required this.formNotifier,
    required this.onSelection,
    required this.selectionSamples,
    required this.stripFromSource,
    required this.highlightAllMatches,
    required this.regex,
    required this.stripSourceValue,
    required this.stripSourceKey,
    required this.selectionKey,
    required this.stripLeadingSeparator,
    required this.stripTrailingSeparator,
    this.showRowSelection = false,
    this.pageRowIndexes = const [],
    this.isRowSelected,
    this.onToggleRowSelection,
  });

  @override
  Widget build(BuildContext context) {
    final cols = formState.previewColumns;
    final rows = formState.previewData;

    if (cols.isEmpty) {
      return const SizedBox.shrink();
    }

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              checkboxTheme: CheckboxThemeData(
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return theme.themeColor;
                  }

                  return Colors.transparent;
                }),
                checkColor: WidgetStateProperty.all(AppColors.white),
                side: BorderSide(
                  color: theme.dashboardBoarder.withAlpha(120),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 60,
              horizontalMargin: 8,
              columnSpacing: 6,
              dividerThickness: 0,
              columns: [
                if (showRowSelection)
                  const DataColumn(
                    label: SizedBox(width: 54),
                  ),
                for (final col in cols)
                  DataColumn(
                    label: _ColumnHeader(
                      theme: theme,
                      columnName: col,
                      mapping: _mappingForColumn(col),
                      hasTransforms: formState.transforms.any(
                        (t) => t.sourceColumn == col || t.outputColumn == col,
                      ),
                      onTap: () {
                        _openColumnMappingSheet(
                          context: context,
                          columnName: col,
                          theme: theme,
                          options: options,
                          formState: formState,
                          formNotifier: formNotifier,
                        );
                      },
                      onDoubleTap: () {
                        _openRenameColumnDialog(
                          context: context,
                          columnName: col,
                          theme: theme,
                          formNotifier: formNotifier,
                        );
                      },
                    ),
                  ),
              ],
              rows: [
                for (var rowIndex = 0; rowIndex < rows.length; rowIndex++)
                  _buildDataRow(
                    context: context,
                    rowIndexOnPage: rowIndex,
                    row: rows[rowIndex],
                    cols: cols,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow({
    required BuildContext context,
    required int rowIndexOnPage,
    required List<String> row,
    required List<String> cols,
  }) {
    final realRowIndex = rowIndexOnPage < pageRowIndexes.length
        ? pageRowIndexes[rowIndexOnPage]
        : rowIndexOnPage;

    final selected = isRowSelected?.call(realRowIndex) ?? false;

    // Selected rows should look normal.
    // Not selected rows are dimmed only when row selection mode is active.
    final dimmed = showRowSelection && !selected;

    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (dimmed) {
          return theme.dashboardContainer.withAlpha(18);
        }

        return Colors.transparent;
      }),
      cells: [
        if (showRowSelection)
          DataCell(
            _RowSelectionCell(
              theme: theme,
              rowIndex: realRowIndex,
              selected: selected,
              dimmed: dimmed,
              onTap: onToggleRowSelection == null
                  ? null
                  : () => onToggleRowSelection!(realRowIndex),
            ),
          ),
        for (var i = 0; i < cols.length; i++)
          DataCell(
            _buildSelectableCell(
              columnName: cols[i],
              text: i < row.length ? row[i] : '',
              rowSelected: selected,
              rowDimmed: dimmed,
            ),
          ),
      ],
    );
  }

  bool _isWordChar(String ch) {
    return RegExp(r'[0-9A-Za-zĄĆĘŁŃÓŚŹŻąćęłńóśźż]').hasMatch(ch);
  }

  RegexSelectionSample? _sampleForCell(
    String columnName,
    String fullText,
  ) {
    for (final s in selectionSamples) {
      if (s.columnName == columnName && s.fullText == fullText) {
        return s;
      }
    }

    return null;
  }

  Widget _buildSelectableCell({
    required String columnName,
    required String text,
    required bool rowSelected,
    required bool rowDimmed,
  }) {
    final original = text;
    final manualSample = _sampleForCell(columnName, original);
    final hasManualSelection = manualSample != null;

    final baseTextAlpha = rowDimmed ? 105 : 230;
    final emptyTextAlpha = rowDimmed ? 75 : 120;

    final baseStyle = TextStyle(
      color: theme.textColor.withAlpha(baseTextAlpha),
      fontSize: 12,
      height: 1.35,
      fontWeight: rowDimmed ? FontWeight.w400 : FontWeight.w500,
    );

    final fadedStyle = baseStyle.copyWith(
      color: theme.textColor.withAlpha(rowDimmed ? 70 : 125),
      decoration: TextDecoration.lineThrough,
      decorationColor: Colors.redAccent.withAlpha(rowDimmed ? 70 : 130),
      decorationThickness: 2,
    );

    final regexHighlightStyle = baseStyle.copyWith(
      backgroundColor: theme.themeColor.withAlpha(rowDimmed ? 22 : 58),
      fontWeight: rowDimmed ? FontWeight.w500 : FontWeight.w700,
    );

    final manualSelectionStyle = baseStyle.copyWith(
      backgroundColor: Colors.amber.withAlpha(rowDimmed ? 32 : 95),
      color: theme.textColor.withAlpha(rowDimmed ? 145 : 255),
      fontWeight: rowDimmed ? FontWeight.w600 : FontWeight.w800,
    );

    void handleSelection(TextSelection sel, SelectionChangedCause? cause) {
      onSelection(columnName, original, sel);
    }

    final wrapperDecoration = BoxDecoration(
      color: hasManualSelection
          ? Colors.amber.withAlpha(rowDimmed ? 6 : 14)
          : theme.dashboardContainer.withAlpha(rowDimmed ? 42 : 110),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: hasManualSelection
            ? Colors.amber.withAlpha(rowDimmed ? 70 : 170)
            : theme.dashboardBoarder.withAlpha(rowDimmed ? 36 : 80),
        width: hasManualSelection && !rowDimmed ? 1.3 : 1,
      ),
    );

    Widget cellWrapper({
      required Widget child,
    }) {
      return Container(
        constraints: const BoxConstraints(minWidth: 150),
        padding: const EdgeInsets.all(8),
        decoration: wrapperDecoration,
        child: child,
      );
    }

    if (hasManualSelection) {
      final start = manualSample.start.clamp(0, original.length);
      final end = manualSample.end.clamp(0, original.length);

      if (end > start) {
        final before = original.substring(0, start);
        final middle = original.substring(start, end);
        final after = original.substring(end);

        return cellWrapper(
          child: SelectableText.rich(
            TextSpan(
              children: [
                TextSpan(text: before, style: baseStyle),
                TextSpan(text: middle, style: manualSelectionStyle),
                TextSpan(text: after, style: baseStyle),
              ],
            ),
            onSelectionChanged: handleSelection,
          ),
        );
      }
    }

    if (regex == null) {
      return cellWrapper(
        child: SelectableText(
          original.isEmpty ? '—' : original,
          style: original.isEmpty
              ? baseStyle.copyWith(
                  color: theme.textColor.withAlpha(emptyTextAlpha),
                )
              : baseStyle,
          onSelectionChanged: handleSelection,
        ),
      );
    }

    RegExpMatch? match;

    try {
      match = regex!.firstMatch(original);
    } catch (_) {
      return cellWrapper(
        child: SelectableText(
          original.isEmpty ? '—' : original,
          style: original.isEmpty
              ? baseStyle.copyWith(
                  color: theme.textColor.withAlpha(emptyTextAlpha),
                )
              : baseStyle,
          onSelectionChanged: handleSelection,
        ),
      );
    }

    if (match == null) {
      return cellWrapper(
        child: SelectableText(
          original.isEmpty ? '—' : original,
          style: original.isEmpty
              ? baseStyle.copyWith(
                  color: theme.textColor.withAlpha(emptyTextAlpha),
                )
              : baseStyle,
          onSelectionChanged: handleSelection,
        ),
      );
    }

    try {
      int fullStart = match.start;
      int fullEnd = match.end;

      fullStart = fullStart.clamp(0, original.length);
      fullEnd = fullEnd.clamp(fullStart, original.length);

      int valueStart;
      int valueEnd;

      if (match.groupCount >= 1 && (match.group(1)?.isNotEmpty ?? false)) {
        final full = match.group(0)!;
        final value = match.group(1)!;
        final innerOffset = full.indexOf(value);
        final safeOffset = innerOffset < 0 ? 0 : innerOffset;

        valueStart = (fullStart + safeOffset).clamp(0, original.length);
        valueEnd = (valueStart + value.length).clamp(
          valueStart,
          original.length,
        );
      } else {
        valueStart = fullStart;
        valueEnd = fullEnd;
      }

      int keyStart = fullStart;
      int keyEnd = valueStart.clamp(fullStart, fullEnd);

      int beforeEnd = fullStart;
      int afterStart = valueEnd;

      if (stripLeadingSeparator && beforeEnd > 0) {
        final ch = original[beforeEnd - 1];

        if (!_isWordChar(ch)) {
          beforeEnd -= 1;
        }
      }

      if (stripTrailingSeparator && afterStart < original.length) {
        final ch = original[afterStart];

        if (!_isWordChar(ch)) {
          afterStart += 1;
        }
      }

      beforeEnd = beforeEnd.clamp(0, original.length);
      afterStart = afterStart.clamp(0, original.length);
      keyStart = keyStart.clamp(0, original.length);
      keyEnd = keyEnd.clamp(keyStart, original.length);
      valueStart = valueStart.clamp(0, original.length);
      valueEnd = valueEnd.clamp(valueStart, original.length);

      final before = original.substring(0, beforeEnd);
      final keyChunk = original.substring(keyStart, keyEnd);
      final valueChunk = original.substring(valueStart, valueEnd);
      final after = original.substring(afterStart);

      final shouldHighlightRegex = highlightAllMatches;

      final spans = <TextSpan>[
        TextSpan(text: before, style: baseStyle),
      ];

      if (keyChunk.isNotEmpty) {
        spans.add(
          TextSpan(
            text: keyChunk,
            style: stripSourceKey
                ? fadedStyle
                : shouldHighlightRegex
                    ? regexHighlightStyle
                    : baseStyle,
          ),
        );
      }

      if (valueChunk.isNotEmpty) {
        spans.add(
          TextSpan(
            text: valueChunk,
            style: stripSourceValue
                ? fadedStyle
                : shouldHighlightRegex
                    ? regexHighlightStyle
                    : baseStyle,
          ),
        );
      }

      spans.add(TextSpan(text: after, style: baseStyle));

      return cellWrapper(
        child: SelectableText.rich(
          TextSpan(children: spans),
          onSelectionChanged: handleSelection,
        ),
      );
    } catch (_) {
      return cellWrapper(
        child: SelectableText(
          original.isEmpty ? '—' : original,
          style: original.isEmpty
              ? baseStyle.copyWith(
                  color: theme.textColor.withAlpha(emptyTextAlpha),
                )
              : baseStyle,
          onSelectionChanged: handleSelection,
        ),
      );
    }
  }

  FieldMappingRule? _mappingForColumn(String columnName) {
    for (final m in formState.fieldMappings) {
      if (m.columnName == columnName) return m;
    }

    return null;
  }
}

class _RowSelectionCell extends StatelessWidget {
  final ThemeColors theme;
  final int rowIndex;
  final bool selected;
  final bool dimmed;
  final VoidCallback? onTap;

  const _RowSelectionCell({
    required this.theme,
    required this.rowIndex,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = dimmed
        ? theme.textColor.withAlpha(95)
        : theme.textColor.withAlpha(230);

    final borderColor = dimmed
        ? theme.dashboardBoarder.withAlpha(55)
        : theme.dashboardBoarder.withAlpha(120);

    return SizedBox(
      width: 54,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${rowIndex + 1}',
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Checkbox(
              value: selected,
              onChanged: onTap == null ? null : (_) => onTap!(),
              activeColor: theme.themeColor,
              checkColor: AppColors.white,
              visualDensity: VisualDensity.compact,
              side: BorderSide(
                color: borderColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  final ThemeColors theme;
  final String columnName;
  final FieldMappingRule? mapping;
  final VoidCallback onTap;
  final bool hasTransforms;
  final VoidCallback? onDoubleTap;

  const _ColumnHeader({
    required this.theme,
    required this.columnName,
    required this.mapping,
    required this.onTap,
    required this.hasTransforms,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMapped = mapping != null;

    final subtitle = isMapped
        ? '${mapping!.targetModel}.${mapping!.targetField}'
        : 'Nie zmapowano'.tr;

    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 150),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    columnName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: theme.textColor,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                if (hasTransforms) ...[
                  Icon(
                    Icons.functions_rounded,
                    size: 14,
                    color: theme.themeColor,
                  ),
                  const SizedBox(width: 2),
                ],
                Icon(
                  isMapped
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  size: 16,
                  color: isMapped
                      ? Colors.greenAccent
                      : theme.textColor.withAlpha(102),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                color: theme.textColor.withAlpha(178),
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      ),
    );
  }
}

void _openColumnMappingSheet({
  required BuildContext context,
  required String columnName,
  required ThemeColors theme,
  required ImportOptions options,
  required ImportFormState formState,
  required ImportFormNotifier formNotifier,
}) {
  final allModelNames = options.targetModels.keys.toList()..sort();

  final currentMapping = formNotifier.getFieldMappingForColumn(columnName);

  String? selectedModel =
      currentMapping?.targetModel ?? formState.selectedTargetModel;
  String? selectedField = currentMapping?.targetField;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.dashboardContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StatefulBuilder(
          builder: (ctx, setState) {
            final modelFields = selectedModel != null
                ? options.targetModels[selectedModel] as List<dynamic>? ?? []
                : <dynamic>[];

            final modelFieldNames = modelFields
                .map(
                  (f) => (f as Map<String, dynamic>)['field_name']?.toString(),
                )
                .whereType<String>()
                .toList();

            if (selectedField != null &&
                !modelFieldNames.contains(selectedField)) {
              selectedField = null;
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Mapowanie kolumny'.tr,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(8),
                          ),
                          color: theme.themeColor,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          '"$columnName"',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Wybierz model i pole docelowe albo przejdź od razu do transformacji tej kolumny.'
                      .tr,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(178),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    style: _outlinedButtonStyle(theme),
                    icon: Icon(
                      Icons.functions_rounded,
                      size: 18,
                      color: theme.textColor,
                    ),
                    label: Text(
                      'Transformacje tej kolumny'.tr,
                      style: TextStyle(color: theme.textColor),
                    ),
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
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedModel,
                  dropdownColor: theme.dashboardContainer,
                  style: TextStyle(color: theme.textColor),
                  decoration: _buildInputDecoration(
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
                    setState(() {
                      selectedModel = val;
                      selectedField = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedField,
                  dropdownColor: theme.dashboardContainer,
                  style: TextStyle(color: theme.textColor),
                  decoration: _buildInputDecoration(
                    theme: theme,
                    label: 'Pole docelowe'.tr,
                  ),
                  items: modelFieldNames
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
                  onChanged: modelFieldNames.isEmpty
                      ? null
                      : (val) {
                          setState(() {
                            selectedField = val;
                          });
                        },
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton(
                      style: _outlinedButtonStyle(theme),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        'Anuluj'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                    OutlinedButton.icon(
                      style: _outlinedButtonStyle(theme),
                      onPressed: () {
                        formNotifier.upsertFieldMappingForColumn(
                          columnName,
                          targetModel: null,
                          targetField: null,
                        );
                        Navigator.of(ctx).pop();
                      },
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: theme.textColor,
                      ),
                      label: Text(
                        'Usuń mapowanie'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: _filledButtonStyle(theme),
                      onPressed: () {
                        formNotifier.upsertFieldMappingForColumn(
                          columnName,
                          targetModel: selectedModel,
                          targetField: selectedField,
                        );
                        Navigator.of(ctx).pop();
                      },
                      icon: const Icon(
                        Icons.check_rounded,
                        color: AppColors.white,
                      ),
                      label: Text(
                        'Zapisz'.tr,
                        style: const TextStyle(color: AppColors.white),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

InputDecoration _buildInputDecoration({
  required ThemeColors theme,
  required String label,
}) {
  return InputDecoration(
    filled: true,
    fillColor: theme.adPopBackground,
    floatingLabelStyle: TextStyle(
      color: theme.textColor.withAlpha(160),
    ),
    labelText: label,
    labelStyle: TextStyle(
      color: theme.textColor.withAlpha(190),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: theme.dashboardBoarder.withAlpha(150),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: theme.themeColor,
        width: 1.5,
      ),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

void _openRenameColumnDialog({
  required BuildContext context,
  required String columnName,
  required ThemeColors theme,
  required ImportFormNotifier formNotifier,
}) {
  final controller = TextEditingController(text: columnName);

  showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: theme.dashboardContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Zmień nazwę kolumny'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: theme.textColor),
          decoration: InputDecoration(
            labelText: 'Nowa nazwa'.tr,
            labelStyle: TextStyle(color: theme.textColor.withAlpha(160)),
            filled: true,
            fillColor: theme.adPopBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: (value) {
            final newName = value.trim();
            if (newName.isNotEmpty && newName != columnName) {
              formNotifier.renameColumn(columnName, newName);
            }
            Navigator.of(ctx).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Anuluj'.tr, style: TextStyle(color: theme.textColor.withAlpha(180))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.themeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != columnName) {
                formNotifier.renameColumn(columnName, newName);
              }
              Navigator.of(ctx).pop();
            },
            child: Text('Zapisz'.tr),
          ),
        ],
      );
    },
  ).then((_) => controller.dispose());
}

ButtonStyle _outlinedButtonStyle(ThemeColors theme) {
  return OutlinedButton.styleFrom(
    foregroundColor: theme.textColor,
    backgroundColor: theme.dashboardContainer,
    side: BorderSide(
      color: theme.dashboardBoarder.withAlpha(150),
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

ButtonStyle _filledButtonStyle(ThemeColors theme) {
  return ElevatedButton.styleFrom(
    backgroundColor: theme.themeColor,
    foregroundColor: AppColors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}