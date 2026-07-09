import 'package:crm/calendar/widgets/member_calendar_hr_layer.dart';
import 'package:flutter/material.dart';

/// Displays a member's calendar using the HR availability + events preview.
/// Uses [EmployeeHrCalendarPreview] — the same component as the employee panel calendar tab.
class MemberCalendarPanel extends StatelessWidget {
  final int memberId;
  final bool isMobile;

  const MemberCalendarPanel({
    super.key,
    required this.memberId,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return EmployeeHrCalendarPreview(
      key: ValueKey<String>('member-calendar-$memberId'),
      memberId: memberId,
      initialDate: DateTime.now(),
      initiallyShowEvents: true,
      initiallyShowAvailability: true,
    );
  }
}
