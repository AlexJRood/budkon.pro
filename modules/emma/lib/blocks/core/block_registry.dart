import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:emma/blocks/definitions/calendar/event_block.dart';
import 'package:emma/blocks/definitions/calendar/event_list_block.dart';

import 'package:emma/blocks/definitions/email_draft_block.dart';
import 'package:emma/blocks/definitions/email_list_block.dart';
import 'package:emma/blocks/definitions/choice_question_block.dart';
import 'package:emma/blocks/definitions/web_sources_block.dart';
import 'package:emma/blocks/definitions/image_block.dart';
import 'package:emma/blocks/definitions/generic_block.dart';
import 'package:emma/blocks/definitions/info_block.dart';
import 'package:emma/blocks/definitions/loading_block.dart';

import 'package:emma/blocks/definitions/memos/memo_daily_block.dart';

import 'package:emma/blocks/definitions/proactive/suggestion_reply_block.dart';
import 'package:emma/blocks/definitions/proactive/suggestion_event_block.dart';
import 'package:emma/blocks/definitions/proactive/suggestion_task_block.dart';
import 'package:emma/blocks/definitions/proactive/suggestion_invite_response_block.dart';
import 'package:emma/blocks/definitions/proactive/suggestion_przetarg_block.dart';

import 'package:emma/blocks/definitions/tms/board_list_block.dart';
import 'package:emma/blocks/definitions/tms/progress_column_block.dart';
import 'package:emma/blocks/definitions/tms/project_block.dart';
import 'package:emma/blocks/definitions/tms/task_block.dart';
import 'package:emma/blocks/definitions/tms/task_delete_result_block.dart';
import 'package:emma/blocks/definitions/tms/task_list_block.dart';

import 'package:emma/blocks/definitions/anchors/action_block.dart';
import 'package:emma/blocks/definitions/anchors/search_results.dart';

import 'package:emma/blocks/definitions/advertisements/ad_card_block.dart';
import 'package:emma/blocks/definitions/advertisements/ad_list_block.dart';
import 'package:emma/blocks/definitions/advertisements/ad_comparison_block.dart';
import 'package:emma/blocks/definitions/advertisements/mortgage_result_block.dart';

import 'package:emma/blocks/definitions/docs/docs_text_edit_block.dart';
import 'package:emma/blocks/definitions/docs/docs_create_from_contact_block.dart';
import 'package:emma/blocks/definitions/transactions/document_pipeline_block.dart';

import 'package:emma/blocks/definitions/automation/automation_workflow_block.dart';
import 'package:emma/blocks/definitions/automation/automation_dry_run_block.dart';
import 'package:emma/blocks/definitions/automation/automation_setup_wizard_block.dart';
import 'package:emma/blocks/definitions/automation/automation_connector_block.dart';

import 'block_definition.dart';
import 'block_descriptor.dart';

class ResolvedEmmaBlock {
  final EmmaBlockDescriptor block;
  final EmmaBlockDefinition definition;

  const ResolvedEmmaBlock({
    required this.block,
    required this.definition,
  });
}

class EmmaBlockRegistry {
  final List<EmmaBlockDefinition> definitions;
  final EmmaBlockDefinition fallback;

  const EmmaBlockRegistry({
    required this.definitions,
    required this.fallback,
  });

  EmmaBlockDefinition resolve(EmmaBlockDescriptor block) {
    for (final definition in definitions) {
      if (definition.supports(block)) return definition;
    }

    final byAlias = _resolveByAlias(block);
    if (byAlias != null) return byAlias;

    final byToolName = _resolveByToolName(block);
    if (byToolName != null) return byToolName;

    final byShape = _resolveByPayloadShape(block);
    if (byShape != null) return byShape;

    return fallback;
  }

