import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/add_offer/provider/add_offer_provider.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';

class PropertyTypeSelector extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final bool isBig;
  final List options; // Assumes list of objects with `.value` and `.label`
  final String labelText;
  final String updateField;
  final bool isExpanded;
  final bool isWidthFixed;

  const PropertyTypeSelector({
    super.key,
    required this.controller,
    required this.updateField,
    required this.options,
    required this.labelText,
    this.isExpanded = false,
    this.isBig = false,
    this.isWidthFixed=false,
  });

  @override
  ConsumerState<PropertyTypeSelector> createState() =>
      _PropertyTypeSelectorState();
}

class _PropertyTypeSelectorState extends ConsumerState<PropertyTypeSelector> {
  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final selectedTextColor = AppColors.white;
    final unselectedTextColor = theme.textColor;
    final addOfferStateNotifier = ref.watch(addOfferProvider.notifier);

    // Calculate button height based on isBig and isExpanded
    double buttonHeight;
    if (widget.isBig) {
      buttonHeight = widget.isExpanded && widget.options.length == 2 ? 60 : 50;
    } else {
      buttonHeight = widget.isExpanded && widget.options.length == 2 ? 50 : 40;
    }

    // Calculate text size based on isBig
    double textSize = widget.isBig ? 16 : 14;

    List<Widget> buttons = widget.options.map<Widget>((option) {
      final isSelected = widget.controller.text == option.value;

      final button = SizedBox(
        width: widget.isWidthFixed ? buttonHeight : null,
        height: buttonHeight,
        child: ElevatedButton(
          onPressed: () {
            widget.controller.text = option.value;

            addOfferStateNotifier.updateField(
              widget.updateField,
              option.value,
            );

            log(option.value);
          },
          style: ElevatedButton.styleFrom(
            minimumSize: Size.zero,
            fixedSize: Size.fromHeight(buttonHeight),
            backgroundColor: isSelected ? AppColors.redBeige : theme.adPopBackground,
            foregroundColor: isSelected ? selectedTextColor : unselectedTextColor,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: theme.dashboardBoarder),
            ),
          ),
          child: Text(
            option.label,
            style: TextStyle(
              color: isSelected ? selectedTextColor : unselectedTextColor,
              fontSize: textSize,
              fontWeight: widget.isBig ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      );
      if (widget.isWidthFixed){
        return button;
      }

      return widget.isExpanded && widget.options.length == 2
          ? Expanded(child: button)
          : button;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: AppTextStyles.interRegular.copyWith(
            fontSize: widget.isBig ? 15 : 13,
            fontWeight: FontWeight.bold,
            color: theme.primaryBackgroundTextColor,
          ),
        ),
        const SizedBox(height: 10),
        widget.isWidthFixed
        ?  GridView.builder(
          shrinkWrap: true, // Important for use inside a Column
          physics: const NeverScrollableScrollPhysics(), // Also important
          itemCount: buttons.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: buttons.length, // All buttons in one row
            childAspectRatio: 1.1, // Adjust this ratio of width-to-height
            mainAxisSpacing: 5.0,
            crossAxisSpacing: 5.0,
          ),
          itemBuilder: (context, index) {
            return buttons[index];
          },
        )
        : widget.isExpanded && widget.options.length == 2
            ? Row(children: [buttons[0], const SizedBox(width: 10), buttons[1]])
            : Wrap(spacing: 5.0, runSpacing: 5.0, children: buttons),
      ],
    );
  }
}

class PropertyTypeSelectorMobile extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final List options; // Assumes list of objects with `.value` and `.label`
  final String labelText;
  final String updateField;

  const PropertyTypeSelectorMobile({
    super.key,
    required this.controller,
    required this.updateField,
    required this.options,
    required this.labelText,
  });

  @override
  ConsumerState<PropertyTypeSelectorMobile> createState() =>
      _PropertyTypeSelectorMobileState();
}

class _PropertyTypeSelectorMobileState
    extends ConsumerState<PropertyTypeSelectorMobile> {
  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final selectedTextColor = Colors.white;
    final unselectedTextColor = Colors.black;
    final addOfferStateNotifier = ref.watch(addOfferProvider.notifier);

    List<Widget> rows = [];
    final options = widget.options;
    for (int i = 0; i < options.length; i += 2) {
      final option1 = options[i];
      final option2 = (i + 1 < options.length) ? options[i + 1] : null;

      final isSelected1 = widget.controller.text == option1.value;
      final button1 = Expanded(
        child: SizedBox(
          height: 55,
          child: ElevatedButton(
            onPressed: () {
              widget.controller.text = option1.value;
              addOfferStateNotifier.updateField(
                widget.updateField,
                option1.value,
              );
              log(option1.value);
            },
            style:
                isSelected1
                    ? buttonStyleRounded10ThemeRed
                    : elevatedButtonStyleRounded10White,
            child: Text(
              option1.label,
              style: TextStyle(
                color: isSelected1 ? selectedTextColor : unselectedTextColor,
              ),
            ),
          ),
        ),
      );

      Widget row;
      if (option2 != null) {
        final isSelected2 = widget.controller.text == option2.value;
        final button2 = Expanded(
          child: SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                widget.controller.text = option2.value;
                addOfferStateNotifier.updateField(
                  widget.updateField,
                  option2.value,
                );
                log(option2.value);
              },
              style:
                  isSelected2
                      ? buttonStyleRounded10ThemeRed
                      : elevatedButtonStyleRounded10White,
              child: Text(
                option2.label,
                style: TextStyle(
                  color: isSelected2 ? selectedTextColor : unselectedTextColor,
                ),
              ),
            ),
          ),
        );

        row = Row(children: [button1, const SizedBox(width: 10), button2]);
      } else {
        row = Row(children: [button1]);
      }

      rows.add(Padding(padding: const EdgeInsets.only(bottom: 10), child: row));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: AppTextStyles.interRegular.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: theme.primaryBackgroundTextColor,
          ),
        ),
        const SizedBox(height: 10),
        ...rows,
      ],
    );
  }
}
