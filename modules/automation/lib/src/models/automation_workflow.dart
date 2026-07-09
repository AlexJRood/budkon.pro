import 'automation_common.dart';
import 'automation_graph.dart';

class AutomationWorkflow {
  final String id;
  final String name;
  final String description;
  final AutomationWorkflowStatus status;
  final AutomationScopeType scopeType;
  final int? companyId;
  final int? ownerId;
  final AutomationGraph graph;
  final List<String> triggerKeys;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastRunAt;

  const AutomationWorkflow({
    required this.id,
    required this.name,
    this.description = '',
    this.status = AutomationWorkflowStatus.draft,
    this.scopeType = AutomationScopeType.user,
    this.companyId,
    this.ownerId,
    this.graph = const AutomationGraph(),
    this.triggerKeys = const [],
    this.createdAt,
    this.updatedAt,
    this.lastRunAt,
  });

  factory AutomationWorkflow.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String key) {
      final value = json[key]?.toString();
      if (value == null || value.isEmpty) return null;
      return DateTime.tryParse(value);
    }

    return AutomationWorkflow(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: workflowStatusFromJson(json['status']?.toString()),
      scopeType: scopeTypeFromJson(json['scope_type']?.toString()),
      companyId: (json['company_id'] as num?)?.toInt() ?? (json['company'] as num?)?.toInt(),
      ownerId: (json['owner_id'] as num?)?.toInt() ?? (json['owner'] as num?)?.toInt(),
      graph: AutomationGraph.fromJson(Map<String, dynamic>.from(json['graph_json'] as Map? ?? const {})),
      triggerKeys: (json['trigger_keys'] as List? ?? const []).map((item) => item.toString()).toList(),
      createdAt: parseDate('created_at'),
      updatedAt: parseDate('updated_at'),
      lastRunAt: parseDate('last_run_at'),
    );
  }

  Map<String, dynamic> toJsonForSave() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'description': description,
      'status': enumName(status),
      'scope_type': enumName(scopeType),
      'company_id': companyId,
      'owner_id': ownerId,
      'graph_json': graph.toJson(),
    };
  }

  AutomationWorkflow copyWith({
    String? id,
    String? name,
    String? description,
    AutomationWorkflowStatus? status,
    AutomationScopeType? scopeType,
    int? companyId,
    int? ownerId,
    AutomationGraph? graph,
    List<String>? triggerKeys,
  }) {
    return AutomationWorkflow(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      scopeType: scopeType ?? this.scopeType,
      companyId: companyId ?? this.companyId,
      ownerId: ownerId ?? this.ownerId,
      graph: graph ?? this.graph,
      triggerKeys: triggerKeys ?? this.triggerKeys,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastRunAt: lastRunAt,
    );
  }
}