  EmmaBlockDefinition? _resolveByAlias(EmmaBlockDescriptor block) {
    final type = _rawType(block);

    if (type.isEmpty) return null;

    switch (type) {
      case 'info':
      case 'message':
      case 'notice':
      case 'notification':
      case 'status':
      case 'success':
      case 'warning':
      case 'error':
      case 'local_tool_action':
      case 'tool_action':
      case 'tool_result':
      case 'local_tool_result':
        return _findDefinition<InfoBlockDefinition>();

      case 'loading':
      case 'loader':
      case 'spinner':
      case 'pending':
      case 'thinking':
      case 'progress':
        return _findDefinition<LoadingBlockDefinition>();

      case 'email_draft':
      case 'email_compose':
      case 'email_message_draft':
      case 'mail_draft':
      case 'draft_email':
      case 'draft_message':
        return _findDefinition<EmailDraftBlockDefinition>();

      case 'email_list':
      case 'email_messages':
      case 'mail_list':
      case 'mailbox_list':
      case 'message_list':
        return _findDefinition<EmailListBlockDefinition>();

      case 'calendar_event':
      case 'event':
      case 'created_event':
      case 'calendar_created_event':
      case 'calendar_event_created':
        return _findDefinition<CalendarEventBlockDefinition>();

      case 'calendar_event_list':
      case 'calendar_events':
      case 'event_list':
      case 'events_list':
      case 'calendar_list':
      case 'upcoming_events':
        return _findDefinition<CalendarEventListBlockDefinition>();

      case 'tms_task':
      case 'task':
      case 'todo':
      case 'todo_task':
      case 'kanban_task':
      case 'created_task':
      case 'task_created':
        return _findDefinition<TmsTaskBlockDefinition>();

      case 'tms_task_list':
      case 'task_list':
      case 'tasks':
      case 'todo_list':
      case 'kanban_tasks':
        return _findDefinition<TmsTaskListBlockDefinition>();

      case 'tms_task_delete_result':
      case 'task_delete_result':
      case 'deleted_task':
      case 'task_deleted':
        return _findDefinition<TmsTaskDeleteResultBlockDefinition>();

      case 'tms_project':
      case 'project':
      case 'board':
      case 'tms_board':
      case 'created_project':
      case 'created_board':
        return _findDefinition<TmsProjectBlockDefinition>();

      case 'tms_progress_column':
      case 'progress_column':
      case 'task_column':
      case 'kanban_column':
      case 'tms_column':
      case 'created_column':
        return _findDefinition<TmsProgressColumnBlockDefinition>();

      case 'tms_board_list':
      case 'board_list':
      case 'project_list':
      case 'boards':
      case 'projects':
      case 'tms_projects':
      case 'tms_boards':
        return _findDefinition<TmsBoardListBlockDefinition>();

      case 'ui_anchor_search_results':
      case 'anchor_search_results':
      case 'ui_search_results':
      case 'search_anchors':
      case 'ui_anchors':
        return _findDefinition<UiAnchorSearchResultsBlockDefinition>();

      case 'ui_anchor_action':
      case 'anchor_action':
      case 'ui_action':
      case 'highlight_anchor':
      case 'open_anchor':
        return _findDefinition<UiAnchorActionBlockDefinition>();

      case 'memo_daily':
      case 'daily_memo':
      case 'memo_daily_overview':
      case 'daily_overview':
      case 'memos_daily':
        return _findDefinition<MemoDailyBlockDefinition>();

      case 'suggestion_reply':
      case 'proactive_reply':
        return _findDefinition<SuggestionReplyBlockDefinition>();

      case 'suggestion_event':
      case 'proactive_event':
        return _findDefinition<SuggestionEventBlockDefinition>();

      case 'suggestion_task':
      case 'proactive_task':
        return _findDefinition<SuggestionTaskBlockDefinition>();

      case 'suggestion_przetarg':
      case 'przetarg_suggestion':
        return _findDefinition<SuggestionPrzetargBlockDefinition>();

      case 'suggestion_invite_response':
      case 'proactive_invite_response':
      case 'invite_response':
        return _findDefinition<SuggestionInviteResponseBlockDefinition>();

      case 'advertisement_card':
      case 'ad_card':
      case 'property_card':
      case 'listing_card':
        return _findDefinition<AdCardBlockDefinition>();

      case 'advertisement_list':
      case 'ad_list':
      case 'property_list':
      case 'listing_list':
      case 'similar_ads':
        return _findDefinition<AdListBlockDefinition>();

      case 'advertisement_comparison':
      case 'ad_comparison':
      case 'property_comparison':
      case 'listing_comparison':
        return _findDefinition<AdComparisonBlockDefinition>();

      case 'mortgage_result':
      case 'mortgage_calculator':
      case 'kredyt_wynik':
        return _findDefinition<MortgageResultBlockDefinition>();

      case 'docs_text_edit':
      case 'text_edit':
      case 'doc_text_edit':
        return _findDefinition<DocsTextEditBlockDefinition>();

      case 'docs_create_from_contact':
      case 'doc_create_from_contact':
      case 'create_from_contact':
        return _findDefinition<DocsCreateFromContactBlockDefinition>();

      case 'transaction_document_pipeline':
      case 'doc_pipeline':
      case 'document_pipeline':
      case 'missing_documents':
        return _findDefinition<DocumentPipelineBlockDefinition>();

      case 'choice_question':
      case 'question':
      case 'quick_replies':
      case 'ask_user':
        return _findDefinition<ChoiceQuestionBlockDefinition>();

      case 'web_sources':
      case 'search_sources':
      case 'sources':
        return _findDefinition<WebSourcesBlockDefinition>();

      case 'image':
      case 'generated_image':
        return _findDefinition<ImageBlockDefinition>();

      case 'automation_workflow':
      case 'automation_draft':
      case 'automation_created':
      case 'automation_updated':
      case 'automation_activated':
        return _findDefinition<AutomationWorkflowBlockDefinition>();

      case 'automation_dry_run':
      case 'automation_dry_run_result':
        return _findDefinition<AutomationDryRunBlockDefinition>();

      case 'automation_setup_wizard':
      case 'automation_wizard':
      case 'automation_questions':
        return _findDefinition<AutomationSetupWizardBlockDefinition>();

      case 'automation_connector':
      case 'automation_api_connector':
      case 'external_api_connector':
        return _findDefinition<AutomationConnectorBlockDefinition>();
    }

    return null;
  }

