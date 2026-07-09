// lib/emma/tools/tool_type.dart

/// Główny moduł narzędzia – odpowiada backendowemu `module`.
enum AiModule {
  crm,
  calendar,
  tms,
  finance,
  email,
  docs,
  notes,
  memos,
  realestate,
  dynamicApp,
  automation,
  multi,
  unknown,
}

enum AutomationToolKind {
  createWorkflow,
  updateWorkflow,
  activateWorkflow,
  deactivateWorkflow,
  dryRun,
  getWorkflow,
  listWorkflows,
  explainWorkflow,
  createConnector,
  testConnector,
  unknown,
}

/// Enum per moduł: kalendarz
enum CalendarToolKind {
  createEvent,
  listUpcomingEvents,
  updateCalendar,
  unknown,
}

/// Enum per moduł: e-mail
enum EmailToolKind {
  sendMessage,
  scheduleMessage,
  listMessages,
  searchMessages,
  getMessage,
  unknown,
}

/// Enum per moduł: finanse
enum FinanceToolKind {
  createExpense,
  listExpenses,
  getExpense,
  updateExpense,
  deleteExpense,
  createRevenue,
  listRevenues,
  getRevenue,
  updateRevenue,
  deleteRevenue,
  unknown,
}

/// Enum per moduł: notatki
enum NoteToolKind {
  createNote,
  updateNote,
  deleteNote,
  listNotes,
  unknown,
}

/// Enum per moduł: TMS / zadania
enum TmsToolKind {
  createTask,
  updateTask,
  deleteTask,
  unknown,
}

class AiToolDescriptor {
  /// Rozpoznany moduł (calendar / email / finance / …).
  final AiModule module;

  /// Nazwa systemowa narzędzia, np. `calendar_create_event`.
  final String name;

  /// Status z backendu: success / error / pending.
  final String status;

  /// Wynik narzędzia (payload JSON).
  final Map<String, dynamic> result;

  /// Skrócona flaga sukcesu.
  final bool ok;

  /// Enumy per moduł – tylko jeden z nich ma sens dla danego modułu.
  final CalendarToolKind? calendarKind;
  final EmailToolKind? emailKind;
  final FinanceToolKind? financeKind;
  final NoteToolKind? noteKind;
  final TmsToolKind? tmsKind;
  final AutomationToolKind? automationKind;

  const AiToolDescriptor({
    required this.module,
    required this.name,
    required this.status,
    required this.result,
    required this.ok,
    this.calendarKind,
    this.emailKind,
    this.financeKind,
    this.noteKind,
    this.tmsKind,
    this.automationKind,
  });

  factory AiToolDescriptor.fromRaw(Map<String, dynamic> raw) {
    final rawName = raw['name'] as String? ?? 'tool';
    final rawModule = raw['module'] as String? ?? '';
    final result = (raw['result'] as Map?) != null
        ? Map<String, dynamic>.from(raw['result'] as Map)
        : <String, dynamic>{};
    final ok = raw['ok'] == true;
    final status = raw['status'] as String? ?? (ok ? 'success' : 'error');

    final module = _detectModule(rawModule, rawName);

    CalendarToolKind? calendarKind;
    EmailToolKind? emailKind;
    FinanceToolKind? financeKind;
    NoteToolKind? noteKind;
    TmsToolKind? tmsKind;
    AutomationToolKind? automationKind;

    switch (module) {
      case AiModule.calendar:
        calendarKind = _detectCalendarKind(rawName);
        break;
      case AiModule.email:
        emailKind = _detectEmailKind(rawName);
        break;
      case AiModule.finance:
        financeKind = _detectFinanceKind(rawName);
        break;
      case AiModule.notes:
        noteKind = _detectNoteKind(rawName);
        break;
      case AiModule.tms:
        tmsKind = _detectTmsKind(rawName);
        break;
      case AiModule.automation:
        automationKind = _detectAutomationKind(rawName);
        break;
      default:
        break;
    }

    return AiToolDescriptor(
      module: module,
      name: rawName,
      status: status,
      result: result,
      ok: ok,
      calendarKind: calendarKind,
      emailKind: emailKind,
      financeKind: financeKind,
      noteKind: noteKind,
      tmsKind: tmsKind,
      automationKind: automationKind,
    );
  }

