import 'package:docs/provider/document_page_setup_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';

class DocumentPageSetupDialog extends StatefulWidget {
  final DocumentPageSetup initial;
  final ThemeColors theme;

  const DocumentPageSetupDialog({
    super.key,
    required this.initial,
    required this.theme,
  });

  @override
  State<DocumentPageSetupDialog> createState() =>
      _DocumentPageSetupDialogState();
}

class _DocumentPageSetupDialogState extends State<DocumentPageSetupDialog> {
  late DocumentPageSetup _draft;

  static const DocumentPageMargins _normalMargins = DocumentPageMargins(
    topMm: 25.4,
    rightMm: 25.4,
    bottomMm: 25.4,
    leftMm: 25.4,
  );

  static const DocumentPageMargins _narrowMargins = DocumentPageMargins(
    topMm: 12.7,
    rightMm: 12.7,
    bottomMm: 12.7,
    leftMm: 12.7,
  );

  static const DocumentPageMargins _moderateMargins = DocumentPageMargins(
    topMm: 25.4,
    rightMm: 19.1,
    bottomMm: 25.4,
    leftMm: 19.1,
  );

  static const DocumentPageMargins _wideMargins = DocumentPageMargins(
    topMm: 25.4,
    rightMm: 50.8,
    bottomMm: 25.4,
    leftMm: 50.8,
  );

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  void _updateDraft(DocumentPageSetup value) {
    setState(() {
      _draft = value;
    });
  }

  void _updateMargins(DocumentPageMargins margins) {
    _updateDraft(
      _draft.copyWith(
        margins: _sanitizeMargins(margins),
      ),
    );
  }

  DocumentPageMargins _sanitizeMargins(DocumentPageMargins margins) {
    final maxHorizontal = (_draft.widthMm - 20).clamp(10.0, 120.0).toDouble();
    final maxVertical = (_draft.heightMm - 20).clamp(10.0, 120.0).toDouble();

    final left = margins.leftMm.clamp(0.0, maxHorizontal).toDouble();
    final right = margins.rightMm.clamp(0.0, maxHorizontal).toDouble();
    final top = margins.topMm.clamp(0.0, maxVertical).toDouble();
    final bottom = margins.bottomMm.clamp(0.0, maxVertical).toDouble();

    final horizontalSum = left + right;
    final verticalSum = top + bottom;

    if (horizontalSum > _draft.widthMm - 10) {
      final ratio = (_draft.widthMm - 10) / horizontalSum;

      return DocumentPageMargins(
        topMm: verticalSum > _draft.heightMm - 10
            ? top * ((_draft.heightMm - 10) / verticalSum)
            : top,
        rightMm: right * ratio,
        bottomMm: verticalSum > _draft.heightMm - 10
            ? bottom * ((_draft.heightMm - 10) / verticalSum)
            : bottom,
        leftMm: left * ratio,
      );
    }

    if (verticalSum > _draft.heightMm - 10) {
      final ratio = (_draft.heightMm - 10) / verticalSum;

      return DocumentPageMargins(
        topMm: top * ratio,
        rightMm: right,
        bottomMm: bottom * ratio,
        leftMm: left,
      );
    }

    return DocumentPageMargins(
      topMm: top,
      rightMm: right,
      bottomMm: bottom,
      leftMm: left,
    );
  }

  String _orientationLabel(DocumentPageOrientation orientation) {
    switch (orientation) {
      case DocumentPageOrientation.portrait:
        return 'Pionowa';
      case DocumentPageOrientation.landscape:
        return 'Pozioma';
    }
  }

  IconData _orientationIcon(DocumentPageOrientation orientation) {
    switch (orientation) {
      case DocumentPageOrientation.portrait:
        return Icons.stay_current_portrait_outlined;
      case DocumentPageOrientation.landscape:
        return Icons.stay_current_landscape_outlined;
    }
  }

  String _mm(double value) {
    return '${value.toStringAsFixed(1)} mm';
  }