  EmmaBlockDefinition? _resolveByToolName(EmmaBlockDescriptor block) {
    final toolName = _toolName(block);

    if (toolName.isEmpty) return null;

    if (toolName == 'calendar_create_event') {
      return _findDefinition<CalendarEventBlockDefinition>();
    }

    if (toolName == 'calendar_list_upcoming_events') {
      return _findDefinition<CalendarEventListBlockDefinition>();
    }

    if (toolName == 'tms_create_task' ||
        toolName == 'tms_update_task' ||
        toolName == 'tms_move_task' ||
        toolName == 'tms_complete_task') {
      return _findDefinition<TmsTaskBlockDefinition>();
    }

    if (toolName == 'tms_delete_task') {
      return _findDefinition<TmsTaskDeleteResultBlockDefinition>();
    }

    if (toolName == 'tms_list_tasks') {
      return _findDefinition<TmsTaskListBlockDefinition>();
    }

    if (toolName == 'tms_create_project') {
      return _findDefinition<TmsProjectBlockDefinition>();
    }

    if (toolName == 'tms_create_progress_column') {
      return _findDefinition<TmsProgressColumnBlockDefinition>();
    }

    if (toolName == 'tms_list_boards') {
      return _findDefinition<TmsBoardListBlockDefinition>();
    }

    if (toolName == 'email_send_message' ||
        toolName == 'email_schedule_message') {
      return _findDefinition<EmailDraftBlockDefinition>();
    }

    if (toolName == 'email_list_messages' ||
        toolName == 'email_search_messages' ||
        toolName == 'email_check_mailbox') {
      return _findDefinition<EmailListBlockDefinition>();
    }

    if (toolName == 'ui_search_anchors') {
      return _findDefinition<UiAnchorSearchResultsBlockDefinition>();
    }

    if (toolName == 'ui_highlight_anchor' ||
        toolName == 'ui_open_selected_anchor' ||
        toolName == 'ui_show_chat_form' ||
        toolName == 'ui_start_flow') {
      return _findDefinition<UiAnchorActionBlockDefinition>();
    }

    if (toolName == 'memos_collect_daily_overview' ||
        toolName == 'memos_collect_followup_for_day') {
      return _findDefinition<MemoDailyBlockDefinition>();
    }

    if (toolName == 'advertisements_get_ad') {
      return _findDefinition<AdCardBlockDefinition>();
    }

    if (toolName == 'advertisements_similar_ads' ||
        toolName == 'advertisements_search_ads' ||
        toolName == 'advertisements_list_favorite_ads') {
      return _findDefinition<AdListBlockDefinition>();
    }

    if (toolName == 'advertisements_compare_ads') {
      return _findDefinition<AdComparisonBlockDefinition>();
    }

    if (toolName == 'advertisements_calculate_mortgage') {
      return _findDefinition<MortgageResultBlockDefinition>();
    }

    if (toolName == 'automation_create_workflow' ||
        toolName == 'automation_update_workflow' ||
        toolName == 'automation_activate_workflow' ||
        toolName == 'automation_deactivate_workflow' ||
        toolName == 'automation_get_workflow') {
      return _findDefinition<AutomationWorkflowBlockDefinition>();
    }

    if (toolName == 'automation_dry_run') {
      return _findDefinition<AutomationDryRunBlockDefinition>();
    }

    if (toolName == 'automation_list_workflows') {
      return _findDefinition<AutomationWorkflowBlockDefinition>();
    }

    if (toolName == 'automation_create_connector' ||
        toolName == 'automation_connect_api') {
      return _findDefinition<AutomationConnectorBlockDefinition>();
    }

    return null;
  }