  // ---------- helpers: module ----------

static AiModule _detectModule(String module, String name) {
  switch (module) {
    case 'crm':
      return AiModule.crm;
    case 'calendar':
      return AiModule.calendar;
    case 'tms':
      return AiModule.tms;
    case 'finance':
      return AiModule.finance;
    case 'email':
      return AiModule.email;
    case 'docs':
      return AiModule.docs;
    case 'notes':
      return AiModule.notes;
    case 'memos':
      return AiModule.memos;
    case 'realestate':
      return AiModule.realestate;
    case 'dynamic_app':
      return AiModule.dynamicApp;
    case 'automation':
      return AiModule.automation;
    case 'multi':
      return AiModule.multi;
  }

  // fallback po prefiksie nazwy
  if (name.startsWith('crm_')) return AiModule.crm;
  if (name.startsWith('calendar_')) return AiModule.calendar;
  if (name.startsWith('tms_')) return AiModule.tms;
  if (name.startsWith('finance_')) return AiModule.finance;
  if (name.startsWith('email_')) return AiModule.email;
  if (name.startsWith('docs_')) return AiModule.docs;
  if (name.startsWith('notes_')) return AiModule.notes;
  if (name.startsWith('memos_')) return AiModule.memos;
  if (name.startsWith('realestate_')) return AiModule.realestate;
  if (name.startsWith('dynamic_')) return AiModule.dynamicApp;
  if (name.startsWith('automation_')) return AiModule.automation;
  if (name == 'multi_tool_use.parallel') return AiModule.multi;

  return AiModule.unknown;
}


  // ---------- helpers: calendar ----------

  static CalendarToolKind _detectCalendarKind(String name) {
    switch (name) {
      case 'calendar_create_event':
        return CalendarToolKind.createEvent;
      case 'calendar_list_upcoming_events':
        return CalendarToolKind.listUpcomingEvents;
      case 'calendar_update_calendar':
        return CalendarToolKind.updateCalendar;
      default:
        return CalendarToolKind.unknown;
    }
  }

  // ---------- helpers: email ----------

  static EmailToolKind _detectEmailKind(String name) {
    switch (name) {
      case 'email_send_message':
        return EmailToolKind.sendMessage;
      case 'email_schedule_message':
        return EmailToolKind.scheduleMessage;
      case 'email_list_messages':
        return EmailToolKind.listMessages;
      case 'email_search_messages':
        return EmailToolKind.searchMessages;
      case 'email_get_message':
        return EmailToolKind.getMessage;
      default:
        return EmailToolKind.unknown;
    }
  }

  // ---------- helpers: finance ----------

  static FinanceToolKind _detectFinanceKind(String name) {
    switch (name) {
      case 'finance_create_expense':
        return FinanceToolKind.createExpense;
      case 'finance_list_expenses':
        return FinanceToolKind.listExpenses;
      case 'finance_get_expense':
        return FinanceToolKind.getExpense;
      case 'finance_update_expense':
        return FinanceToolKind.updateExpense;
      case 'finance_delete_expense':
        return FinanceToolKind.deleteExpense;
      case 'finance_create_revenue':
        return FinanceToolKind.createRevenue;
      case 'finance_list_revenues':
        return FinanceToolKind.listRevenues;
      case 'finance_get_revenue':
        return FinanceToolKind.getRevenue;
      case 'finance_update_revenue':
        return FinanceToolKind.updateRevenue;
      case 'finance_delete_revenue':
        return FinanceToolKind.deleteRevenue;
      default:
        return FinanceToolKind.unknown;
    }
  }

  // ---------- helpers: notes ----------

  static NoteToolKind _detectNoteKind(String name) {
    switch (name) {
      case 'notes_create_note':
        return NoteToolKind.createNote;
      case 'notes_update_note':
        return NoteToolKind.updateNote;
      case 'notes_delete_note':
        return NoteToolKind.deleteNote;
      case 'notes_list_notes':
        return NoteToolKind.listNotes;
      default:
        return NoteToolKind.unknown;
    }
  }

  // ---------- helpers: tms ----------

  static TmsToolKind _detectTmsKind(String name) {
    switch (name) {
      case 'tms_create_task':
        return TmsToolKind.createTask;
      case 'tms_update_task':
        return TmsToolKind.updateTask;
      case 'tms_delete_task':
        return TmsToolKind.deleteTask;
      default:
        return TmsToolKind.unknown;
    }
  }

  // ---------- helpers: automation ----------

  static AutomationToolKind _detectAutomationKind(String name) {
    switch (name) {
      case 'automation_create_workflow':
        return AutomationToolKind.createWorkflow;
      case 'automation_update_workflow':
        return AutomationToolKind.updateWorkflow;
      case 'automation_activate_workflow':
        return AutomationToolKind.activateWorkflow;
      case 'automation_deactivate_workflow':
        return AutomationToolKind.deactivateWorkflow;
      case 'automation_dry_run':
        return AutomationToolKind.dryRun;
      case 'automation_get_workflow':
        return AutomationToolKind.getWorkflow;
      case 'automation_list_workflows':
        return AutomationToolKind.listWorkflows;
      case 'automation_explain_workflow':
        return AutomationToolKind.explainWorkflow;
      case 'automation_connect_api':
      case 'automation_create_connector':
        return AutomationToolKind.createConnector;
      case 'automation_test_connector':
        return AutomationToolKind.testConnector;
      default:
        return AutomationToolKind.unknown;
    }
  }
}
