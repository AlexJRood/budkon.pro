import 'automation_common.dart';
import 'automation_graph.dart';

class AutomationTemplate {
  final String id;
  final int? companyId;
  final String name;
  final String description;
  final String category;
  final AutomationTemplateVisibility visibility;
  final AutomationWorkflowRiskLevel riskLevel;
  final AutomationGraph graph;

  const AutomationTemplate({
    required this.id,
    this.companyId,
    this.name = '',
    this.description = '',
    this.category = '',
    this.visibility = AutomationTemplateVisibility.private,
    this.riskLevel = AutomationWorkflowRiskLevel.low,
    this.graph = const AutomationGraph(),
  });

  factory AutomationTemplate.fromJson(Map<String, dynamic> json) {
    return AutomationTemplate(
      id: json['id']?.toString() ?? '',
      companyId: asInt(json['company_id'] ?? json['company']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      visibility: templateVisibilityFromJson(json['visibility']?.toString()),
      riskLevel: workflowRiskFromJson(json['risk_level']?.toString()),
      graph: AutomationGraph.fromJson(asMap(json['graph_json'])),
    );
  }
}