  EmmaBlockDefinition? _resolveByPayloadShape(EmmaBlockDescriptor block) {
    final raw = block.raw;

    final event = raw['event'];
    if (event is Map) {
      final eventMap = Map<String, dynamic>.from(event);
      if (_hasAnyKey(eventMap, const [
        'start_time',
        'end_time',
        'calendar_id',
        'calendar_name',
      ])) {
        return _findDefinition<CalendarEventBlockDefinition>();
      }
    }

    if (_hasAnyKey(raw, const [
      'start_time',
      'end_time',
      'calendar_id',
      'calendar_name',
    ])) {
      return _findDefinition<CalendarEventBlockDefinition>();
    }

    final draft = raw['draft'];
    if (draft is Map) {
      final draftMap = Map<String, dynamic>.from(draft);
      if (_hasAnyKey(draftMap, const [
        'to',
        'cc',
        'bcc',
        'subject',
        'body',
        'from',
      ])) {
        return _findDefinition<EmailDraftBlockDefinition>();
      }
    }

    if (_hasAnyKey(raw, const [
      'emails',
      'messages',
      'mailbox',
      'email_messages',
    ])) {
      return _findDefinition<EmailListBlockDefinition>();
    }

    final task = raw['task'];
    if (task is Map) {
      final taskMap = Map<String, dynamic>.from(task);
      if (_hasAnyKey(taskMap, const [
        'task_id',
        'local_task_id',
        'backend_task_id',
        'name',
        'deadline',
        'priority',
        'progress_id',
        'project_id',
      ])) {
        return _findDefinition<TmsTaskBlockDefinition>();
      }
    }

    if (_hasAnyKey(raw, const [
      'task_id',
      'local_task_id',
      'backend_task_id',
      'name',
      'deadline',
      'priority',
      'progress_id',
      'project_id',
    ])) {
      final operation = (raw['operation'] ?? '').toString();

      if (operation == 'delete' || raw['deleted'] == true) {
        return _findDefinition<TmsTaskDeleteResultBlockDefinition>();
      }

      return _findDefinition<TmsTaskBlockDefinition>();
    }

    if (_hasAnyKey(raw, const [
      'tasks',
      'task_items',
    ])) {
      return _findDefinition<TmsTaskListBlockDefinition>();
    }

    if (_hasAnyKey(raw, const [
      'boards',
      'projects',
    ])) {
      return _findDefinition<TmsBoardListBlockDefinition>();
    }

    if (_hasAnyKey(raw, const [
      'project',
      'board',
    ])) {
      return _findDefinition<TmsProjectBlockDefinition>();
    }

    if (_hasAnyKey(raw, const [
      'column',
      'progress',
      'progress_column',
    ])) {
      return _findDefinition<TmsProgressColumnBlockDefinition>();
    }

    if (_hasAnyKey(raw, const [
      'anchors',
      'anchor_results',
      'search_results',
    ])) {
      return _findDefinition<UiAnchorSearchResultsBlockDefinition>();
    }

    if (_hasAnyKey(raw, const [
      'anchor_key',
      'client_action',
      'ui_action',
    ])) {
      return _findDefinition<UiAnchorActionBlockDefinition>();
    }

    if (_hasAnyKey(raw, const [
      'memo',
      'memos',
      'daily_overview',
      'followups',
    ])) {
      return _findDefinition<MemoDailyBlockDefinition>();
    }

    final ad = raw['ad'];
    if (ad is Map) {
      if (_hasAnyKey(Map<String, dynamic>.from(ad), const [
        'slug',
        'estate_type',
        'offer_type',
        'square_footage',
      ])) {
        return _findDefinition<AdCardBlockDefinition>();
      }
    }

    if (_hasAnyKey(raw, const ['ads'])) {
      return _findDefinition<AdListBlockDefinition>();
    }

    if (_hasAnyKey(raw, const ['comparison'])) {
      return _findDefinition<AdComparisonBlockDefinition>();
    }

    if (_hasAnyKey(raw, const ['mortgage'])) {
      return _findDefinition<MortgageResultBlockDefinition>();
    }

    if (_hasAnyKey(raw, const ['missing_documents', 'document_pipeline'])) {
      return _findDefinition<DocumentPipelineBlockDefinition>();
    }

    final workflow = raw['workflow'];
    if (workflow is Map) {
      final wfMap = Map<String, dynamic>.from(workflow);
      if (_hasAnyKey(wfMap, const [
        'trigger_count',
        'node_count',
        'scope_type',
        'trigger_labels',
      ])) {
        return _findDefinition<AutomationWorkflowBlockDefinition>();
      }
    }

    final dryRun = raw['dry_run'];
    if (dryRun is Map) {
      return _findDefinition<AutomationDryRunBlockDefinition>();
    }

    if (_hasAnyKey(raw, const ['wizard', 'automation_questions'])) {
      return _findDefinition<AutomationSetupWizardBlockDefinition>();
    }

    if (_hasAnyKey(raw, const ['connector', 'base_url', 'auth_type'])) {
      final connector = raw['connector'];
      if (connector is Map || raw['base_url'] != null) {
        return _findDefinition<AutomationConnectorBlockDefinition>();
      }
    }

    return null;
  }

