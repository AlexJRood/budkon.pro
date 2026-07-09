import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class BuildDropdownButtonFormField extends ConsumerWidget {
  const BuildDropdownButtonFormField({
    super.key,
    required this.controller,
    required this.items,
    required this.labelText,
    this.isEditAdView = false,
  });

  final TextEditingController controller;
  final List<String> items;
  final String labelText;
  final bool isEditAdView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool flat = isEditAdView;
    final theme = ref.watch(themeColorsProvider);

    final OutlineInputBorder flatBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.dark),
    );

    final OutlineInputBorder pillBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30.0),
      borderSide: const BorderSide(color: AppColors.dark),
    );

    final String? currentValue =
        (controller.text.isNotEmpty && items.contains(controller.text))
            ? controller.text
            : null;

    return DropdownButtonFormField<String>(
      value: currentValue,
      isExpanded: true,
      isDense: true,
      menuMaxHeight: 320,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: theme.textColor,
        size: 18,
      ),
      dropdownColor: theme.adPopBackground,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.fromLTRB(12, 14, 40, 14),
        label: Text(
          labelText,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.interRegular.copyWith(
            fontSize: 14,
            color: theme.textColor,
          ),
        ),
        filled: !flat,
        fillColor: flat ? Colors.transparent : Colors.white,
        border: flat ? flatBorder : pillBorder,
        enabledBorder: (flat ? flatBorder : pillBorder).copyWith(
          borderSide: BorderSide(color: theme.textColor.withAlpha(120)),
        ),
        focusedBorder: (flat ? flatBorder : pillBorder).copyWith(
          borderSide: BorderSide(color: theme.textColor.withAlpha(120)),
        ),
      ),
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.interRegular.copyWith(
                fontSize: 14,
                color: theme.textColor,
              ),
            ),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        controller.text = newValue ?? '';
      },
      selectedItemBuilder: (BuildContext context) {
        return items.map<Widget>((String value) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.interSemiBold.copyWith(
                fontSize: 14,
                color: theme.textColor,
              ),
            ),
          );
        }).toList();
      },
    );
  }
}

class BuildSelectableButtonsFormField extends StatelessWidget {
  const BuildSelectableButtonsFormField({
    super.key,
    required this.controller,
    required this.options,
    required this.labelText,
  });

  final TextEditingController controller;
  final List<String> options;
  final String labelText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            labelText,
            style: AppTextStyles.interRegular.copyWith(
              fontSize: 14,
              color: AppColors.light,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            return ElevatedButton(
              onPressed: () {
                controller.text = option;
                (context as Element).markNeedsBuild();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    controller.text == option ? Colors.blue : Colors.white,
                foregroundColor:
                    controller.text == option ? AppColors.light : AppColors.dark,
                textStyle: AppTextStyles.interRegular.copyWith(
                  fontSize: 14,
                ),
              ),
              child: Text(option),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class AdditionalInfoFilterButton extends StatelessWidget {
  final String text;
  final ValueNotifier<bool> controller;

  const AdditionalInfoFilterButton({
    super.key,
    required this.text,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller,
      builder: (_, isSelected, __) {
        return ElevatedButton(
          onPressed: () => controller.value = !isSelected,
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue : Colors.white,
            foregroundColor: isSelected ? Colors.white : Colors.black,
            side: isSelected ? null : const BorderSide(color: Colors.grey),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(color: isSelected ? Colors.white : Colors.black),
          ),
        );
      },
    );
  }
}

class EstateTypeAddButton extends ConsumerWidget {
  final String text;
  final String filterValue;
  final TextEditingController controller;

  const EstateTypeAddButton({
    super.key,
    required this.text,
    required this.filterValue,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSelected = controller.text == filterValue;

    return ElevatedButton(
      onPressed: () {
        if (isSelected) {
          controller.text = '';
        } else {
          controller.text = filterValue;
        }
        (context as Element).markNeedsBuild();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        side: isSelected ? null : const BorderSide(color: Colors.grey),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(color: isSelected ? Colors.white : Colors.black),
      ),
    );
  }
}

class ButtonOption {
  final String label;
  final String value;

  const ButtonOption(this.label, this.value);
}

class SelectButtonsOptions extends StatelessWidget {
  const SelectButtonsOptions({
    super.key,
    required this.controller,
    required this.options,
    required this.labelText,
  });

  final TextEditingController controller;
  final List<ButtonOption> options;
  final String labelText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            labelText,
            style: AppTextStyles.interRegular.copyWith(
              fontSize: 14,
              color: AppColors.light,
            ),
          ),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: options.map((option) {
            return ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, value, child) {
                return ElevatedButton(
                  onPressed: () {
                    controller.text = option.label;
                    if (kDebugMode) {
                      debugPrint(controller.text);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.text == option.label
                        ? Colors.blue
                        : Colors.white,
                    foregroundColor: controller.text == option.label
                        ? Colors.white
                        : Colors.black,
                  ),
                  child: Text(option.label),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class BuildTextField extends ConsumerStatefulWidget {
  const BuildTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.maxLines,
    this.validator,
    this.isEditAdView = false,
  });

  final TextEditingController controller;
  final String labelText;
  final int? maxLines;
  final FormFieldValidator<String>? validator;
  final bool isEditAdView;

  @override
  ConsumerState<BuildTextField> createState() => _BuildTextFieldState();
}

class _BuildTextFieldState extends ConsumerState<BuildTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: 0.25,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool flat = widget.isEditAdView;
    final theme = ref.watch(themeColorsProvider);

    final OutlineInputBorder flatBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.light),
    );

    final OutlineInputBorder normalBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15.0),
      borderSide: const BorderSide(color: AppColors.light),
    );

