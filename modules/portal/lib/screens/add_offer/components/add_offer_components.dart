
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/apptheme.dart';
import 'package:intl/intl.dart';
import 'package:get/get_utils/get_utils.dart';


class DropdownButtonFormFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final List<String> items;
  final String labelText;
  final WidgetRef ref;
  final String? Function(String?)? validator;

  const DropdownButtonFormFieldWidget({
    super.key,
    required this.controller,
    required this.items,
    required this.labelText,
    required this.ref,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    // Access theme providers
    final theme = ref.watch(themeColorsProvider);

    final backgroundColor = theme.textFieldColor;
    final textColor = theme.textColor;

    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: Colors.transparent, // Remove hover color
        splashColor: Colors.transparent, // Remove ripple effect
        focusColor: Colors.transparent, // Remove focus color
      ),
      child: Material(
        borderRadius: BorderRadius.circular(10.0),
        color: Colors.transparent,
        child: SizedBox(
          height: 65.0, // Increased height to accommodate error text
          child: DropdownButtonFormField<String>(
            validator: validator,
            elevation: 0,
            borderRadius: BorderRadius.circular(10),
            value: controller.text.isNotEmpty ? controller.text : null,
            decoration: InputDecoration(
              hintText: labelText,
              hintStyle: AppTextStyles.interMedium14dark.copyWith(
                color: textColor,
              ),
              contentPadding: const EdgeInsets.only(
                left: 12,
                top: 8,
                bottom: 8,
              ),
              fillColor: backgroundColor,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: Colors.black),
              ),
              errorStyle: const TextStyle(
                color: Colors.red, // Custom error color
                fontSize: 12, // Smaller error font size
                height: 1.2, // Line height for better spacing
              ),
              errorMaxLines: 2, // Allows wrapping for long error messages
            ),
            dropdownColor: backgroundColor,
            items:
                items.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: AppTextStyles.interMedium14dark.copyWith(
                        color: textColor,
                      ),
                    ),
                  );
                }).toList(),
            onChanged: (String? newValue) {
              controller.text = newValue ?? '';
            },
            selectedItemBuilder: (BuildContext context) {
              return items.map<Widget>((String value) {
                return Text(
                  value,
                  style: AppTextStyles.interSemiBold.copyWith(
                    fontSize: 14,
                    color: textColor,
                  ),
                );
              }).toList();
            },
            iconSize: 24.0,
          ),
        ),
      ),
    );
  }
}

class SelectableButtonsFormFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final List<String> options;
  final String labelText;
  final WidgetRef ref;
  final String? Function(String?)? validator;

  const SelectableButtonsFormFieldWidget({
    super.key,
    required this.controller,
    required this.options,
    required this.labelText,
    required this.ref,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final scrollController = ScrollController();

    final selectedBackgroundColor = theme.themeColor;
    final unselectedBackgroundColor = theme.textFieldColor;
    final selectedTextColor = theme.textFieldColor;
    final unselectedTextColor = theme.textColor;

    return FormField<String>(
      initialValue: controller.text,
      validator: validator,
      builder: (FormFieldState<String> fieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Text(
                labelText,
                style: AppTextStyles.interRegular.copyWith(
                  fontSize: 14,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onHorizontalDragUpdate: (details) {
                scrollController.jumpTo(
                  scrollController.offset - details.delta.dx,
                );
              },
              child: SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...options.map((option) {
                      final isSelected = controller.text == option;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Container(
                          width: 40,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              controller.text = option;
                              fieldState.didChange(option);
                              (context as Element).markNeedsBuild();
                            },
                            style:
                                isSelected
                                    ? buttonStyleRounded10ThemeRed.copyWith(
                                      padding: MaterialStateProperty.all(
                                        EdgeInsets.zero,
                                      ),
                                    )
                                    : elevatedButtonStyleRounded10White
                                        .copyWith(
                                          padding: MaterialStateProperty.all(
                                            EdgeInsets.zero,
                                          ),
                                        ),

                            child: Text(
                              option,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? selectedTextColor
                                        : unselectedTextColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    if (controller.text.isNotEmpty)
                      ElevatedButton(
                        onPressed: () {
                          controller.clear();
                          fieldState.didChange(null);
                          (context as Element).markNeedsBuild();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.hardRed.withAlpha(178),
                          foregroundColor: Colors.white,
                          textStyle: AppTextStyles.interRegular.copyWith(
                            fontSize: 14,
                          ),
                        ),
                        child: Text("Clear".tr),
                      ),
                  ],
                ),
              ),
            ),
            if (fieldState.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  fieldState.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}

class AdditionalInfoFilterButton extends ConsumerWidget {
  final String text;
  final ValueNotifier<bool> controller;

  const AdditionalInfoFilterButton({
    super.key,
    required this.text,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, ref) {
    final theme = ref.watch(themeColorsProvider);

    final selectedBackgroundColor = theme.themeColor;
    final unselectedBackgroundColor = theme.textFieldColor;
    final selectedTextColor = theme.textFieldColor;
    final unselectedTextColor = theme.textColor;

    return ValueListenableBuilder<bool>(
      valueListenable: controller,
      builder: (_, isSelected, __) {
        return Container(
          height: 40,
          child: ElevatedButton(
            onPressed: () => controller.value = !isSelected,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isSelected
                      ? selectedBackgroundColor
                      : unselectedBackgroundColor,
              foregroundColor:
                  isSelected ? selectedTextColor : unselectedTextColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? selectedTextColor : unselectedTextColor,
              ),
            ),
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
    // Sprawdzanie, czy wartość przycisku jest aktualnie wybrana
    bool isSelected = controller.text == filterValue;

    return ElevatedButton(
      onPressed: () {
        // Jeśli przycisk jest już zaznaczony, to kliknięcie go ponownie powinno usunąć selekcję
        if (isSelected) {
          controller.text =
              ''; // Czyszczenie kontrolera, jeśli wartość jest już zaznaczona
        } else {
          // Ustawienie kontrolera na wartość przycisku, niezależnie od poprzedniego stanu
          controller.text = filterValue;
        }
        // Zmuszenie interfejsu do odświeżenia i pokazania aktualnego stanu
        (context as Element).markNeedsBuild();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected
                ? Colors.blue
                : Colors.white, // Podświetlenie przycisku, gdy jest wybrany
        foregroundColor:
            isSelected
                ? Colors.white
                : Colors.black, // Zmiana koloru tekstu w zależności od stanu
        side:
            isSelected
                ? null
                : const BorderSide(
                  color: Colors.grey,
                ), // Dodanie obramowania dla niezaznaczonych przycisków
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ), // Zaokrąglenie rogów przycisku
      ),
      child: Text(
        text,
        style: TextStyle(color: isSelected ? Colors.white : Colors.black),
      ), // Zmiana koloru tekstu w zależności od stanu
    );
  }
}

class ButtonOption {
  final String label;
  final String value;

  ButtonOption(this.label, this.value);
}

class SelectButtonsOptionsWidget extends StatelessWidget {
  final TextEditingController controller;
  final List<ButtonOption> options;
  final String labelText;
  final WidgetRef ref;
  final String? Function(String?)? validator;

  /// If true, user must choose a value (can't clear).
  final bool isRequired;

  const SelectButtonsOptionsWidget({
    super.key,
    required this.controller,
    required this.options,
    required this.labelText,
    required this.ref,
    this.validator,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    final theme = ref.read(themeColorsProvider);
    final selectedTextColor = theme.textFieldColor;
    final unselectedTextColor = theme.textColor;

    return FormField<String>(
      initialValue: controller.text.isEmpty ? null : controller.text,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (validator != null) return validator!(value);
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Required'.tr;
        }
        return null;
      },
      builder: (FormFieldState<String> fieldState) {
        final current = fieldState.value ?? '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                labelText,
                style: AppTextStyles.interRegular.copyWith(
                  fontSize: 14,
                  color: theme.textColor,
                ),
              ),
            ),
            GestureDetector(
              onHorizontalDragUpdate: (details) {
                scrollController.jumpTo(
                  scrollController.offset - details.delta.dx,
                );
              },
              child: SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...options.map((option) {
                      final isSelected = current == option.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 5.0),
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              // Toggle off if already selected and not required
                              if (isSelected && !isRequired) {
                                controller.clear();
                                fieldState.didChange(null);
                              } else {
                                controller.text = option.value;
                                fieldState.didChange(option.value);
                              }
                            },
                            style: isSelected
                                ? buttonStyleRounded10ThemeRed
                                : elevatedButtonStyleRounded10White,
                            child: Text(
                              option.label,
                              style: TextStyle(
                                color: isSelected
                                    ? selectedTextColor
                                    : unselectedTextColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    // Optional clear button when not required and something selected
                    if (!isRequired && (current.isNotEmpty))
                      Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              controller.clear();
                              fieldState.didChange(null);
                            },
                            style: elevatedButtonStyleRounded10White,
                            child:Text('Clear'.tr),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (fieldState.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  fieldState.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final int? maxLines;
  final String? Function(String?)? validator;
  final WidgetRef ref;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    required this.ref,
    this.maxLines,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final textFieldColor = theme.textColor;

    return TextFormField(
      style: AppTextStyles.interRegular.copyWith(
        fontSize: 14,
        color: textFieldColor,
      ),
      controller: controller,
      decoration: InputDecoration(
        fillColor: theme.textFieldColor, // <-- Białe tło
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
        hintText: labelText,
        hintStyle: AppTextStyles.interRegular.copyWith(
          fontSize: 14,
          color: textFieldColor,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: AppColors.light),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: AppColors.light),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
      ),
      maxLines: maxLines ?? 1, // Default to one line unless specified
      validator: validator,
    );
  }
}

class CustomTextFieldDescription extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final WidgetRef ref;
  final String? Function(String?)? validator;

  const CustomTextFieldDescription({
    super.key,
    required this.controller,
    required this.labelText,
    required this.ref,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final textFieldColor = theme.textColor;

    return TextFormField(
      style: AppTextStyles.interRegular.copyWith(
        fontSize: 14,
        color: textFieldColor,
      ),
      controller: controller,
      decoration: InputDecoration(
        fillColor: theme.textFieldColor, // <-- Białe tło
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
        hintText: labelText,
        hintStyle: AppTextStyles.interRegular.copyWith(
          fontSize: 14,
          color: textFieldColor,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: AppColors.light),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: AppColors.light),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        counterText: '', // Hides character counter
      ),
      maxLines: null, // Allows unlimited lines; field expands vertically
      maxLength: 2500, // Limits character count to 2500
      validator: validator,
    );
  }
}

class CustomNumberTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final WidgetRef ref;
  final String? Function(String?)? validator;
  final String unit;
  final bool limitTo4Digits; // New property

  const CustomNumberTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.ref,
    this.validator,
    required this.unit,
    this.limitTo4Digits = false, // default value
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###.##', 'pl_PL');
    final theme = ref.watch(themeColorsProvider);
    final textFieldColor = theme.textColor;

    return TextFormField(
      style: AppTextStyles.interSemiBold.copyWith(
        fontSize: 14,
        color: textFieldColor,
      ),
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
        hintText: labelText,
        hintStyle: AppTextStyles.interRegular.copyWith(
          fontSize: 14,
          color: textFieldColor,
        ),
        filled: true,
        fillColor: theme.textFieldColor, // <-- Białe tło
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: AppColors.dark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: AppColors.light),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        suffixText: unit,
        suffixStyle: AppTextStyles.interRegular.copyWith(fontSize: 14),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        if (limitTo4Digits)
          LengthLimitingTextInputFormatter(4), // Limit input to 4 digits
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
      validator: validator,
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
    String newText = newValue.text.replaceAll(
      ',',
      '.',
    ); // Zamiana przecinka na kropkę

    if (newText.isNotEmpty && !newText.endsWith(unit)) {
      // Jeśli nowy tekst nie kończy się jednostką, dodaj ją
      newText += ' $unit';
    }

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newText.length - unit.length - 1,
      ), // Aktualizacja pozycji kursora
    );
  }
}