  ThemeData _dialogTheme(BuildContext context) {
    final base = Theme.of(context);
    final theme = widget.theme;

    final textTheme = base.textTheme.apply(
      bodyColor: theme.textColor,
      displayColor: theme.textColor,
    );

    return base.copyWith(
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        surface: theme.dashboardContainer,
        onSurface: theme.textColor,
        primary: theme.themeColor,
      ),
      canvasColor: theme.dashboardContainer,
      cardColor: theme.dashboardContainer,
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: theme.dashboardContainer,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: theme.adPopBackground,
        labelStyle: TextStyle(
          color: theme.textColor.withAlpha(170),
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(
          color: theme.textColor.withAlpha(110),
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dashboardBoarder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.themeColor, width: 1.4),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dashboardBoarder),
        ),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: theme.themeColor,
        inactiveTrackColor: theme.dashboardBoarder,
        thumbColor: theme.themeColor,
        overlayColor: theme.themeColor.withAlpha(35),
        valueIndicatorColor: theme.themeColor,
        valueIndicatorTextStyle: TextStyle(
          color: theme.themeColorText,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Theme(
      data: _dialogTheme(context),
      child: AlertDialog(
        backgroundColor: theme.dashboardContainer,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: theme.dashboardBoarder),
        ),
        titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
        contentPadding: const EdgeInsets.fromLTRB(22, 10, 22, 8),
        actionsPadding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        title: Row(
          children: [
            Icon(
              Icons.tune_outlined,
              color: theme.textColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ustawienia strony',
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 760,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 680;

              final children = [
                Expanded(
                  flex: isNarrow ? 0 : 6,
                  child: _buildSettingsPanel(),
                ),
                SizedBox(width: isNarrow ? 0 : 20, height: isNarrow ? 18 : 0),
                Expanded(
                  flex: isNarrow ? 0 : 4,
                  child: _buildPreviewPanel(),
                ),
              ];

              if (isNarrow) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: children
                        .map(
                          (child) => child is Expanded ? child.child : child,
                        )
                        .toList(),
                  ),
                );
              }

              return SizedBox(
                height: 560,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            style: TextButton.styleFrom(
              foregroundColor: theme.textColor,
            ),
            child: Text(
              'Cancel'.tr,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _draft = DocumentPageSetup.a4Default;
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.textColor,
            ),
            child: Text(
              'Reset A4',
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(_draft),
            icon: const Icon(Icons.check),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.themeColor,
              foregroundColor: theme.themeColorText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            label: Text(
              'Zastosuj',
              style: TextStyle(
                color: theme.themeColorText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(
            icon: Icons.description_outlined,
            title: 'Papier',
          ),
          const SizedBox(height: 10),
          _buildPaperControls(),
          const SizedBox(height: 22),
          _buildSectionTitle(
            icon: Icons.border_outer_outlined,
            title: 'Marginesy',
          ),
          const SizedBox(height: 10),
          _buildMarginPresets(),
          const SizedBox(height: 14),
          _buildMarginSliders(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
  }) {
    final theme = widget.theme;

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.textColor.withAlpha(170),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPaperControls() {
    final theme = widget.theme;

    return Column(
      children: [
        DropdownButtonFormField<DocumentPaperSize>(
          value: _draft.paperSize,
          dropdownColor: theme.dashboardContainer,
          iconEnabledColor: theme.textColor,
          decoration: const InputDecoration(
            labelText: 'Rozmiar papieru',
            prefixIcon: Icon(Icons.article_outlined),
          ),
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.w800,
          ),
          items: DocumentPaperSize.values.map((size) {
            return DropdownMenuItem<DocumentPaperSize>(
              value: size,
              child: Text(
                '${size.spec.label} — ${size.spec.widthMm.toStringAsFixed(0)} × ${size.spec.heightMm.toStringAsFixed(0)} mm',
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            _updateDraft(
              _draft.copyWith(
                paperSize: value,
                margins: _sanitizeMargins(_draft.margins),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<DocumentPageOrientation>(
          value: _draft.orientation,
          dropdownColor: theme.dashboardContainer,
          iconEnabledColor: theme.textColor,
          decoration: const InputDecoration(
            labelText: 'Orientacja',
            prefixIcon: Icon(Icons.screen_rotation_alt_outlined),
          ),
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.w800,
          ),
          items: DocumentPageOrientation.values.map((orientation) {
            return DropdownMenuItem<DocumentPageOrientation>(
              value: orientation,
              child: Row(
                children: [
                  Icon(
                    _orientationIcon(orientation),
                    size: 17,
                    color: theme.textColor.withAlpha(170),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _orientationLabel(orientation),
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            _updateDraft(
              _draft.copyWith(
                orientation: value,
                margins: _sanitizeMargins(_draft.margins),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMarginPresets() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildPresetChip(
          label: 'Normalne',
          margins: _normalMargins,
        ),
        _buildPresetChip(
          label: 'Wąskie',
          margins: _narrowMargins,
        ),
        _buildPresetChip(
          label: 'Umiarkowane',
          margins: _moderateMargins,
        ),
        _buildPresetChip(
          label: 'Szerokie',
          margins: _wideMargins,
        ),
      ],
    );
  }

  Widget _buildPresetChip({
    required String label,
    required DocumentPageMargins margins,
  }) {
    final theme = widget.theme;
    final selected = _isSameMargins(_draft.margins, margins);

    return Material(
      color: selected ? theme.themeColor : theme.adPopBackground,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () => _updateMargins(margins),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? theme.themeColor : theme.dashboardBoarder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? theme.themeColorText : theme.textColor,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  bool _isSameMargins(
    DocumentPageMargins a,
    DocumentPageMargins b,
  ) {
    bool same(double x, double y) => (x - y).abs() < 0.2;

    return same(a.topMm, b.topMm) &&
        same(a.rightMm, b.rightMm) &&
        same(a.bottomMm, b.bottomMm) &&
        same(a.leftMm, b.leftMm);
  }

  Widget _buildMarginSliders() {
    final margins = _draft.margins;

    return Column(
      children: [
        _MarginSlider(
          label: 'Górny',
          icon: Icons.vertical_align_top_outlined,
          value: margins.topMm,
          max: _maxVerticalMargin,
          theme: widget.theme,
          onChanged: (value) {
            _updateMargins(
              margins.copyWith(topMm: value),
            );
          },
        ),
        _MarginSlider(
          label: 'Dolny',
          icon: Icons.vertical_align_bottom_outlined,
          value: margins.bottomMm,
          max: _maxVerticalMargin,
          theme: widget.theme,
          onChanged: (value) {
            _updateMargins(
              margins.copyWith(bottomMm: value),
            );
          },
        ),
        _MarginSlider(
          label: 'Lewy',
          icon: Icons.align_horizontal_left_outlined,
          value: margins.leftMm,
          max: _maxHorizontalMargin,
          theme: widget.theme,
          onChanged: (value) {
            _updateMargins(
              margins.copyWith(leftMm: value),
            );
          },
        ),
        _MarginSlider(
          label: 'Prawy',
          icon: Icons.align_horizontal_right_outlined,
          value: margins.rightMm,
          max: _maxHorizontalMargin,
          theme: widget.theme,
          onChanged: (value) {
            _updateMargins(
              margins.copyWith(rightMm: value),
            );
          },
        ),
      ],
    );
  }

  double get _maxHorizontalMargin {
    return (_draft.widthMm * 0.42).clamp(20.0, 90.0).toDouble();
  }

  double get _maxVerticalMargin {
    return (_draft.heightMm * 0.35).clamp(20.0, 100.0).toDouble();
  }

  Widget _buildPreviewPanel() {
    final theme = widget.theme;

    return Container(
      decoration: BoxDecoration(
        color: theme.adPopBackground.withAlpha(95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.preview_outlined,
                size: 18,
                color: theme.textColor.withAlpha(170),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Podgląd',
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: _PaperPreview(
                setup: _draft,
                theme: theme,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_draft.paperSize.spec.label} • ${_draft.widthMm.toStringAsFixed(1)} × ${_draft.heightMm.toStringAsFixed(1)} mm',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textColor.withAlpha(170),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Marginesy: G ${_mm(_draft.margins.topMm)}, D ${_mm(_draft.margins.bottomMm)}, L ${_mm(_draft.margins.leftMm)}, P ${_mm(_draft.margins.rightMm)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textColor.withAlpha(130),
              fontWeight: FontWeight.w700,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarginSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final double max;
  final ThemeColors theme;
  final ValueChanged<double> onChanged;

  const _MarginSlider({
    required this.label,
    required this.icon,
    required this.value,
    required this.max,
    required this.theme,
    required this.onChanged,
  });

  String _formatted(double value) {
    return '${value.toStringAsFixed(1)} mm';
  }

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, max).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: theme.adPopBackground.withAlpha(95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 17,
                color: theme.textColor.withAlpha(165),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                width: 76,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.dashboardBoarder),
                ),
                child: Text(
                  _formatted(safeValue),
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: safeValue,
            min: 0,
            max: max,
            divisions: max.round(),
            label: _formatted(safeValue),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _PaperPreview extends StatelessWidget {
  final DocumentPageSetup setup;
  final ThemeColors theme;

  const _PaperPreview({
    required this.setup,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ratio = setup.widthMm / setup.heightMm;

        var height = constraints.maxHeight;
        var width = height * ratio;

        if (width > constraints.maxWidth) {
          width = constraints.maxWidth;
          height = width / ratio;
        }

        final scaleX = width / setup.widthMm;
        final scaleY = height / setup.heightMm;

        final left = setup.margins.leftMm * scaleX;
        final right = setup.margins.rightMm * scaleX;
        final top = setup.margins.topMm * scaleY;
        final bottom = setup.margins.bottomMm * scaleY;

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.black.withAlpha(55),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(45),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(left, top, right, bottom),
            child: Container(
              decoration: BoxDecoration(
                color: theme.themeColor.withAlpha(20),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: theme.themeColor.withAlpha(110),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.subject_outlined,
                  color: theme.themeColor.withAlpha(120),
                  size: 28,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}