import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:importer/import_state.dart';
import 'package:importer/tabs/import_tab_editor.dart';
import 'package:importer/tabs/mapping/enum.dart';
import 'package:importer/tabs/mapping/models.dart';
import 'package:importer/tabs/mapping/regex.dart';
import 'package:importer/tabs/mapping/strip.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';

mixin SelectionOverlayMixin on ConsumerState<ImportTabEditor> {
  final TextEditingController _selectionNewColumnCtrl =
      TextEditingController();

  List<RegexSelectionSample> _selectionSamples = [];
  String? _selectionBaseColumn;
  bool _selectionOverlayVisible = false;
  bool _selectionApplyToAllColumns = false;

  String? _selectionRegexPattern;
  RegExp? _selectionRegex;
  int _selectionPotentialMatches = 0;

  Offset _selectionOverlayOffset = Offset.zero;

  String? _selectionKey;

  bool _targetIncludeKey = false;

  bool _stripSourceValue = false;
  bool _stripSourceKey = false;
  bool _stripLeadingSeparator = false;
  bool _stripTrailingSeparator = false;

  bool _selectionOverlayMinimized = false;
  bool _highlightAllMatches = false;

  OutputMode _selectionOutputMode = OutputMode.replaceSource;

  String? _selectionExistingColumn;
  bool _normalizeDigits = true;

  bool _selectionIsEmail = false;
  bool _selectionIsAddress = false;

  List<RegexSelectionSample> get selectionSamples => _selectionSamples;
  bool get highlightAllMatches => _highlightAllMatches;
  RegExp? get selectionRegex => _selectionRegex;
  bool get stripSourceValue => _stripSourceValue;
  bool get stripSourceKey => _stripSourceKey;
  bool get stripLeadingSeparator => _stripLeadingSeparator;
  bool get stripTrailingSeparator => _stripTrailingSeparator;
  String? get selectionKey => _selectionKey;
  OutputMode get selectionOutputMode => _selectionOutputMode;

  void disposeSelectionOverlay() {
    _selectionNewColumnCtrl.dispose();
  }

  void handleCellSelection(
    String columnName,
    String cellText,
    TextSelection selection,
  ) {
    if (selection.isCollapsed) {
      setState(() {
        _selectionSamples = _selectionSamples
            .where((s) => !(s.columnName == columnName && s.fullText == cellText))
            .toList();
        if (_selectionSamples.isEmpty) {
          _resetSelectionState();
        } else {
          _rebuildSelectionRegex();
        }
      });
      return;
    }

    final start = selection.start.clamp(0, cellText.length);
    final end = selection.end.clamp(0, cellText.length);
    if (end <= start) return;

    final raw = cellText.substring(start, end);
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _selectionBaseColumn ??= columnName;

      final existingIndex = _selectionSamples.indexWhere(
        (s) => s.columnName == columnName && s.fullText == cellText,
      );

      if (existingIndex >= 0) {
        _selectionSamples[existingIndex] = RegexSelectionSample(
          columnName: columnName,
          fullText: cellText,
          start: start,
          end: end,
        );
      } else {
        _selectionSamples.add(
          RegexSelectionSample(
            columnName: columnName,
            fullText: cellText,
            start: start,
            end: end,
          ),
        );
      }

      _selectionOverlayVisible = true;
      _selectionOverlayMinimized = false;
      _rebuildSelectionRegex();
    });
  }

  void _rebuildSelectionRegex() {
    if (_selectionSamples.isEmpty) {
      _selectionRegexPattern = null;
      _selectionRegex = null;
      _selectionPotentialMatches = 0;
      _selectionKey = null;
      return;
    }

    final first = _selectionSamples.first;

    final result = buildRegexFromSampleContext(
      fullText: first.fullText,
      selectionStart: first.start,
      selectionEnd: first.end,
    );

    _selectionKey = result.key;
    _selectionRegexPattern = result.pattern;
    _selectionIsEmail = result.isEmail;
    _selectionIsAddress = result.isAddress;
    _normalizeDigits = !(_selectionIsEmail || _selectionIsAddress);

    try {
      _selectionRegex = RegExp(
        _selectionRegexPattern!,
        caseSensitive: false,
      );
    } catch (_) {
      _selectionRegexPattern = null;
      _selectionRegex = null;
      _selectionPotentialMatches = 0;
      return;
    }

    _recountSelectionMatches();
  }

  void _recountSelectionMatches() {
    if (_selectionRegex == null || _selectionBaseColumn == null) {
      _selectionPotentialMatches = 0;
      return;
    }

    final formState = widget.formState;
    final cols = formState.previewColumns;
    final rows = formState.previewData;

    final List<String> targetColumns =
        _selectionApplyToAllColumns ? cols : [_selectionBaseColumn!];

    int count = 0;
    for (final row in rows) {
      for (final colName in targetColumns) {
        final colIndex = cols.indexOf(colName);
        if (colIndex == -1) continue;
        final text = colIndex < row.length ? row[colIndex] : '';
        if (_selectionRegex!.hasMatch(text)) {
          count++;
        }
      }
    }

    _selectionPotentialMatches = count;
  }

  void _resetSelectionState({bool keepOverlayVisible = false}) {
    _selectionSamples = [];
    _selectionBaseColumn = null;
    _selectionRegexPattern = null;
    _selectionRegex = null;
    _selectionPotentialMatches = 0;
    _selectionNewColumnCtrl.clear();
    _selectionApplyToAllColumns = false;
    _selectionKey = null;
    _targetIncludeKey = false;
    _stripSourceValue = false;
    _stripSourceKey = false;
    _stripLeadingSeparator = false;
    _stripTrailingSeparator = false;
    _selectionOverlayOffset = Offset.zero;
    _selectionOverlayMinimized = false;
    _highlightAllMatches = false;
    _selectionOutputMode = OutputMode.replaceSource;
    _selectionExistingColumn = null;
    _selectionOverlayVisible =
        keepOverlayVisible ? _selectionOverlayVisible : false;
    _selectionIsEmail = false;
    _selectionIsAddress = false;
    _normalizeDigits = true;
  }

  void _removeSingleSample(RegexSelectionSample sample) {
    setState(() {
      _selectionSamples = _selectionSamples
          .where((s) =>
              !(s.columnName == sample.columnName &&
                  s.fullText == sample.fullText &&
                  s.start == sample.start &&
                  s.end == sample.end))
          .toList();
      if (_selectionSamples.isEmpty) {
        _resetSelectionState();
      } else {
        _rebuildSelectionRegex();
      }
    });
  }

  String _computeOutputName(String sourceCol) {
    switch (_selectionOutputMode) {
      case OutputMode.replaceSource:
        return sourceCol;
      case OutputMode.newColumn:
        final manual = _selectionNewColumnCtrl.text.trim();
        if (manual.isNotEmpty) return manual;
        if (_selectionKey != null && _selectionKey!.isNotEmpty) {
          return _selectionKey!.toLowerCase();
        }
        if (_selectionIsEmail) return 'email';
        if (_selectionIsAddress) return 'address';
        return '${sourceCol}_regex';
      case OutputMode.existingColumn:
        if (_selectionExistingColumn != null &&
            _selectionExistingColumn!.trim().isNotEmpty) {
          return _selectionExistingColumn!.trim();
        }
        return sourceCol;
    }
  }

  void _applySelectionRegex() {
    if (_selectionRegexPattern == null || _selectionBaseColumn == null) {
      return;
    }

    final formNotifier = widget.formNotifier;
    final formState = widget.formState;
    final columns = formState.previewColumns;

    if (_selectionApplyToAllColumns &&
        _selectionOutputMode == OutputMode.existingColumn) {
      _selectionOutputMode = OutputMode.newColumn;
    }

    final String pattern = _selectionRegexPattern!;
    final String baseCol = _selectionBaseColumn!;

    final Iterable<String> targetColumns =
        _selectionApplyToAllColumns ? columns : [baseCol];

    final nowId = DateTime.now().microsecondsSinceEpoch;

    final bool multiSourceToOne =
        _selectionApplyToAllColumns &&
            _selectionOutputMode != OutputMode.replaceSource;

    final bool shouldNormalizeDigits =
        _normalizeDigits && !_selectionIsEmail && !_selectionIsAddress;

    for (final col in targetColumns) {
      if (_selectionOutputMode == OutputMode.replaceSource) {
        formNotifier.removeTransformsForSource(col);
      }

      final outputName = _computeOutputName(col);

      final extractRule = ColumnTransformRule(
        id: 'tr_${nowId}_${col}_selregex_extract',
        sourceColumn: col,
        outputColumn: outputName,
        transform: TransformType.regex,
        regexPattern: pattern,
        regexGroup: _targetIncludeKey ? 0 : 1,
        skipIfNoMatch: multiSourceToOne,
        regexNormalizeDigits: shouldNormalizeDigits,
      );

      formNotifier.addTransformRule(extractRule);

      final bool shouldStripFromSource =
          _selectionOutputMode != OutputMode.replaceSource &&
              (_stripSourceValue ||
                  _stripSourceKey ||
                  _stripLeadingSeparator ||
                  _stripTrailingSeparator);

      if (shouldStripFromSource) {
        final stripRule = ColumnTransformRule(
          id: 'tr_${nowId}_${col}_selregex_strip',
          sourceColumn: col,
          outputColumn: col,
          transform: TransformType.regex,
          regexPattern: pattern,
          regexGroup: 1,
          regexStripSourceValue: _stripSourceValue,
          regexStripSourceKey: _stripSourceKey,
          regexStripLeadingSeparator: _stripLeadingSeparator,
          regexStripTrailingSeparator: _stripTrailingSeparator,
          skipIfNoMatch: false,
        );
        formNotifier.addTransformRule(stripRule);
      }
    }

    setState(() {
      _resetSelectionState();
    });
  }

  String _selectionTypeLabel() {
    if (_selectionIsEmail) return 'Email'.tr;
    if (_selectionIsAddress) return 'Adres'.tr;
    if (_selectionKey != null && _selectionKey!.isNotEmpty) {
      return 'Wartość po kluczu "$_selectionKey"'.tr;
    }
    return 'Dokładnie zaznaczony fragment'.tr;
  }

  Widget _buildSamplePreview(
    RegexSelectionSample s,
    ThemeColors theme,
  ) {
    final text = s.fullText;
    final start = s.start.clamp(0, text.length);
    final end = s.end.clamp(0, text.length);

    final selectedText =
        (end > start) ? text.substring(start, end) : '';

    final before = (end > start) ? text.substring(0, start) : text;
    final middle = selectedText;
    final after = (end > start) ? text.substring(end) : '';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dashboardBoarder.withAlpha(110),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.adPopBackground,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: theme.dashboardBoarder.withAlpha(100),
                  ),
                ),
                child: Text(
                  'Kolumna: ${s.columnName}',
                  style: TextStyle(
                    color: theme.textColor.withAlpha(210),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (selectedText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(30),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.amber.withAlpha(130),
                    ),
                  ),
                  child: Text(
                    'Zaznaczono: ${selectedText.length} znaków',
                    style: TextStyle(
                      color: theme.textColor.withAlpha(220),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Dokładnie zaznaczony fragment'.tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(165),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha(18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.amber.withAlpha(110),
              ),
            ),
            child: Text(
              selectedText.isEmpty ? '— brak zaznaczenia —'.tr : selectedText,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Cała komórka'.tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(165),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.adPopBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.dashboardBoarder.withAlpha(100),
              ),
            ),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: before,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(180),
                      fontSize: 11,
                    ),
                  ),
                  if (middle.isNotEmpty)
                    TextSpan(
                      text: middle,
                      style: TextStyle(
                        color: theme.textColor,
                        backgroundColor: Colors.amber.withAlpha(85),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  TextSpan(
                    text: after,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(180),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 16,
              padding: EdgeInsets.zero,
              onPressed: () => _removeSingleSample(s),
              icon: Icon(
                Icons.close_rounded,
                color: theme.textColor.withAlpha(178),
              ),
              tooltip: 'Usuń to zaznaczenie'.tr,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultPreview(ThemeColors theme) {
    if (_selectionRegexPattern == null || _selectionSamples.isEmpty) {
      return const SizedBox.shrink();
    }

    final previewItems = _selectionSamples.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Podgląd: co wyciągniemy i co zostanie'.tr,
          style: TextStyle(
            color: theme.textColor.withAlpha(230),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: previewItems.map((sample) {
            final source = sample.fullText;

            final extractRule = ColumnTransformRule(
              id: 'preview_extract',
              sourceColumn: sample.columnName,
              outputColumn: _computeOutputName(sample.columnName),
              transform: TransformType.regex,
              regexPattern: _selectionRegexPattern!,
              regexGroup: _targetIncludeKey ? 0 : 1,
              regexNormalizeDigits:
                  _normalizeDigits && !_selectionIsEmail && !_selectionIsAddress,
            );

            final extracted = applyTransformRuleValue(extractRule, source);

            String sourceAfter = source;
            final shouldStrip =
                _selectionOutputMode != OutputMode.replaceSource &&
                    (_stripSourceValue ||
                        _stripSourceKey ||
                        _stripLeadingSeparator ||
                        _stripTrailingSeparator);

            if (shouldStrip) {
              final stripRule = ColumnTransformRule(
                id: 'preview_strip',
                sourceColumn: sample.columnName,
                outputColumn: sample.columnName,
                transform: TransformType.regex,
                regexPattern: _selectionRegexPattern!,
                regexGroup: 1,
                regexStripSourceValue: _stripSourceValue,
                regexStripSourceKey: _stripSourceKey,
                regexStripLeadingSeparator: _stripLeadingSeparator,
                regexStripTrailingSeparator: _stripTrailingSeparator,
              );
              sourceAfter = applyTransformRuleValue(stripRule, source);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
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
                    'Źródło'.tr,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(160),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    source,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Wyciągnięta wartość'.tr,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(160),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    extracted.isEmpty ? '— brak dopasowania —'.tr : extracted,
                    style: TextStyle(
                      color: extracted.isEmpty
                          ? theme.textColor.withAlpha(140)
                          : theme.themeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (shouldStrip) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Źródło po strip'.tr,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(160),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sourceAfter.isEmpty ? '— pusto —'.tr : sourceAfter,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required ThemeColors theme,
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? theme.themeColor.withAlpha(22)
              : theme.dashboardContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? theme.themeColor.withAlpha(140)
                : theme.dashboardBoarder.withAlpha(100),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? theme.themeColor : theme.textColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(170),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSelectionOverlay(
    BuildContext context,
    ThemeColors theme,
  ) {
    if (!_selectionOverlayVisible || _selectionRegexPattern == null) {
      return const SizedBox.shrink();
    }

    final baseCol = _selectionBaseColumn ?? '';
    final previewColumns = widget.formState.previewColumns;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    if (_selectionOverlayMinimized) {
      return Align(
        alignment: Alignment.bottomRight,
        child: Transform.translate(
          offset: _selectionOverlayOffset,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16, right: 16),
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _selectionOverlayOffset += details.delta;
                });
              },
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectionOverlayMinimized = false;
                  });
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.dashboardContainer,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.dashboardBoarder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(64),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_fix_high_rounded,
                        size: 18,
                        color: theme.themeColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Wyciągnij wartość · $_selectionPotentialMatches'.tr,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.bottomRight,
      child: Transform.translate(
        offset: _selectionOverlayOffset,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16, right: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 700,
              maxHeight: maxHeight,
            ),
            child: Material(
              borderRadius: BorderRadius.circular(16),
              color: theme.adPopBackground,
              elevation: 14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _selectionOverlayOffset += details.delta;
                          });
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_fix_high_rounded,
                              color: theme.themeColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Wyciągnij wartość z zaznaczenia'.tr,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.remove_rounded,
                                color: theme.textColor.withAlpha(178),
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectionOverlayMinimized = true;
                                });
                              },
                              tooltip: 'Zminimalizuj'.tr,
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: theme.textColor.withAlpha(178),
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  _resetSelectionState();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

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
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _overlayInfoChip(
                              theme,
                              Icons.label_rounded,
                              _selectionTypeLabel(),
                            ),
                            if (_selectionKey != null &&
                                _selectionKey!.isNotEmpty)
                              _overlayInfoChip(
                                theme,
                                Icons.key_rounded,
                                'Klucz: $_selectionKey'.tr,
                              ),
                            _overlayInfoChip(
                              theme,
                              Icons.filter_alt_rounded,
                              'Dopasowania: $_selectionPotentialMatches'.tr,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Twoje zaznaczenia'.tr,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(230),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: _selectionSamples
                            .map((s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildSamplePreview(s, theme),
                                ))
                            .toList(),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Gdzie zastosować?'.tr,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(230),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildModeCard(
                        theme: theme,
                        selected: !_selectionApplyToAllColumns,
                        icon: Icons.filter_1_rounded,
                        title: 'Tylko kolumna "$baseCol"'.tr,
                        subtitle: 'Bezpieczna opcja — działa tylko tu.'.tr,
                        onTap: () {
                          setState(() {
                            _selectionApplyToAllColumns = false;
                            _recountSelectionMatches();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildModeCard(
                        theme: theme,
                        selected: _selectionApplyToAllColumns,
                        icon: Icons.view_column_rounded,
                        title: 'Wszystkie kolumny'.tr,
                        subtitle: 'Szuka tego samego wzorca w całym preview.'.tr,
                        onTap: () {
                          setState(() {
                            _selectionApplyToAllColumns = true;
                            _recountSelectionMatches();
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Gdzie zapisać wynik?'.tr,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(230),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildModeCard(
                        theme: theme,
                        selected:
                            _selectionOutputMode == OutputMode.replaceSource,
                        icon: Icons.sync_alt_rounded,
                        title: 'Nadpisz bieżącą kolumnę'.tr,
                        subtitle: 'Najprostsza opcja — wynik zastąpi źródło.'.tr,
                        onTap: () {
                          setState(() {
                            _selectionOutputMode = OutputMode.replaceSource;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildModeCard(
                        theme: theme,
                        selected: _selectionOutputMode == OutputMode.newColumn,
                        icon: Icons.add_box_rounded,
                        title: 'Zapisz do nowej kolumny'.tr,
                        subtitle: 'Bezpieczna opcja — źródło zostaje nietknięte.'.tr,
                        onTap: () {
                          setState(() {
                            _selectionOutputMode = OutputMode.newColumn;
                          });
                        },
                      ),
                      if (_selectionOutputMode == OutputMode.newColumn) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _selectionNewColumnCtrl,
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: theme.dashboardContainer,
                            labelText: 'Nazwa nowej kolumny'.tr,
                            labelStyle: TextStyle(
                              color: theme.textColor.withAlpha(160),
                              fontSize: 11,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      _buildModeCard(
                        theme: theme,
                        selected:
                            _selectionOutputMode == OutputMode.existingColumn,
                        icon: Icons.move_down_rounded,
                        title: 'Zapisz do istniejącej kolumny'.tr,
                        subtitle:
                            'Przydatne, gdy chcesz uzupełnić inną kolumnę.'.tr,
                        onTap: () {
                          setState(() {
                            _selectionOutputMode = OutputMode.existingColumn;
                          });
                        },
                      ),
                      if (_selectionOutputMode == OutputMode.existingColumn) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectionExistingColumn,
                          dropdownColor: theme.dashboardContainer,
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: theme.dashboardContainer,
                            labelText: 'Wybierz kolumnę docelową'.tr,
                            labelStyle: TextStyle(
                              color: theme.textColor.withAlpha(160),
                              fontSize: 11,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: previewColumns
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c,
                                    style: TextStyle(
                                      color: theme.textColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectionExistingColumn = val;
                            });
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Uwaga: zapis do istniejącej kolumny nadpisze jej obecną wartość.'
                              .tr,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(165),
                            fontSize: 11,
                          ),
                        ),
                      ],

                      if (_selectionOutputMode != OutputMode.replaceSource) ...[
                        const SizedBox(height: 12),
                        if (!_selectionIsEmail && !_selectionIsAddress)
                          SwitchListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Ujednolicaj cyfry (usuń spacje i myślniki)'.tr,
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 12,
                              ),
                            ),
                            subtitle: Text(
                              'Przydatne dla NIP, REGON, telefonów i numerów.'
                                  .tr,
                              style: TextStyle(
                                color: theme.textColor.withAlpha(170),
                                fontSize: 11,
                              ),
                            ),
                            value: _normalizeDigits,
                            onChanged: (v) {
                              setState(() {
                                _normalizeDigits = v ?? false;
                              });
                            },
                          ),
                        if (_selectionKey != null &&
                            _selectionKey!.isNotEmpty)
                          SwitchListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Dołącz klucz do wyniku'.tr,
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 12,
                              ),
                            ),
                            subtitle: Text(
                              _targetIncludeKey
                                  ? 'Wynik będzie np. "NIP 1234567890".'.tr
                                  : 'Wynik będzie samą wartością, np. "1234567890".'
                                      .tr,
                              style: TextStyle(
                                color: theme.textColor.withAlpha(170),
                                fontSize: 11,
                              ),
                            ),
                            value: _targetIncludeKey,
                            onChanged: (v) {
                              setState(() {
                                _targetIncludeKey = v ?? false;
                              });
                            },
                          ),
                        const SizedBox(height: 8),
                        SelectionStripOptions(
                          theme: theme,
                          selectionKey: _selectionKey,
                          stripSourceValue: _stripSourceValue,
                          stripSourceKey: _stripSourceKey,
                          stripLeadingSeparator: _stripLeadingSeparator,
                          stripTrailingSeparator: _stripTrailingSeparator,
                          onStripSourceValueChanged: (v) {
                            setState(() {
                              _stripSourceValue = v;
                            });
                          },
                          onStripSourceKeyChanged: (v) {
                            setState(() {
                              _stripSourceKey = v;
                            });
                          },
                          onStripLeadingSeparatorChanged: (v) {
                            setState(() {
                              _stripLeadingSeparator = v;
                            });
                          },
                          onStripTrailingSeparatorChanged: (v) {
                            setState(() {
                              _stripTrailingSeparator = v;
                            });
                          },
                        ),
                      ],

                      const SizedBox(height: 12),

                      _buildResultPreview(theme),

                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: elevatedButtonStyleRounded10,
                            onPressed: () {
                              setState(() {
                                _resetSelectionState();
                              });
                            },
                            child: Text(
                              'Anuluj'.tr,
                              style: TextStyle(
                                color: theme.textColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: buttonStyleRounded10ThemeRedWithPadding15,
                            onPressed: _applySelectionRegex,
                            icon: const Icon(
                              Icons.check_rounded,
                              color: AppColors.white,
                            ),
                            label: Text(
                              'Zastosuj'.tr,
                              style: const TextStyle(
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _overlayInfoChip(
    ThemeColors theme,
    IconData icon,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.dashboardBoarder.withAlpha(110),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.themeColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}