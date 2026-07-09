import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';

import '../import_state.dart';
import 'mapping/regex.dart';

// ========================
// Draggable sheet transformacji
// ========================

enum _TransformMode { split, regex, constant }
enum _RegexValueMode { toEnd, toSpace, toComma, digitsOnly }

void openTransformDraggableSheet({
  required BuildContext context,
  required String columnName,
  required ThemeColors theme,
  required ImportFormState formState,
  required ImportFormNotifier formNotifier,
}) {
  final colIndex = formState.originalColumns.indexOf(columnName);
  if (colIndex == -1 || formState.originalData.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Brak danych do transformacji tej kolumny'.tr)),
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.48,
        maxChildSize: 0.97,
        builder: (sheetCtx, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 16,
                  offset: Offset(0, -4),
                  color: Colors.black26,
                ),
              ],
            ),
            child: _TransformSheetContent(
              theme: theme,
              columnName: columnName,
              formState: formState,
              formNotifier: formNotifier,
              scrollController: scrollController,
            ),
          );
        },
      );
    },
  );
}

class _TransformSheetContent extends StatefulWidget {
  final ThemeColors theme;
  final String columnName;
  final ImportFormState formState;
  final ImportFormNotifier formNotifier;
  final ScrollController scrollController;

  const _TransformSheetContent({
    required this.theme,
    required this.columnName,
    required this.formState,
    required this.formNotifier,
    required this.scrollController,
  });

  @override
  State<_TransformSheetContent> createState() =>
      _TransformSheetContentState();
}

class _TransformSheetContentState extends State<_TransformSheetContent> {
  _TransformMode _mode = _TransformMode.split;

  // Split
  late final TextEditingController _separatorController;
  List<String> _parts = [];
  List<bool> _selected = [];
  List<TextEditingController> _nameControllers = [];
  int? _currentIndex;

  // Regex
  final TextEditingController _regexKeyController =
      TextEditingController();
  final TextEditingController _regexPatternController =
      TextEditingController();
  final TextEditingController _regexGroupController =
      TextEditingController(text: '1');
  final TextEditingController _regexOutputNameController =
      TextEditingController();

  bool _regexReplaceCurrent = true;
  bool _regexExpertMode = false;
  bool _regexNormalizeDigits = false;
  _RegexValueMode _regexValueMode = _RegexValueMode.digitsOnly;
  String? _selectedQuickPresetId;

  // Const
  final TextEditingController _constValueController =
      TextEditingController();
  final TextEditingController _constOutputNameController =
      TextEditingController();
  bool _constReplaceCurrent = true;

  late final List<String> _columnSamples;

  @override
  void initState() {
    super.initState();

    _separatorController = TextEditingController(text: ' ');
    _columnSamples = _collectColumnSamples(maxItems: 12);

    final detected = detectKeywordSuggestionsFromSamples(_columnSamples);
    if (detected.isNotEmpty) {
      _regexKeyController.text = detected.first;
    }

    _separatorController.addListener(() {
      setState(_recomputeParts);
    });

    _regexKeyController.addListener(() {
      setState(() {
        if (!_regexExpertMode) {
          _selectedQuickPresetId = null;
        }
      });
    });

    _regexPatternController.addListener(() {
      if (_regexExpertMode && mounted) setState(() {});
    });

    _regexGroupController.addListener(() {
      if (_regexExpertMode && mounted) setState(() {});
    });

    _recomputeParts();
  }

  @override
  void dispose() {
    _separatorController.dispose();
    _disposeNameControllers();

    _regexKeyController.dispose();
    _regexPatternController.dispose();
    _regexGroupController.dispose();
    _regexOutputNameController.dispose();

    _constValueController.dispose();
    _constOutputNameController.dispose();
    super.dispose();
  }

