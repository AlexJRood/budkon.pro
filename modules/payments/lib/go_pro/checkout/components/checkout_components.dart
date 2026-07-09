import 'package:country_flags/country_flags.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

import 'package:get/get_utils/get_utils.dart';

class GradientTextFieldcheckout extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final FocusNode? focusNode;
  final FocusNode? reqNode;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  const GradientTextFieldcheckout({
    super.key,
    this.focusNode,
    this.reqNode,
    required this.controller,
    required this.hintText,
    this.inputFormatters,
    this.maxLength,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.errorText,
  });

  @override
  _GradientTextFieldcheckoutState createState() =>
      _GradientTextFieldcheckoutState();
}

class _GradientTextFieldcheckoutState
    extends ConsumerState<GradientTextFieldcheckout> {
  late FocusNode? _focusNode;
  late bool _isFocused;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode;
    _isFocused = false;

    if (_focusNode != null) {
      _focusNode!.addListener(_onFocusChange);
    }
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode?.hasFocus ?? false;
      });
    }

    if (_focusNode?.hasFocus ?? false) {
      _ensureVisible();
    }
  }

  @override
  void dispose() {
    if (_focusNode != null) {
      _focusNode!.removeListener(_onFocusChange);
    }
    // No need to dispose `_focusNode` if it's passed in from outside.
    super.dispose();
  }

  void _ensureVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;

      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: 0.55,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: BoxBorder.all(
              color: theme.dashboardBoarder,
            ),
            borderRadius: BorderRadius.circular(8),
            color: theme.dashboardContainer,
          ),
          child: TextField(
            cursorColor: theme.popupcontainertextcolor,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            textInputAction:
            widget.reqNode != null ? TextInputAction.next : TextInputAction.done,

            scrollPadding: EdgeInsets.only(
              left: 20,
              top: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 160,
            ),

            onTap: _ensureVisible,
            style: TextStyle(
              color: theme.textColor,
            ),
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            onSubmitted: (_) {
              if (widget.reqNode != null) {
                widget.reqNode!.requestFocus();
              } else {
                FocusScope.of(context).unfocus();
              }
            },
            keyboardType: widget.keyboardType,
            decoration: InputDecoration(
              counterText: '',
              floatingLabelStyle: TextStyle(
                color: _isFocused
                    ? theme.textColor
                    : theme.textColor.withAlpha(120),
              ),
              labelText: widget.hintText,
              labelStyle:
              TextStyle(color: theme.textColor, fontSize: 14),
              filled: true,
              fillColor: _isFocused
                  ? theme.dashboardBoarder.withAlpha(80)
                  : Colors.transparent,
              hintStyle: TextStyle(color: theme.textColor),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class GradientDropdownCountrycheckout extends ConsumerStatefulWidget {
  final String hintText;
  final List<Map<String, String>>
  countries; // Each country has 'name' and 'countryCode'
  final String? selectedCountry;
  final ValueChanged<String?> onChanged;

  const GradientDropdownCountrycheckout({
    super.key,
    required this.hintText,
    required this.countries,
    required this.selectedCountry,
    required this.onChanged,
  });

  @override
  _GradientDropdownCountrycheckoutState createState() =>
      _GradientDropdownCountrycheckoutState();
}

class _GradientDropdownCountrycheckoutState
    extends ConsumerState<GradientDropdownCountrycheckout> {
  final searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colorscheme = ref.watch(colorSchemeProvider);
    final theme = ref.watch(themeColorsProvider);
    return Container(
      padding: const EdgeInsets.only(left: 15, right: 10),
      decoration: BoxDecoration(
            border: BoxBorder.all(
              color: theme.dashboardBoarder,
            ),
            borderRadius: BorderRadius.circular(8),
            color: theme.dashboardContainer,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2(
          buttonStyleData: ButtonStyleData(
            overlayColor: WidgetStatePropertyAll(Colors.transparent),
          ),
          isExpanded: true,
          dropdownStyleData: DropdownStyleData(
            scrollbarTheme: ScrollbarThemeData(
              thumbColor: WidgetStatePropertyAll(
                theme.textColor,
              ),
            ),
            maxHeight: 300,
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
            ),
          ),
          hint: Text(
            widget.hintText,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 14,
            ),
          ),
          value: widget.selectedCountry,
          onChanged: (value) {
            widget.onChanged(value as String?);
          },
          iconStyleData: IconStyleData(
            iconEnabledColor: theme.textColor
                .withAlpha((200)),
          ),
          items:
              widget.countries.map((country) {
                return DropdownMenuItem<String>(
                  value: country['name'],
                  child: Row(
                    children: [
                      CountryFlag.fromCountryCode(
                        country['flag']!,
                        width: 30,
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        country['name']!,
                        style: TextStyle(
                          color: country['name'] == widget.selectedCountry
                                  ? theme.themeColor
                                  : theme.textColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          selectedItemBuilder: (BuildContext context) {
            return widget.countries.map((country) {
              return Row(
                children: [
                  CountryFlag.fromCountryCode(
                    country['flag']!,
                    width: 30,
                    height: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    country['name']!,
                    style: TextStyle(
                      color:
                          colorscheme == FlexScheme.blackWhite
                              ? Theme.of(context).colorScheme.onSecondary
                              : theme.textColor,
                    ),
                  ),
                ],
              );
            }).toList();
          },
          dropdownSearchData: DropdownSearchData(
            searchController: searchController,
            searchInnerWidgetHeight: 50,
            searchInnerWidget: Padding(
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 4,
                right: 8,
                left: 8,
              ),
              child: TextFormField(
                controller: searchController,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  hintText: 'Search for a country...'.tr,
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            searchMatchFn: (item, searchValue) {
              return item.value.toString().toLowerCase().contains(
                searchValue.toLowerCase(),
              );
            },
          ),
          onMenuStateChange: (isOpen) {
            if (!isOpen) {
              searchController.clear();
            }
          },
        ),
      ),
    );
  }
}

class Successpagebutton extends ConsumerWidget {
  final double buttonheight;
  final VoidCallback onTap;
  final String text;
  final bool backgroundcolor;
  final bool isborder;
  final bool hasicon;
  const Successpagebutton({
    super.key,
    this.hasicon = false,
    required this.buttonheight,
    required this.onTap,
    required this.text,
    this.isborder = false,
    this.backgroundcolor = true,
  });

  @override
  Widget build(BuildContext context, ref) {
    final theme = ref.watch(themeColorsProvider);
    final currentMode = ref.watch(isDefaultDarkSystemProvider);
    final colorscheme = ref.watch(colorSchemeProvider);
    return hasicon
        ? SizedBox(
          height: buttonheight,
          child: ElevatedButton.icon(
            icon: Icon(
              Icons.attach_file_sharp,
              color:
                  currentMode
                      ? Colors.lightBlueAccent
                      : colorscheme == FlexScheme.blackWhite
                      ? Theme.of(context).colorScheme.onSecondary
                      : theme.textFieldColor,
            ),
            iconAlignment: IconAlignment.start,
            style: ButtonStyle(
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side:
                      isborder
                          ? BorderSide(
                            width: 2,
                            color:
                                currentMode
                                    ? Colors.lightBlueAccent
                                    : colorscheme == FlexScheme.blackWhite
                                    ? Theme.of(context).colorScheme.onSecondary
                                    : theme.textFieldColor,
                          )
                          : BorderSide.none,
                ),
              ),
              backgroundColor: WidgetStatePropertyAll(
                backgroundcolor
                    ? currentMode
                        ? theme.settingsButtoncolor
                        : Theme.of(context).colorScheme.primary
                    : Colors.transparent,
              ),
            ),
            onPressed: onTap,
            label: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    currentMode
                        ? Colors.lightBlueAccent
                        : colorscheme == FlexScheme.blackWhite
                        ? Theme.of(context).colorScheme.onSecondary
                        : theme.textFieldColor,
                fontSize: 11,
              ),
            ),
          ),
        )
        : SizedBox(
          height: buttonheight,
          child: ElevatedButton(
            style: ButtonStyle(
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side:
                      isborder
                          ? BorderSide(width: 2, color: theme.textFieldColor)
                          : BorderSide.none,
                ),
              ),
              backgroundColor: WidgetStatePropertyAll(
               theme.themeColor,
              ),
            ),
            onPressed: onTap,
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.themeTextColor,
                fontSize: 11,
              ),
            ),
          ),
        );
  }
}

