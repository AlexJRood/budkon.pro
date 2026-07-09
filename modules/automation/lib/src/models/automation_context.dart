import 'automation_common.dart';

class AutomationContextData {
  final String sourceModule;
  final String sourceType;
  final String? sourceId;
  final String? sourceLabel;

  final AutomationScopeType defaultScopeType;
  final int? companyId;
  final int? userId;

  final Map<String, dynamic> payload;
  final List<String> suggestedSignals;
  final List<String> suggestedActions;

  const AutomationContextData({
    required this.sourceModule,
    required this.sourceType,
    this.sourceId,
    this.sourceLabel,
    this.defaultScopeType = AutomationScopeType.user,
    this.companyId,
    this.userId,
    this.payload = const {},
    this.suggestedSignals = const [],
    this.suggestedActions = const [],
  });

  factory AutomationContextData.dashboard({
    String? dashboardId,
    String? dashboardName,
    String dashboardType = 'main',
    int? companyId,
    int? userId,
    AutomationScopeType? defaultScopeType,
    Map<String, dynamic> payload = const {},
  }) {
    return AutomationContextData(
      sourceModule: 'dynamic_dashboard',
      sourceType: 'dashboard',
      sourceId: dashboardId,
      sourceLabel: dashboardName ?? 'Dashboard',
      defaultScopeType: defaultScopeType ??
          (companyId != null
              ? AutomationScopeType.company
              : AutomationScopeType.user),
      companyId: companyId,
      userId: userId,
      payload: {
        'dashboard_id': dashboardId,
        'dashboard_name': dashboardName,
        'dashboard_type': dashboardType,
        ...payload,
      },
      suggestedSignals: const [
        'dashboard.opened',
        'dashboard.widget_added',
        'dashboard.widget_removed',
        'dashboard.widget_settings_changed',
      ],
      suggestedActions: const [
        'send_notification',
        'create_task',
        'update_record',
        'loyalty.emit_event',
      ],
    );
  }

  factory AutomationContextData.dashboardWidget({
    required String widgetType,
    String? widgetId,
    String? widgetTitle,
    String? dashboardId,
    String? dashboardName,
    int? companyId,
    int? userId,
    AutomationScopeType? defaultScopeType,
    Map<String, dynamic> settings = const {},
    Map<String, dynamic> payload = const {},
  }) {
    return AutomationContextData(
      sourceModule: 'dynamic_dashboard',
      sourceType: 'dashboard_widget',
      sourceId: widgetId ?? widgetType,
      sourceLabel: widgetTitle ?? widgetType,
      defaultScopeType: defaultScopeType ??
          (companyId != null
              ? AutomationScopeType.company
              : AutomationScopeType.user),
      companyId: companyId,
      userId: userId,
      payload: {
        'widget_id': widgetId,
        'widget_type': widgetType,
        'widget_title': widgetTitle,
        'dashboard_id': dashboardId,
        'dashboard_name': dashboardName,
        'settings': settings,
        ...payload,
      },
      suggestedSignals: const [
        'dashboard.widget_added',
        'dashboard.widget_removed',
        'dashboard.widget_settings_changed',
        'dashboard.widget_clicked',
      ],
      suggestedActions: const [
        'send_notification',
        'update_record',
        'create_record',
        'loyalty.emit_event',
      ],
    );
  }

  factory AutomationContextData.tmsBoard({
    required String boardId,
    required String boardName,
    int? companyId,
    int? userId,
    AutomationScopeType? defaultScopeType,
    Map<String, dynamic> payload = const {},
  }) {
    return AutomationContextData(
      sourceModule: 'tms',
      sourceType: 'task_board',
      sourceId: boardId,
      sourceLabel: boardName,
      defaultScopeType: defaultScopeType ??
          (companyId != null
              ? AutomationScopeType.company
              : AutomationScopeType.user),
      companyId: companyId,
      userId: userId,
      payload: {
        'board_id': boardId,
        'board_name': boardName,
        ...payload,
      },
      suggestedSignals: const [
        'task.created',
        'task.updated',
        'task.moved',
        'task.completed',
        'task.deadline_changed',
      ],
      suggestedActions: const [
        'create_task',
        'move_record',
        'set_status',
        'mark_done',
        'send_notification',
        'loyalty.emit_event',
      ],
    );
  }

  factory AutomationContextData.tmsColumn({
    required String columnId,
    required String columnKey,
    required String columnName,
    required String boardId,
    int? companyId,
    int? userId,
    AutomationScopeType? defaultScopeType,
    Map<String, dynamic> payload = const {},
  }) {
    return AutomationContextData(
      sourceModule: 'tms',
      sourceType: 'task_column',
      sourceId: columnId,
      sourceLabel: columnName,
      defaultScopeType: defaultScopeType ??
          (companyId != null
              ? AutomationScopeType.company
              : AutomationScopeType.user),
      companyId: companyId,
      userId: userId,
      payload: {
        'column_id': columnId,
        'column_key': columnKey,
        'column_name': columnName,
        'board_id': boardId,
        ...payload,
      },
      suggestedSignals: const [
        'task.moved',
        'task.created',
        'task.completed',
        'task.entered_column',
        'task.left_column',
      ],
      suggestedActions: const [
        'move_record',
        'mark_done',
        'set_status',
        'send_notification',
        'loyalty.emit_event',
      ],
    );
  }

  factory AutomationContextData.calendarEvent({
    required String eventId,
    String? eventTitle,
    String? clientId,
    int? companyId,
    int? userId,
    Map<String, dynamic> payload = const {},
  }) {
    return AutomationContextData(
      sourceModule: 'calendar',
      sourceType: 'calendar_event',
      sourceId: eventId,
      sourceLabel: eventTitle ?? 'Calendar event',
      defaultScopeType: companyId != null
          ? AutomationScopeType.company
          : AutomationScopeType.user,
      companyId: companyId,
      userId: userId,
      payload: {
        'event_id': eventId,
        'event_title': eventTitle,
        'client_id': clientId,
        ...payload,
      },
      suggestedSignals: const [
        'calendar.event.created',
        'calendar.event.updated',
        'calendar.event.done',
        'calendar.event.cancelled',
      ],
      suggestedActions: const [
        'mark_done',
        'move_record',
        'create_task',
        'loyalty.emit_event',
      ],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source_module': sourceModule,
      'source_type': sourceType,
      'source_id': sourceId,
      'source_label': sourceLabel,
      'default_scope_type': enumName(defaultScopeType),
      'company_id': companyId,
      'user_id': userId,
      'payload': payload,
      'suggested_signals': suggestedSignals,
      'suggested_actions': suggestedActions,
    };
  }
}
