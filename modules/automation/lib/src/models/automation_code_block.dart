import 'automation_common.dart';

class AutomationCodeBlock {
  final String id;
  final String? workflowId;
  final int? companyId;
  final String name;
  final String description;
  final AutomationCodeLanguage language;
  final String code;
  final AutomationCodeBlockStatus status;
  final AutomationCodeRiskLevel riskLevel;
  final Map<String, dynamic> validationReport;
  final DateTime? approvedAt;

  const AutomationCodeBlock({
    required this.id,
    this.workflowId,
    this.companyId,
    this.name = '',
    this.description = '',
    this.language = AutomationCodeLanguage.safeExpression,
    this.code = '',
    this.status = AutomationCodeBlockStatus.draft,
    this.riskLevel = AutomationCodeRiskLevel.high,
    this.validationReport = const {},
    this.approvedAt,
  });

  bool get isApproved => status == AutomationCodeBlockStatus.approved && approvedAt != null;

  factory AutomationCodeBlock.fromJson(Map<String, dynamic> json) {
    return AutomationCodeBlock(
      id: json['id']?.toString() ?? '',
      workflowId: json['workflow_id']?.toString() ?? json['workflow']?.toString(),
      companyId: asInt(json['company_id'] ?? json['company']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      language: codeLanguageFromJson(json['language']?.toString()),
      code: json['code']?.toString() ?? '',
      status: codeBlockStatusFromJson(json['status']?.toString()),
      riskLevel: codeRiskFromJson(json['risk_level']?.toString()),
      validationReport: asMap(json['validation_report']),
      approvedAt: asDate(json['approved_at']),
    );
  }

  Map<String, dynamic> toJsonForSave() => {
        if (id.isNotEmpty) 'id': id,
        'workflow': workflowId,
        'company': companyId,
        'name': name,
        'description': description,
        'language': enumName(language),
        'code': code,
      }..removeWhere((_, value) => value == null);
}

class AutomationCodeExecution {
  final String id;
  final String codeBlockId;
  final AutomationCodeExecutionStatus status;
  final Map<String, dynamic> outputData;
  final String stdout;
  final String stderr;
  final String errorMessage;
  final bool dryRun;

  const AutomationCodeExecution({
    required this.id,
    required this.codeBlockId,
    this.status = AutomationCodeExecutionStatus.queued,
    this.outputData = const {},
    this.stdout = '',
    this.stderr = '',
    this.errorMessage = '',
    this.dryRun = false,
  });

  factory AutomationCodeExecution.fromJson(Map<String, dynamic> json) {
    return AutomationCodeExecution(
      id: json['id']?.toString() ?? '',
      codeBlockId: json['code_block_id']?.toString() ?? json['code_block']?.toString() ?? '',
      status: codeExecutionStatusFromJson(json['status']?.toString()),
      outputData: asMap(json['output_data']),
      stdout: json['stdout']?.toString() ?? '',
      stderr: json['stderr']?.toString() ?? '',
      errorMessage: json['error_message']?.toString() ?? '',
      dryRun: asBool(json['dry_run']),
    );
  }
}