    final baseBorder = flat ? flatBorder : normalBorder;

    return TextFormField(
      focusNode: _focusNode,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) {
        FocusScope.of(context).nextFocus();
      },
      style: AppTextStyles.interRegular.copyWith(
        fontSize: 14,
        color: theme.textColor,
      ),
      controller: widget.controller,
      maxLines: widget.maxLines ?? 1,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
        label: Text(
          widget.labelText,
          style: AppTextStyles.interRegular.copyWith(
            fontSize: 14,
            color: theme.textColor,
          ),
        ),
        filled: false,
        border: baseBorder,
        enabledBorder: baseBorder.copyWith(
          borderSide: BorderSide(color: theme.textColor.withAlpha(120)),
        ),
        focusedBorder: baseBorder.copyWith(
          borderSide: BorderSide(color: theme.textColor.withAlpha(120)),
        ),
      ),
      validator: widget.validator,
    );
  }
}

class BuildTextFieldDes extends ConsumerWidget {
  const BuildTextFieldDes({
    super.key,
    required this.controller,
    required this.labelText,
    this.validator,
    this.isEditAdView = false,
  });

  final TextEditingController controller;
  final String labelText;
  final FormFieldValidator<String>? validator;
  final bool isEditAdView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool flat = isEditAdView;
    final theme = ref.watch(themeColorsProvider);

    final OutlineInputBorder flatBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.light),
    );

    final OutlineInputBorder normalBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15.0),
      borderSide: const BorderSide(color: AppColors.light),
    );

    final baseBorder = flat ? flatBorder : normalBorder;

    return TextFormField(
      style: AppTextStyles.interRegular.copyWith(
        fontSize: 14,
        color: theme.textColor,
      ),
      controller: controller,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
        label: Text(
          labelText,
          style: AppTextStyles.interRegular.copyWith(
            fontSize: 14,
            color: theme.textColor,
          ),
        ),
        filled: false,
        border: baseBorder,
        enabledBorder: baseBorder.copyWith(
          borderSide: BorderSide(color: theme.textColor.withAlpha(120)),
        ),
        focusedBorder: baseBorder.copyWith(
          borderSide: BorderSide(color: theme.textColor.withAlpha(120)),
        ),
        counterText: '',
      ),
      maxLines: null,
      maxLength: 2500,
      validator: validator,
    );
  }
}

class BuildNumberTextField extends ConsumerStatefulWidget {
  const BuildNumberTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.validator,
    required this.unit,
    this.isEditAdView = false,
  });

  final TextEditingController controller;
  final String labelText;
  final FormFieldValidator<String>? validator;
  final String unit;
  final bool isEditAdView;

  @override
  ConsumerState<BuildNumberTextField> createState() =>
      _BuildNumberTextFieldState();
}

class _BuildNumberTextFieldState extends ConsumerState<BuildNumberTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: 0.25,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###.##', 'pl_PL');
    final bool flat = widget.isEditAdView;
    final theme = ref.watch(themeColorsProvider);

    final OutlineInputBorder flatBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.dark),
    );

    final OutlineInputBorder pillBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30.0),
      borderSide: const BorderSide(color: AppColors.dark),
    );

    return TextFormField(
      focusNode: _focusNode,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) {
        FocusScope.of(context).nextFocus();
      },
      style: AppTextStyles.interSemiBold.copyWith(
        fontSize: 14,
        color: theme.textColor,
      ),
      controller: widget.controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
        label: Text(
          widget.labelText,
          style: AppTextStyles.interRegular.copyWith(
            fontSize: 14,
            color: theme.textColor,
          ),
        ),
        filled: !flat,
        fillColor: flat ? Colors.transparent : Colors.white,
        border: flat ? flatBorder : pillBorder,
        enabledBorder: (flat ? flatBorder : pillBorder).copyWith(
          borderSide: BorderSide(color: theme.textColor.withAlpha(120)),
        ),
        focusedBorder: (flat ? flatBorder : pillBorder).copyWith(
          borderSide: BorderSide(color: theme.textColor.withAlpha(120)),
        ),
        suffixText: widget.unit.isNotEmpty ? widget.unit : null,
        suffixStyle: AppTextStyles.interRegular.copyWith(
          fontSize: 14,
          color: AppColors.dark50,
        ),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        TextInputFormatter.withFunction((oldValue, newValue) {
          if (newValue.text.isEmpty) {
            return newValue.copyWith(text: '');
          }

          final int value = int.parse(
            newValue.text.replaceAll(' ', '').replaceAll(',', ''),
          );

          final String newText = formatter.format(value).replaceAll(',', ' ');

          return newValue.copyWith(
            text: newText,
            selection: TextSelection.collapsed(offset: newText.length),
          );
        }),
      ],
      validator: widget.validator,
    );
  }
}

class UnitInputFormatter extends TextInputFormatter {
  final String unit;

  UnitInputFormatter({required this.unit});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text.replaceAll(',', '.');

    if (newText.isNotEmpty && !newText.endsWith(unit)) {
      newText += ' $unit';
    }

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newText.length - unit.length - 1,
      ),
    );
  }
}