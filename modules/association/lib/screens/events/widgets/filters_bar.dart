import 'package:association/screens/events/providers/event_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/text_field.dart';
import 'package:core/theme/design.dart';

class FiltersBar extends ConsumerStatefulWidget {
  const FiltersBar({required this.filter});
  final EventsFilter filter;
  @override
  ConsumerState<FiltersBar> createState() => FiltersBarState();
}

class FiltersBarState extends ConsumerState<FiltersBar> {
  late final TextEditingController _q = TextEditingController(
    text: widget.filter.q,
  );
  late final TextEditingController _city = TextEditingController(
    text: widget.filter.city,
  );
  late DateTime? _start = widget.filter.start;
  late DateTime? _end = widget.filter.end;

   Future<void> _pickDateRange() async {
  final now = DateTime.now();
  final isDesktop = MediaQuery.of(context).size.width > 800;
  
  final res = await showDateRangePicker(
    context: context,
    firstDate: DateTime(now.year - 1),
    lastDate: DateTime(now.year + 2),
    currentDate: now,
    builder: (context, child) {
      final themedChild = pickerThemeBuilder(context, child);
      if (isDesktop) {
        return Dialog(
          insetPadding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.15,
            bottom: MediaQuery.of(context).size.height * 0.15,
            left: MediaQuery.of(context).size.width * 0.2,
            right: MediaQuery.of(context).size.width * 0.2,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 700,
              maxHeight: 650,
              minWidth: 500,
              minHeight: 550,
            ),
            child: themedChild,
          ),
        );
      } else {
        return Dialog(
          insetPadding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.08,
            bottom: MediaQuery.of(context).size.height * 0.08,
            left: MediaQuery.of(context).size.width * 0.05,
            right: MediaQuery.of(context).size.width * 0.05,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              minWidth: MediaQuery.of(context).size.width * 0.85,
              minHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: themedChild,
          ),
        );
      }
    },
    initialDateRange: _start != null && _end != null
        ? DateTimeRange(start: _start!, end: _end!)
        : null,
    helpText: 'Select range',
    saveText: 'Save',
    cancelText: 'Cancel',
    confirmText: 'OK',
    fieldStartLabelText: 'Start Date',
    fieldEndLabelText: 'End Date',
    fieldStartHintText: 'mm/dd/yyyy',
    fieldEndHintText: 'mm/dd/yyyy',
  );

  if (res != null) {
    setState(() {
      _start = res.start;
      _end = res.end;
    });
    _apply();
  }
}
  void _apply() {
    ref.read(eventsFilterProvider.notifier).state = ref
        .read(eventsFilterProvider)
        .copyWith(q: _q.text, city: _city.text, start: _start, end: _end);
  }

  void _reset() {
    _q.clear();
    _city.clear();
    setState(() {
      _start = null;
      _end = null;
    });
    ref.read(eventsFilterProvider.notifier).state = const EventsFilter();
  }

  @override
  Widget build(BuildContext context) {

    final theme = ref.read(themeColorsProvider);
    final labelStyle = TextStyle(
      color: theme.textColor.withValues(alpha: 0.5),
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 1,
    );

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CustomColors.secondaryWidgetColor(context, ref),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FILTER EVENTS',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              IconButton(
                onPressed: _reset,
                icon: Icon(Icons.refresh, size: 20, color: theme.textColor),
                tooltip: 'Reset Filters',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search
          Text('SEARCH', style: labelStyle),
          const SizedBox(height: 8),
          CoreTextField(
            label: 'Keywords...',
            controller: _q,
            onSubmitted: (_) => _apply(),
          ),

          const SizedBox(height: 20),

          // City
          Text('CITY', style: labelStyle),
          const SizedBox(height: 8),
          CoreTextField(
            label: 'Enter city...',
            controller: _city,
            onSubmitted: (_) => _apply(),
          ),

          const SizedBox(height: 20),

          // Date Range
          Text('DATE RANGE', style: labelStyle),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDateRange,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.textColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.textColor.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 18, color: theme.textColor),
                  const SizedBox(width: 12),
                  Text(
                    _start == null || _end == null
                        ? 'Select range'
                        : '${DateFormat('MMM d').format(_start!)} - ${DateFormat('MMM d').format(_end!)}',
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: () {
              _apply();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redBeige,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'APPLY FILTERS',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

Widget pickerThemeBuilder(BuildContext context, Widget? child) {
  final theme = ref.watch(themeColorsProvider);
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final bg = CustomColors.secondaryWidgetColor(context, ref);
  final fg = isDark ? Colors.white : Colors.black87;
  final headerBg = theme.themeColor;
  final headerFg = Colors.white;

  final outline = OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: BorderSide(
      color: fg.withOpacity(0.22),
      width: 1.2,
    ),
  );

  final focusedOutline = OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: BorderSide(
      color: theme.themeColor,
      width: 1.5,
    ),
  );

  return Theme(
    data: Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: theme.themeColor,
        onPrimary: Colors.white,
        surface: bg,
        onSurface: fg,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.04),
        labelStyle: TextStyle(
          color: fg,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: fg.withOpacity(0.6),
        ),
        floatingLabelStyle: TextStyle(
          color: theme.themeColor,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: outline,
        enabledBorder: outline,
        focusedBorder: focusedOutline,
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: bg,
        rangePickerBackgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        rangePickerSurfaceTintColor: Colors.transparent,
        headerBackgroundColor: headerBg,
        headerForegroundColor: headerFg,
        headerHeadlineStyle: TextStyle(
          color:theme.textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        headerHelpStyle: TextStyle(
          color:theme.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        rangePickerHeaderBackgroundColor: headerBg,
        rangePickerHeaderForegroundColor: headerFg,
        rangePickerHeaderHeadlineStyle: TextStyle(
          color:theme.textColor,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        rangePickerHeaderHelpStyle: TextStyle(
          color:theme.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),

        dividerColor: fg.withOpacity(0.1),

        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) {
            return fg.withOpacity(0.35);
          }
          return fg;
        }),

        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return theme.themeColor;
          }
          return null;
        }),

        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) {
            return fg.withOpacity(0.35);
          }
          return fg;
        }),

        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return theme.themeColor;
          }
          return null;
        }),

        todayForegroundColor: WidgetStatePropertyAll(theme.themeColor),
        todayBorder: BorderSide(color: theme.themeColor),

        rangeSelectionBackgroundColor: theme.themeColor.withOpacity(0.2),

        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: theme.textColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: theme.textColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: theme.textColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,  
          ),
        ),
      ),

      iconTheme: IconThemeData(
        color: theme.textColor,
      ),

      textTheme: Theme.of(context).textTheme.copyWith(
        bodyLarge: TextStyle(color: fg),
        bodyMedium: TextStyle(color: fg),
        titleMedium: TextStyle(color: fg),
      ),
    ),
    child: child!,
  );
}
}
