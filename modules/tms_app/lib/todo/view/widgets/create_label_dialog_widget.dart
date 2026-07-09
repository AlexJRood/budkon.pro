import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:tms_app/todo/provider/task_labels_provider.dart';
import 'package:tms_app/todo/view/model/task_label_model.dart';

class CreateLabelDialogWidget extends ConsumerStatefulWidget {
  final TaskLabel? editLabel;
  final bool isEditMode;

  const CreateLabelDialogWidget({
    super.key,
    this.editLabel,
    this.isEditMode = false,
  });

  static const _colors = [
    '#61bd4f',
    '#f2d600',
    '#ff9f1a',
    '#eb5a46',
    '#c377e0',
    '#0079bf',
    '#00c2e0',
    '#51e898',
    '#ff78cb',
    '#344563',
    '#ffab4a',
    '#6b778c',
    '#d29034',
    '#519839',
    '#b04632',
    '#89609e',
    '#cd5a91',
    '#4bbf6b',
    '#00aecc',
    '#838c91',
  ];

  @override
  ConsumerState<CreateLabelDialogWidget> createState() =>
      _CreateLabelDialogWidgetState();
}

class _CreateLabelDialogWidgetState
    extends ConsumerState<CreateLabelDialogWidget> {
  String _norm(String hex) {
    final h = hex.trim().toLowerCase();
    return h.startsWith('#') ? h : '#$h';
  }

  Color _colorFromHex(String hex) =>
      Color(int.parse(_norm(hex).replaceFirst('#', '0xff')));

  String _hexFromColor(Color c) =>
      '#${c.red.toRadixString(16).padLeft(2, '0')}${c.green.toRadixString(16).padLeft(2, '0')}${c.blue.toRadixString(16).padLeft(2, '0')}'
          .toUpperCase();

  Future<String?> _showCustomColorPicker({
    required BuildContext context,
    required ThemeColors theme,
    String? initialHex,
  }) async {
    final initial = initialHex ?? '#61bd4f';

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.adPopBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref2, _) {
            final inited = ref2.watch(pickerInitDoneProvider);
            if (!inited) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final hsv = HSVColor.fromColor(_colorFromHex(initial));
                final hex = _hexFromColor(hsv.toColor());
                ref2.read(pickerColorProvider.notifier).state = hsv;
                ref2.read(pickerHexProvider.notifier).state = hex;

                final ctrl = ref2.read(pickerHexTextControllerProvider);
                ctrl.text = hex;

                ref2.read(pickerInitDoneProvider.notifier).state = true;
              });
            }

            final hsv = ref2.watch(pickerColorProvider);
            final currentColor = hsv.toColor();
            final hexCtrl = ref2.watch(pickerHexTextControllerProvider);

            void syncHexFromHSV() {
              final hex = _hexFromColor(
                ref2.read(pickerColorProvider).toColor(),
              );
              ref2.read(pickerHexProvider.notifier).state = hex;
              if (hexCtrl.text.toUpperCase() != hex) {
                hexCtrl.value = hexCtrl.value.copyWith(
                  text: hex,
                  selection: TextSelection.collapsed(offset: hex.length),
                );
              }
            }

            void setHSV(HSVColor v) {
              ref2.read(pickerColorProvider.notifier).state = v;
              syncHexFromHSV();
            }

            void setFromHex(String s) {
              final cleaned = _norm(s);
              final ok = RegExp(r'^#([0-9a-fA-F]{6})$').hasMatch(cleaned);
              if (!ok) return;
              final color = _colorFromHex(cleaned);
              ref2
                  .read(pickerColorProvider.notifier)
                  .state = HSVColor.fromColor(color);

              final normalized = _hexFromColor(color);
              ref2.read(pickerHexProvider.notifier).state = normalized;

              if (hexCtrl.text.toUpperCase() != normalized) {
                hexCtrl.value = hexCtrl.value.copyWith(
                  text: normalized,
                  selection: TextSelection.collapsed(offset: normalized.length),
                );
              }
            }

            Widget _title(String t) => Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  t,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );

            Widget hsvSlider({
              required String label,
              required double value,
              required double min,
              required double max,
              int? divisions,
              required ValueChanged<double> onChanged,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        label == 'Hue'
                            ? value.toStringAsFixed(0)
                            : (value * 100).round().toString(),
                        style: TextStyle(
                          color: theme.textColor.withAlpha(204),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 10,
                      thumbColor: currentColor,
                      activeTrackColor: currentColor.withAlpha(230),
                      inactiveTrackColor: theme.textFieldColor,
                      overlayColor: currentColor.withAlpha(51),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10,
                      ),
                      trackShape: const RoundedRectSliderTrackShape(),
                    ),
                    child: Slider(
                      min: min,
                      max: max,
                      value: value.clamp(min, max).toDouble(),
                      divisions: divisions,
                      onChanged: onChanged,
                    ),
                  ),
                ],
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 10,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: theme.textColor.withAlpha(64),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Pick a color'.tr,
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        // Live preview chip
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: currentColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.dashboardBoarder,
                              width: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Quick swatches row
                    _title('Quick colors'.tr),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: CreateLabelDialogWidget._colors.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final hex = CreateLabelDialogWidget._colors[i];
                          final color = _colorFromHex(hex);
                          final selected =
                              _hexFromColor(color) ==
                                  _hexFromColor(currentColor);
                          return InkWell(
                            onTap: () => setHSV(HSVColor.fromColor(color)),
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                                boxShadow: [
                                  if (selected)
                                    BoxShadow(
                                      color: theme.themeColor.withAlpha(128),
                                      blurRadius: 8,
                                    ),
                                ],
                                border: Border.all(
                                  color: selected
                                      ? theme.themeColor
                                      : theme.dashboardBoarder,
                                  width: selected ? 3 : 1,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Hex input
                    _title('Hex'),
                    TextField(
                      controller: hexCtrl
                        ..text = hexCtrl.text.isEmpty
                            ? ref2.read(pickerHexProvider)
                            : hexCtrl.text,
                      style: TextStyle(color: theme.textColor),
                      cursorColor: theme.textColor,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.textFieldColor,
                        hintText: '#RRGGBB',
                        hintStyle: TextStyle(
                          color: theme.textColor.withAlpha(153),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onChanged: setFromHex,
                    ),

                    const SizedBox(height: 16),

                    // HSV sliders
                    _title('Adjust'.tr),
                    hsvSlider(
                      label: 'Hue',
                      value: hsv.hue,
                      min: 0,
                      max: 360,
                      divisions: 360,
                      onChanged: (v) => setHSV(hsv.withHue(v)),
                    ),
                    hsvSlider(
                      label: 'Saturation'.tr,
                      value: hsv.saturation,
                      min: 0,
                      max: 1,
                      divisions: 100,
                      onChanged: (v) => setHSV(hsv.withSaturation(v)),
                    ),
                    hsvSlider(
                      label: 'Brightness'.tr,
                      value: hsv.value,
                      min: 0,
                      max: 1,
                      divisions: 100,
                      onChanged: (v) => setHSV(hsv.withValue(v)),
                    ),

                    const SizedBox(height: 12),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.dashboardBoarder),
                              foregroundColor: theme.textColor,
                            ),
                            onPressed: () => Navigator.pop(ctx, null),
                            child:  Text('Cancel'.tr),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.themeColor,
                              foregroundColor: theme.themeTextColor,
                            ),
                            onPressed: () =>
                                Navigator.pop(ctx, _hexFromColor(currentColor)),
                            child:  Text('Use color'.tr),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // prefill (once)
      if (widget.isEditMode &&
          widget.editLabel != null &&
          !ref.read(prefilledProvider)) {
        ref.read(labelColorProvider.notifier).state = widget.editLabel!.color;
        ref.read(labelNameProvider.notifier).state = widget.editLabel!.name;
        ref.read(prefilledProvider.notifier).state = true;
      }

      final alreadyFetched = ref.read(fetchGuardProvider);
      final current = ref.read(taskLabelsProvider);
      final needFetch = current == null || current.results.isEmpty;
      if (!alreadyFetched && needFetch) {
        ref.read(fetchGuardProvider.notifier).state = true;
        await ref.read(taskLabelsProvider.notifier).fetchLabels();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    // removed usedColors filtering
    final labelColor = ref.watch(labelColorProvider);
    final labelName = ref.watch(labelNameProvider);
    final triedSubmit = ref.watch(triedSubmitProvider);

    final selectedHex = labelColor == null ? null : _norm(labelColor);
    final pickedColor =
    selectedHex != null ? _colorFromHex(selectedHex) : Colors.transparent;

    final nameMissing = triedSubmit && labelName.trim().isEmpty;
    final colorMissing = triedSubmit && labelColor == null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: theme.adPopBackground,
      child: Container(
        width: 400,
        constraints: const BoxConstraints(minHeight: 600),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isEditMode ? 'Edit Label'.tr : 'Create Label'.tr,
                style: TextStyle(color: theme.textColor, fontSize: 16),
              ),
              const SizedBox(height: 12),

              if (pickedColor != Colors.transparent)
                Container(
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                    color: pickedColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),

              const SizedBox(height: 12),

              // Title
              TextField(
                controller: TextEditingController(text: labelName)
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: labelName.length),
                  ),
                style: TextStyle(color: theme.textColor),
                cursorColor: theme.textColor,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.textFieldColor,
                  hintText: 'Title'.tr,
                  hintStyle: TextStyle(color: theme.textColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  errorText: nameMissing ? 'Please enter a title'.tr : null,
                ),
                onChanged:
                    (val) => ref.read(labelNameProvider.notifier).state = val,
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select a color'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  ...CreateLabelDialogWidget._colors.map((hex) {
                    final norm = _norm(hex);
                    final selected = selectedHex == norm;

                    return GestureDetector(
                      onTap: () =>
                      ref.read(labelColorProvider.notifier).state = hex,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _colorFromHex(hex),
                          borderRadius: BorderRadius.circular(6),
                          border: selected
                              ? Border.all(
                            color: theme.themeColor,
                            width: 3,
                          )
                              : Border.all(
                            color: Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }),

                  GestureDetector(
                    onTap: () async {
                      final pickedHex = await _showCustomColorPicker(
                        context: context,
                        theme: theme,
                        initialHex: selectedHex ?? '#61bd4f',
                      );
                      if (pickedHex != null) {
                        ref.read(labelColorProvider.notifier).state = _norm(
                          pickedHex,
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: theme.themeColor.withAlpha(153),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(Icons.add, color: theme.textColor, size: 24),
                      ),
                    ),
                  ),
                ],
              ),

              if (colorMissing) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Please select a color'.tr,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ],

              const SizedBox(height: 8),

              if (labelColor != null)
                InkWell(
                  onTap: () {
                    ref.read(labelColorProvider.notifier).state = null;
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.textFieldColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        'X Remove color'.tr,
                        style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              InkWell(
                onTap: () async {
                  ref.read(triedSubmitProvider.notifier).state = true;

                  final name = ref.read(labelNameProvider);
                  final color = ref.read(labelColorProvider);

                  if (name.trim().isEmpty || color == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                        content: Text('Please enter a title and select a color.'.tr),
                      ),
                    );
                    return;
                  }

                  TaskLabel? resultLabel;

                  if (widget.isEditMode && widget.editLabel != null) {
                    await ref
                        .read(taskLabelsProvider.notifier)
                        .editLabel(
                      labelId: widget.editLabel!.id.toString(),
                      name: name,
                      color: color,
                    );

                    await ref.read(taskLabelsProvider.notifier).fetchLabels();
                    final all =
                        ref.read(taskLabelsProvider)?.results ?? <TaskLabel>[];
                    resultLabel = all.firstWhere(
                          (l) => l.id == widget.editLabel!.id,
                      orElse: () => widget.editLabel!,
                    );
                  } else {
                    await ref
                        .read(taskLabelsProvider.notifier)
                        .addLabel(name, color);
                    await ref.read(taskLabelsProvider.notifier).fetchLabels();

                    final all =
                        ref.read(taskLabelsProvider)?.results ?? <TaskLabel>[];
                    resultLabel = all.firstWhere(
                          (l) =>
                      l.name == name &&
                          l.color.toLowerCase() == color.toLowerCase(),
                      orElse: () => TaskLabel(id: -1, name: name, color: color),
                    );
                  }

                  ref.invalidate(labelNameProvider);
                  ref.invalidate(labelColorProvider);
                  ref.invalidate(triedSubmitProvider);
                  ref.invalidate(prefilledProvider);

                  ref.invalidate(pickerColorProvider);
                  ref.invalidate(pickerHexProvider);
                  ref.invalidate(pickerInitDoneProvider);

                  if (context.mounted) {
                    Navigator.pop(context, resultLabel);
                  }
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.themeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      widget.isEditMode ? 'Update'.tr : 'Create'.tr,
                      style: TextStyle(
                        color: theme.themeTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              if (widget.isEditMode) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    await ref
                        .read(taskLabelsProvider.notifier)
                        .deleteLabel(widget.editLabel!.id.toString());
                    if (context.mounted) Navigator.pop(context, true);
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.textfieldnofocus,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child:  Center(
                      child: Text(
                        'Delete'.tr,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
