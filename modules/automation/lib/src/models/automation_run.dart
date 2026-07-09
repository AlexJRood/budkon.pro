import 'automation_common.dart';

class AutomationRun {
  final String id;
  final String workflowId;
  final String? eventId;
  final AutomationRunStatus status;
  final String errorMessage;
  final Map<String, dynamic> outputData;
  final List<AutomationNodeRun> nodeRuns;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  const AutomationRun({
    required this.id,
    required this.workflowId,
    this.eventId,
    this.status = AutomationRunStatus.queued,
    this.errorMessage = '',
    this.outputData = const {},
    this.nodeRuns = const [],
    this.createdAt,
    this.startedAt,
    this.finishedAt,
  });

  factory AutomationRun.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String key) {
      final value = json[key]?.toString();
      if (value == null || value.isEmpty) return null;
      return DateTime.tryParse(value);
    }

    return AutomationRun(
      id: json['id']?.toString() ?? '',
      workflowId: json['workflow']?.toString() ?? json['workflow_id']?.toString() ?? '',
      eventId: json['event']?.toString() ?? json['event_id']?.toString(),
      status: runStatusFromJson(json['status']?.toString()),
      errorMessage: json['error_message']?.toString() ?? '',
      outputData: Map<String, dynamic>.from(json['output_data'] as Map? ?? const {}),
      nodeRuns: (json['node_runs'] as List? ?? json['action_runs'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => AutomationNodeRun.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      createdAt: parseDate('created_at'),
      startedAt: parseDate('started_at'),
      finishedAt: parseDate('finished_at'),
    );
  }
}

class AutomationNodeRun {
  final String id;
  final String nodeId;
  final String nodeType;
  final String actionKey;
  final AutomationRunStatus status;
  final String errorMessage;
  final Map<String, dynamic> inputData;
  final Map<String, dynamic> outputData;

  const AutomationNodeRun({
    required this.id,
    required this.nodeId,
    this.nodeType = '',
    this.actionKey = '',
    this.status = AutomationRunStatus.queued,
    this.errorMessage = '',
    this.inputData = const {},
    this.outputData = const {},
  });

  factory AutomationNodeRun.fromJson(Map<String, dynamic> json) {
    return AutomationNodeRun(
      id: json['id']?.toString() ?? '',
      nodeId: json['node_id']?.toString() ?? '',
      nodeType: json['node_type']?.toString() ?? '',
      actionKey: json['action_key']?.toString() ?? '',
      status: runStatusFromJson(json['status']?.toString()),
      errorMessage: json['error_message']?.toString() ?? '',
      inputData: Map<String, dynamic>.from(json['input_data'] as Map? ?? const {}),
      outputData: Map<String, dynamic>.from(json['output_data'] as Map? ?? const {}),
    );
  }
}