  T? _findDefinition<T extends EmmaBlockDefinition>() {
    for (final definition in definitions) {
      if (definition is T) return definition;
    }
    return null;
  }

  static String _rawType(EmmaBlockDescriptor block) {
    return (block.raw['type'] ??
            block.raw['block_type'] ??
            block.raw['kind'] ??
            block.raw['variant_type'] ??
            '')
        .toString()
        .trim()
        .toLowerCase();
  }

  static String _toolName(EmmaBlockDescriptor block) {
    return (block.raw['tool_name'] ??
            block.raw['name'] ??
            block.raw['summary_tool_name'] ??
            block.raw['tool'] ??
            '')
        .toString()
        .trim();
  }

  static bool _hasAnyKey(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      if (map.containsKey(key) && map[key] != null) return true;
    }
    return false;
  }
}

final emmaBlockRegistryProvider = Provider<EmmaBlockRegistry>((ref) {
  return const EmmaBlockRegistry(
    definitions: [
      LoadingBlockDefinition(),
      InfoBlockDefinition(),
      ChoiceQuestionBlockDefinition(),
      WebSourcesBlockDefinition(),
      ImageBlockDefinition(),

      EmailDraftBlockDefinition(),
      EmailListBlockDefinition(),

      CalendarEventBlockDefinition(),
      CalendarEventListBlockDefinition(),

      TmsTaskBlockDefinition(),
      TmsTaskListBlockDefinition(),
      TmsTaskDeleteResultBlockDefinition(),
      TmsProjectBlockDefinition(),
      TmsProgressColumnBlockDefinition(),
      TmsBoardListBlockDefinition(),

      UiAnchorSearchResultsBlockDefinition(),
      UiAnchorActionBlockDefinition(),

      MemoDailyBlockDefinition(),

      SuggestionReplyBlockDefinition(),
      SuggestionEventBlockDefinition(),
      SuggestionTaskBlockDefinition(),
      SuggestionPrzetargBlockDefinition(),
      SuggestionInviteResponseBlockDefinition(),

      AdCardBlockDefinition(),
      AdListBlockDefinition(),
      AdComparisonBlockDefinition(),
      MortgageResultBlockDefinition(),

      DocsTextEditBlockDefinition(),
      DocsCreateFromContactBlockDefinition(),

      DocumentPipelineBlockDefinition(),

      AutomationWorkflowBlockDefinition(),
      AutomationDryRunBlockDefinition(),
      AutomationSetupWizardBlockDefinition(),
      AutomationConnectorBlockDefinition(),
    ],
    fallback: GenericBlockDefinition(),
  );
});