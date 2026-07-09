import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class DateSelectionRow extends StatefulWidget {
  final String todaydate;
  final String tomorowsdate;
  final Function(DateTime? issueDate, DateTime? dueDate) onDatesChanged;

  const DateSelectionRow(
      {super.key, required this.onDatesChanged,
      required this.todaydate,
      required this.tomorowsdate});

  @override
  // ignore: library_private_types_in_public_api
  _DateSelectionRowState createState() => _DateSelectionRowState();
}

class _DateSelectionRowState extends State<DateSelectionRow> {
  DateTime? issueDate;
  DateTime? dueDate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(
              hintStyle: TextStyle(
                  color: issueDate == null ? Colors.grey[700] : Colors.black),
              hintText: issueDate == null
                  ? widget.todaydate.toString()
                  : DateFormat('MM.dd.yyyy').format(issueDate!),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.grey[300],
            ),
            readOnly: true, // Make it read-only to avoid keyboard pop-up
            onTap: () {
              _selectDate(context, isIssueDate: true);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(
              hintStyle: TextStyle(
                  color: dueDate == null ? Colors.grey[700] : Colors.black),
              hintText: dueDate == null
                  ? widget.tomorowsdate.toString()
                  : DateFormat('MM.dd.yyyy').format(dueDate!),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.grey[300],
            ),
            readOnly: true, // Make it read-only to avoid keyboard pop-up
            onTap: () {
              _selectDate(context, isIssueDate: false);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context,
      {required bool isIssueDate}) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isIssueDate
          ? (issueDate ?? DateTime.now())
          : (dueDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        if (isIssueDate) {
          issueDate = pickedDate;
        } else {
          dueDate = pickedDate;
        }
      });
      // Call the callback function to notify parent widget
      widget.onDatesChanged(issueDate, dueDate);
    }
  }
}
