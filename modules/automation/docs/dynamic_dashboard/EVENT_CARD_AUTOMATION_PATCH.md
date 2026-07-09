# Calendar/Event card contextual Automation Studio button

Your event card already has a `more_vert_rounded` icon button inside each event row. You can replace that `IconButton` with a popup menu that opens Automation Studio for this exact event.

Add import:

```dart
import 'package:automation_studio/automation_studio.dart';
```

Replace the current empty `onPressed: () {}` more button with:

```dart
PopupMenuButton<String>(
  tooltip: 'Event options'.tr,
  icon: Icon(
    Icons.more_vert_rounded,
    color: theme.textColor,
    size: 14,
  ),
  onSelected: (value) {
    if (value == 'automation') {
      showAutomationStudioPopup(
        context,
        contextData: AutomationContextData.calendarEvent(
          eventId: event.id.toString(),
          eventTitle: event.title,
          clientId: clientId,
          payload: {
            'location': event.location,
            'from': event.from.toIso8601String(),
            'to': event.to.toIso8601String(),
            'calendar': event.calendar,
          },
        ),
      );
    }
  },
  itemBuilder: (context) => [
    PopupMenuItem(
      value: 'automation',
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_motion_rounded, size: 18),
          const SizedBox(width: 10),
          Text('Automation Studio'.tr),
        ],
      ),
    ),
  ],
)
```

This opens the same popup as TMS columns, but scoped to `calendar_event`.