class Failiurepagebutton extends ConsumerWidget {
  final double buttonheight;
  final VoidCallback onTap;
  final String text;
  final bool backgroundcolor;
  final bool isborder;
  final bool hasicon;
  const Failiurepagebutton({
    super.key,
    this.hasicon = false,
    required this.buttonheight,
    required this.onTap,
    required this.text,
    this.isborder = false,
    this.backgroundcolor = true,
  });

  @override
  Widget build(BuildContext context, ref) {
    final theme = ref.watch(themeColorsProvider);
    final currentMode = ref.watch(isDefaultDarkSystemProvider);
    final colorscheme = ref.watch(colorSchemeProvider);
    return hasicon
        ? SizedBox(
          height: buttonheight,
          child: ElevatedButton.icon(
            icon: Icon(
              Icons.refresh_rounded,
              color:
                  currentMode
                      ? Colors.lightBlueAccent
                      : colorscheme == FlexScheme.blackWhite
                      ? Theme.of(context).colorScheme.onSecondary
                      : theme.textFieldColor,
            ),
            iconAlignment: IconAlignment.start,
            style: ButtonStyle(
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side:
                      isborder
                          ? BorderSide(
                            width: 2,
                            color:
                                currentMode
                                    ? Colors.lightBlueAccent
                                    : colorscheme == FlexScheme.blackWhite
                                    ? Theme.of(context).colorScheme.onSecondary
                                    : theme.textFieldColor,
                          )
                          : BorderSide.none,
                ),
              ),
              backgroundColor: WidgetStatePropertyAll(
                backgroundcolor
                    ? currentMode
                        ? theme.settingsButtoncolor
                        : Theme.of(context).colorScheme.primary
                    : Colors.transparent,
              ),
            ),
            onPressed: onTap,
            label: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    currentMode
                        ? Colors.lightBlueAccent
                        : colorscheme == FlexScheme.blackWhite
                        ? Theme.of(context).colorScheme.onSecondary
                        : theme.textFieldColor,
                fontSize: 11,
              ),
            ),
          ),
        )
        : SizedBox(
          height: buttonheight,
          child: ElevatedButton(
            style: ButtonStyle(
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side:
                      isborder
                          ? BorderSide(
                            width: 2,
                            color: Theme.of(context).iconTheme.color!,
                          )
                          : BorderSide.none,
                ),
              ),
              backgroundColor: WidgetStatePropertyAll(
                backgroundcolor
                    ? currentMode
                        ? theme.settingsButtoncolor
                        : Theme.of(context).colorScheme.primary
                    : Colors.transparent,
              ),
            ),
            onPressed: onTap,
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    currentMode
                        ? Colors.lightBlueAccent
                        : colorscheme == FlexScheme.blackWhite
                        ? Theme.of(context).colorScheme.onSecondary
                        : Theme.of(context).iconTheme.color,
                fontSize: 11,
              ),
            ),
          ),
        );
  }
}