  void _disposeNameControllers() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    _nameControllers = [];
  }

  List<String> _collectColumnSamples({int maxItems = 8}) {
    final colIndex =
        widget.formState.originalColumns.indexOf(widget.columnName);
    if (colIndex == -1) return [];

    final out = <String>[];
    for (final row in widget.formState.originalData) {
      final value = colIndex < row.length ? row[colIndex] : '';
      if (value.trim().isNotEmpty) {
        out.add(value);
        if (out.length >= maxItems) break;
      }
    }
    return out;
  }

  void _recomputeParts() {
    final colIndex =
        widget.formState.originalColumns.indexOf(widget.columnName);
    final firstNonEmpty = widget.formState.originalData.isNotEmpty
        ? widget.formState.originalData.firstWhere(
            (row) =>
                colIndex < row.length && row[colIndex].trim().isNotEmpty,
            orElse: () => widget.formState.originalData.first,
          )
        : <String>[];

    final sample = (firstNonEmpty.isNotEmpty && colIndex < firstNonEmpty.length)
        ? firstNonEmpty[colIndex]
        : '';

    final separator = _separatorController.text.isEmpty
        ? ' '
        : _separatorController.text;

    _parts = sample.split(separator);
    if (_parts.isEmpty) _parts = [''];

    _selected = List<bool>.filled(_parts.length, false);
    _currentIndex = null;

    _disposeNameControllers();
    _nameControllers = List.generate(
      _parts.length,
      (i) => TextEditingController(
        text: '${widget.columnName}_${i + 1}',
      ),
    );
  }

  List<RegexQuickPreset> _quickPresets() {
    return buildQuickRegexPresets(
      samples: _columnSamples,
      preferredKey: _regexKeyController.text.trim().isEmpty
          ? null
          : _regexKeyController.text.trim(),
    );
  }

  RegexQuickPreset? _selectedQuickPreset(List<RegexQuickPreset> presets) {
    if (_selectedQuickPresetId == null) return null;
    for (final p in presets) {
      if (p.id == _selectedQuickPresetId) return p;
    }
    return null;
  }

  String _buildAutoRegexPattern() {
    final rawKey = _regexKeyController.text.trim();
    if (rawKey.isEmpty) return '';
    final key = RegExp.escape(rawKey);

    switch (_regexValueMode) {
      case _RegexValueMode.toEnd:
        return '$key\\s*[:\\-–]?\\s*(.+)\$';
      case _RegexValueMode.toSpace:
        return '$key\\s*[:\\-–]?\\s*([^\\s]+)';
      case _RegexValueMode.toComma:
        return '$key\\s*[:\\-–]?\\s*([^,;]+)';
      case _RegexValueMode.digitsOnly:
        return '$key\\D*(\\d[\\d\\s-]*)';
    }
  }

  String _currentRegexPattern(List<RegexQuickPreset> presets) {
    if (_regexExpertMode) {
      return _regexPatternController.text.trim();
    }

    final quick = _selectedQuickPreset(presets);
    if (quick != null) return quick.pattern;

    return _buildAutoRegexPattern();
  }

  int _currentRegexGroup() {
    if (_regexExpertMode) {
      return int.tryParse(_regexGroupController.text.trim()) ?? 1;
    }
    return 1;
  }

  String _currentRegexOutputName(List<RegexQuickPreset> presets) {
    if (_regexReplaceCurrent) return widget.columnName;

    final manual = _regexOutputNameController.text.trim();
    if (manual.isNotEmpty) return manual;

    final quick = _selectedQuickPreset(presets);
    if (quick != null && quick.suggestedOutputName.trim().isNotEmpty) {
      return quick.suggestedOutputName;
    }

    if (_regexKeyController.text.trim().isNotEmpty) {
      return _regexKeyController.text.trim().toLowerCase();
    }

    return '${widget.columnName}_regex';
  }

  String _modeTitle() {
    switch (_mode) {
      case _TransformMode.split:
        return 'Podziel tekst'.tr;
      case _TransformMode.regex:
        return 'Wyciągnij wartość'.tr;
      case _TransformMode.constant:
        return 'Wstaw stałą wartość'.tr;
    }
  }

  String _modeDescription() {
    switch (_mode) {
      case _TransformMode.split:
        return 'Najlepsze, gdy jedna kolumna zawiera kilka części, np. imię i nazwisko.'
            .tr;
      case _TransformMode.regex:
        return 'Najlepsze do numerów, emaili, dat, adresów i wartości po słowie-kluczu.'
            .tr;
      case _TransformMode.constant:
        return 'Najlepsze, gdy chcesz ustawić jedną wartość dla wszystkich wierszy.'
            .tr;
    }
  }

  void _apply() {
    switch (_mode) {
      case _TransformMode.split:
        _applySplit();
        break;
      case _TransformMode.regex:
        _applyRegex();
        break;
      case _TransformMode.constant:
        _applyConst();
        break;
    }
  }

  void _applySplit() {
    widget.formNotifier.removeTransformsForSource(widget.columnName);

    final hasAnyExtra = _selected.any((e) => e);
    final effectiveCurrent = _currentIndex ?? (hasAnyExtra ? null : 0);

    if (effectiveCurrent != null &&
        effectiveCurrent >= 0 &&
        effectiveCurrent < _parts.length) {
      final rule = ColumnTransformRule(
        id: 'tr_${DateTime.now().microsecondsSinceEpoch}_main',
        sourceColumn: widget.columnName,
        outputColumn: widget.columnName,
        transform: TransformType.split,
        separator: _separatorController.text.isEmpty
            ? ' '
            : _separatorController.text,
        splitIndex: effectiveCurrent,
        takeRemainder: false,
      );
      widget.formNotifier.addTransformRule(rule);
    }

    for (var i = 0; i < _parts.length; i++) {
      if (!_selected[i]) continue;
      if (effectiveCurrent != null && effectiveCurrent == i) continue;

      final name = _nameControllers[i].text.trim().isEmpty
          ? '${widget.columnName}_${i + 1}'
          : _nameControllers[i].text.trim();

      final rule = ColumnTransformRule(
        id: 'tr_${DateTime.now().microsecondsSinceEpoch}_$i',
        sourceColumn: widget.columnName,
        outputColumn: name,
        transform: TransformType.split,
        separator: _separatorController.text.isEmpty
            ? ' '
            : _separatorController.text,
        splitIndex: i,
        takeRemainder: false,
      );

      widget.formNotifier.addTransformRule(rule);
    }

    Navigator.of(context).pop();
  }

  void _applyRegex() {
    final presets = _quickPresets();
    final pattern = _currentRegexPattern(presets);
    final group = _currentRegexGroup();

    if (pattern.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Najpierw wybierz preset, wpisz słowo-klucz albo regex.'.tr,
          ),
        ),
      );
      return;
    }

    widget.formNotifier.removeTransformsForSource(widget.columnName);

    final quick = _selectedQuickPreset(presets);
    final normalizeDigits =
        _regexNormalizeDigits || (quick?.normalizeDigits ?? false);

    final outputName = _currentRegexOutputName(presets);

    final rule = ColumnTransformRule(
      id: 'tr_${DateTime.now().microsecondsSinceEpoch}_regex',
      sourceColumn: widget.columnName,
      outputColumn: outputName,
      transform: TransformType.regex,
      regexPattern: pattern,
      regexGroup: group,
      regexNormalizeDigits: normalizeDigits,
    );

    widget.formNotifier.addTransformRule(rule);
    Navigator.of(context).pop();
  }

  void _applyConst() {
    final value = _constValueController.text;
    widget.formNotifier.removeTransformsForSource(widget.columnName);

    final outputName = _constReplaceCurrent
        ? widget.columnName
        : (_constOutputNameController.text.trim().isEmpty
            ? '${widget.columnName}_const'
            : _constOutputNameController.text.trim());

    final rule = ColumnTransformRule(
      id: 'tr_${DateTime.now().microsecondsSinceEpoch}_const',
      sourceColumn: widget.columnName,
      outputColumn: outputName,
      transform: TransformType.constant,
      constValue: value,
    );

    widget.formNotifier.addTransformRule(rule);
    Navigator.of(context).pop();
  }

  Widget _buildRegexPreview(ThemeColors theme) {
    if (_columnSamples.isEmpty) return const SizedBox.shrink();

    final presets = _quickPresets();
    final pattern = _currentRegexPattern(presets);
    if (pattern.isEmpty) return const SizedBox.shrink();

    RegExp? re;
    try {
      re = RegExp(pattern, caseSensitive: false);
    } catch (_) {
      re = null;
    }

    final groupIndex = _currentRegexGroup();

    final tempRule = ColumnTransformRule(
      id: 'preview_regex',
      sourceColumn: widget.columnName,
      outputColumn: _currentRegexOutputName(presets),
      transform: TransformType.regex,
      regexPattern: pattern,
      regexGroup: groupIndex,
      regexNormalizeDigits: _regexNormalizeDigits ||
          (_selectedQuickPreset(presets)?.normalizeDigits ?? false),
    );

    return _SectionCard(
      theme: theme,
      title: 'Podgląd wyniku'.tr,
      subtitle:
          'Sprawdź, czy system wyciąga dokładnie to, czego oczekujesz.'.tr,
      child: Column(
        children: [
          for (final text in _columnSamples.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RegexSampleRow(
                    text: text,
                    regex: re,
                    groupIndex: groupIndex,
                    base: TextStyle(
                      color: theme.textColor.withAlpha(210),
                      fontSize: 11,
                    ),
                    highlight: TextStyle(
                      color: theme.themeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.dashboardContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.dashboardBoarder.withAlpha(90),
                      ),
                    ),
                    child: Text(
                      'Wynik: ${applyTransformRuleValue(tempRule, text).isEmpty ? "— brak dopasowania —" : applyTransformRuleValue(tempRule, text)}'
                          .tr,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(220),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Text(
            'Jeśli chcesz również usuwać wyciągniętą wartość z kolumny źródłowej, zrób to z poziomu zaznaczenia w tabeli.'
                .tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(170),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitPreview(ThemeColors theme) {
    if (_columnSamples.isEmpty) return const SizedBox.shrink();

    final separator = _separatorController.text.isEmpty
        ? ' '
        : _separatorController.text;

    return _SectionCard(
      theme: theme,
      title: 'Podgląd podziału'.tr,
      subtitle: 'Zobacz, jak system rozbije przykładowe wartości.'.tr,
      child: Column(
        children: [
          for (final sample in _columnSamples.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sample,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: sample
                        .split(separator)
                        .map(
                          (part) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: theme.dashboardContainer,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.dashboardBoarder.withAlpha(90),
                              ),
                            ),
                            child: Text(
                              part.isEmpty ? '∅' : part,
                              style: TextStyle(
                                color: theme.textColor.withAlpha(220),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConstPreview(ThemeColors theme) {
    final value = _constValueController.text.trim();
    if (value.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      theme: theme,
      title: 'Podgląd wyniku'.tr,
      subtitle:
          'Taka wartość zostanie wpisana do wszystkich wierszy tej kolumny.'
              .tr,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.dashboardBoarder.withAlpha(90),
          ),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBox(ThemeColors theme) {
    String outputLabel;
    switch (_mode) {
      case _TransformMode.split:
        outputLabel =
            'Po zapisaniu kolumna zostanie podzielona według wybranego separatora.'
                .tr;
        break;
      case _TransformMode.regex:
        outputLabel =
            'Po zapisaniu system będzie wyciągał wskazaną wartość z tej kolumny.'
                .tr;
        break;
      case _TransformMode.constant:
        outputLabel =
            'Po zapisaniu wszystkie wartości w tej kolumnie zostaną ustawione na jedną stałą wartość.'
                .tr;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.themeColor.withAlpha(80),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: theme.themeColor,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              outputLabel,
              style: TextStyle(
                color: theme.textColor.withAlpha(220),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final presets = _quickPresets();
    final selectedPreset = _selectedQuickPreset(presets);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.textColor.withAlpha(76),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(
              children: [
                Text(
                  'Transformacja kolumny'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                _Pill(
                  text: widget.columnName,
                  background: theme.themeColor,
                  textColor: AppColors.white,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Wybierz, co chcesz zrobić z tą kolumną. Poniżej zobaczysz od razu podgląd efektu.'
                  .tr,
              style: TextStyle(
                color: theme.textColor.withAlpha(180),
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),

            _SectionCard(
              theme: theme,
              title: 'Krok 1 · Co chcesz zrobić?'.tr,
              subtitle:
                  'Wybierz typ transformacji. Dla większości userów najlepsze są gotowe ścieżki poniżej.'
                      .tr,
              child: Column(
                children: [
                  _ModeTile(
                    theme: theme,
                    title: 'Podziel tekst'.tr,
                    subtitle:
                        'Np. "Jan Kowalski" → imię i nazwisko'.tr,
                    icon: Icons.call_split_rounded,
                    isSelected: _mode == _TransformMode.split,
                    onTap: () {
                      setState(() {
                        _mode = _TransformMode.split;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  _ModeTile(
                    theme: theme,
                    title: 'Wyciągnij wartość'.tr,
                    subtitle:
                        'Np. email, telefon, NIP, data, kwota, adres'.tr,
                    icon: Icons.filter_alt_rounded,
                    isSelected: _mode == _TransformMode.regex,
                    onTap: () {
                      setState(() {
                        _mode = _TransformMode.regex;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  _ModeTile(
                    theme: theme,
                    title: 'Wstaw stałą wartość'.tr,
                    subtitle:
                        'Np. "PLN", "Polska", "aktywny"'.tr,
                    icon: Icons.push_pin_rounded,
                    isSelected: _mode == _TransformMode.constant,
                    onTap: () {
                      setState(() {
                        _mode = _TransformMode.constant;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            _SectionCard(
              theme: theme,
              title: 'Krok 2 · Ustawienia'.tr,
              subtitle: _modeDescription(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentModeHeader(theme),
                  const SizedBox(height: 14),
                  if (_mode == _TransformMode.split)
                    _buildSplitSection(theme)
                  else if (_mode == _TransformMode.regex)
                    _buildRegexSection(theme, presets, selectedPreset)
                  else
                    _buildConstSection(theme),
                ],
              ),
            ),

            const SizedBox(height: 14),
            _buildSummaryBox(theme),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: elevatedButtonStyleRounded10,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Anuluj'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: buttonStyleRounded10ThemeRedWithPadding15,
                  onPressed: _apply,
                  icon: const Icon(
                    Icons.save_rounded,
                    color: AppColors.white,
                  ),
                  label: Text(
                    'Zapisz transformację'.tr,
                    style: const TextStyle(color: AppColors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentModeHeader(ThemeColors theme) {
    return Row(
      children: [
        Icon(
          _mode == _TransformMode.split
              ? Icons.call_split_rounded
              : _mode == _TransformMode.regex
                  ? Icons.filter_alt_rounded
                  : Icons.push_pin_rounded,
          size: 18,
          color: theme.themeColor,
        ),
        const SizedBox(width: 8),
        Text(
          _modeTitle(),
          style: TextStyle(
            color: theme.textColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSplitSection(ThemeColors theme) {
    final separatorChips = <MapEntry<String, String>>[
      MapEntry('Spacja'.tr, ' '),
      MapEntry(','.tr, ','),
      MapEntry(';'.tr, ';'),
      MapEntry('|'.tr, '|'),
      MapEntry('TAB'.tr, '\t'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MiniStepLabel(
          theme: theme,
          text: '1. Wybierz separator'.tr,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _separatorController,
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.adPopBackground,
            labelText: 'Separator'.tr,
            labelStyle: TextStyle(
              color: theme.textColor.withAlpha(153),
              fontSize: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: separatorChips.map((entry) {
            final isSelected = _separatorController.text == entry.value;
            return ChoiceChip(
              label: Text(entry.key),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _separatorController.text = entry.value;
                  _recomputeParts();
                });
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 14),
        _buildSplitPreview(theme),

        const SizedBox(height: 14),
        _MiniStepLabel(
          theme: theme,
          text: '2. Zdecyduj, które części zachować'.tr,
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.adPopBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dashboardBoarder),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              for (var i = 0; i < _parts.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Radio<int>(
                        value: i,
                        groupValue: _currentIndex,
                        onChanged: (v) {
                          setState(() {
                            _currentIndex = v;
                          });
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        'Zostaw jako główną'.tr,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(178),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Checkbox(
                        value: _selected[i],
                        onChanged: (v) {
                          setState(() {
                            _selected[i] = v ?? false;
                          });
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        'Dodaj jako nową kolumnę'.tr,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(178),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.dashboardContainer,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.dashboardBoarder.withAlpha(90),
                            ),
                          ),
                          child: Text(
                            _parts[i].isEmpty ? '∅' : _parts[i],
                            style: TextStyle(
                              color: theme.textColor.withAlpha(230),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _nameControllers[i],
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: 'Nazwa nowej kolumny'.tr,
                            labelStyle: TextStyle(
                              color: theme.textColor.withAlpha(153),
                              fontSize: 11,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegexSection(
    ThemeColors theme,
    List<RegexQuickPreset> presets,
    RegexQuickPreset? selectedPreset,
  ) {
    String valueModeLabel(_RegexValueMode mode) {
      switch (mode) {
        case _RegexValueMode.toEnd:
          return 'Tekst do końca linii'.tr;
        case _RegexValueMode.toSpace:
          return 'Pierwszy fragment po słowie'.tr;
        case _RegexValueMode.toComma:
          return 'Tekst do przecinka'.tr;
        case _RegexValueMode.digitsOnly:
          return 'Cyfry po słowie-kluczu'.tr;
      }
    }

    final keywordSuggestions =
        detectKeywordSuggestionsFromSamples(_columnSamples);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MiniStepLabel(
          theme: theme,
          text: '1. Wybierz najszybszą ścieżkę'.tr,
        ),
        const SizedBox(height: 8),

        Text(
          'Gotowe presety'.tr,
          style: TextStyle(
            color: theme.textColor.withAlpha(230),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((preset) {
            final isSelected = _selectedQuickPresetId == preset.id;
            return ChoiceChip(
              label: Text(preset.label),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedQuickPresetId = preset.id;
                  if (preset.key != null && preset.key!.isNotEmpty) {
                    _regexKeyController.text = preset.key!;
                  }
                  _regexNormalizeDigits = preset.normalizeDigits;
                  if (!_regexReplaceCurrent &&
                      _regexOutputNameController.text.trim().isEmpty) {
                    _regexOutputNameController.text =
                        preset.suggestedOutputName;
                  }
                });
              },
            );
          }).toList(),
        ),

        if (selectedPreset != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.adPopBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dashboardBoarder),
            ),
            child: Text(
              '${selectedPreset.label}: ${selectedPreset.description}',
              style: TextStyle(
                color: theme.textColor.withAlpha(210),
                fontSize: 11,
              ),
            ),
          ),
        ],

        const SizedBox(height: 14),
        _MiniStepLabel(
          theme: theme,
          text: '2. Albo ustaw własną regułę prostą'.tr,
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: theme.adPopBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dashboardBoarder),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _regexKeyController,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: theme.dashboardContainer,
                  labelText: 'Słowo-klucz (np. NIP, REGON, TEL)'.tr,
                  labelStyle: TextStyle(
                    color: theme.textColor.withAlpha(153),
                    fontSize: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (keywordSuggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: keywordSuggestions.map((token) {
                    return ActionChip(
                      label: Text(token),
                      onPressed: () {
                        setState(() {
                          _regexKeyController.text = token;
                          _selectedQuickPresetId = null;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 10),
              DropdownButtonFormField<_RegexValueMode>(
                value: _regexValueMode,
                dropdownColor: theme.dashboardContainer,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: theme.dashboardContainer,
                  labelText: 'Co pobrać po słowie-kluczu?'.tr,
                  labelStyle: TextStyle(
                    color: theme.textColor.withAlpha(153),
                    fontSize: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: _RegexValueMode.values
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(
                          valueModeLabel(m),
                          style: TextStyle(color: theme.textColor),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() {
                    _regexValueMode = val;
                    _selectedQuickPresetId = null;
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Tryb zaawansowany (własny regex)'.tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(230),
              fontSize: 12,
            ),
          ),
          subtitle: Text(
            'Włącz tylko wtedy, gdy chcesz ręcznie wpisać pattern i numer grupy.'
                .tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(153),
              fontSize: 11,
            ),
          ),
          value: _regexExpertMode,
          onChanged: (v) {
            setState(() {
              _regexExpertMode = v;
            });
          },
        ),

        if (_regexExpertMode) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _regexPatternController,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.adPopBackground,
              labelText: 'Pattern'.tr,
              labelStyle: TextStyle(
                color: theme.textColor.withAlpha(153),
                fontSize: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 120,
            child: TextField(
              controller: _regexGroupController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.adPopBackground,
                labelText: 'Group'.tr,
                labelStyle: TextStyle(
                  color: theme.textColor.withAlpha(153),
                  fontSize: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 14),
        _MiniStepLabel(
          theme: theme,
          text: '3. Gdzie zapisać wynik?'.tr,
        ),
        const SizedBox(height: 8),

        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Nadpisz bieżącą kolumnę'.tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(204),
              fontSize: 12,
            ),
          ),
          subtitle: Text(
            'Wyłącz tę opcję, jeśli chcesz zachować oryginalną kolumnę i zapisać wynik do nowej.'
                .tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(165),
              fontSize: 11,
            ),
          ),
          value: _regexReplaceCurrent,
          onChanged: (v) {
            setState(() {
              _regexReplaceCurrent = v;
            });
          },
        ),
        if (!_regexReplaceCurrent)
          TextField(
            controller: _regexOutputNameController,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: theme.adPopBackground,
              labelText: 'Nazwa nowej kolumny'.tr,
              labelStyle: TextStyle(
                color: theme.textColor.withAlpha(153),
                fontSize: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

        const SizedBox(height: 8),

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
            'Przydatne dla NIP, REGON, telefonów i numerów.'.tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(165),
              fontSize: 11,
            ),
          ),
          value: _regexNormalizeDigits,
          onChanged: (v) {
            setState(() {
              _regexNormalizeDigits = v;
            });
          },
        ),

        const SizedBox(height: 12),
        _buildRegexPreview(theme),
      ],
    );
  }

  Widget _buildConstSection(ThemeColors theme) {
    final quickValues = [
      'PLN',
      'Polska'.tr,
      'aktywny'.tr,
      'tak'.tr,
      'nie'.tr,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MiniStepLabel(
          theme: theme,
          text: '1. Podaj wartość'.tr,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _constValueController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.adPopBackground,
            labelText: 'Wartość stała'.tr,
            labelStyle: TextStyle(
              color: theme.textColor.withAlpha(153),
              fontSize: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: quickValues.map((item) {
            return ActionChip(
              label: Text(item),
              onPressed: () {
                setState(() {
                  _constValueController.text = item;
                });
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 14),
        _MiniStepLabel(
          theme: theme,
          text: '2. Gdzie zapisać wynik?'.tr,
        ),
        const SizedBox(height: 8),

        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Nadpisz bieżącą kolumnę'.tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(204),
              fontSize: 12,
            ),
          ),
          subtitle: Text(
            'Wyłącz, jeśli chcesz zapisać tę wartość do nowej kolumny.'.tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(165),
              fontSize: 11,
            ),
          ),
          value: _constReplaceCurrent,
          onChanged: (v) {
            setState(() {
              _constReplaceCurrent = v;
            });
          },
        ),
        if (!_constReplaceCurrent)
          TextField(
            controller: _constOutputNameController,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: theme.adPopBackground,
              labelText: 'Nazwa nowej kolumny'.tr,
              labelStyle: TextStyle(
                color: theme.textColor.withAlpha(153),
                fontSize: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

        const SizedBox(height: 12),
        _buildConstPreview(theme),
      ],
    );
  }
}

class _RegexSampleRow extends StatelessWidget {
  final String text;
  final RegExp? regex;
  final int groupIndex;
  final TextStyle base;
  final TextStyle highlight;

  const _RegexSampleRow({
    required this.text,
    required this.regex,
    required this.groupIndex,
    required this.base,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    if (regex == null) {
      return Text(text, style: base);
    }

    final match = regex!.firstMatch(text);
    if (match == null) {
      return Text(
        text,
        style: base.copyWith(
          color: base.color?.withAlpha(128),
        ),
      );
    }

    String? captured;
    try {
      captured = match.group(groupIndex);
    } catch (_) {
      captured = null;
    }
    if (captured == null || captured.isEmpty) {
      return Text(text, style: base);
    }

    final start = text.indexOf(captured);
    if (start < 0) {
      return Text(text, style: base);
    }
    final end = start + captured.length;

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: text.substring(0, start), style: base),
          TextSpan(text: captured, style: highlight),
          TextSpan(text: text.substring(end), style: base),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final ThemeColors theme;
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({
    required this.theme,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dashboardBoarder.withAlpha(110),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                color: theme.textColor.withAlpha(170),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final ThemeColors theme;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTile({
    required this.theme,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.themeColor.withAlpha(18)
              : theme.dashboardContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? theme.themeColor.withAlpha(120)
                : theme.dashboardBoarder.withAlpha(90),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.themeColor.withAlpha(26)
                    : theme.adPopBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? theme.themeColor : theme.textColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(170),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              size: 18,
              color: isSelected
                  ? theme.themeColor
                  : theme.textColor.withAlpha(120),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStepLabel extends StatelessWidget {
  final ThemeColors theme;
  final String text;

  const _MiniStepLabel({
    required this.theme,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.subdirectory_arrow_right_rounded,
          size: 16,
          color: theme.themeColor,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color background;
  final Color textColor;

  const _Pill({
    required this.text,
    required this.background,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        color: background,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}