import 'package:flutter/foundation.dart';

enum EmmaBlockType {
  text,
  info,
  loading,

  emailDraft,
  emailList,

  calendarEvent,
  calendarEventList,

  tmsTask,
  tmsTaskList,
  tmsTaskDeleteResult,
  tmsProject,
  tmsProgressColumn,
  tmsBoardList,

  uiAnchorSearchResults,
  uiAnchorAction,

  memoDaily,

  advertisementCard,
  advertisementList,
  advertisementComparison,
  mortgageResult,

  suggestionReply,
  suggestionEvent,
  suggestionTask,
  suggestionInviteResponse,

  docsTextEdit,
  docsCreateFromContact,

  transactionDocumentPipeline,

  choiceQuestion,

  webSources,

  image,

  automationWorkflow,
  automationDryRun,
  automationSetupWizard,
  automationConnector,

  unknown,
}

@immutable
class EmmaBlockDescriptor {
  final EmmaBlockType type;
  final Map<String, dynamic> raw;

  const EmmaBlockDescriptor({
    required this.type,
    required this.raw,
  });

  factory EmmaBlockDescriptor.fromRaw(Map<String, dynamic> raw) {
    final type = (raw['type'] ?? '').toString().trim().toLowerCase();

    return EmmaBlockDescriptor(
      type: _detectType(type),
      raw: raw,
    );
  }

  static EmmaBlockType _detectType(String type) {
    switch (type.trim().toLowerCase()) {
      case 'text':
        return EmmaBlockType.text;

      case 'info':
        return EmmaBlockType.info;
      case 'loading':
        return EmmaBlockType.loading;

      case 'email_draft':
        return EmmaBlockType.emailDraft;
      case 'email_list':
        return EmmaBlockType.emailList;

      case 'calendar_event':
        return EmmaBlockType.calendarEvent;
      case 'calendar_event_list':
        return EmmaBlockType.calendarEventList;

      case 'tms_task':
        return EmmaBlockType.tmsTask;
      case 'tms_task_list':
        return EmmaBlockType.tmsTaskList;
      case 'tms_task_delete_result':
        return EmmaBlockType.tmsTaskDeleteResult;
      case 'tms_project':
        return EmmaBlockType.tmsProject;
      case 'tms_progress_column':
        return EmmaBlockType.tmsProgressColumn;
      case 'tms_board_list':
        return EmmaBlockType.tmsBoardList;

      case 'ui_anchor_search_results':
        return EmmaBlockType.uiAnchorSearchResults;
      case 'ui_anchor_action':
        return EmmaBlockType.uiAnchorAction;

      case 'memo_daily':
        return EmmaBlockType.memoDaily;

      case 'advertisement_card':
        return EmmaBlockType.advertisementCard;
      case 'advertisement_list':
        return EmmaBlockType.advertisementList;
      case 'advertisement_comparison':
        return EmmaBlockType.advertisementComparison;
      case 'mortgage_result':
        return EmmaBlockType.mortgageResult;

      case 'suggestion_reply':
        return EmmaBlockType.suggestionReply;
      case 'suggestion_event':
        return EmmaBlockType.suggestionEvent;
      case 'suggestion_task':
        return EmmaBlockType.suggestionTask;
      case 'suggestion_invite_response':
        return EmmaBlockType.suggestionInviteResponse;

      case 'docs_text_edit':
        return EmmaBlockType.docsTextEdit;

      case 'docs_create_from_contact':
        return EmmaBlockType.docsCreateFromContact;

      case 'transaction_document_pipeline':
      case 'doc_pipeline':
      case 'document_pipeline':
        return EmmaBlockType.transactionDocumentPipeline;

      case 'choice_question':
      case 'question':
      case 'quick_replies':
      case 'ask_user':
        return EmmaBlockType.choiceQuestion;

      case 'web_sources':
      case 'search_sources':
      case 'sources':
        return EmmaBlockType.webSources;

      case 'image':
      case 'generated_image':
        return EmmaBlockType.image;

      case 'automation_workflow':
      case 'automation_draft':
      case 'automation_created':
        return EmmaBlockType.automationWorkflow;

      case 'automation_dry_run':
      case 'automation_dry_run_result':
        return EmmaBlockType.automationDryRun;

      case 'automation_setup_wizard':
      case 'automation_wizard':
      case 'automation_questions':
        return EmmaBlockType.automationSetupWizard;

      case 'automation_connector':
      case 'automation_api_connector':
      case 'external_api_connector':
        return EmmaBlockType.automationConnector;

      default:
        return EmmaBlockType.unknown;
    }
  }
}