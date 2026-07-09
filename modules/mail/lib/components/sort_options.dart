// mail/sort_options.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';

/// Convenience enum for known sort options (optional).
enum MailSortOption {
  receivedAtDesc('received_at_desc', 'Newest'),
  receivedAtAsc('received_at_asc', 'Oldest');
  // subjectAsc('subject_asc', 'Topic A-Z'),
  // subjectDesc('subject_desc', 'Topic Z-A');

  final String value;
  final String label;
  const MailSortOption(this.value, this.label);
}

/// -------------------------
/// PURE WIDGET
/// -------------------------
class SortDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?>? onChanged;

  final EdgeInsetsGeometry padding;
  final double height;
  final double? width;
  final double borderRadius;
  final Color? dropdownColor;
  final TextStyle? textStyle;
  final ThemeColors theme;

  final List<DropdownMenuItem<String>>? items;

  const SortDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.padding = const EdgeInsets.all(5),
    this.height = 50,
    this.width,
    this.borderRadius = 10,
    this.dropdownColor,
    this.textStyle,
    this.items,
    required this.theme,
  });

  List<DropdownMenuItem<String>> _defaultItems(BuildContext context) {
    final style = textStyle ?? TextStyle(color: theme.textColor);

    return [
      for (final opt in MailSortOption.values)
        DropdownMenuItem<String>(
          value: opt.value,
          child: Text(opt.label.tr, style: style),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.all(Radius.circular(borderRadius));

    return Container(
      padding: padding,
      height: height,
      width: width ?? double.infinity,
      child: DropdownButton<String>(
        isExpanded: true,
        value: value,
        style: TextStyle(color: theme.textColor),
        onChanged: onChanged,
        dropdownColor: dropdownColor ?? theme.adPopBackground,
        borderRadius: radius,
        items: items ?? _defaultItems(context),
      ),
    );
  }
}

/// ---------------------------------------
/// RIVERPOD ADAPTER
/// ---------------------------------------
class MailSortDropdownRP extends ConsumerWidget {
  final StateProvider<String> sortProvider;
  final StateProvider<int> pageProvider;

  final EdgeInsetsGeometry padding;
  final double height;
  final double? width;
  final double borderRadius;
  final Color? dropdownColor;
  final TextStyle? textStyle;
  final List<DropdownMenuItem<String>>? items;

  const MailSortDropdownRP({
    super.key,
    required this.sortProvider,
    required this.pageProvider,
    this.padding = const EdgeInsets.all(5),
    this.height = 50,
    this.width,
    this.borderRadius = 10,
    this.dropdownColor,
    this.textStyle,
    this.items,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(sortProvider);
    final theme = ref.read(themeColorsProvider);
    debugPrint('MailSortDropdownRP build -> current sort=$current');

    return SortDropdown(
      value: current,
      onChanged: (val) {
        debugPrint('SORT DROPDOWN onChanged fired, val=$val');

        if (val == null) return;

        final beforeSort = ref.read(sortProvider);
        final beforePage = ref.read(pageProvider);

        debugPrint('BEFORE update -> sort=$beforeSort, page=$beforePage');

        ref.read(sortProvider.notifier).state = val;
        ref.read(pageProvider.notifier).state = 1;

        final afterSort = ref.read(sortProvider);
        final afterPage = ref.read(pageProvider);

        debugPrint('AFTER update -> sort=$afterSort, page=$afterPage');
      },
      theme: theme,
      padding: padding,
      height: height,
      width: width,
      borderRadius: borderRadius,
      dropdownColor: dropdownColor,
      textStyle: textStyle,
      items: items,
    );
  }
}