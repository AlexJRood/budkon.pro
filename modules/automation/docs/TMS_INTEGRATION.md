# TMS integration

Add a menu item/button to each task column:

```dart
PopupMenuItem(
  child: const Text('Automation Studio'),
  onTap: () {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      openTmsColumnAutomationStudio(
        context,
        columnId: column.id.toString(),
        columnKey: column.key,
        columnName: column.name,
        boardId: board.id.toString(),
        companyId: associationId,
        userId: currentUserId,
      );
    });
  },
)
```

Suggested events emitted by backend:

```txt
task.created
task.moved
task.completed
task.uncompleted
task.assigned
task.due_date_changed
task.overdue
```

Suggested payload for `task.moved`:

```json
{
  "task_id": 123,
  "board_id": 5,
  "old_column_id": 10,
  "new_column_id": 11,
  "old_column_key": "todo",
  "new_column_key": "done",
  "related_event_id": 55,
  "lead_id": 77,
  "moved_by_id": 1,
  "association_id": 8
}
```
