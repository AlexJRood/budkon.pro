import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:core/theme/apptheme.dart';

Future<DateTimeRange?> showCustomDateRangePicker({
  required BuildContext context,
  required WidgetRef ref,
  DateTimeRange? initialDateRange,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? currentDate,
  bool useRootNavigator = true,
  Offset? anchorPoint,
}) async {
  final theme = ref.watch(themeColorsProvider);
  
  return await showDialog<DateTimeRange>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: theme.dashboardContainer,
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomDateRangePickerDialog(
          initialDateRange: initialDateRange,
          firstDate: firstDate,
          lastDate: lastDate,
          currentDate: currentDate,
          theme: theme,
        ),
      );
    },
    anchorPoint: anchorPoint,
  );
}

class CustomDateRangePickerDialog extends StatefulWidget {
  final DateTimeRange? initialDateRange;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? currentDate;
  final ThemeColors theme;

  const CustomDateRangePickerDialog({
    super.key,
    this.initialDateRange,
    required this.firstDate,
    required this.lastDate,
    this.currentDate,
    required this.theme,
  });

  @override
  _CustomDateRangePickerDialogState createState() => _CustomDateRangePickerDialogState();
}

class _CustomDateRangePickerDialogState extends State<CustomDateRangePickerDialog> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  DatePickerEntryMode _entryMode = DatePickerEntryMode.calendar;
  late DateTime _displayedMonth; 

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDateRange?.start;
    _endDate = widget.initialDateRange?.end;
    _displayedMonth = widget.currentDate ?? DateTime.now();
    _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
  }

  void _handleDateChanged(DateTime date) {
    setState(() {
      if (_startDate == null) {
        _startDate = date;
      } else if (_endDate == null && !date.isBefore(_startDate!)) {
        _endDate = date;
      } else {
        _startDate = date;
        _endDate = null;
      }
    });
  }

  void _previousMonth() => setState(() => _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1));

  void _nextMonth() => setState(() => _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1));

  void _toggleEntryMode() {
    setState(() {
      _entryMode = _entryMode == DatePickerEntryMode.calendar 
          ? DatePickerEntryMode.input 
          : DatePickerEntryMode.calendar;
    });
  }

  void _confirmSelection() {
    if (_startDate != null && _endDate != null) {
      Navigator.pop(context, DateTimeRange(start: _startDate!, end: _endDate!));
    }
  }

  void _cancelSelection() => Navigator.pop(context);

  String _formatDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);

  @override
  Widget build(BuildContext context) {
    final currentDate = widget.currentDate ?? DateTime.now();
    final startText = _startDate != null ? _formatDate(_startDate!) : 'Start Date';
    final endText = _endDate != null ? _formatDate(_endDate!) : 'End Date';

    return SizedBox(
      width: 400,
      height: 500,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.theme.themeColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _cancelSelection,
                ),
                Expanded(
                  child: Text(
                    'Select Date Range',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _entryMode == DatePickerEntryMode.calendar 
                        ? Icons.edit 
                        : Icons.calendar_today,
                    color: Colors.white,
                  ),
                  onPressed: _toggleEntryMode,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: widget.theme.dashboardBoarder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.theme.textColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      startText,
                      style: TextStyle(
                        fontSize: 16,
                        color: widget.theme.textColor,
                        fontWeight: _startDate != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward, color: widget.theme.textColor),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.theme.textColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      endText,
                      style: TextStyle(
                        fontSize: 16,
                        color: widget.theme.textColor,
                        fontWeight: _endDate != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _entryMode == DatePickerEntryMode.calendar
                ? _buildCalendarPicker()
                : _buildInputPicker(),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: widget.theme.dashboardBoarder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _cancelSelection,
                  child: Text(
                    'CANCEL',
                    style: TextStyle(color: widget.theme.textColor),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.theme.themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: _startDate != null && _endDate != null ? _confirmSelection : null,
                  child: Text(
                    'APPLY',
                    style: TextStyle(color: widget.theme.themeTextColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: widget.theme.textColor),
                  onPressed: _previousMonth,
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_displayedMonth),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.theme.textColor,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: widget.theme.textColor),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        color: widget.theme.textColor.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _SimpleCalendarGrid(
              displayedMonth: _displayedMonth,
              startDate: _startDate,
              endDate: _endDate,
              onDateSelected: _handleDateChanged,
              theme: widget.theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _DateInputField(
            label: 'Start Date',
            initialDate: _startDate,
            onDateChanged: (date) => setState(() => _startDate = date),
            theme: widget.theme,
          ),
          const SizedBox(height: 16),
          _DateInputField(
            label: 'End Date',
            initialDate: _endDate,
            onDateChanged: (date) => setState(() => _endDate = date),
            theme: widget.theme,
          ),
          const Spacer(),
          Text(
            'Enter dates in format: MM/DD/YYYY',
            style: TextStyle(
              color: widget.theme.textColor.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleCalendarGrid extends StatelessWidget {
  final DateTime displayedMonth;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime) onDateSelected;
  final ThemeColors theme;

  const _SimpleCalendarGrid({
    required this.displayedMonth,
    required this.startDate,
    required this.endDate,
    required this.onDateSelected,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final year = displayedMonth.year;
    final month = displayedMonth.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstDayOfMonth = DateTime(year, month, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    final today = DateTime.now();

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(), 
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1.2, 
      ),
      itemCount: 42, 
      itemBuilder: (context, index) {
        final day = index - firstWeekday + 1;
        
        if (day < 1 || day > daysInMonth) {
          return const SizedBox(); 
        }

        final date = DateTime(year, month, day);
        final isStartDate = startDate != null && DateUtils.isSameDay(startDate, date);
        final isEndDate = endDate != null && DateUtils.isSameDay(endDate, date);
        final isInRange = startDate != null && endDate != null && 
            date.isAfter(startDate!) && date.isBefore(endDate!);
        final isToday = DateUtils.isSameDay(date, today);

        Color bgColor = Colors.transparent;
        Color textColor = theme.textColor;
        BorderRadius borderRadius = BorderRadius.circular(6);

        if (isStartDate || isEndDate) {
          bgColor = theme.themeColor;
          textColor = theme.themeTextColor;
        } else if (isInRange) {
          bgColor = theme.themeColor.withOpacity(0.2);
        } else if (isToday) {
          bgColor = theme.dashboardBoarder;
        }

        return GestureDetector(
          onTap: () => onDateSelected(date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: borderRadius,
              border: isToday && !isStartDate && !isEndDate
                  ? Border.all(color: theme.themeColor)
                  : null,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  color: textColor,
                  fontWeight: isStartDate || isEndDate ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DateInputField extends StatefulWidget {
  final String label;
  final DateTime? initialDate;
  final Function(DateTime?) onDateChanged;
  final ThemeColors theme;

  const _DateInputField({
    required this.label,
    this.initialDate,
    required this.onDateChanged,
    required this.theme,
  });

  @override
  _DateInputFieldState createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<_DateInputField> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _controller.text = DateFormat('MM/dd/yyyy').format(widget.initialDate!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _parseDate(String text) {
    try {
      final date = DateFormat('MM/dd/yyyy').parseStrict(text);
      setState(() => _errorText = null);
      widget.onDateChanged(date);
    } catch (e) {
      setState(() => _errorText = 'Invalid date format');
      widget.onDateChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: widget.theme.textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          cursorColor: widget.theme.textColor,
          decoration: InputDecoration(
            hintText: 'MM/DD/YYYY',
            hintStyle: TextStyle(color: widget.theme.textColor.withOpacity(0.5)),
            errorText: _errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: widget.theme.dashboardBoarder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: widget.theme.dashboardBoarder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: widget.theme.themeColor, width: 2),
            ),
            filled: true,
            fillColor: widget.theme.dashboardContainer,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          style: TextStyle(color: widget.theme.textColor),
          onChanged: _parseDate,
        ),
      ],
    );
  }
}